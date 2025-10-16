// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../services/sentry_service.dart';

class FocusSettingsScreen extends StatefulWidget {
  const FocusSettingsScreen({super.key});

  @override
  State<FocusSettingsScreen> createState() => _FocusSettingsScreenState();
}

class _FocusSettingsScreenState extends State<FocusSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Focus Mode Settings
  int _pomodoroDuration = 25;
  int _shortBreakDuration = 5;
  int _longBreakDuration = 15;
  int _deepWorkDuration = 90;
  int _sessionsBeforeLongBreak = 4;
  
  // Notification Settings
  bool _enableNotifications = true;
  bool _enableSounds = true;
  bool _enableVibration = true;
  String _notificationSound = 'default';
  
  // Distraction Blocking Settings
  bool _enableDistractionBlock = false;
  bool _blockSocialMedia = true;
  bool _blockGames = true;
  bool _blockNews = false;
  bool _blockShopping = false;
  
  // Goal Settings
  int _dailyFocusGoal = 120; // minutes
  int _weeklySessionsGoal = 25;
  bool _enableGoalReminders = true;
  
  // Auto-start Settings
  bool _autoStartBreaks = false;
  bool _autoStartNextSession = false;
  bool _skipBreaks = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _pomodoroDuration = prefs.getInt('focus_pomodoro_duration') ?? 25;
        _shortBreakDuration = prefs.getInt('focus_short_break_duration') ?? 5;
        _longBreakDuration = prefs.getInt('focus_long_break_duration') ?? 15;
        _deepWorkDuration = prefs.getInt('focus_deep_work_duration') ?? 90;
        _sessionsBeforeLongBreak = prefs.getInt('focus_sessions_before_long_break') ?? 4;
        
        _enableNotifications = prefs.getBool('focus_enable_notifications') ?? true;
        _enableSounds = prefs.getBool('focus_enable_sounds') ?? true;
        _enableVibration = prefs.getBool('focus_enable_vibration') ?? true;
        _notificationSound = prefs.getString('focus_notification_sound') ?? 'default';
        
        _enableDistractionBlock = prefs.getBool('focus_enable_distraction_block') ?? false;
        _blockSocialMedia = prefs.getBool('focus_block_social_media') ?? true;
        _blockGames = prefs.getBool('focus_block_games') ?? true;
        _blockNews = prefs.getBool('focus_block_news') ?? false;
        _blockShopping = prefs.getBool('focus_block_shopping') ?? false;
        
        _dailyFocusGoal = prefs.getInt('focus_daily_goal') ?? 120;
        _weeklySessionsGoal = prefs.getInt('focus_weekly_sessions_goal') ?? 25;
        _enableGoalReminders = prefs.getBool('focus_enable_goal_reminders') ?? true;
        
        _autoStartBreaks = prefs.getBool('focus_auto_start_breaks') ?? false;
        _autoStartNextSession = prefs.getBool('focus_auto_start_next_session') ?? false;
        _skipBreaks = prefs.getBool('focus_skip_breaks') ?? false;
      });
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setInt('focus_pomodoro_duration', _pomodoroDuration);
      await prefs.setInt('focus_short_break_duration', _shortBreakDuration);
      await prefs.setInt('focus_long_break_duration', _longBreakDuration);
      await prefs.setInt('focus_deep_work_duration', _deepWorkDuration);
      await prefs.setInt('focus_sessions_before_long_break', _sessionsBeforeLongBreak);
      
      await prefs.setBool('focus_enable_notifications', _enableNotifications);
      await prefs.setBool('focus_enable_sounds', _enableSounds);
      await prefs.setBool('focus_enable_vibration', _enableVibration);
      await prefs.setString('focus_notification_sound', _notificationSound);
      
      await prefs.setBool('focus_enable_distraction_block', _enableDistractionBlock);
      await prefs.setBool('focus_block_social_media', _blockSocialMedia);
      await prefs.setBool('focus_block_games', _blockGames);
      await prefs.setBool('focus_block_news', _blockNews);
      await prefs.setBool('focus_block_shopping', _blockShopping);
      
      await prefs.setInt('focus_daily_goal', _dailyFocusGoal);
      await prefs.setInt('focus_weekly_sessions_goal', _weeklySessionsGoal);
      await prefs.setBool('focus_enable_goal_reminders', _enableGoalReminders);
      
      await prefs.setBool('focus_auto_start_breaks', _autoStartBreaks);
      await prefs.setBool('focus_auto_start_next_session', _autoStartNextSession);
      await prefs.setBool('focus_skip_breaks', _skipBreaks);
      
      SentryService.addBreadcrumb(
        message: 'focus_settings_saved',
        category: 'settings',
        data: {
          'pomodoro_duration': _pomodoroDuration,
          'notifications_enabled': _enableNotifications,
          'distraction_block_enabled': _enableDistractionBlock,
        },
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Focus settings saved successfully'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      SentryService.captureException(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving settings'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildProfileStyleAppBar(theme),
      body: Column(
        children: [
          _buildTabBar(theme),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTimerSettingsTab(),
                _buildNotificationSettingsTab(),
                _buildDistractionBlockTab(),
                _buildGoalsAutomationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildProfileStyleAppBar(ThemeData theme) {
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
              Icons.settings_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).focusSettings,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: FilledButton.icon(
            onPressed: _saveSettings,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1976D2),
            ),
            icon: const Icon(Icons.save_rounded, size: 18),
            label: Text(AppLocalizations.of(context).save),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1976D2),
            Color(0xFF1565C0),
          ],
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        tabs: [
          _buildEnhancedTab('Timer', Icons.timer_rounded),
          _buildEnhancedTab('Notifications', Icons.notifications_rounded),
          _buildEnhancedTab('Blocking', Icons.block_rounded),
          _buildEnhancedTab('Goals', Icons.flag_rounded),
        ],
      ),
    );
  }

  Widget _buildEnhancedTab(String text, IconData icon) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Focus Durations', Icons.schedule_rounded),
          const SizedBox(height: 16),
          _buildDurationSetting(
            'Pomodoro Session',
            'Standard focused work session',
            _pomodoroDuration,
            (value) => setState(() => _pomodoroDuration = value),
            5,
            60,
          ),
          _buildDurationSetting(
            'Short Break',
            'Brief rest between sessions',
            _shortBreakDuration,
            (value) => setState(() => _shortBreakDuration = value),
            1,
            15,
          ),
          _buildDurationSetting(
            'Long Break',
            'Extended rest after multiple sessions',
            _longBreakDuration,
            (value) => setState(() => _longBreakDuration = value),
            10,
            30,
          ),
          _buildDurationSetting(
            'Deep Work Session',
            'Extended focused work period',
            _deepWorkDuration,
            (value) => setState(() => _deepWorkDuration = value),
            60,
            180,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Session Patterns', Icons.repeat_rounded),
          const SizedBox(height: 16),
          _buildCounterSetting(
            'Sessions Before Long Break',
            'Number of pomodoros before taking a long break',
            _sessionsBeforeLongBreak,
            (value) => setState(() => _sessionsBeforeLongBreak = value),
            2,
            8,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Notification Preferences', Icons.notifications_rounded),
          const SizedBox(height: 16),
          _buildSwitchTile(
            'Enable Notifications',
            'Get notified when sessions start and end',
            _enableNotifications,
            (value) => setState(() => _enableNotifications = value),
            Icons.notifications_active_rounded,
          ),
          _buildSwitchTile(
            'Sound Alerts',
            'Play sound when sessions change',
            _enableSounds,
            (value) => setState(() => _enableSounds = value),
            Icons.volume_up_rounded,
          ),
          _buildSwitchTile(
            'Vibration',
            'Vibrate device for session alerts',
            _enableVibration,
            (value) => setState(() => _enableVibration = value),
            Icons.vibration_rounded,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Sound Selection', Icons.music_note_rounded),
          const SizedBox(height: 16),
          _buildSoundSelector(),
        ],
      ),
    );
  }

  Widget _buildDistractionBlockTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Distraction Blocking', Icons.block_rounded),
          const SizedBox(height: 16),
          _buildSwitchTile(
            'Enable Distraction Blocking',
            'Block distracting apps during focus sessions',
            _enableDistractionBlock,
            (value) => setState(() => _enableDistractionBlock = value),
            Icons.security_rounded,
          ),
          if (_enableDistractionBlock) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('Block Categories', Icons.category_rounded),
            const SizedBox(height: 16),
            _buildSwitchTile(
              'Social Media',
              'Block Facebook, Instagram, Twitter, etc.',
              _blockSocialMedia,
              (value) => setState(() => _blockSocialMedia = value),
              Icons.people_rounded,
            ),
            _buildSwitchTile(
              'Games',
              'Block gaming apps and websites',
              _blockGames,
              (value) => setState(() => _blockGames = value),
              Icons.games_rounded,
            ),
            _buildSwitchTile(
              'News & Media',
              'Block news websites and apps',
              _blockNews,
              (value) => setState(() => _blockNews = value),
              Icons.newspaper_rounded,
            ),
            _buildSwitchTile(
              'Shopping',
              'Block e-commerce and shopping sites',
              _blockShopping,
              (value) => setState(() => _blockShopping = value),
              Icons.shopping_cart_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalsAutomationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Focus Goals', Icons.flag_rounded),
          const SizedBox(height: 16),
          _buildCounterSetting(
            'Daily Focus Goal',
            'Target minutes of focused work per day',
            _dailyFocusGoal,
            (value) => setState(() => _dailyFocusGoal = value),
            30,
            480,
            suffix: 'min',
          ),
          _buildCounterSetting(
            'Weekly Sessions Goal',
            'Target number of focus sessions per week',
            _weeklySessionsGoal,
            (value) => setState(() => _weeklySessionsGoal = value),
            5,
            50,
            suffix: 'sessions',
          ),
          _buildSwitchTile(
            'Goal Reminders',
            'Get reminded about your daily focus goals',
            _enableGoalReminders,
            (value) => setState(() => _enableGoalReminders = value),
            Icons.alarm_rounded,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Automation', Icons.auto_awesome_rounded),
          const SizedBox(height: 16),
          _buildSwitchTile(
            'Auto-start Breaks',
            'Automatically start break timers',
            _autoStartBreaks,
            (value) => setState(() => _autoStartBreaks = value),
            Icons.play_arrow_rounded,
          ),
          _buildSwitchTile(
            'Auto-start Next Session',
            'Automatically start the next focus session',
            _autoStartNextSession,
            (value) => setState(() => _autoStartNextSession = value),
            Icons.skip_next_rounded,
          ),
          _buildSwitchTile(
            'Skip Breaks',
            'Skip break periods and go straight to next session',
            _skipBreaks,
            (value) => setState(() => _skipBreaks = value),
            Icons.fast_forward_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1976D2), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSetting(
    String title,
    String subtitle,
    int value,
    Function(int) onChanged,
    int min,
    int max,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1976D2).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                onPressed: value > min ? () => onChanged(value - 5) : null,
                icon: const Icon(Icons.remove_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2).withOpacity(0.1),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$value minutes',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: value < max ? () => onChanged(value + 5) : null,
                icon: const Icon(Icons.add_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2).withOpacity(0.1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterSetting(
    String title,
    String subtitle,
    int value,
    Function(int) onChanged,
    int min,
    int max, {
    String suffix = '',
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1976D2).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                onPressed: value > min ? () => onChanged(value - (suffix == 'min' ? 15 : 1)) : null,
                icon: const Icon(Icons.remove_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2).withOpacity(0.1),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$value ${suffix.isNotEmpty ? suffix : ''}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: value < max ? () => onChanged(value + (suffix == 'min' ? 15 : 1)) : null,
                icon: const Icon(Icons.add_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2).withOpacity(0.1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1976D2).withOpacity(0.2),
        ),
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF1976D2)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(subtitle),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF1976D2),
      ),
    );
  }

  Widget _buildSoundSelector() {
    final sounds = [
      {'name': 'Default', 'value': 'default'},
      {'name': 'Bell', 'value': 'bell'},
      {'name': 'Chime', 'value': 'chime'},
      {'name': 'Ding', 'value': 'ding'},
      {'name': 'Whistle', 'value': 'whistle'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1976D2).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notification Sound',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...sounds.map((sound) => RadioListTile<String>(
            title: Text(sound['name']!),
            value: sound['value']!,
            groupValue: _notificationSound,
            onChanged: (value) => setState(() => _notificationSound = value!),
            activeColor: const Color(0xFF1976D2),
          )),
        ],
      ),
    );
  }
}
