// lib/widgets/notification_test_widget.dart
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationTestWidget extends StatefulWidget {
  const NotificationTestWidget({super.key});

  @override
  State<NotificationTestWidget> createState() => _NotificationTestWidgetState();
}

class _NotificationTestWidgetState extends State<NotificationTestWidget> {
  final NotificationService _notificationService = NotificationService();
  String _status = 'Ready to test notifications';
  bool _isLoading = false;
  Color _statusColor = Colors.blue;

  void _updateStatus(String status, {Color? color}) {
    setState(() {
      _status = status;
      _statusColor = color ?? Colors.blue;
    });
    // ignore: avoid_print
    print('🔔 $status');
  }

  Future<void> _initializeAndTest() async {
    setState(() => _isLoading = true);
    _updateStatus('Initializing notification service...', color: Colors.orange);
    
    try {
      await _notificationService.initialize();
      _updateStatus('✅ Service initialized! Test notification should appear now.', 
                   color: Colors.green);
      
      // Show debug info
      await _notificationService.debugNotificationSettings();
      
    } catch (e) {
      _updateStatus('❌ Initialization failed: $e', color: Colors.red);
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _sendImmediateTest() async {
    _updateStatus('Sending immediate test notification...', color: Colors.orange);
    
    try {
      await _notificationService.sendTestNotification();
      _updateStatus('✅ Test notification sent! Check your notification panel.', 
                   color: Colors.green);
    } catch (e) {
      _updateStatus('❌ Test notification failed: $e', color: Colors.red);
    }
  }

  Future<void> _checkPendingNotifications() async {
    _updateStatus('Checking pending notifications...', color: Colors.blue);
    try {
      final pending = await _notificationService.getPendingNotifications();
      _updateStatus('📋 Found ${pending.length} pending notifications', 
                   color: Colors.blue);
    } catch (e) {
      _updateStatus('❌ Error checking pending: $e', color: Colors.red);
    }
  }

  Future<void> _checkPermissions() async {
    _updateStatus('Checking notification permissions...', color: Colors.blue);
    try {
      final enabled = await _notificationService.areNotificationsEnabled();
      _updateStatus(
        enabled ? '✅ Notifications are enabled' : '❌ Notifications are disabled - tap "Open Settings"', 
        color: enabled ? Colors.green : Colors.red
      );
    } catch (e) {
      _updateStatus('❌ Error checking permissions: $e', color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '🧪 Notification Test Panel',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                // ignore: deprecated_member_use
                border: Border.all(color: _statusColor.withOpacity(0.3)),
              ),
              child: Text(
                _status,
                style: TextStyle(
                  fontSize: 12, 
                  fontFamily: 'monospace',
                  color: _statusColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _initializeAndTest,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Initialize & Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  ElevatedButton.icon(
                    onPressed: _sendImmediateTest,
                    icon: const Icon(Icons.notification_add),
                    label: const Text('Send Test Notification'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _checkPermissions,
                          icon: const Icon(Icons.security, size: 16),
                          label: const Text('Check Permissions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _checkPendingNotifications,
                          icon: const Icon(Icons.list, size: 16),
                          label: const Text('Check Pending'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  TextButton.icon(
                    onPressed: () => _notificationService.openNotificationSettings(),
                    icon: const Icon(Icons.settings),
                    label: const Text('Open Settings'),
                  ),
                ],
              ),
            
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Instructions:\n'
                '1. Tap "Initialize & Test" first\n'
                '2. Then tap "Send Test Notification"\n'
                '3. Check your notification panel for the notification\n'
                '4. If no notification appears, check permissions\n'
                '5. Use "Open Settings" if permissions are disabled',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}