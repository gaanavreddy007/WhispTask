// ignore_for_file: unused_import, unnecessary_import, avoid_print

import 'dart:ui';
import 'dart:io';

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _isInitialized = false;

  // Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔔 Starting NotificationService initialization...');

      // Initialize timezone data
      tz_data.initializeTimeZones();
      debugPrint('✅ Timezone data initialized');

      // Initialize local notifications
      await _initializeLocalNotifications();
      debugPrint('✅ Local notifications initialized');
      
      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();
      debugPrint('✅ Firebase messaging initialized');

      // Create notification channel for Android
      await _createNotificationChannel();
      debugPrint('✅ Notification channel created');

      // Request permissions explicitly
      await _requestAllPermissions();
      debugPrint('✅ Permissions requested');

      _isInitialized = true;
      debugPrint('🎉 NotificationService initialized successfully');
      
    } catch (e) {
      print('Error initializing notifications: $e');
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('service', 'notification');
          scope.setTag('operation', 'initialize');
          scope.level = SentryLevel.error;
        },
      );
      _isInitialized = false;
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: null, // For iOS < 10
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  // Create Android notification channel
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'task_reminders',
      'Task Reminders',
      description: 'Notifications for task reminders in WhispTask',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
        
    debugPrint('📱 Android notification channel created: ${channel.id}');
  }

  // Request all necessary permissions
  Future<void> _requestAllPermissions() async {
    // For Android 13+ notification permission
    if (Platform.isAndroid) {
      final notificationStatus = await Permission.notification.status;
      debugPrint('📋 Current notification permission: $notificationStatus');
      
      if (notificationStatus.isDenied) {
        final result = await Permission.notification.request();
        debugPrint('📋 Notification permission request result: $result');
        
        if (result.isDenied) {
          debugPrint('⚠️ Notification permission denied by user');
        }
      }
      
      // Request exact alarm permission for Android 12+
      final alarmStatus = await Permission.scheduleExactAlarm.status;
      if (alarmStatus.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    }

    // For local notifications plugin
    final bool? localResult = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    debugPrint('📱 Local notifications permission: $localResult');
  }

  // Initialize Firebase Cloud Messaging
  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Request permission
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('🔥 FCM Permission status: ${settings.authorizationStatus}');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background message taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

      // Get FCM token
      String? token = await _firebaseMessaging.getToken();
      debugPrint('🔥 FCM Token: ${token?.substring(0, 20)}...');
    } catch (e) {
      debugPrint('⚠️ Firebase messaging initialization failed: $e');
      // Continue without FCM if it fails
    }
  }

  // Handle notification tap
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('👆 Notification tapped: ${response.payload}');
    // Handle navigation based on payload
    // You can parse the payload and navigate to specific task
  }

  // Handle foreground FCM messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📨 Received foreground message: ${message.messageId}');
    
    // Show local notification for foreground messages
    if (message.notification != null) {
      _showLocalNotification(
        id: message.hashCode,
        title: message.notification!.title ?? 'WhispTask',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  // Handle background message tap
  void _handleBackgroundMessageTap(RemoteMessage message) {
    debugPrint('📨 Background message tapped: ${message.messageId}');
    // Handle navigation
  }

  // Schedule task reminder notification
  Future<void> scheduleTaskReminder(Task task) async {
    if (!task.hasActiveReminder || task.reminderTime == null) {
      debugPrint('⏭️ Skipping reminder for task: ${task.title} (no active reminder)');
      return;
    }

    final int notificationId = task.id.hashCode.abs();
    
    try {
      debugPrint('⏰ Scheduling reminder for task: ${task.title}');
      
      // Check permissions first
      final hasPermission = await _hasNotificationPermission();
      if (!hasPermission) {
        debugPrint('⚠️ No notification permission - requesting...');
        final granted = await _requestNotificationPermission();
        if (!granted) {
          debugPrint('❌ Notification permission denied');
          return;
        }
      }
      
      // Cancel existing notification
      await cancelNotification(notificationId);

      // Determine notification details based on task
      final notificationDetails = _getNotificationDetails(task.notificationTone);
      
      // Convert reminder time to timezone
      final tz.TZDateTime scheduledDate = _convertToTZDateTime(task.reminderTime!);
      
      // Check if the scheduled time is in the future
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint('⚠️ Scheduled time is in the past for task: ${task.title}');
        return;
      }

      // Schedule based on reminder type
      switch (task.reminderType) {
        case 'once':
          await _scheduleOnceNotification(
            notificationId, 
            task, 
            scheduledDate, 
            notificationDetails
          );
          break;
        
        case 'daily':
          await _scheduleDailyNotification(
            notificationId, 
            task, 
            scheduledDate, 
            notificationDetails
          );
          break;
        
        case 'weekly':
          await _scheduleWeeklyNotification(
            notificationId, 
            task, 
            scheduledDate, 
            notificationDetails
          );
          break;
      }

      debugPrint('✅ Scheduled ${task.reminderType} reminder for: ${task.title} at $scheduledDate');
    } catch (e) {
      print('Error scheduling notification: $e');
      await Sentry.captureException(
        e,
        stackTrace: StackTrace.current,
        withScope: (scope) {
          scope.setTag('service', 'notification');
          scope.setTag('operation', 'schedule_notification');
          scope.setExtra('notification_id', notificationId);
          scope.setExtra('scheduled_time', task.reminderTime.toString());
          scope.level = SentryLevel.warning;
        },
      );
      rethrow;
    }
  }

  // Schedule one-time notification
  Future<void> _scheduleOnceNotification(
    int id, 
    Task task, 
    tz.TZDateTime scheduledDate, 
    NotificationDetails details
  ) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      '📋 Task Reminder',
      task.title,
      scheduledDate,
      details,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: task.id,
    );
  }

  // Schedule daily notification
  Future<void> _scheduleDailyNotification(
    int id, 
    Task task, 
    tz.TZDateTime scheduledDate, 
    NotificationDetails details
  ) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      '🔄 Daily Reminder',
      task.title,
      scheduledDate,
      details,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Daily repeat
      payload: task.id,
    );
  }

  // Schedule weekly notification
  Future<void> _scheduleWeeklyNotification(
    int id, 
    Task task, 
    tz.TZDateTime scheduledDate, 
    NotificationDetails details
  ) async {
    if (task.repeatDays.isEmpty) {
      // Default to weekly on same day
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        '📅 Weekly Reminder',
        task.title,
        scheduledDate,
        details,
        uiLocalNotificationDateInterpretation: 
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: task.id,
      );
    } else {
      // Schedule for specific days
      for (int i = 0; i < task.repeatDays.length; i++) {
        final dayOffset = _getDayOffset(task.repeatDays[i]);
        final dayScheduledDate = _getNextWeekday(scheduledDate, dayOffset);
        
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id + i, // Unique ID for each day
          '📅 Weekly Reminder',
          '${task.repeatDays[i].toUpperCase()}: ${task.title}',
          dayScheduledDate,
          details,
          uiLocalNotificationDateInterpretation: 
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: task.id,
        );
      }
    }
  }

  // Show immediate notification
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String tone = 'default',
  }) async {
    final details = _getNotificationDetails(tone);
    
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
    
    debugPrint('📬 Immediate notification sent: $title');
  }

  // Get notification details based on tone - FIXED VERSION
  NotificationDetails _getNotificationDetails(String tone) {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for task reminders in WhispTask',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@drawable/ic_notification',
      color: const Color(0xFF6366F1), // Indigo color
      ledColor: const Color(0xFF6366F1),
      ledOnMs: 1000,
      ledOffMs: 500,
      enableVibration: true,
      vibrationPattern: Int64List.fromList(const [0, 1000, 500, 1000]),
      playSound: true,
      // REMOVED CUSTOM SOUND - Using default system sound instead
      // sound: const RawResourceAndroidNotificationSound('notification'),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default.caf',
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  // Convert DateTime to TZDateTime
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    final tz.Location local = tz.local; // Use the device's local timezone
    return tz.TZDateTime.from(dateTime, local);
  }

  // Get day offset for weekly scheduling
  int _getDayOffset(String day) {
    const dayMap = {
      'mon': 1, 'tue': 2, 'wed': 3, 'thu': 4, 
      'fri': 5, 'sat': 6, 'sun': 7
    };
    return dayMap[day.toLowerCase()] ?? 1;
  }

  // Get next occurrence of weekday
  tz.TZDateTime _getNextWeekday(tz.TZDateTime date, int weekday) {
    int daysToAdd = weekday - date.weekday;
    if (daysToAdd <= 0) daysToAdd += 7;
    return date.add(Duration(days: daysToAdd));
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
    debugPrint('🗑️ Cancelled notification: $id');
  }

  // Static method for canceling notifications
  static Future<void> cancelNotificationStatic(int id) async {
    final instance = NotificationService();
    await instance.cancelNotification(id);
  }

  // Schedule a notification (alias for scheduleTaskReminder)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    String reminderType = 'once', // Default to 'once'
  }) async {
    final task = Task(
      id: id.toString(),
      title: title,
      description: body,
      createdAt: DateTime.now(),
      reminderTime: scheduledTime,
      hasReminder: true,
      notificationId: id,
      reminderType: reminderType, // Pass reminderType
    );
    await scheduleTaskReminder(task);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('🗑️ Cancelled all notifications');
  }

  // Check if notification permission is granted
  Future<bool> _hasNotificationPermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        return status.isGranted;
      } else if (Platform.isIOS) {
        final settings = await _firebaseMessaging.getNotificationSettings();
        return settings.authorizationStatus == AuthorizationStatus.authorized;
      }
      return true; // Default for other platforms
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return false;
    }
  }

  // Request notification permission
  Future<bool> _requestNotificationPermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        return status.isGranted;
      } else if (Platform.isIOS) {
        final settings = await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        return settings.authorizationStatus == AuthorizationStatus.authorized;
      }
      return true; // Default for other platforms
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  // Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final pending = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    debugPrint('📋 Pending notifications: ${pending.length}');
    for (final notification in pending) {
      debugPrint('  - ID: ${notification.id}, Title: ${notification.title}');
    }
    return pending;
  }

  // Send test notification - FIXED VERSION
  Future<void> sendTestNotification() async {
    try {
      debugPrint('🧪 Sending test notification...');
      
      await _showLocalNotification(
        id: 999,
        title: '🎉 WhispTask Ready!',
        body: 'Notifications are working perfectly! You\'re all set to manage your tasks.',
        tone: 'default',
      );
      
      debugPrint('✅ Test notification sent successfully');
      
      // Wait a moment to check if notification actually appeared
      await Future.delayed(const Duration(milliseconds: 500));
      
    } catch (e) {
      debugPrint('❌ Failed to send test notification: $e');
      rethrow; // Re-throw so the error shows in the UI
    }
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    } else {
      // For iOS, check if the app has notification permissions
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    }
  }

  // Open app notification settings
  Future<void> openNotificationSettings() async {
    await openAppSettings();
  }

  // Debug method to print all settings
  Future<void> debugNotificationSettings() async {
    debugPrint('🔍 === Notification Debug Info ===');
    debugPrint('Service initialized: $_isInitialized');
    debugPrint('Platform: ${Platform.operatingSystem}');
    
    if (Platform.isAndroid) {
      final notificationStatus = await Permission.notification.status;
      final alarmStatus = await Permission.scheduleExactAlarm.status;
      debugPrint('Notification permission: $notificationStatus');
      debugPrint('Exact alarm permission: $alarmStatus');
    }
    
    final pending = await getPendingNotifications();
    debugPrint('Pending notifications: ${pending.length}');
    
    try {
      final fcmSettings = await _firebaseMessaging.getNotificationSettings();
      debugPrint('FCM authorization: ${fcmSettings.authorizationStatus}');
    } catch (e) {
      debugPrint('FCM settings unavailable: $e');
    }
    
    debugPrint('=== End Debug Info ===');
  }
}