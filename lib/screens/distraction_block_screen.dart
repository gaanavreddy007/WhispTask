// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../services/sentry_service.dart';

class DistractionBlockScreen extends StatefulWidget {
  const DistractionBlockScreen({super.key});

  @override
  State<DistractionBlockScreen> createState() => _DistractionBlockScreenState();
}

class _DistractionBlockScreenState extends State<DistractionBlockScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  bool _isBlockingEnabled = false;
  bool _blockSocialMedia = true;
  bool _blockGames = true;
  bool _blockNews = false;
  bool _blockShopping = false;
  bool _blockEntertainment = false;
  bool _allowEmergencyAccess = true;
  
  List<String> _customBlockedSites = [];
  List<String> _allowedSites = [];
  
  final TextEditingController _siteController = TextEditingController();

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
    _loadSettings();
    
    SentryService.addBreadcrumb(
      message: 'distraction_block_screen_opened',
      category: 'navigation',
      data: {'screen': 'distraction_block'},
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _siteController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _isBlockingEnabled = prefs.getBool('distraction_blocking_enabled') ?? false;
        _blockSocialMedia = prefs.getBool('block_social_media') ?? true;
        _blockGames = prefs.getBool('block_games') ?? true;
        _blockNews = prefs.getBool('block_news') ?? false;
        _blockShopping = prefs.getBool('block_shopping') ?? false;
        _blockEntertainment = prefs.getBool('block_entertainment') ?? false;
        _allowEmergencyAccess = prefs.getBool('allow_emergency_access') ?? true;
        _customBlockedSites = prefs.getStringList('custom_blocked_sites') ?? [];
        _allowedSites = prefs.getStringList('allowed_sites') ?? [];
      });
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('distraction_blocking_enabled', _isBlockingEnabled);
      await prefs.setBool('block_social_media', _blockSocialMedia);
      await prefs.setBool('block_games', _blockGames);
      await prefs.setBool('block_news', _blockNews);
      await prefs.setBool('block_shopping', _blockShopping);
      await prefs.setBool('block_entertainment', _blockEntertainment);
      await prefs.setBool('allow_emergency_access', _allowEmergencyAccess);
      await prefs.setStringList('custom_blocked_sites', _customBlockedSites);
      await prefs.setStringList('allowed_sites', _allowedSites);
      
      SentryService.addBreadcrumb(
        message: 'distraction_block_settings_saved',
        category: 'settings',
        data: {
          'blocking_enabled': _isBlockingEnabled,
          'categories_blocked': _getBlockedCategoriesCount(),
        },
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Distraction blocking settings saved'),
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

  int _getBlockedCategoriesCount() {
    int count = 0;
    if (_blockSocialMedia) count++;
    if (_blockGames) count++;
    if (_blockNews) count++;
    if (_blockShopping) count++;
    if (_blockEntertainment) count++;
    return count;
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
              _buildMainToggle(),
              if (_isBlockingEnabled) ...[
                const SizedBox(height: 24),
                _buildCategoriesSection(),
                const SizedBox(height: 24),
                _buildCustomSitesSection(),
                const SizedBox(height: 24),
                _buildAllowedSitesSection(),
                const SizedBox(height: 24),
                _buildEmergencyAccessSection(),
                const SizedBox(height: 24),
                _buildQuickActionsSection(),
              ],
            ],
          ),
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
              Icons.block_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).distractionBlock,
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

  Widget _buildMainToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _isBlockingEnabled 
                ? const Color(0xFFE53935).withOpacity(0.1)
                : const Color(0xFF1976D2).withOpacity(0.1),
            _isBlockingEnabled 
                ? const Color(0xFFD32F2F).withOpacity(0.05)
                : const Color(0xFF1565C0).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isBlockingEnabled 
              ? const Color(0xFFE53935).withOpacity(0.3)
              : const Color(0xFF1976D2).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isBlockingEnabled 
                      ? const Color(0xFFE53935).withOpacity(0.1)
                      : const Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isBlockingEnabled ? Icons.shield_rounded : Icons.security_rounded,
                  color: _isBlockingEnabled 
                      ? const Color(0xFFE53935)
                      : const Color(0xFF1976D2),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distraction Blocking',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _isBlockingEnabled 
                          ? 'Block distracting websites and apps during focus sessions'
                          : 'Enable to block distracting content during focus time',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isBlockingEnabled,
                onChanged: (value) {
                  setState(() => _isBlockingEnabled = value);
                },
                activeColor: const Color(0xFFE53935),
              ),
            ],
          ),
          if (_isBlockingEnabled) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.warning_rounded,
                    color: Color(0xFFE53935),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Blocking is active. Distracting content will be blocked during focus sessions.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE53935),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Block Categories', Icons.category_rounded),
        const SizedBox(height: 16),
        _buildCategoryTile(
          'Social Media',
          'Facebook, Instagram, Twitter, TikTok, etc.',
          Icons.people_rounded,
          _blockSocialMedia,
          (value) => setState(() => _blockSocialMedia = value),
        ),
        _buildCategoryTile(
          'Games',
          'Gaming websites and mobile games',
          Icons.games_rounded,
          _blockGames,
          (value) => setState(() => _blockGames = value),
        ),
        _buildCategoryTile(
          'News & Media',
          'News websites, blogs, and media sites',
          Icons.newspaper_rounded,
          _blockNews,
          (value) => setState(() => _blockNews = value),
        ),
        _buildCategoryTile(
          'Shopping',
          'E-commerce and shopping websites',
          Icons.shopping_cart_rounded,
          _blockShopping,
          (value) => setState(() => _blockShopping = value),
        ),
        _buildCategoryTile(
          'Entertainment',
          'YouTube, Netflix, streaming services',
          Icons.movie_rounded,
          _blockEntertainment,
          (value) => setState(() => _blockEntertainment = value),
        ),
      ],
    );
  }

  Widget _buildCategoryTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
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
        activeColor: const Color(0xFFE53935),
      ),
    );
  }

  Widget _buildCustomSitesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Custom Blocked Sites', Icons.web_rounded),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1976D2).withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _siteController,
                      decoration: const InputDecoration(
                        hintText: 'Enter website URL (e.g., example.com)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _addCustomSite,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                    ),
                    child: const Text('Block'),
                  ),
                ],
              ),
              if (_customBlockedSites.isNotEmpty) ...[
                const SizedBox(height: 16),
                ..._customBlockedSites.map((site) => _buildSiteItem(
                  site,
                  true,
                  () => _removeCustomSite(site),
                )),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllowedSitesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Always Allow', Icons.check_circle_rounded),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF4CAF50).withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _siteController,
                      decoration: const InputDecoration(
                        hintText: 'Enter website URL to always allow',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _addAllowedSite,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                    ),
                    child: const Text('Allow'),
                  ),
                ],
              ),
              if (_allowedSites.isNotEmpty) ...[
                const SizedBox(height: 16),
                ..._allowedSites.map((site) => _buildSiteItem(
                  site,
                  false,
                  () => _removeAllowedSite(site),
                )),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSiteItem(String site, bool isBlocked, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isBlocked 
            ? const Color(0xFFE53935).withOpacity(0.1)
            : const Color(0xFF4CAF50).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isBlocked ? Icons.block_rounded : Icons.check_circle_rounded,
            color: isBlocked ? const Color(0xFFE53935) : const Color(0xFF4CAF50),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              site,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.5),
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyAccessSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF9800).withOpacity(0.2),
        ),
      ),
      child: SwitchListTile(
        title: Row(
          children: const [
            Icon(Icons.emergency_rounded, size: 20, color: Color(0xFFFF9800)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Emergency Access',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: const Padding(
          padding: EdgeInsets.only(left: 32),
          child: Text('Allow emergency bypass with 30-second delay'),
        ),
        value: _allowEmergencyAccess,
        onChanged: (value) => setState(() => _allowEmergencyAccess = value),
        activeColor: const Color(0xFFFF9800),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Quick Actions', Icons.flash_on_rounded),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                'Block All',
                'Enable all categories',
                Icons.block_rounded,
                const Color(0xFFE53935),
                _enableAllBlocking,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                'Allow All',
                'Disable all blocking',
                Icons.check_circle_rounded,
                const Color(0xFF4CAF50),
                _disableAllBlocking,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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

  void _addCustomSite() {
    final site = _siteController.text.trim();
    if (site.isNotEmpty && !_customBlockedSites.contains(site)) {
      setState(() {
        _customBlockedSites.add(site);
      });
      _siteController.clear();
    }
  }

  void _addAllowedSite() {
    final site = _siteController.text.trim();
    if (site.isNotEmpty && !_allowedSites.contains(site)) {
      setState(() {
        _allowedSites.add(site);
      });
      _siteController.clear();
    }
  }

  void _removeCustomSite(String site) {
    setState(() {
      _customBlockedSites.remove(site);
    });
  }

  void _removeAllowedSite(String site) {
    setState(() {
      _allowedSites.remove(site);
    });
  }

  void _enableAllBlocking() {
    setState(() {
      _blockSocialMedia = true;
      _blockGames = true;
      _blockNews = true;
      _blockShopping = true;
      _blockEntertainment = true;
    });
  }

  void _disableAllBlocking() {
    setState(() {
      _blockSocialMedia = false;
      _blockGames = false;
      _blockNews = false;
      _blockShopping = false;
      _blockEntertainment = false;
    });
  }
}
