// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/sentry_service.dart';

class HabitTemplateScreen extends StatefulWidget {
  const HabitTemplateScreen({super.key});

  @override
  State<HabitTemplateScreen> createState() => _HabitTemplateScreenState();
}

class _HabitTemplateScreenState extends State<HabitTemplateScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  String _selectedCategory = 'all';
  final List<String> _selectedHabits = [];

  final Map<String, List<Map<String, dynamic>>> _templates = {
    'Health & Fitness': [
      {
        'name': 'Drink 8 glasses of water',
        'icon': Icons.local_drink_rounded,
        'color': Colors.blue,
        'description': 'Stay hydrated throughout the day',
      },
      {
        'name': 'Exercise for 30 minutes',
        'icon': Icons.fitness_center_rounded,
        'color': Colors.red,
        'description': 'Daily physical activity for better health',
      },
      {
        'name': 'Take vitamins',
        'icon': Icons.medication_rounded,
        'color': Colors.orange,
        'description': 'Daily vitamin supplements',
      },
      {
        'name': 'Walk 10,000 steps',
        'icon': Icons.directions_walk_rounded,
        'color': Colors.green,
        'description': 'Achieve daily step goal',
      },
      {
        'name': 'Sleep 8 hours',
        'icon': Icons.bedtime_rounded,
        'color': Colors.indigo,
        'description': 'Get adequate rest every night',
      },
    ],
    'Productivity': [
      {
        'name': 'Read for 30 minutes',
        'icon': Icons.book_rounded,
        'color': Colors.brown,
        'description': 'Daily reading habit for learning',
      },
      {
        'name': 'Plan tomorrow',
        'icon': Icons.event_note_rounded,
        'color': Colors.purple,
        'description': 'Prepare for the next day',
      },
      {
        'name': 'Review daily goals',
        'icon': Icons.checklist_rounded,
        'color': Colors.teal,
        'description': 'Check progress on daily objectives',
      },
      {
        'name': 'Learn something new',
        'icon': Icons.school_rounded,
        'color': Colors.deepOrange,
        'description': 'Continuous learning and growth',
      },
      {
        'name': 'Organize workspace',
        'icon': Icons.cleaning_services_rounded,
        'color': Colors.cyan,
        'description': 'Keep work area clean and organized',
      },
    ],
    'Mindfulness': [
      {
        'name': 'Meditate for 10 minutes',
        'icon': Icons.self_improvement_rounded,
        'color': Colors.deepPurple,
        'description': 'Daily meditation practice',
      },
      {
        'name': 'Practice gratitude',
        'icon': Icons.favorite_rounded,
        'color': Colors.pink,
        'description': 'Write down three things you\'re grateful for',
      },
      {
        'name': 'Deep breathing exercise',
        'icon': Icons.air_rounded,
        'color': Colors.lightBlue,
        'description': '5-minute breathing exercise',
      },
      {
        'name': 'Journal writing',
        'icon': Icons.edit_note_rounded,
        'color': Colors.amber,
        'description': 'Reflect on your day through writing',
      },
      {
        'name': 'Digital detox hour',
        'icon': Icons.phone_disabled_rounded,
        'color': Colors.grey,
        'description': 'One hour without digital devices',
      },
    ],
    'Social Life': [
      {
        'name': 'Call family/friends',
        'icon': Icons.call_rounded,
        'color': Colors.green,
        'description': 'Stay connected with loved ones',
      },
      {
        'name': 'Send a kind message',
        'icon': Icons.message_rounded,
        'color': Colors.blue,
        'description': 'Spread positivity to others',
      },
      {
        'name': 'Practice active listening',
        'icon': Icons.hearing_rounded,
        'color': Colors.orange,
        'description': 'Focus on truly hearing others',
      },
      {
        'name': 'Compliment someone',
        'icon': Icons.thumb_up_rounded,
        'color': Colors.yellow,
        'description': 'Make someone\'s day brighter',
      },
      {
        'name': 'Plan social activity',
        'icon': Icons.group_rounded,
        'color': Colors.purple,
        'description': 'Schedule time with friends or family',
      },
    ],
  };

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
    
    SentryService.addBreadcrumb(
      message: 'habit_template_screen_opened',
      category: 'navigation',
      data: {'screen': 'habit_template'},
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
            _buildCategoryTabs(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTemplateGrid(),
                    if (_selectedHabits.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSelectedHabits(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _selectedHabits.isNotEmpty ? _buildBottomBar() : null,
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
              Icons.dashboard_customize_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).habitTemplates,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        if (_selectedHabits.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedHabits.length} ${AppLocalizations.of(context).selected}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    final categories = ['all', ..._templates.keys];
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1976D2).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((category) => _buildCategoryChip(category)).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    final displayName = category == 'all' 
        ? 'All Categories'
        : _getLocalizedCategoryName(category);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: FilterChip(
        label: Text(displayName),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedCategory = category);
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

  Widget _buildTemplateGrid() {
    final habits = _getFilteredHabits();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedCategory == 'all' 
              ? 'All Habit Templates' 
              : _getLocalizedCategoryName(_selectedCategory),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: habits.length,
          itemBuilder: (context, index) {
            final habit = habits[index];
            return _buildHabitCard(habit);
          },
        ),
      ],
    );
  }

  Widget _buildHabitCard(Map<String, dynamic> habit) {
    final isSelected = _selectedHabits.contains(habit['name']);
    
    return GestureDetector(
      onTap: () => _toggleHabit(habit['name']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF1976D2).withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF1976D2)
                : const Color(0xFF1976D2).withOpacity(0.2),
            width: isSelected ? 2 : 1,
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
                    color: (habit['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    habit['icon'] as IconData,
                    color: habit['color'] as Color,
                    size: 20,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF1976D2),
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              habit['name'] as String,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                habit['description'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedHabits() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppLocalizations.of(context).selected} Habits (${_selectedHabits.length})',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedHabits.map((habit) => _buildSelectedHabitChip(habit)).toList(),
        ),
      ],
    );
  }

  Widget _buildSelectedHabitChip(String habit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1976D2).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1976D2).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            habit,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1976D2),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _toggleHabit(habit),
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: Color(0xFF1976D2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _clearSelection,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE53935)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.clear_rounded, color: Color(0xFFE53935)),
              label: Text(
                AppLocalizations.of(context).clearAll,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE53935),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _createHabits,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                AppLocalizations.of(context).createHabits,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredHabits() {
    if (_selectedCategory == 'all') {
      final allHabits = <Map<String, dynamic>>[];
      for (final category in _templates.values) {
        allHabits.addAll(category);
      }
      return allHabits;
    } else {
      return _templates[_selectedCategory] ?? [];
    }
  }

  void _toggleHabit(String habitName) {
    setState(() {
      if (_selectedHabits.contains(habitName)) {
        _selectedHabits.remove(habitName);
      } else {
        _selectedHabits.add(habitName);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedHabits.clear();
    });
  }

  String _getLocalizedCategoryName(String category) {
    switch (category) {
      case 'Health & Fitness':
        return AppLocalizations.of(context).healthFitness;
      case 'Productivity':
        return AppLocalizations.of(context).productivity;
      case 'Mindfulness':
        return AppLocalizations.of(context).mindfulness;
      case 'Social Life':
        return AppLocalizations.of(context).socialLife;
      default:
        return category;
    }
  }

  void _createHabits() {
    if (_selectedHabits.isEmpty) return;
    
    SentryService.addBreadcrumb(
      message: 'habits_created_from_template',
      category: 'habit_management',
      data: {
        'habit_count': _selectedHabits.length,
        'habits': _selectedHabits,
      },
    );
    
    // Return the selected habits to the previous screen
    Navigator.pop(context, _selectedHabits);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text('${_selectedHabits.length} habits ${AppLocalizations.of(context).created} successfully'),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }
}
