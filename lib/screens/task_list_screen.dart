// ignore_for_file: avoid_print, prefer_final_fields, deprecated_member_use, use_build_context_synchronously, prefer_const_constructors, unused_import, unnecessary_import

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/filter_dialog.dart';
import '../utils/notification_helper.dart';
import 'add_task_screen.dart';
import '../screens/account_settings_screen.dart';
import '../screens/premium_purchase_screen.dart';
import '../providers/auth_provider.dart';
import '../services/ad_service.dart';
import '../l10n/app_localizations.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';
  
  // NEW VOICE-RELATED VARIABLES:
  bool _isVoiceListening = false;
  bool _isProcessingVoiceCommand = false;
  String _voiceStatus = 'Tap to activate voice commands';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeVoiceService();
  }

  void _initializeVoiceService() async {
    try {
      // Initialize TaskProvider voice commands first
      final taskProvider = context.read<TaskProvider>();
      await taskProvider.initializeVoiceCommands();
      
      // Listen to TaskProvider voice command state changes
      taskProvider.addListener(_updateVoiceStatus);
      
      if (mounted) {
        setState(() {
          _voiceStatus = AppLocalizations.of(context).voiceCommandsReady;
        });
      }
      
      print('Voice service initialized successfully');
    } catch (e) {
      print('Voice service initialization failed: $e');
      if (mounted) {
        setState(() {
          _voiceStatus = 'Voice service unavailable';
        });
      }
    }
  }
  
  void _updateVoiceStatus() {
    if (!mounted) return;
    
    try {
      final taskProvider = context.read<TaskProvider>();
      setState(() {
        _isProcessingVoiceCommand = taskProvider.isProcessingVoiceCommand;
        _isVoiceListening = taskProvider.isVoiceCommandActive;
        
        if (_isProcessingVoiceCommand) {
          _voiceStatus = '${AppLocalizations.of(context).processingVoiceCommand}: "${taskProvider.lastVoiceCommand}"';
        } else if (_isVoiceListening) {
          _voiceStatus = AppLocalizations.of(context).listeningForWakeWord;
        } else {
          _voiceStatus = AppLocalizations.of(context).voiceCommandsReady;
        }
      });
    } catch (e) {
      // Widget is disposed, ignore the update
      print('Voice status update skipped - widget disposed');
    }
  }

  // Voice Status Indicator Widget
  Widget _buildVoiceStatusIndicator() {
    if (!_isVoiceListening && !_isProcessingVoiceCommand) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isProcessingVoiceCommand ? Theme.of(context).colorScheme.primaryContainer : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isProcessingVoiceCommand ? Theme.of(context).colorScheme.primary : Colors.green,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isProcessingVoiceCommand)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              Icons.mic,
              color: Colors.green,
              size: 16,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _voiceStatus,
              style: TextStyle(
                color: _isProcessingVoiceCommand ? Theme.of(context).colorScheme.primary : Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_isVoiceListening || _isProcessingVoiceCommand)
            GestureDetector(
              onTap: () {
                final taskProvider = context.read<TaskProvider>();
                taskProvider.stopWakeWordListening();
                setState(() {
                  _isVoiceListening = false;
                  _voiceStatus = AppLocalizations.of(context).voiceInputHint;
                });
              },
              child: Icon(
                Icons.close,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  // Voice Toggle Method
  void _toggleVoiceListening() async {
    try {
      final taskProvider = context.read<TaskProvider>();
      
      if (_isVoiceListening) {
        await taskProvider.stopWakeWordListening();
        setState(() {
          _isVoiceListening = false;
          _voiceStatus = AppLocalizations.of(context).voiceCommandsReady;
        });
      } else {
        setState(() {
          _isVoiceListening = true;
          _voiceStatus = AppLocalizations.of(context).listeningForWakeWord;
        });
        await taskProvider.startWakeWordListening();
      }
    } catch (e) {
      setState(() {
        _isVoiceListening = false;
        _voiceStatus = AppLocalizations.of(context).voiceError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/app_icon.png',
              height: 24, // Smaller icon
              width: 24,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.task_alt, size: 24);
              },
            ),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).appTitle),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
        centerTitle: false,
        
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: [
            Tab(text: AppLocalizations.of(context).all, icon: const Icon(Icons.list, size: 20)),
            Tab(text: AppLocalizations.of(context).pending, icon: const Icon(Icons.pending, size: 20)),
            Tab(text: AppLocalizations.of(context).completed, icon: const Icon(Icons.check_circle, size: 20)),
            Tab(text: AppLocalizations.of(context).notifications, icon: const Icon(Icons.notifications, size: 20)),
          ],
        ),
        
        actions: [
          // Voice command button
          Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              return IconButton(
                icon: Icon(
                  _isVoiceListening ? Icons.mic : Icons.mic_none,
                  color: _isVoiceListening ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: _toggleVoiceListening,
                tooltip: _isVoiceListening ? AppLocalizations.of(context).stopVoiceCommands : AppLocalizations.of(context).startVoiceCommands,
              );
            },
          ),
          
          // Filter button with indicator
          Stack(
            children: [
              Consumer<TaskProvider>(
                builder: (context, taskProvider, child) {
                  return IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () => _showFilterDialog(),
                  );
                },
              ),
              Consumer<TaskProvider>(
                builder: (context, taskProvider, child) {
                  final hasActiveFilters = taskProvider.selectedCategories.isNotEmpty ||
                      taskProvider.selectedPriorities.isNotEmpty ||
                      taskProvider.selectedStatuses.isNotEmpty;
                  
                  if (!hasActiveFilters) return const SizedBox.shrink();
                  
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          
          // Main menu
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'profile', child: Text(AppLocalizations.of(context).profile)),
              PopupMenuItem(value: 'calendar', child: Text(AppLocalizations.of(context).calendarView)),
              PopupMenuItem(value: 'settings', child: Text(AppLocalizations.of(context).settings)),
              PopupMenuItem(value: 'logout', child: Text(AppLocalizations.of(context).logout)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Voice Status Indicator (NEW)
          _buildVoiceStatusIndicator(),
          
          // Daily Productivity Score Display
          Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              final score = taskProvider.dailyProductivityScore;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: score > 70 ? Colors.green.withOpacity(0.1) : 
                         score > 40 ? Colors.orange.withOpacity(0.1) : Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: score > 70 ? Colors.green : 
                           score > 40 ? Colors.orange : Theme.of(context).colorScheme.error,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: score > 70 ? Colors.green : 
                             score > 40 ? Colors.orange : Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${AppLocalizations.of(context).todaysProductivity}: ${score.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: score > 70 ? Colors.green.shade700 : 
                               score > 40 ? Colors.orange.shade700 : Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: score > 70 ? Colors.green : 
                               score > 40 ? Colors.orange : Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        score > 70 ? AppLocalizations.of(context).great : score > 40 ? AppLocalizations.of(context).good : AppLocalizations.of(context).keepGoing,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Premium Features Section (only show for non-premium users)
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isPremium) {
                return const SizedBox.shrink();
              }
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).premiumFeatures,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Custom voice packs\n• Offline mode\n• Smart tags\n• Custom themes\n• Advanced analytics\n• No ads',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PremiumPurchaseScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.upgrade, size: 18),
                          label: Text(AppLocalizations.of(context).upgradeToProButton),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Ad Banner (only show for non-premium users)
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isPremium) {
                return const SizedBox.shrink();
              }
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.ads_click, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Advertisement Space',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Remove with Pro',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          
          // Active Filters Display
          Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              if (!taskProvider.hasActiveFilters) return const SizedBox.shrink();
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.filter_alt, size: 16, color: Colors.blue[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Active Filters:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[600],
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            taskProvider.clearAllFilters();
                            setState(() {});
                          },
                          child: Text(
                            'Clear All',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _buildActiveFilterChips(taskProvider),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Reminder Stats Bar
          Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              final remindersCount = taskProvider.tasksWithReminders.length;
              final overdueCount = taskProvider.overdueReminders.length;
              
              if (remindersCount == 0) return const SizedBox.shrink();
              
              return Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: overdueCount > 0 ? Colors.red[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: overdueCount > 0 ? Colors.red[200]! : Colors.blue[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      overdueCount > 0 ? Icons.warning : Icons.notifications_active,
                      size: 16,
                      color: overdueCount > 0 ? Colors.red[600] : Colors.blue[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        overdueCount > 0 
                          ? '$overdueCount overdue reminder${overdueCount > 1 ? 's' : ''}'
                          : '$remindersCount active reminder${remindersCount > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: overdueCount > 0 ? Colors.red[700] : Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Main content
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                if (taskProvider.isLoading && taskProvider.tasks.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (taskProvider.error != null && taskProvider.tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('${AppLocalizations.of(context).errorPrefix}: ${taskProvider.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            taskProvider.clearError();
                          },
                          child: Text(AppLocalizations.of(context).retry),
                        ),
                      ],
                    ),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTaskList(taskProvider, taskProvider.filteredTasks),
                    _buildTaskList(taskProvider, taskProvider.filteredTasks.where((t) => !t.isCompleted).toList()),
                    _buildTaskList(taskProvider, taskProvider.filteredTasks.where((t) => t.isCompleted).toList()),
                    _buildRemindersList(taskProvider),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTaskScreen()),
          );
        },
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 12.0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  List<Widget> _buildActiveFilterChips(TaskProvider taskProvider) {
    List<Widget> chips = [];

    // Category filters
    for (String category in taskProvider.selectedCategories) {
      chips.add(_buildFilterChip(
        label: category.toUpperCase(),
        icon: _getCategoryIcon(category),
        onRemove: () {
          taskProvider.toggleCategoryFilter(category);
          setState(() {});
        },
      ));
    }

    // Priority filters
    for (String priority in taskProvider.selectedPriorities) {
      chips.add(_buildFilterChip(
        label: priority.toUpperCase(),
        icon: _getPriorityIcon(priority),
        color: _getPriorityColor(priority),
        onRemove: () {
          taskProvider.togglePriorityFilter(priority);
          setState(() {});
        },
      ));
    }

    // Status filters
    for (String status in taskProvider.selectedStatuses) {
      chips.add(_buildFilterChip(
        label: status.toUpperCase(),
        icon: status == 'completed' ? Icons.check_circle : Icons.pending,
        color: status == 'completed' ? Colors.green : Colors.orange,
        onRemove: () {
          taskProvider.toggleStatusFilter(status);
          setState(() {});
        },
      ));
    }

    // Date range filter
    if (taskProvider.hasDateFilter) {
      chips.add(_buildFilterChip(
        label: taskProvider.getDateFilterLabel(),
        icon: Icons.date_range,
        color: Colors.purple,
        onRemove: () {
          taskProvider.clearDateFilter();
          setState(() {});
        },
      ));
    }

    // Special filters
    if (taskProvider.showOverdueOnly) {
      chips.add(_buildFilterChip(
        label: 'OVERDUE',
        icon: Icons.warning,
        color: Colors.red,
        onRemove: () {
          taskProvider.setOverdueFilter(false);
          setState(() {});
        },
      ));
    }

    if (taskProvider.showRecurringOnly) {
      chips.add(_buildFilterChip(
        label: 'RECURRING',
        icon: Icons.repeat,
        color: Colors.purple,
        onRemove: () {
          taskProvider.setRecurringFilter(false);
          setState(() {});
        },
      ));
    }

    if (taskProvider.showRemindersOnly) {
      chips.add(_buildFilterChip(
        label: 'REMINDERS',
        icon: Icons.notifications_active,
        color: Colors.blue,
        onRemove: () {
          taskProvider.setRemindersFilter(false);
          setState(() {});
        },
      ));
    }

    return chips;
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    Color? color,
    required VoidCallback onRemove,
  }) {
    final chipColor = color ?? Colors.blue;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        border: Border.all(color: chipColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: chipColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(TaskProvider taskProvider, List<Task> tasks) {
    List<Task> filteredTasks = taskProvider.hasActiveFilters 
        ? tasks
        : (_selectedCategory == 'all' 
            ? tasks 
            : tasks.where((task) => task.category == _selectedCategory).toList());

    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              taskProvider.hasActiveFilters 
                  ? Icons.filter_list_off
                  : (_selectedCategory == 'all' ? Icons.task_alt : Icons.filter_list_off),
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              taskProvider.hasActiveFilters 
                  ? 'No tasks match your filters.\nTry adjusting your criteria.'
                  : (_selectedCategory == 'all' 
                      ? 'No tasks yet.\nAdd your first task!' 
                      : 'No tasks in this category.'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (taskProvider.hasActiveFilters) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  taskProvider.clearAllFilters();
                  setState(() {});
                },
                icon: const Icon(Icons.clear_all),
                label: Text(AppLocalizations.of(context).clearFilters),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          final task = filteredTasks[index];
          return TaskCard(task: task);
        },
      ),
    );
  }

  Widget _buildRemindersList(TaskProvider taskProvider) {
    final tasksWithReminders = taskProvider.tasksWithReminders;
    final overdueReminders = taskProvider.overdueReminders;
    
    if (tasksWithReminders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No reminders set.\nAdd reminders to your tasks!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final sortedReminders = [...tasksWithReminders]
      ..sort((a, b) {
        if (a.reminderTime == null) return 1;
        if (b.reminderTime == null) return -1;
        return a.reminderTime!.compareTo(b.reminderTime!);
      });

    return Column(
      children: [
        if (overdueReminders.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${overdueReminders.length} Overdue Reminder${overdueReminders.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: sortedReminders.length,
              itemBuilder: (context, index) {
                final task = sortedReminders[index];
                return TaskCard(task: task);
              },
            ),
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'work': return Icons.work;
      case 'personal': return Icons.person;
      case 'health': return Icons.health_and_safety;
      case 'shopping': return Icons.shopping_cart;
      case 'study': return Icons.school;
      default: return Icons.category;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'high': return Icons.keyboard_arrow_up;
      case 'medium': return Icons.remove;
      case 'low': return Icons.keyboard_arrow_down;
      default: return Icons.remove;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  // Add the missing filter dialog method
  void _showFilterDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const FilterDialog(),
    );
    
    if (result == true) {
      setState(() {});
    }
  }

  // Add the menu handler method
  void _handleMenuAction(String value) {
    switch (value) {
      case 'profile':
        Navigator.pushNamed(context, '/profile');
        break;
      case 'calendar':
        Navigator.pushNamed(context, '/calendar');
        break;
      case 'settings':
        Navigator.pushNamed(context, '/account-settings');
        break;
      case 'logout':
        _handleLogout();
        break;
    }
  }

  void _handleLogout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).logout),
          content: Text(AppLocalizations.of(context).logoutConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text(AppLocalizations.of(context).logout),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Remove listener to prevent memory leaks
    try {
      final taskProvider = context.read<TaskProvider>();
      taskProvider.removeListener(_updateVoiceStatus);
    } catch (e) {
      // Context may already be disposed, ignore
      print('TaskProvider cleanup skipped - context disposed');
    }
    super.dispose();
  }
}

// TaskTile class - Updated with reminder indicators
class TaskTile extends StatelessWidget {
  final Task task;

  const TaskTile({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showTaskDetails(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: task.isCompleted,
                    onChanged: (value) {
                      Provider.of<TaskProvider>(context, listen: false)
                          .toggleTask(task.id!, value!);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: task.isCompleted 
                                ? TextDecoration.lineThrough 
                                : TextDecoration.none,
                            color: task.isCompleted 
                                ? Colors.grey 
                                : Colors.black87,
                          ),
                        ),
                        if (task.description != null && task.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: task.isCompleted 
                                  ? Colors.grey 
                                  : Colors.black54,
                              decoration: task.isCompleted 
                                  ? TextDecoration.lineThrough 
                                  : TextDecoration.none,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddTaskScreen(taskToEdit: task),
                            ),
                          );
                          break;
                        case 'delete':
                          _showDeleteConfirmation(context, task);
                          break;
                        case 'duplicate':
                          _duplicateTask(context, task);
                          break;
                        case 'snooze_5':
                          Provider.of<TaskProvider>(context, listen: false)
                              .snoozeReminder(task.id!, 5);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context).reminderSnoozed5min)),
                          );
                          break;
                        case 'cancel_reminder':
                          Provider.of<TaskProvider>(context, listen: false)
                              .cancelReminder(task.id!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context).reminderCancelled)),
                          );
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text(AppLocalizations.of(context).edit),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 18),
                            SizedBox(width: 8),
                            Text(AppLocalizations.of(context).duplicate),
                          ],
                        ),
                      ),
                      if (task.hasActiveReminder && !task.isCompleted) ...[
                        PopupMenuItem(
                          value: 'snooze_5',
                          child: Row(
                            children: [
                              Icon(Icons.snooze, size: 18),
                              SizedBox(width: 8),
                              Text(AppLocalizations.of(context).snooze5min),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'cancel_reminder',
                          child: Row(
                            children: [
                              Icon(Icons.notifications_off, size: 18),
                              SizedBox(width: 8),
                              Text(AppLocalizations.of(context).cancelReminderAction),
                            ],
                          ),
                        ),
                      ],
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text(AppLocalizations.of(context).delete, style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildPriorityChip(task.priority),
                  _buildCategoryChip(task.category),
                  if (task.dueDate != null)
                    _buildDueDateChip(task.dueDate!),
                  if (task.isRecurring)
                    _buildRecurringChip(task.recurringPattern ?? 'recurring'),
                  if (task.hasActiveReminder)
                    _buildReminderChip(task),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderChip(Task task) {
    final isOverdue = task.reminderTime != null && 
                     task.reminderTime!.isBefore(DateTime.now()) && 
                     !task.isCompleted;
    
    final Color color = isOverdue ? Colors.red : Colors.blue;
    final IconData icon = isOverdue ? Icons.warning : Icons.notifications_active;
    final String text = isOverdue ? 'OVERDUE' : 'REMINDER';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    IconData icon;
    switch (priority) {
      case 'high':
        color = Colors.red;
        icon = Icons.keyboard_arrow_up;
        break;
      case 'medium':
        color = Colors.orange;
        icon = Icons.remove;
        break;
      case 'low':
        color = Colors.green;
        icon = Icons.keyboard_arrow_down;
        break;
      default:
        color = Colors.grey;
        icon = Icons.remove;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 2),
          Text(
            priority.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        border: Border.all(color: Colors.blue, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(NotificationHelper.getCategoryIcon(category), size: 12, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            category.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueDateChip(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    bool isOverdue = taskDate.isBefore(today) && !task.isCompleted;
    bool isToday = taskDate.isAtSameMomentAs(today);
    bool isTomorrow = taskDate.isAtSameMomentAs(today.add(const Duration(days: 1)));

    Color color = Colors.grey;
    String text = '${dueDate.day}/${dueDate.month}';
    IconData icon = Icons.calendar_today;

    if (isOverdue) {
      color = Colors.red;
      icon = Icons.warning;
      text = 'OVERDUE';
    } else if (isToday) {
      color = Colors.orange;
      icon = Icons.today;
      text = 'TODAY';
    } else if (isTomorrow) {
      color = Colors.blue;
      icon = Icons.calendar_today;
      text = 'TOMORROW';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringChip(String pattern) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        border: Border.all(color: Colors.purple, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.repeat, size: 12, color: Colors.purple),
          const SizedBox(width: 4),
          Text(
            pattern.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TaskDetailSheet(task: task),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.hasActiveReminder 
                  ? 'This task has an active reminder. Deleting it will also cancel the reminder.'
                  : 'Are you sure you want to delete this task?'
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${task.title}"',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                return TextButton(
                  onPressed: taskProvider.isDeleting ? null : () async {
                    final success = await taskProvider.deleteTask(task.id!);
                    Navigator.of(context).pop();
                    
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            task.hasActiveReminder 
                              ? 'Task and reminder deleted successfully'
                              : 'Task deleted successfully'
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: taskProvider.isDeleting 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Delete'),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _duplicateTask(BuildContext context, Task originalTask) {
    final duplicatedTask = Task(
      title: '${originalTask.title} (Copy)',
      description: originalTask.description,
      createdAt: DateTime.now(),
      dueDate: originalTask.dueDate,
      priority: originalTask.priority,
      category: originalTask.category,
      color: originalTask.color,
      isRecurring: originalTask.isRecurring,
      recurringPattern: originalTask.recurringPattern,
      hasReminder: false,
      reminderTime: null,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(taskToEdit: duplicatedTask),
      ),
    );
  }
}

// TaskDetailSheet class
class TaskDetailSheet extends StatelessWidget {
  final Task task;

  const TaskDetailSheet({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (task.hasActiveReminder)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_active, size: 14, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Text(
                        'REMINDER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (task.description != null && task.description!.isNotEmpty) ...[
            Text(
              task.description!,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 16),
          ],

          _buildDetailRow('Priority', task.priority.toUpperCase()),
          _buildDetailRow('Category', task.category.toUpperCase()),
          
          if (task.dueDate != null)
            _buildDetailRow(
              'Due Date',
              '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year} at ${task.dueDate!.hour}:${task.dueDate!.minute.toString().padLeft(2, '0')}',
            ),

          if (task.hasReminder) ...[
            if (task.reminderTime != null)
              _buildDetailRow(
                'Reminder Time',
                '${task.reminderTime!.day}/${task.reminderTime!.month}/${task.reminderTime!.year} at ${task.reminderTime!.hour}:${task.reminderTime!.minute.toString().padLeft(2, '0')}',
              ),
            _buildDetailRow('Reminder Type', task.reminderType.toUpperCase()),
            if (task.notificationTone != 'default')
              _buildDetailRow('Notification Tone', task.notificationTone.toUpperCase()),
            if (task.repeatDays.isNotEmpty)
              _buildDetailRow('Repeat Days', task.repeatDays.join(', ').toUpperCase()),
            if (task.reminderMinutesBefore > 0)
              _buildDetailRow('Remind Before', '${task.reminderMinutesBefore} minutes'),
          ],

          if (task.isRecurring)
            _buildDetailRow(
              'Recurring',
              task.recurringPattern?.toUpperCase() ?? 'YES',
            ),

          _buildDetailRow(
            'Status',
            task.isCompleted ? 'COMPLETED' : 'PENDING',
          ),

          _buildDetailRow(
            'Created',
            '${task.createdAt.day}/${task.createdAt.month}/${task.createdAt.year}',
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddTaskScreen(taskToEdit: task),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Provider.of<TaskProvider>(context, listen: false)
                        .toggleTask(task.id!, !task.isCompleted);
                    Navigator.pop(context);
                  },
                  icon: Icon(task.isCompleted ? Icons.undo : Icons.check),
                  label: Text(task.isCompleted ? 'Mark Pending' : 'Mark Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: task.isCompleted ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          if (task.hasActiveReminder && !task.isCompleted) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Provider.of<TaskProvider>(context, listen: false)
                          .snoozeReminder(task.id!, 15);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reminder snoozed for 15 minutes')),
                      );
                    },
                    icon: const Icon(Icons.snooze),
                    label: const Text('Snooze 15m'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Provider.of<TaskProvider>(context, listen: false)
                          .cancelReminder(task.id!);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reminder cancelled')),
                      );
                    },
                    icon: const Icon(Icons.notifications_off),
                    label: const Text('Cancel Reminder'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          const Text(' : '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

}