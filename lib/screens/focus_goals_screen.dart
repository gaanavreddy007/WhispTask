// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../l10n/app_localizations.dart';
import '../services/sentry_service.dart';

class FocusGoal {
  final String id;
  final String title;
  final String description;
  final int targetValue;
  final int currentValue;
  final String type; // 'daily', 'weekly', 'monthly'
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isActive;

  FocusGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.targetValue,
    this.currentValue = 0,
    required this.type,
    required this.createdAt,
    this.completedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory FocusGoal.fromJson(Map<String, dynamic> json) {
    return FocusGoal(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      targetValue: json['targetValue'],
      currentValue: json['currentValue'] ?? 0,
      type: json['type'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      isActive: json['isActive'] ?? true,
    );
  }

  FocusGoal copyWith({
    String? id,
    String? title,
    String? description,
    int? targetValue,
    int? currentValue,
    String? type,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isActive,
  }) {
    return FocusGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  double get progress => currentValue / targetValue;
  bool get isCompleted => currentValue >= targetValue;
}

class FocusGoalsScreen extends StatefulWidget {
  const FocusGoalsScreen({super.key});

  @override
  State<FocusGoalsScreen> createState() => _FocusGoalsScreenState();
}

class _FocusGoalsScreenState extends State<FocusGoalsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  List<FocusGoal> _goals = [];
  String _selectedFilter = 'active';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _fadeController.forward();
    _loadGoals();
    _initializeDefaultGoals();
    
    SentryService.addBreadcrumb(
      message: 'focus_goals_screen_opened',
      category: 'navigation',
      data: {'screen': 'focus_goals'},
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goalsJson = prefs.getStringList('focus_goals') ?? [];
      
      setState(() {
        _goals = goalsJson
            .map((json) => FocusGoal.fromJson(jsonDecode(json)))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
      });
    } catch (e) {
      SentryService.captureException(e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goalsJson = _goals.map((goal) => jsonEncode(goal.toJson())).toList();
      await prefs.setStringList('focus_goals', goalsJson);
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  Future<void> _initializeDefaultGoals() async {
    if (_goals.isEmpty) {
      final defaultGoals = [
        FocusGoal(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Daily Focus Time',
          description: 'Complete 2 hours of focused work each day',
          targetValue: 120, // minutes
          type: 'daily',
          createdAt: DateTime.now(),
        ),
        FocusGoal(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          title: 'Weekly Sessions',
          description: 'Complete 25 focus sessions this week',
          targetValue: 25,
          type: 'weekly',
          createdAt: DateTime.now(),
        ),
        FocusGoal(
          id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
          title: 'Monthly Streak',
          description: 'Maintain a 30-day focus streak',
          targetValue: 30,
          type: 'monthly',
          createdAt: DateTime.now(),
        ),
      ];
      
      setState(() {
        _goals = defaultGoals;
      });
      await _saveGoals();
    }
  }

  List<FocusGoal> get _filteredGoals {
    switch (_selectedFilter) {
      case 'active':
        return _goals.where((goal) => goal.isActive && !goal.isCompleted).toList();
      case 'completed':
        return _goals.where((goal) => goal.isCompleted).toList();
      case 'daily':
        return _goals.where((goal) => goal.type == 'daily').toList();
      case 'weekly':
        return _goals.where((goal) => goal.type == 'weekly').toList();
      case 'monthly':
        return _goals.where((goal) => goal.type == 'monthly').toList();
      default:
        return _goals;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildFilterTabs(),
            _buildStatsHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredGoals.isEmpty
                      ? _buildEmptyState()
                      : _buildGoalsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: const Color(0xFF1976D2),
      leading: IconButton(
        icon: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.flag_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).focusGoals,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1976D2).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('active', 'Active'),
            _buildFilterChip('completed', 'Completed'),
            _buildFilterChip('daily', 'Daily'),
            _buildFilterChip('weekly', 'Weekly'),
            _buildFilterChip('monthly', 'Monthly'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = value);
        },
        backgroundColor: Colors.transparent,
        selectedColor: const Color(0xFF1976D2),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF1976D2),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    final activeGoals = _goals.where((g) => g.isActive && !g.isCompleted).length;
    final completedGoals = _goals.where((g) => g.isCompleted).length;
    final totalGoals = _goals.length;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1976D2).withOpacity(0.1),
            const Color(0xFF1565C0).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1976D2).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total Goals',
              totalGoals.toString(),
              Icons.flag_outlined,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFF1976D2).withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatItem(
              'Active',
              activeGoals.toString(),
              Icons.play_circle_outline_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFF1976D2).withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatItem(
              'Completed',
              completedGoals.toString(),
              Icons.check_circle_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF1976D2), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1976D2),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredGoals.length,
      itemBuilder: (context, index) {
        final goal = _filteredGoals[index];
        return _buildGoalCard(goal);
      },
    );
  }

  Widget _buildGoalCard(FocusGoal goal) {
    final theme = Theme.of(context);
    final progress = goal.progress.clamp(0.0, 1.0);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: goal.isCompleted 
              ? const Color(0xFF4CAF50).withOpacity(0.3)
              : const Color(0xFF1976D2).withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getTypeColor(goal.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(goal.type),
                  color: _getTypeColor(goal.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      goal.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (goal.isCompleted)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50),
                  size: 24,
                ),
              PopupMenuButton(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: const [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: const [
                        Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditGoalDialog(goal);
                  } else if (value == 'delete') {
                    _deleteGoal(goal);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${goal.currentValue}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
              Text(
                ' / ${goal.targetValue}',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: goal.isCompleted 
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF1976D2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF1976D2).withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              goal.isCompleted 
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF1976D2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTypeColor(goal.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  goal.type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getTypeColor(goal.type),
                  ),
                ),
              ),
              const Spacer(),
              if (!goal.isCompleted)
                TextButton.icon(
                  onPressed: () => _updateProgress(goal),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Update Progress'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1976D2),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flag_rounded,
              size: 48,
              color: Color(0xFF1976D2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Goals Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set your first focus goal to start tracking your progress',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _showAddGoalDialog,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Goal'),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'daily':
        return const Color(0xFF4CAF50);
      case 'weekly':
        return const Color(0xFF2196F3);
      case 'monthly':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF1976D2);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'daily':
        return Icons.today_rounded;
      case 'weekly':
        return Icons.view_week_rounded;
      case 'monthly':
        return Icons.calendar_month_rounded;
      default:
        return Icons.flag_rounded;
    }
  }

  void _showAddGoalDialog() {
    _showGoalDialog();
  }

  void _showEditGoalDialog(FocusGoal goal) {
    _showGoalDialog(goal: goal);
  }

  void _showGoalDialog({FocusGoal? goal}) {
    final titleController = TextEditingController(text: goal?.title ?? '');
    final descriptionController = TextEditingController(text: goal?.description ?? '');
    final targetController = TextEditingController(text: goal?.targetValue.toString() ?? '');
    String selectedType = goal?.type ?? 'daily';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(goal == null ? 'Create Goal' : 'Edit Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Goal Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: targetController,
                  decoration: const InputDecoration(
                    labelText: 'Target Value',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Goal Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedType = value!);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty &&
                    targetController.text.isNotEmpty) {
                  _saveGoal(
                    goal: goal,
                    title: titleController.text,
                    description: descriptionController.text,
                    targetValue: int.tryParse(targetController.text) ?? 0,
                    type: selectedType,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text(goal == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveGoal({
    FocusGoal? goal,
    required String title,
    required String description,
    required int targetValue,
    required String type,
  }) {
    if (goal == null) {
      // Create new goal
      final newGoal = FocusGoal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        targetValue: targetValue,
        type: type,
        createdAt: DateTime.now(),
      );
      setState(() {
        _goals.add(newGoal);
      });
    } else {
      // Edit existing goal
      final index = _goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        setState(() {
          _goals[index] = goal.copyWith(
            title: title,
            description: description,
            targetValue: targetValue,
            type: type,
          );
        });
      }
    }
    _saveGoals();
  }

  void _updateProgress(FocusGoal goal) {
    final controller = TextEditingController(text: goal.currentValue.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Progress'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Current Progress (max: ${goal.targetValue})',
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newValue = int.tryParse(controller.text) ?? goal.currentValue;
              final index = _goals.indexWhere((g) => g.id == goal.id);
              if (index != -1) {
                setState(() {
                  _goals[index] = goal.copyWith(
                    currentValue: newValue.clamp(0, goal.targetValue),
                    completedAt: newValue >= goal.targetValue ? DateTime.now() : null,
                  );
                });
                _saveGoals();
              }
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteGoal(FocusGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _goals.removeWhere((g) => g.id == goal.id);
              });
              _saveGoals();
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
