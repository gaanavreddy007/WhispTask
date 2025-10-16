// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../services/sentry_service.dart';
import '../services/focus_service.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  
  Timer? _focusTimer;
  Duration _focusDuration = const Duration(minutes: 25); // Pomodoro default
  Duration _remainingTime = const Duration(minutes: 25);
  bool _isRunning = false;
  bool _isPaused = false;
  
  int _selectedDuration = 25; // minutes
  String _selectedMode = 'pomodoro';
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _fadeController.forward();
    
    SentryService.addBreadcrumb(
      message: 'focus_screen_opened',
      category: 'navigation',
      data: {'screen': 'focus'},
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _focusTimer?.cancel();
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFocusModeSelector(theme),
              const SizedBox(height: 24),
              _buildFocusTimer(theme),
              const SizedBox(height: 24),
              _buildFocusStats(theme),
              const SizedBox(height: 24),
              _buildQuickActions(theme),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: const Color(0xFF1976D2),
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
        ),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.center_focus_strong_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).focus,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _showFocusSettings(),
          icon: const Icon(Icons.settings_rounded, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildFocusModeSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
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
          Text(
            AppLocalizations.of(context).focusMode,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildModeCard(
                  'pomodoro',
                  AppLocalizations.of(context).pomodoro,
                  AppLocalizations.of(context).pomodoroDesc,
                  Icons.timer_rounded,
                  const Color(0xFFE53935),
                  theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModeCard(
                  'deep_work',
                  AppLocalizations.of(context).deepWork,
                  AppLocalizations.of(context).deepWorkDesc,
                  Icons.psychology_rounded,
                  const Color(0xFF1976D2),
                  theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildModeCard(
                  'break',
                  AppLocalizations.of(context).breakTime,
                  AppLocalizations.of(context).breakTimeDesc,
                  Icons.coffee_rounded,
                  const Color(0xFF4CAF50),
                  theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModeCard(
                  'custom',
                  AppLocalizations.of(context).custom,
                  AppLocalizations.of(context).customDesc,
                  Icons.tune_rounded,
                  const Color(0xFF9C27B0),
                  theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(
    String mode,
    String title,
    String description,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    final isSelected = _selectedMode == mode;
    
    return GestureDetector(
      onTap: () => _selectMode(mode),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : theme.colorScheme.onSurface.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusTimer(ThemeData theme) {
    final progress = 1.0 - (_remainingTime.inSeconds / _focusDuration.inSeconds);
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isRunning
              ? [
                  const Color(0xFF1976D2).withOpacity(0.8),
                  const Color(0xFF1565C0).withOpacity(0.6),
                ]
              : [
                  theme.colorScheme.surface,
                  theme.colorScheme.surface,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _isRunning 
                ? const Color(0xFF1976D2).withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _isRunning ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: _isRunning 
                        ? Colors.white.withOpacity(0.3)
                        : theme.colorScheme.outline.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isRunning ? Colors.white : const Color(0xFF1976D2),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      _formatDuration(_remainingTime),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _isRunning ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _getModeTitle(),
                      style: TextStyle(
                        fontSize: 16,
                        color: _isRunning 
                            ? Colors.white.withOpacity(0.8)
                            : theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!_isRunning) ...[
                _buildTimerButton(
                  AppLocalizations.of(context).start,
                  Icons.play_arrow_rounded,
                  const Color(0xFF4CAF50),
                  () => _startTimer(),
                ),
              ] else ...[
                _buildTimerButton(
                  _isPaused ? AppLocalizations.of(context).resume : AppLocalizations.of(context).pause,
                  _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  const Color(0xFFFF9800),
                  () => _pauseResumeTimer(),
                ),
                _buildTimerButton(
                  AppLocalizations.of(context).stop,
                  Icons.stop_rounded,
                  const Color(0xFFE53935),
                  () => _stopTimer(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildFocusStats(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
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
          Text(
            AppLocalizations.of(context).todaysFocus,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  AppLocalizations.of(context).sessionsCompleted,
                  '3', // Mock data
                  Icons.check_circle_rounded,
                  const Color(0xFF4CAF50),
                  theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  AppLocalizations.of(context).totalFocusTime,
                  '2h 15m', // Mock data
                  Icons.timer_rounded,
                  const Color(0xFF2196F3),
                  theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  AppLocalizations.of(context).averageSession,
                  '45m', // Mock data
                  Icons.trending_up_rounded,
                  const Color(0xFFFF9800),
                  theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  AppLocalizations.of(context).focusStreak,
                  '7 ${AppLocalizations.of(context).days}', // Mock data
                  Icons.local_fire_department_rounded,
                  const Color(0xFFE53935),
                  theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).quickActions,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _buildActionCard(
              AppLocalizations.of(context).quickFocus,
              Icons.flash_on_rounded,
              const Color(0xFFFFB300),
              () => _startQuickFocus(),
              theme,
            ),
            _buildActionCard(
              AppLocalizations.of(context).focusHistory,
              Icons.history_rounded,
              const Color(0xFF9C27B0),
              () => _showFocusHistory(),
              theme,
            ),
            _buildActionCard(
              AppLocalizations.of(context).focusGoals,
              Icons.flag_rounded,
              const Color(0xFF4CAF50),
              () => _showFocusGoals(),
              theme,
            ),
            _buildActionCard(
              AppLocalizations.of(context).distractionBlock,
              Icons.block_rounded,
              const Color(0xFFE53935),
              () => _showDistractionBlock(),
              theme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getModeTitle() {
    switch (_selectedMode) {
      case 'pomodoro':
        return AppLocalizations.of(context).pomodoro;
      case 'deep_work':
        return AppLocalizations.of(context).deepWork;
      case 'break':
        return AppLocalizations.of(context).breakTime;
      case 'custom':
        return AppLocalizations.of(context).custom;
      default:
        return AppLocalizations.of(context).focus;
    }
  }

  void _selectMode(String mode) {
    setState(() {
      _selectedMode = mode;
      switch (mode) {
        case 'pomodoro':
          _selectedDuration = 25;
          break;
        case 'deep_work':
          _selectedDuration = 90;
          break;
        case 'break':
          _selectedDuration = 5;
          break;
        case 'custom':
          _showCustomTimeDialog();
          return;
      }
      _focusDuration = Duration(minutes: _selectedDuration);
      _remainingTime = _focusDuration;
    });
    
    SentryService.addBreadcrumb(
      message: 'focus_mode_selected',
      category: 'focus',
      data: {'mode': mode, 'duration': _selectedDuration},
    );
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    
    _pulseController.repeat(reverse: true);
    
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
        });
      } else {
        _completeSession();
      }
    });
    
    SentryService.addBreadcrumb(
      message: 'focus_session_started',
      category: 'focus',
      data: {'mode': _selectedMode, 'duration': _selectedDuration},
    );
  }

  void _pauseResumeTimer() {
    setState(() {
      _isPaused = !_isPaused;
    });
    
    if (_isPaused) {
      _focusTimer?.cancel();
      _pulseController.stop();
    } else {
      _startTimer();
    }
    
    SentryService.addBreadcrumb(
      message: 'focus_session_paused',
      category: 'focus',
      data: {'paused': _isPaused},
    );
  }

  void _stopTimer() {
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _remainingTime = _focusDuration;
    });
    
    _focusTimer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    
    SentryService.addBreadcrumb(
      message: 'focus_session_stopped',
      category: 'focus',
      data: {'mode': _selectedMode},
    );
  }

  void _completeSession() {
    _stopTimer();
    
    // Show completion dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).sessionComplete),
        content: Text(AppLocalizations.of(context).sessionCompleteDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).ok),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startTimer();
            },
            child: Text(AppLocalizations.of(context).startAnother),
          ),
        ],
      ),
    );
    
    SentryService.addBreadcrumb(
      message: 'focus_session_completed',
      category: 'focus',
      data: {'mode': _selectedMode, 'duration': _selectedDuration},
    );
  }

  void _showFocusSettings() {
    Navigator.pushNamed(context, '/focus-settings');
  }

  void _startQuickFocus() {
    _selectMode('pomodoro');
    _startTimer();
  }

  void _showFocusHistory() {
    Navigator.pushNamed(context, '/focus-history');
  }

  void _showFocusGoals() {
    Navigator.pushNamed(context, '/focus-goals');
  }

  void _showDistractionBlock() {
    Navigator.pushNamed(context, '/distraction-block');
  }

  void _showCustomTimeDialog() {
    final TextEditingController minutesController = TextEditingController(
      text: _selectedDuration.toString(),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Custom Focus Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your custom focus duration'),
            const SizedBox(height: 16),
            TextField(
              controller: minutesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).minutes,
                hintText: 'Enter minutes (1-180)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixText: 'min',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Reset to previous mode if cancelled
              setState(() {
                _selectedMode = 'pomodoro';
              });
            },
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final minutes = int.tryParse(minutesController.text);
              if (minutes != null && minutes > 0 && minutes <= 180) {
                setState(() {
                  _selectedDuration = minutes;
                  _focusDuration = Duration(minutes: _selectedDuration);
                  _remainingTime = _focusDuration;
                });
                Navigator.pop(context);
                
                SentryService.addBreadcrumb(
                  message: 'custom_focus_time_set',
                  category: 'focus',
                  data: {'duration': _selectedDuration},
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a valid time between 1 and 180 minutes'),
                    backgroundColor: const Color(0xFFE53935),
                  ),
                );
              }
            },
            child: Text('Set Time'),
          ),
        ],
      ),
    );
  }
}
