// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../l10n/app_localizations.dart';
import '../services/sentry_service.dart';
import '../services/focus_service.dart';

class FocusHistoryScreen extends StatefulWidget {
  const FocusHistoryScreen({super.key});

  @override
  State<FocusHistoryScreen> createState() => _FocusHistoryScreenState();
}

class _FocusHistoryScreenState extends State<FocusHistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  List<FocusSession> _sessions = [];
  String _selectedFilter = 'all';
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
    _loadFocusHistory();
    
    SentryService.addBreadcrumb(
      message: 'focus_history_screen_opened',
      category: 'navigation',
      data: {'screen': 'focus_history'},
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadFocusHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getStringList('focus_sessions') ?? [];
      
      setState(() {
        _sessions = sessionsJson
            .map((json) => FocusSession.fromJson(jsonDecode(json)))
            .toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));
        _isLoading = false;
      });
    } catch (e) {
      SentryService.captureException(e);
      setState(() => _isLoading = false);
    }
  }

  List<FocusSession> get _filteredSessions {
    switch (_selectedFilter) {
      case 'today':
        final today = DateTime.now();
        return _sessions.where((session) =>
          session.startTime.year == today.year &&
          session.startTime.month == today.month &&
          session.startTime.day == today.day
        ).toList();
      case 'week':
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        return _sessions.where((session) =>
          session.startTime.isAfter(weekAgo)
        ).toList();
      case 'month':
        final monthAgo = DateTime.now().subtract(const Duration(days: 30));
        return _sessions.where((session) =>
          session.startTime.isAfter(monthAgo)
        ).toList();
      case 'completed':
        return _sessions.where((session) =>
          session.status == FocusSessionStatus.completed
        ).toList();
      default:
        return _sessions;
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
                  : _filteredSessions.isEmpty
                      ? _buildEmptyState()
                      : _buildSessionsList(),
            ),
          ],
        ),
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
              Icons.history_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).focusHistory,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _clearHistory,
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
      ],
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
            _buildFilterChip('all', 'All'),
            _buildFilterChip('today', 'Today'),
            _buildFilterChip('week', 'This Week'),
            _buildFilterChip('month', 'This Month'),
            _buildFilterChip('completed', 'Completed'),
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
    final sessions = _filteredSessions;
    final completedSessions = sessions.where((s) => s.status == FocusSessionStatus.completed).length;
    final totalTime = sessions.fold<Duration>(
      Duration.zero,
      (total, session) => total + session.duration,
    );
    
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
              'Sessions',
              sessions.length.toString(),
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
              completedSessions.toString(),
              Icons.check_circle_outline_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFF1976D2).withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatItem(
              'Total Time',
              '${totalTime.inHours}h ${totalTime.inMinutes % 60}m',
              Icons.schedule_rounded,
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

  Widget _buildSessionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSessions.length,
      itemBuilder: (context, index) {
        final session = _filteredSessions[index];
        return _buildSessionCard(session);
      },
    );
  }

  Widget _buildSessionCard(FocusSession session) {
    final theme = Theme.of(context);
    final isCompleted = session.status == FocusSessionStatus.completed;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted 
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCompleted 
                  ? const Color(0xFF4CAF50).withOpacity(0.1)
                  : _getModeColor(session.mode).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getModeIcon(session.mode),
              color: isCompleted 
                  ? const Color(0xFF4CAF50)
                  : _getModeColor(session.mode),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getModeDisplayName(session.mode),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCompleted 
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF9800),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isCompleted ? 'Completed' : 'Cancelled',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.duration.inMinutes} minutes',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  _formatDateTime(session.startTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF4CAF50),
              size: 24,
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
              Icons.history_rounded,
              size: 48,
              color: Color(0xFF1976D2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Focus Sessions Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your first focus session to see your history here',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start Focus Session'),
          ),
        ],
      ),
    );
  }

  Color _getModeColor(FocusMode mode) {
    switch (mode) {
      case FocusMode.pomodoro:
        return const Color(0xFFE53935);
      case FocusMode.deepWork:
        return const Color(0xFF1976D2);
      case FocusMode.breakTime:
        return const Color(0xFF4CAF50);
      case FocusMode.custom:
        return const Color(0xFF9C27B0);
    }
  }

  IconData _getModeIcon(FocusMode mode) {
    switch (mode) {
      case FocusMode.pomodoro:
        return Icons.timer_rounded;
      case FocusMode.deepWork:
        return Icons.psychology_rounded;
      case FocusMode.breakTime:
        return Icons.coffee_rounded;
      case FocusMode.custom:
        return Icons.tune_rounded;
    }
  }

  String _getModeDisplayName(FocusMode mode) {
    switch (mode) {
      case FocusMode.pomodoro:
        return 'Pomodoro';
      case FocusMode.deepWork:
        return 'Deep Work';
      case FocusMode.breakTime:
        return 'Break Time';
      case FocusMode.custom:
        return 'Custom';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return 'Today at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all focus session history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('focus_sessions');
        setState(() {
          _sessions.clear();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Focus history cleared successfully'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      } catch (e) {
        SentryService.captureException(e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error clearing history'),
              backgroundColor: Color(0xFFE53935),
            ),
          );
        }
      }
    }
  }
}
