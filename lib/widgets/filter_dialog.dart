// ignore_for_file: unused_import, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../l10n/app_localizations.dart';

class FilterDialog extends StatefulWidget {
  const FilterDialog({super.key});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Local filter state
  Set<String> _selectedCategories = {};
  Set<String> _selectedPriorities = {};
  Set<String> _selectedStatuses = {};
  Set<String> _selectedColors = {};
  DateTime? _dueDateStart;
  DateTime? _dueDateEnd;
  bool _showRecurringOnly = false;
  bool _showReminderOnly = false;
  bool _showOverdueOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCurrentFilters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCurrentFilters() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    // Load current filter state from provider
    setState(() {
      _selectedCategories = Set.from(taskProvider.selectedCategories);
      _selectedPriorities = Set.from(taskProvider.selectedPriorities);
      _selectedStatuses = Set.from(taskProvider.selectedStatuses);
      _selectedColors = Set.from(taskProvider.selectedColors);
      _dueDateStart = taskProvider.dueDateStart;
      _dueDateEnd = taskProvider.dueDateEnd;
      _showRecurringOnly = taskProvider.showRecurringOnly;
      _showReminderOnly = taskProvider.showRemindersOnly;
      _showOverdueOnly = taskProvider.showOverdueOnly;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.blue[50]!.withOpacity(0.3),
            ],
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.blue[700]!],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Filter Tasks',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _clearAllFilters,
                    icon: const Icon(Icons.clear_all, color: Colors.white),
                    tooltip: 'Clear All Filters',
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Active filters summary
            if (taskProvider.hasActiveFilters)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.amber[50],
                child: Row(
                  children: [
                    Icon(Icons.info, size: 16, color: Colors.amber[700]),
                    const SizedBox(width: 8),
                    Text(
                      '${_getActiveFilterCount()} filter(s) active',
                      style: TextStyle(
                        color: Colors.amber[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _clearAllFilters,
                      child: Text(
                        'Clear All',
                        style: TextStyle(
                          color: Colors.amber[700],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.category), text: 'Categories'),
                Tab(icon: Icon(Icons.flag), text: 'Properties'),
                Tab(icon: Icon(Icons.calendar_today), text: 'Dates'),
                Tab(icon: Icon(Icons.color_lens), text: 'Colors'),
              ],
              labelColor: Colors.blue[600],
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.blue[600],
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCategoriesTab(taskProvider),
                  _buildPropertiesTab(taskProvider),
                  _buildDatesTab(taskProvider),
                  _buildColorsTab(taskProvider),
                ],
              ),
            ),

            // Footer with actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Results count
                  Expanded(
                    child: Consumer<TaskProvider>(
                      builder: (context, provider, child) {
                        final filteredTasks = provider.filteredTasks;
                        return Text(
                          '${filteredTasks.length} task${filteredTasks.length != 1 ? 's' : ''} match',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Action buttons
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(AppLocalizations.of(context).applyFiltersLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Categories tab
  Widget _buildCategoriesTab(TaskProvider taskProvider) {
    final availableCategories = taskProvider.availableCategories;
    // Add default categories if none exist
    final categories = availableCategories.isEmpty 
        ? TaskCategory.all 
        : availableCategories;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Categories',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategories.contains(category);
                final categoryColor = _getCategoryColor(category);
                final categoryIcon = _getCategoryIcon(category);
                
                return GestureDetector(
                  onTap: () => _toggleCategory(category),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? categoryColor.withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? categoryColor
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          categoryIcon,
                          size: 18,
                          color: isSelected 
                              ? categoryColor
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            category.capitalize(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected 
                                  ? FontWeight.w600 
                                  : FontWeight.w500,
                              color: isSelected 
                                  ? categoryColor
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: categoryColor,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Properties tab (Priority, Status, Special flags)
  Widget _buildPropertiesTab(TaskProvider taskProvider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority section
            _buildPropertySection(
              title: 'Priority',
              icon: Icons.flag,
              items: ['high', 'medium', 'low'],
              selectedItems: _selectedPriorities,
              onToggle: _togglePriority,
              getColor: (priority) => _getPriorityColor(priority),
              getIcon: (priority) => _getPriorityIcon(priority),
            ),
            
            const SizedBox(height: 20),
            
            // Status section
            _buildPropertySection(
              title: 'Status',
              icon: Icons.assignment_turned_in,
              items: ['pending', 'completed'],
              selectedItems: _selectedStatuses,
              onToggle: _toggleStatus,
              getColor: (status) => _getStatusColor(status),
              getIcon: (status) => _getStatusIcon(status),
            ),
            
            const SizedBox(height: 20),
            
            // Special filters
            Text(
              'Special Filters',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            
            // Special filter switches
            _buildFilterSwitch(
              title: 'Recurring Tasks Only',
              subtitle: 'Show only tasks that repeat',
              icon: Icons.repeat,
              value: _showRecurringOnly,
              onChanged: (value) => setState(() => _showRecurringOnly = value),
              color: Colors.purple,
            ),
            
            _buildFilterSwitch(
              title: 'Tasks with Reminders Only',
              subtitle: 'Show only tasks with active reminders',
              icon: Icons.notifications_active,
              value: _showReminderOnly,
              onChanged: (value) => setState(() => _showReminderOnly = value),
              color: Colors.blue,
            ),
            
            _buildFilterSwitch(
              title: 'Overdue Tasks Only',
              subtitle: 'Show only tasks past their due date',
              icon: Icons.warning,
              value: _showOverdueOnly,
              onChanged: (value) => setState(() => _showOverdueOnly = value),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  // Dates tab
  Widget _buildDatesTab(TaskProvider taskProvider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Due Date Range',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          
          // Quick date filters
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickDateChip('Today', () => _setQuickDateFilter('today')),
              _buildQuickDateChip('Tomorrow', () => _setQuickDateFilter('tomorrow')),
              _buildQuickDateChip('This Week', () => _setQuickDateFilter('week')),
              _buildQuickDateChip('Next Week', () => _setQuickDateFilter('next_week')),
              _buildQuickDateChip('This Month', () => _setQuickDateFilter('month')),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Custom date range
          Text(
            'Custom Date Range',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          
          // Start date picker
          _buildDatePickerTile(
            title: 'Start Date',
            date: _dueDateStart,
            onTap: () => _selectDate(context, true),
            icon: Icons.calendar_today,
          ),
          
          const SizedBox(height: 8),
          
          // End date picker
          _buildDatePickerTile(
            title: 'End Date',
            date: _dueDateEnd,
            onTap: () => _selectDate(context, false),
            icon: Icons.event,
          ),
          
          const SizedBox(height: 16),
          
          // Clear date filters
          if (_dueDateStart != null || _dueDateEnd != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _clearDateFilters,
                icon: const Icon(Icons.clear, size: 16),
                label: Text(AppLocalizations.of(context).clearDateFiltersLabel),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Colors tab
  Widget _buildColorsTab(TaskProvider taskProvider) {
    final availableColors = taskProvider.colors;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colors section
            if (availableColors.isNotEmpty) ...[
              Text(
                'Colors',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: availableColors.map((colorName) {
                  final color = _parseColor(colorName);
                  final isSelected = _selectedColors.contains(colorName);
                  
                  return GestureDetector(
                    onTap: () => _toggleColor(colorName),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected 
                              ? Colors.grey[800]!
                              : Colors.grey[300]!,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: isSelected 
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: _getContrastColor(color),
                              size: 24,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method to build property sections
  Widget _buildPropertySection({
    required String title,
    required IconData icon,
    required List<String> items,
    required Set<String> selectedItems,
    required Function(String) onToggle,
    required Color Function(String) getColor,
    required IconData Function(String) getIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final isSelected = selectedItems.contains(item);
            final color = getColor(item);
            final itemIcon = getIcon(item);
            
            return GestureDetector(
              onTap: () => onToggle(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? color.withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      itemIcon,
                      size: 16,
                      color: isSelected ? color : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.capitalize(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected 
                            ? FontWeight.w600 
                            : FontWeight.w500,
                        color: isSelected ? color : Colors.grey[700],
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.check,
                        size: 14,
                        color: color,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Helper method to build filter switches
  Widget _buildFilterSwitch({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? color.withOpacity(0.3) : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? color : Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: value ? color : Colors.grey[700],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  // Helper method to build quick date chips
  Widget _buildQuickDateChip(String label, VoidCallback onTap) {
    final isActive = _isQuickDateActive(label);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue[100] : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? Colors.blue[400]! : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.blue[700] : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  // Helper method to build date picker tiles
  Widget _buildDatePickerTile({
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: date != null ? Colors.blue[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null ? Colors.blue[200]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: date != null ? Colors.blue[600] : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const Spacer(),
            Text(
              date != null 
                  ? '${date.day}/${date.month}/${date.year}'
                  : 'Select Date',
              style: TextStyle(
                color: date != null ? Colors.blue[600] : Colors.grey[500],
                fontWeight: date != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Toggle methods
  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  void _togglePriority(String priority) {
    setState(() {
      if (_selectedPriorities.contains(priority)) {
        _selectedPriorities.remove(priority);
      } else {
        _selectedPriorities.add(priority);
      }
    });
  }

  void _toggleStatus(String status) {
    setState(() {
      if (_selectedStatuses.contains(status)) {
        _selectedStatuses.remove(status);
      } else {
        _selectedStatuses.add(status);
      }
    });
  }

  void _toggleColor(String color) {
    setState(() {
      if (_selectedColors.contains(color)) {
        _selectedColors.remove(color);
      } else {
        _selectedColors.add(color);
      }
    });
  }

  // Date selection methods
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate 
          ? (_dueDateStart ?? DateTime.now())
          : (_dueDateEnd ?? DateTime.now().add(const Duration(days: 7))),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[600]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _dueDateStart = picked;
        } else {
          _dueDateEnd = picked;
        }
      });
    }
  }

  void _setQuickDateFilter(String filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    setState(() {
      switch (filter) {
        case 'today':
          _dueDateStart = today;
          _dueDateEnd = today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
          break;
        case 'tomorrow':
          final tomorrow = today.add(const Duration(days: 1));
          _dueDateStart = tomorrow;
          _dueDateEnd = tomorrow.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
          break;
        case 'week':
          _dueDateStart = today;
          _dueDateEnd = today.add(const Duration(days: 7));
          break;
        case 'next_week':
          _dueDateStart = today.add(const Duration(days: 7));
          _dueDateEnd = today.add(const Duration(days: 14));
          break;
        case 'month':
          _dueDateStart = today;
          _dueDateEnd = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
          break;
      }
    });
  }

  void _clearDateFilters() {
    setState(() {
      _dueDateStart = null;
      _dueDateEnd = null;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategories.clear();
      _selectedPriorities.clear();
      _selectedStatuses.clear();
      _selectedColors.clear();
      _dueDateStart = null;
      _dueDateEnd = null;
      _showRecurringOnly = false;
      _showReminderOnly = false;
      _showOverdueOnly = false;
    });
  }

  void _applyFilters() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    // Apply all filters to the provider
    taskProvider.setFilters(
      categories: _selectedCategories.toList(),
      priorities: _selectedPriorities.toList(),
      statuses: _selectedStatuses.toList(),
      colors: _selectedColors.toList(),
      startDate: _dueDateStart,
      endDate: _dueDateEnd,
      showRecurring: _showRecurringOnly,
      showReminders: _showReminderOnly,
      showOverdue: _showOverdueOnly,
    );
    
    Navigator.of(context).pop(true); // Return true to indicate filters were applied
  }

  // Helper methods for UI state
  bool _isQuickDateActive(String label) {
    if (_dueDateStart == null || _dueDateEnd == null) return false;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (label) {
      case 'Today':
        final tomorrow = today.add(const Duration(days: 1));
        return _dueDateStart!.isAtSameMomentAs(today) && 
               _dueDateEnd!.isBefore(tomorrow);
      case 'Tomorrow':
        final tomorrow = today.add(const Duration(days: 1));
        final dayAfter = tomorrow.add(const Duration(days: 1));
        return _dueDateStart!.isAtSameMomentAs(tomorrow) && 
               _dueDateEnd!.isBefore(dayAfter);
      case 'This Week':
        final nextWeek = today.add(const Duration(days: 7));
        return _dueDateStart!.isAtSameMomentAs(today) && 
               _dueDateEnd!.isAtSameMomentAs(nextWeek);
      case 'Next Week':
        final nextWeek = today.add(const Duration(days: 7));
        final weekAfter = today.add(const Duration(days: 14));
        return _dueDateStart!.isAtSameMomentAs(nextWeek) && 
               _dueDateEnd!.isAtSameMomentAs(weekAfter);
      case 'This Month':
        final nextMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
        return _dueDateStart!.isAtSameMomentAs(today) && 
               _dueDateEnd!.isAtSameMomentAs(nextMonth);
      default:
        return false;
    }
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedCategories.isNotEmpty) count++;
    if (_selectedPriorities.isNotEmpty) count++;
    if (_selectedStatuses.isNotEmpty) count++;
    if (_selectedColors.isNotEmpty) count++;
    if (_dueDateStart != null || _dueDateEnd != null) count++;
    if (_showRecurringOnly) count++;
    if (_showReminderOnly) count++;
    if (_showOverdueOnly) count++;
    return count;
  }

  // Color and styling helper methods
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work': return Colors.blue[600]!;
      case 'personal': return Colors.green[600]!;
      case 'shopping': return Colors.purple[600]!;
      case 'health': return Colors.red[600]!;
      case 'education': return Colors.indigo[600]!;
      case 'finance': return Colors.teal[600]!;
      case 'social': return Colors.pink[600]!;
      default: return Colors.grey[600]!;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'work': return Icons.work;
      case 'personal': return Icons.person;
      case 'shopping': return Icons.shopping_cart;
      case 'health': return Icons.favorite;
      case 'education': return Icons.school;
      case 'finance': return Icons.account_balance_wallet;
      case 'social': return Icons.people;
      default: return Icons.task;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Colors.red[600]!;
      case 'medium': return Colors.orange[600]!;
      case 'low': return Colors.green[600]!;
      default: return Colors.grey[600]!;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Icons.priority_high;
      case 'medium': return Icons.remove;
      case 'low': return Icons.expand_more;
      default: return Icons.flag;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green[600]!;
      case 'pending': return Colors.orange[600]!;
      default: return Colors.grey[600]!;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Icons.check_circle;
      case 'pending': return Icons.pending;
      default: return Icons.help;
    }
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      } else if (colorString.startsWith('0x')) {
        return Color(int.parse(colorString));
      } else {
        // Named colors
        switch (colorString.toLowerCase()) {
          case 'red': return Colors.red[600]!;
          case 'blue': return Colors.blue[600]!;
          case 'green': return Colors.green[600]!;
          case 'orange': return Colors.orange[600]!;
          case 'purple': return Colors.purple[600]!;
          case 'teal': return Colors.teal[600]!;
          case 'pink': return Colors.pink[600]!;
          case 'yellow': return Colors.yellow[600]!;
          case 'indigo': return Colors.indigo[600]!;
          case 'cyan': return Colors.cyan[600]!;
          default: return Colors.blue[600]!;
        }
      }
    } catch (e) {
      return Colors.blue[600]!;
    }
  }

  Color _getContrastColor(Color color) {
    // Calculate the relative luminance
    double luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

// Extension to capitalize strings
extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}