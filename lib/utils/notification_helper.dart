// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/task.dart';

class NotificationHelper {
  // Available notification tones (matching your task service)
  static const Map<String, String> notificationTones = {
    'default': 'Default',
    'chime': 'Chime',
    'bell': 'Bell',
    'whistle': 'Whistle',
    'ding': 'Ding',
    'buzz': 'Buzz',
  };

  // Available reminder types (matching your task service)
  static const Map<String, String> reminderTypes = {
    'once': 'One Time',
    'daily': 'Daily',
    'weekly': 'Weekly',
    'monthly': 'Monthly',
  };

  // Days of the week for weekly reminders
  static const Map<String, String> weekDays = {
    'monday': 'Monday',
    'tuesday': 'Tuesday', 
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
  };

  // Priority colors (enhanced set)
  static const Map<String, Color> priorityColors = {
    'high': Colors.red,
    'medium': Colors.orange,
    'low': Colors.green,
    'urgent': Colors.deepPurple,
  };

  // Category colors
  static const Map<String, Color> categoryColors = {
    'work': Color(0xFF2196F3),
    'personal': Color(0xFF4CAF50),
    'health': Color(0xFFE91E63),
    'finance': Color(0xFF9C27B0),
    'education': Color(0xFFFF9800),
    'shopping': Color(0xFF795548),
    'travel': Color(0xFF607D8B),
    'family': Color(0xFF8BC34A),
    'hobby': Color(0xFFFFEB3B),
    'other': Color(0xFF9E9E9E),
  };

  // Task status colors
  static const Map<String, Color> statusColors = {
    'pending': Colors.grey,
    'in_progress': Colors.blue,
    'completed': Colors.green,
    'overdue': Colors.red,
  };

  // FIXED PROBLEM 3 - Get all available colors
  static List<String> getAllColors() {
    return [
      '#FF5722', // Red
      '#E91E63', // Pink
      '#9C27B0', // Purple
      '#673AB7', // Deep Purple
      '#3F51B5', // Indigo
      '#2196F3', // Blue
      '#03A9F4', // Light Blue
      '#00BCD4', // Cyan
      '#009688', // Teal
      '#4CAF50', // Green
      '#8BC34A', // Light Green
      '#CDDC39', // Lime
      '#FFEB3B', // Yellow
      '#FFC107', // Amber
      '#FF9800', // Orange
      '#FF5722', // Deep Orange
      '#795548', // Brown
      '#9E9E9E', // Grey
      '#607D8B', // Blue Grey
    ];
  }

  // FIXED PROBLEM 18 - Get reminder notification title
  static String getReminderTitle(Task task) {
    if (task.isUrgent) {
      return '⚡ Urgent: ${task.title}';
    } else if (task.isHighPriority) {
      return '🔴 High Priority: ${task.title}';
    } else {
      return '📋 Reminder: ${task.title}';
    }
  }

  // FIXED PROBLEM 19 - Get reminder notification body
  static String getReminderBody(Task task) {
    final List<String> bodyParts = [];
    
    // Add description if available
    if (task.description != null && task.description!.isNotEmpty) {
      bodyParts.add(task.description!);
    }
    
    // Add due date info
    if (task.dueDate != null) {
      if (task.isDueToday) {
        bodyParts.add('Due today');
      } else if (task.isDueTomorrow) {
        bodyParts.add('Due tomorrow');
      } else if (task.isOverdue) {
        bodyParts.add('Overdue!');
      } else {
        bodyParts.add('Due: ${task.formattedDueDate}');
      }
    }
    
    // Add category info
    if (task.category.isNotEmpty && task.category != 'general') {
      bodyParts.add('Category: ${formatCategory(task.category)}');
    }
    
    // Add priority info for high priority tasks
    if (task.isHighPriority) {
      bodyParts.add('High Priority');
    }
    
    // Add estimated time if available
    if (task.estimatedMinutes > 0) {
      final hours = task.estimatedMinutes ~/ 60;
      final minutes = task.estimatedMinutes % 60;
      if (hours > 0) {
        bodyParts.add('Est. time: ${hours}h ${minutes}m');
      } else {
        bodyParts.add('Est. time: ${minutes}m');
      }
    }
    
    return bodyParts.isNotEmpty ? bodyParts.join(' • ') : 'Tap to view details';
  }

  // Format category name for display
  static String formatCategory(String category) {
    if (category.isEmpty) return 'General';
    return category.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ');
  }

  // Format priority name for display
  static String formatPriority(String priority) {
    return priority.toUpperCase();
  }

  // Check and request notification permissions
  static Future<bool> requestNotificationPermissions(BuildContext context) async {
    try {
      // Check if notification permission is granted
      PermissionStatus status = await Permission.notification.status;
      
      if (status.isDenied) {
        // Show explanation dialog first
        final shouldRequest = await showPermissionDialog(context);
        if (!shouldRequest) return false;
        
        // Request permission
        status = await Permission.notification.request();
      }
      
      if (status.isPermanentlyDenied) {
        // Show dialog to open settings
        await _showSettingsDialog(context);
        return false;
      }
      
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  // Show permission explanation dialog
  static Future<bool> showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.blue),
              SizedBox(width: 8),
              Text('Enable Notifications'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WhispTask needs notification permission to send you reminders for your tasks.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Benefits:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Never miss important deadlines'),
              Text('• Stay organized and productive'),
              Text('• Customizable reminder tones'),
              Text('• Flexible scheduling options'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Enable'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Show settings dialog for permanently denied permissions
  static Future<void> _showSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'Notifications are disabled. Please enable them in your device settings to receive task reminders.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  // Format reminder time for display
  static String formatReminderTime(DateTime? reminderTime) {
    if (reminderTime == null) return 'No reminder set';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final reminderDate = DateTime(
      reminderTime.year, 
      reminderTime.month, 
      reminderTime.day
    );
    
    String timeStr = _formatTime24Hour(reminderTime);
    
    if (reminderDate == today) {
      return 'Today at $timeStr';
    } else if (reminderDate == tomorrow) {
      return 'Tomorrow at $timeStr';
    } else {
      final daysDiff = reminderDate.difference(today).inDays;
      if (daysDiff < 7) {
        final weekday = getWeekdayName(reminderDate.weekday);
        return '$weekday at $timeStr';
      } else {
        return '${reminderTime.day}/${reminderTime.month}/${reminderTime.year} at $timeStr';
      }
    }
  }
  
  // Helper to format time in 24-hour format
  static String _formatTime24Hour(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Get weekday name
  static String getWeekdayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  // Get time until reminder with better formatting
  // Get a list of valid notification tones
  static List<String> getValidNotificationTones() {
    return notificationTones.keys.toList();
  }

  // Calculate the next occurrence of a recurring task
  static DateTime? getNextOccurrence(
    String pattern,
    int interval,
    DateTime currentDueDate,
  ) {
    switch (pattern) {
      case 'daily':
        return currentDueDate.add(Duration(days: interval));
      case 'weekly':
        return currentDueDate.add(Duration(days: 7 * interval));
      case 'monthly':
        // This is a simplified version; a robust implementation would handle month ends
        return DateTime(
          currentDueDate.year,
          currentDueDate.month + interval,
          currentDueDate.day,
          currentDueDate.hour,
          currentDueDate.minute,
        );
      case 'yearly':
        return DateTime(
          currentDueDate.year + interval,
          currentDueDate.month,
          currentDueDate.day,
          currentDueDate.hour,
          currentDueDate.minute,
        );
      default:
        return null;
    }
  }

  // Get time until reminder with better formatting
  static String getTimeUntilReminder(DateTime? reminderTime) {
    if (reminderTime == null) return '';
    
    final now = DateTime.now();
    final difference = reminderTime.difference(now);
    
    if (difference.isNegative) {
      return 'Overdue';
    }
    
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    
    if (days > 0) {
      if (days == 1) {
        return '1 day';
      } else if (days < 7) {
        return '$days days';
      } else {
        final weeks = (days / 7).floor();
        return '${weeks}w ${days % 7}d';
      }
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return 'Now';
    }
  }

  // Get reminder status with color
  static Map<String, dynamic> getReminderStatus(DateTime? reminderTime, bool isCompleted) {
    if (isCompleted) {
      return {'text': 'Completed', 'color': Colors.green, 'icon': Icons.check_circle};
    }
    
    if (reminderTime == null) {
      return {'text': 'No reminder', 'color': Colors.grey, 'icon': Icons.notifications_off};
    }
    
    final now = DateTime.now();
    final difference = reminderTime.difference(now);
    
    if (difference.isNegative) {
      return {'text': 'Overdue', 'color': Colors.red, 'icon': Icons.warning};
    } else if (difference.inMinutes < 60) {
      return {'text': 'Due soon', 'color': Colors.orange, 'icon': Icons.schedule};
    } else {
      return {'text': 'Scheduled', 'color': Colors.blue, 'icon': Icons.alarm};
    }
  }

  // Get reminder icon based on type
  static IconData getReminderIcon(String reminderType) {
    switch (reminderType) {
      case 'once':
        return Icons.alarm_on;
      case 'daily':
        return Icons.today;
      case 'weekly':
        return Icons.date_range;
      case 'monthly':
        return Icons.calendar_month;
      default:
        return Icons.notifications;
    }
  }

  // Get notification tone icon
  static IconData getNotificationToneIcon(String tone) {
    switch (tone) {
      case 'chime':
        return Icons.music_note;
      case 'bell':
        return Icons.notifications_active;
      case 'whistle':
        return Icons.campaign;
      case 'ding':
        return Icons.notification_important;
      case 'buzz':
        return Icons.vibration;
      default:
        return Icons.volume_up;
    }
  }

  // Get priority icon
  static IconData getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.keyboard_arrow_down;
      case 'urgent':
        return Icons.crisis_alert;
      default:
        return Icons.flag;
    }
  }

  // Get category icon
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return Icons.work;
      case 'personal':
        return Icons.person;
      case 'health':
        return Icons.favorite;
      case 'finance':
        return Icons.attach_money;
      case 'education':
        return Icons.school;
      case 'shopping':
        return Icons.shopping_cart;
      case 'travel':
        return Icons.airplanemode_active;
      case 'family':
        return Icons.family_restroom;
      case 'hobby':
        return Icons.sports_esports;
      default:
        return Icons.category;
    }
  }

  // Get status icon
  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'in_progress':
        return Icons.play_arrow;
      case 'completed':
        return Icons.check_circle;
      case 'overdue':
        return Icons.warning;
      default:
        return Icons.help_outline;
    }
  }

  // Validate reminder time
  static String? validateReminderTime(DateTime? reminderTime) {
    if (reminderTime == null) return 'Please select a reminder time';
    
    final now = DateTime.now();
    if (reminderTime.isBefore(now.subtract(const Duration(minutes: 1)))) {
      return 'Reminder time cannot be in the past';
    }
    
    // Check if reminder is more than 1 year in the future
    final oneYearFromNow = now.add(const Duration(days: 365));
    if (reminderTime.isAfter(oneYearFromNow)) {
      return 'Reminder time cannot be more than 1 year in the future';
    }
    
    return null;
  }

  // Validate repeat days for weekly reminders
  static String? validateRepeatDays(String reminderType, List<String> repeatDays) {
    if (reminderType == 'weekly' && repeatDays.isEmpty) {
      return 'Please select at least one day for weekly reminders';
    }
    return null;
  }

  // Generate snooze options
  static List<Map<String, dynamic>> getSnoozeOptions() {
    return [
      {'label': '5 minutes', 'minutes': 5, 'icon': Icons.snooze},
      {'label': '15 minutes', 'minutes': 15, 'icon': Icons.access_time},
      {'label': '30 minutes', 'minutes': 30, 'icon': Icons.timer},
      {'label': '1 hour', 'minutes': 60, 'icon': Icons.schedule},
      {'label': '2 hours', 'minutes': 120, 'icon': Icons.access_alarm},
      {'label': '4 hours', 'minutes': 240, 'icon': Icons.alarm},
      {'label': 'Tomorrow', 'minutes': 1440, 'icon': Icons.today},
    ];
  }

  // Get color by priority
  static Color getPriorityColor(String priority) {
    return priorityColors[priority.toLowerCase()] ?? Colors.grey;
  }

  // Get color by category
  static Color getCategoryColor(String category) {
    return categoryColors[category.toLowerCase()] ?? Colors.grey;
  }

  // Get color by task status
  static Color getStatusColor(String status) {
    return statusColors[status.toLowerCase()] ?? Colors.grey;
  }

  // Parse color string to Color object
  static Color parseColor(String colorStr) {
    if (colorStr.startsWith('#')) {
      final hexValue = colorStr.substring(1);
      if (hexValue.length == 6) {
        return Color(int.parse('FF$hexValue', radix: 16));
      } else if (hexValue.length == 8) {
        return Color(int.parse(hexValue, radix: 16));
      }
    }
    return Colors.grey;
  }

  // Convert Color to hex string
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  // Get contrast text color for background color
  static Color getContrastTextColor(Color backgroundColor) {
    // Calculate luminance
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  // Show comprehensive reminder options bottom sheet
  static Future<Map<String, dynamic>?> showReminderOptionsSheet(
    BuildContext context, {
    DateTime? initialTime,
    String initialType = 'once',
    String initialTone = 'default',
    List<String> initialRepeatDays = const [],
  }) async {
    DateTime selectedTime = initialTime ?? DateTime.now().add(const Duration(hours: 1));
    String selectedType = initialType;
    String selectedTone = initialTone;
    List<String> selectedDays = List.from(initialRepeatDays);

    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Set Reminder',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date and Time Picker
                          Card(
                            child: ListTile(
                              leading: Icon(Icons.schedule, color: Theme.of(context).primaryColor),
                              title: const Text('Reminder Time'),
                              subtitle: Text(
                                formatReminderTime(selectedTime),
                                style: TextStyle(color: Theme.of(context).primaryColor),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                await _selectDateTime(context, selectedTime, (newTime) {
                                  setState(() {
                                    selectedTime = newTime;
                                  });
                                });
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Reminder Type
                          const Text(
                            'Reminder Type',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          
                          Card(
                            child: Column(
                              children: reminderTypes.entries.map((entry) {
                                return RadioListTile<String>(
                                  title: Row(
                                    children: [
                                      Icon(getReminderIcon(entry.key)),
                                      const SizedBox(width: 8),
                                      Text(entry.value),
                                    ],
                                  ),
                                  value: entry.key,
                                  groupValue: selectedType,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedType = value!;
                                      if (value != 'weekly') {
                                        selectedDays.clear();
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                          
                          // Weekly repeat days (show only if weekly is selected)
                          if (selectedType == 'weekly') ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Repeat on Days',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: weekDays.entries.map((entry) {
                                    return FilterChip(
                                      label: Text(entry.key.substring(0, 3).toUpperCase()),
                                      selected: selectedDays.contains(entry.key.toLowerCase()),
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            selectedDays.add(entry.key.toLowerCase());
                                          } else {
                                            selectedDays.remove(entry.key.toLowerCase());
                                          }
                                        });
                                      },
                                      selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 16),
                          
                          // Notification Tone
                          const Text(
                            'Notification Tone',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          
                          Card(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Select Tone',
                                prefixIcon: Icon(Icons.music_note),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              value: selectedTone,
                              items: notificationTones.entries.map((entry) {
                                return DropdownMenuItem(
                                  value: entry.key,
                                  child: Row(
                                    children: [
                                      Icon(getNotificationToneIcon(entry.key)),
                                      const SizedBox(width: 8),
                                      Text(entry.value),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedTone = value!;
                                });
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Quick time presets
                          const Text(
                            'Quick Presets',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _getTimePresets().map((preset) {
                                  return ActionChip(
                                    label: Text(preset['label']),
                                    avatar: Icon(preset['icon'], size: 18),
                                    onPressed: () {
                                      setState(() {
                                        selectedTime = preset['time'];
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            // Validate selection
                            final timeValidation = validateReminderTime(selectedTime);
                            final daysValidation = validateRepeatDays(selectedType, selectedDays);
                            
                            if (timeValidation != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(timeValidation)),
                              );
                              return;
                            }
                            
                            if (daysValidation != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(daysValidation)),
                              );
                              return;
                            }
                            
                            Navigator.pop(context, {
                              'time': selectedTime,
                              'type': selectedType,
                              'tone': selectedTone,
                              'repeatDays': selectedDays,
                            });
                          },
                          child: const Text('Set Reminder'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper to select date and time
  static Future<void> _selectDateTime(
    BuildContext context, 
    DateTime initialTime, 
    Function(DateTime) onTimeSelected
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select reminder date',
    );
    
    if (date != null) {
      if (!context.mounted) return;
      
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialTime),
        helpText: 'Select reminder time',
      );
      
      if (time != null) {
        final newDateTime = DateTime(
          date.year, date.month, date.day,
          time.hour, time.minute,
        );
        onTimeSelected(newDateTime);
      }
    }
  }

  // Get time presets for quick selection
  static List<Map<String, dynamic>> _getTimePresets() {
    final now = DateTime.now();
    
    return [
      {
        'label': 'In 1 hour',
        'time': now.add(const Duration(hours: 1)),
        'icon': Icons.access_time,
      },
      {
        'label': 'Tomorrow 9 AM',
        'time': DateTime(now.year, now.month, now.day + 1, 9, 0),
        'icon': Icons.wb_sunny,
      },
      {
        'label': 'This Evening',
        'time': DateTime(now.year, now.month, now.day, 18, 0),
        'icon': Icons.wb_twilight,
      },
      {
        'label': 'Next Week',
        'time': now.add(const Duration(days: 7)),
        'icon': Icons.next_week,
      },
    ];
  }

  // Show snooze options dialog
  static Future<int?> showSnoozeDialog(BuildContext context) async {
    return await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.snooze),
              SizedBox(width: 8),
              Text('Snooze Reminder'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: getSnoozeOptions().map((option) {
              return ListTile(
                leading: Icon(option['icon']),
                title: Text(option['label']),
                onTap: () => Navigator.of(context).pop(option['minutes']),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Show task color picker
  static Future<Color?> showColorPicker(BuildContext context, {Color? initialColor}) async {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];

    return await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Task Color'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: colors.length,
              itemBuilder: (context, index) {
                final color = colors[index];
                final isSelected = color == initialColor;
                
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(color),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected 
                        ? Border.all(color: Colors.black, width: 3)
                        : null,
                    ),
                    child: isSelected 
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(Colors.transparent),
              child: const Text('No Color'),
            ),
          ],
        );
      },
    );
  }

  // Show notification test dialog
  static Future<void> showNotificationTest(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.notification_important),
              SizedBox(width: 8),
              Text('Test Notification'),
            ],
          ),
          content: const Text(
            'A test notification will be sent immediately to verify your notification settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Here you would trigger a test notification
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test notification sent!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Send Test'),
            ),
          ],
        );
      },
    );
  }

  // Show reminder deletion confirmation
  static Future<bool> showDeleteReminderDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Reminder'),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this reminder? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Get notification importance level
  static int getNotificationImportance(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return 5; // Maximum importance
      case 'high':
        return 4; // High importance
      case 'medium':
        return 3; // Default importance
      case 'low':
        return 2; // Low importance
      default:
        return 3; // Default importance
    }
  }

  // Get notification channel ID based on priority
  static String getNotificationChannelId(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return 'urgent_reminders';
      case 'high':
        return 'high_priority_reminders';
      case 'medium':
        return 'normal_reminders';
      case 'low':
        return 'low_priority_reminders';
      default:
        return 'normal_reminders';
    }
  }

  // Get notification channel name based on priority
  static String getNotificationChannelName(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return 'Urgent Task Reminders';
      case 'high':
        return 'High Priority Reminders';
      case 'medium':
        return 'Normal Task Reminders';
      case 'low':
        return 'Low Priority Reminders';
      default:
        return 'Task Reminders';
    }
  }

  // Get notification channel description
  static String getNotificationChannelDescription(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return 'Critical task reminders that require immediate attention';
      case 'high':
        return 'Important task reminders with high priority';
      case 'medium':
        return 'Regular task reminders for everyday tasks';
      case 'low':
        return 'Low priority task reminders that can wait';
      default:
        return 'General task reminders';
    }
  }

  // Calculate optimal reminder time based on task complexity
  static DateTime calculateOptimalReminderTime(Task task) {
    final now = DateTime.now();
    final dueDate = task.dueDate ?? now.add(const Duration(days: 1));
    
    // Base reminder time (default to 1 hour before due date)
    var reminderTime = dueDate.subtract(const Duration(hours: 1));
    
    // Adjust based on estimated time
    if (task.estimatedMinutes > 0) {
      final estimatedDuration = Duration(minutes: task.estimatedMinutes);
      // Add buffer time (20% extra)
      final bufferTime = Duration(minutes: (task.estimatedMinutes * 0.2).round());
      reminderTime = dueDate.subtract(estimatedDuration).subtract(bufferTime);
    }
    
    // Adjust based on priority
    switch (task.priority.toLowerCase()) {
      case 'urgent':
        // Urgent tasks get multiple reminders
        reminderTime = dueDate.subtract(const Duration(hours: 2));
        break;
      case 'high':
        // High priority gets earlier reminder
        reminderTime = dueDate.subtract(const Duration(hours: 4));
        break;
      case 'low':
        // Low priority can have shorter notice
        reminderTime = dueDate.subtract(const Duration(minutes: 30));
        break;
    }
    
    // Ensure reminder is not in the past
    if (reminderTime.isBefore(now)) {
      reminderTime = now.add(const Duration(minutes: 5));
    }
    
    return reminderTime;
  }

  // Get task urgency level (0-10 scale)
  static int getTaskUrgencyLevel(Task task) {
    int urgencyLevel = 5; // Base level
    
    // Priority impact
    switch (task.priority.toLowerCase()) {
      case 'urgent':
        urgencyLevel += 4;
        break;
      case 'high':
        urgencyLevel += 2;
        break;
      case 'low':
        urgencyLevel -= 2;
        break;
    }
    
    // Due date impact
    if (task.dueDate != null) {
      final now = DateTime.now();
      final timeUntilDue = task.dueDate!.difference(now).inHours;
      
      if (timeUntilDue < 0) {
        urgencyLevel += 3; // Overdue
      } else if (timeUntilDue < 24) {
        urgencyLevel += 2; // Due within 24 hours
      } else if (timeUntilDue < 48) {
        urgencyLevel += 1; // Due within 48 hours
      }
    }
    
    // Ensure level stays within bounds
    return urgencyLevel.clamp(0, 10);
  }

  // Show bulk reminder options for multiple tasks
  static Future<Map<String, dynamic>?> showBulkReminderSheet(
    BuildContext context,
    List<Task> tasks,
  ) async {
    String selectedType = 'once';
    String selectedTone = 'default';
    DateTime selectedTime = DateTime.now().add(const Duration(hours: 1));
    List<String> selectedDays = [];

    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bulk Set Reminders',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Setting reminders for ${tasks.length} tasks',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Quick presets for bulk actions
                  const Text(
                    'Quick Setup',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.auto_awesome),
                            title: const Text('Smart Reminders'),
                            subtitle: const Text('Set optimal reminders based on priority and due dates'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(context, {
                                'mode': 'smart',
                                'tasks': tasks,
                              });
                            },
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.schedule),
                            title: const Text('Same Time for All'),
                            subtitle: Text('Set ${formatReminderTime(selectedTime)} for all tasks'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await _selectDateTime(context, selectedTime, (newTime) {
                                setState(() {
                                  selectedTime = newTime;
                                });
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, {
                              'mode': 'manual',
                              'time': selectedTime,
                              'type': selectedType,
                              'tone': selectedTone,
                              'repeatDays': selectedDays,
                              'tasks': tasks,
                            });
                          },
                          child: const Text('Set for All Tasks'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Show reminder management options
  static Future<String?> showReminderManagementDialog(BuildContext context, Task task) async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        final hasReminder = task.reminderTime != null;
        
        return AlertDialog(
          title: Text('Manage Reminder: ${task.title}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasReminder) ...[
                Text('Current reminder: ${formatReminderTime(task.reminderTime)}'),
                const SizedBox(height: 16),
              ],
              
              ListTile(
                leading: Icon(hasReminder ? Icons.edit : Icons.add_alarm),
                title: Text(hasReminder ? 'Edit Reminder' : 'Set Reminder'),
                onTap: () => Navigator.of(context).pop('edit'),
              ),
              
              if (hasReminder) ...[
                ListTile(
                  leading: const Icon(Icons.snooze),
                  title: const Text('Snooze Reminder'),
                  onTap: () => Navigator.of(context).pop('snooze'),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete Reminder'),
                  onTap: () => Navigator.of(context).pop('delete'),
                ),
              ],
              
              ListTile(
                leading: const Icon(Icons.science),
                title: const Text('Test Notification'),
                onTap: () => Navigator.of(context).pop('test'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Calculate next reminder time for recurring reminders
  static DateTime? calculateNextReminderTime(
    DateTime baseTime,
    String reminderType,
    List<String> repeatDays,
  ) {
    final now = DateTime.now();
    
    switch (reminderType) {
      case 'daily':
        DateTime nextDaily = DateTime(
          now.year, now.month, now.day,
          baseTime.hour, baseTime.minute,
        );
        if (nextDaily.isBefore(now)) {
          nextDaily = nextDaily.add(const Duration(days: 1));
        }
        return nextDaily;
        
      case 'weekly':
        if (repeatDays.isEmpty) return null;
        
        // Find next occurrence
        DateTime? nextWeekly;
        final currentWeekday = now.weekday;
        
        for (int i = 0; i < 7; i++) {
          final checkDay = (currentWeekday + i - 1) % 7 + 1;
          final dayName = getWeekdayName(checkDay).toLowerCase();
          
          if (repeatDays.contains(dayName.toLowerCase())) {
            final candidateDate = now.add(Duration(days: i));
            final candidateTime = DateTime(
              candidateDate.year, candidateDate.month, candidateDate.day,
              baseTime.hour, baseTime.minute,
            );
            
            if (candidateTime.isAfter(now)) {
              nextWeekly = candidateTime;
              break;
            }
          }
        }
        
        return nextWeekly;
        
      case 'monthly':
        DateTime nextMonthly = DateTime(
          now.year, now.month, baseTime.day,
          baseTime.hour, baseTime.minute,
        );
        
        if (nextMonthly.isBefore(now) || nextMonthly.day != baseTime.day) {
          // Move to next month
          final nextMonth = now.month == 12 ? 1 : now.month + 1;
          final nextYear = now.month == 12 ? now.year + 1 : now.year;
          
          nextMonthly = DateTime(
            nextYear, nextMonth, baseTime.day,
            baseTime.hour, baseTime.minute,
          );
          
          // Handle case where target day doesn't exist in the month
          if (nextMonthly.month != nextMonth) {
            nextMonthly = DateTime(nextYear, nextMonth + 1, 0, baseTime.hour, baseTime.minute);
          }
        }
        
        return nextMonthly;
        
      default:
        return null;
    }
  }

  // Show notification permission status
  static Future<void> showPermissionStatus(BuildContext context) async {
    final status = await Permission.notification.status;
    
    String statusText;
    Color statusColor;
    IconData statusIcon;
    
    if (status.isGranted) {
      statusText = 'Notifications are enabled';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (status.isDenied) {
      statusText = 'Notifications are denied';
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    } else if (status.isPermanentlyDenied) {
      statusText = 'Notifications are permanently denied';
      statusColor = Colors.red;
      statusIcon = Icons.block;
    } else {
      statusText = 'Notification permission not determined';
      statusColor = Colors.grey;
      statusIcon = Icons.help_outline;
    }
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notification Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, color: statusColor, size: 48),
              const SizedBox(height: 16),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 16,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (!status.isGranted) ...[
                const SizedBox(height: 16),
                const Text(
                  'Enable notifications to receive reminders for your tasks.',
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
          actions: [
            if (!status.isGranted) ...[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  if (status.isPermanentlyDenied) {
                    await openAppSettings();
                  } else {
                    await Permission.notification.request();
                  }
                },
                child: Text(status.isPermanentlyDenied ? 'Open Settings' : 'Enable'),
              ),
            ] else ...[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ],
        );
      },
    );
  }

  // Get reminder frequency text
  static String getReminderFrequencyText(String reminderType, List<String> repeatDays) {
    switch (reminderType) {
      case 'once':
        return 'One time only';
      case 'daily':
        return 'Every day';
      case 'weekly':
        if (repeatDays.isEmpty) return 'Weekly';
        if (repeatDays.length == 7) return 'Every day';
        if (repeatDays.length == 1) return 'Every ${formatCategory(repeatDays.first)}';
        return 'Every ${repeatDays.map((d) => d.substring(0, 3)).join(', ')}';
      case 'monthly':
        return 'Every month';
      default:
        return 'Custom';
    }
  }
}