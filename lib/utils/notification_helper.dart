import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationHelper {
  // Available notification tones
  static const Map<String, String> notificationTones = {
    'default': 'Default',
    'chime': 'Chime',
    'bell': 'Bell',
    'whistle': 'Whistle',
    'ding': 'Ding',
    'buzz': 'Buzz',
  };

  // Available reminder types
  static const Map<String, String> reminderTypes = {
    'once': 'One Time',
    'daily': 'Daily',
    'weekly': 'Weekly',
    'monthly': 'Monthly',
  };

  // Days of the week for weekly reminders
  static const Map<String, String> weekDays = {
    'mon': 'Monday',
    'tue': 'Tuesday', 
    'wed': 'Wednesday',
    'thu': 'Thursday',
    'fri': 'Friday',
    'sat': 'Saturday',
    'sun': 'Sunday',
  };

  // Priority colors
  static const Map<String, Color> priorityColors = {
    'high': Colors.red,
    'medium': Colors.orange,
    'low': Colors.green,
  };

  // Check and request notification permissions
  static Future<bool> requestNotificationPermissions() async {
    // Check if notification permission is granted
    PermissionStatus status = await Permission.notification.status;
    
    if (status.isDenied) {
      // Request permission
      status = await Permission.notification.request();
    }
    
    return status.isGranted;
  }

  // Format reminder time for display
  static String formatReminderTime(DateTime? reminderTime) {
    if (reminderTime == null) return 'Not set';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final reminderDate = DateTime(
      reminderTime.year, 
      reminderTime.month, 
      reminderTime.day
    );
    
   
    if (reminderDate == today) {
      return 'Today at ${_formatTime24Hour(reminderTime)}';
    } else if (reminderDate == tomorrow) {
      return 'Tomorrow at ${_formatTime24Hour(reminderTime)}';
    } else {
      return '${reminderTime.day}/${reminderTime.month}/${reminderTime.year} at ${_formatTime24Hour(reminderTime)}';
    }
  }
  
  // Helper to format time in 24-hour format
  static String _formatTime24Hour(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Get time until reminder
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
      return '${days}d ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
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

  // Validate reminder time
  static String? validateReminderTime(DateTime? reminderTime) {
    if (reminderTime == null) return 'Please select a reminder time';
    
    final now = DateTime.now();
    if (reminderTime.isBefore(now)) {
      return 'Reminder time cannot be in the past';
    }
    
    // Check if reminder is more than 1 year in the future
    final oneYearFromNow = now.add(const Duration(days: 365));
    if (reminderTime.isAfter(oneYearFromNow)) {
      return 'Reminder time cannot be more than 1 year in the future';
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
    ];
  }

  // Show notification permission dialog
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
          content: const Text(
            'WhispTask needs notification permission to send you reminders for your tasks. '
            'This helps you stay on top of your to-dos!',
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

  // Show reminder options bottom sheet
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
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set Reminder',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  // Date and Time Picker
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: const Text('Reminder Time'),
                    subtitle: Text(formatReminderTime(selectedTime)),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedTime,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      
                      if (date != null) {
                        final time = await showTimePicker(
                          // ignore: use_build_context_synchronously
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedTime),
                        );
                        
                        if (time != null) {
                          setState(() {
                            selectedTime = DateTime(
                              date.year, date.month, date.day,
                              time.hour, time.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                  
                  const Divider(),
                  
                  // Reminder Type
                  const Text('Reminder Type', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...reminderTypes.entries.map((entry) {
                    return RadioListTile<String>(
                      title: Text(entry.value),
                      value: entry.key,
                      // ignore: deprecated_member_use
                      groupValue: selectedType,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                    );
                  // ignore: unnecessary_to_list_in_spreads
                  }).toList(),
                  
                  // Weekly repeat days (show only if weekly is selected)
                  if (selectedType == 'weekly') ...[
                    const Text('Repeat on Days', style: TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      children: weekDays.entries.map((entry) {
                        return FilterChip(
                          label: Text(entry.key.toUpperCase()),
                          selected: selectedDays.contains(entry.key),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedDays.add(entry.key);
                              } else {
                                selectedDays.remove(entry.key);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  
                  const Divider(),
                  
                  // Notification Tone
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Notification Tone',
                      prefixIcon: Icon(Icons.music_note),
                    ),
                    initialValue: selectedTone,
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
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
}