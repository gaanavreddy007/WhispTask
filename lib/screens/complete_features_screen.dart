// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/language_provider.dart';
import '../services/advanced_analytics_service.dart';
import '../services/backup_sync_service.dart';
import '../services/testing_service.dart';
import '../services/documentation_service.dart';
import '../services/app_integration_service.dart';
import '../services/statistics_export_service.dart';
import '../services/habit_service.dart';
import '../services/achievement_service.dart';
import '../services/focus_service.dart';
import '../services/settings_service.dart';
import '../services/sentry_service.dart';
import '../l10n/app_localizations.dart';

class CompleteFeaturesScreen extends StatefulWidget {
  const CompleteFeaturesScreen({super.key});

  @override
  State<CompleteFeaturesScreen> createState() => _CompleteFeaturesScreenState();
}

class _CompleteFeaturesScreenState extends State<CompleteFeaturesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _statusMessage = '';
  AppHealthReport? _healthReport;
  List<ProductivityInsight> _insights = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _initializeFeatures();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeFeatures() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing complete feature ecosystem...';
    });

    try {
      // Initialize app integration
      await AppIntegrationService.initialize();
      
      // Generate insights
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      _insights = await AdvancedAnalyticsService.generateInsights(taskProvider.tasks);
      
      // Perform health check
      _healthReport = await AppIntegrationService.performHealthCheck();
      
      setState(() {
        _statusMessage = 'All features initialized successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
      SentryService.captureException(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        title: Text(
          'Complete WhispTask Features',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.backup), text: 'Backup'),
            Tab(icon: Icon(Icons.bug_report), text: 'Testing'),
            Tab(icon: Icon(Icons.health_and_safety), text: 'Health'),
            Tab(icon: Icon(Icons.settings), text: 'System'),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingScreen()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildAnalyticsTab(),
                _buildBackupTab(),
                _buildTestingTab(),
                _buildHealthTab(),
                _buildSystemTab(),
              ],
            ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
          ),
          const SizedBox(height: 24),
          Text(
            _statusMessage,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeatureCard(
            'Task Management',
            'Complete task lifecycle with voice input, categories, and smart reminders',
            Icons.task_alt,
            Colors.blue,
            () => _showFeatureDemo('Task Management'),
          ),
          _buildFeatureCard(
            'Habit Tracking',
            'Build positive habits with streak tracking and automated reminders',
            Icons.trending_up,
            Colors.green,
            () => _showFeatureDemo('Habit Tracking'),
          ),
          _buildFeatureCard(
            'Achievement System',
            '15+ achievements to unlock with progress tracking and celebrations',
            Icons.emoji_events,
            Colors.orange,
            () => _showFeatureDemo('Achievement System'),
          ),
          _buildFeatureCard(
            'Focus Timer',
            'Pomodoro technique with session management and productivity tracking',
            Icons.timer,
            Colors.red,
            () => _showFeatureDemo('Focus Timer'),
          ),
          _buildFeatureCard(
            'Advanced Analytics',
            'AI-powered insights with productivity recommendations',
            Icons.insights,
            Colors.purple,
            () => _showFeatureDemo('Advanced Analytics'),
          ),
          _buildFeatureCard(
            'Data Export',
            'Professional reports in JSON, CSV, and text formats',
            Icons.file_download,
            Colors.teal,
            () => _showFeatureDemo('Data Export'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Productivity Insights',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_insights.isEmpty)
            const Center(
              child: Text('No insights available yet. Complete some tasks to generate insights!'),
            )
          else
            ..._insights.take(5).map((insight) => _buildInsightCard(insight)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _generateNewInsights,
            icon: const Icon(Icons.refresh),
            label: const Text('Generate New Insights'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Management',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            'Create Backup',
            'Generate complete backup of all app data',
            Icons.backup,
            Colors.blue,
            _createBackup,
          ),
          _buildActionCard(
            'Export Statistics',
            'Export comprehensive statistics report',
            Icons.analytics,
            Colors.green,
            _exportStatistics,
          ),
          _buildActionCard(
            'System Diagnostics',
            'Run complete system health check',
            Icons.health_and_safety,
            Colors.orange,
            _runDiagnostics,
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>>(
            future: BackupSyncService.getBackupStatistics(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final stats = snapshot.data!;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Backup Statistics',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Size: ${stats['backup_size_kb']} KB'),
                        Text('Tasks: ${stats['tasks_count']}'),
                        Text('Habits: ${stats['habits_count']}'),
                        Text('Last Backup: ${stats['last_backup'] ?? 'Never'}'),
                      ],
                    ),
                  ),
                );
              }
              return const CircularProgressIndicator();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTestingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quality Assurance',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            'Run All Tests',
            'Execute comprehensive test suite',
            Icons.play_arrow,
            Colors.blue,
            _runAllTests,
          ),
          _buildActionCard(
            'Core Tests',
            'Test core service functionality',
            Icons.settings,
            Colors.green,
            () => _runTestCategory('core'),
          ),
          _buildActionCard(
            'Performance Tests',
            'Benchmark app performance',
            Icons.speed,
            Colors.orange,
            () => _runTestCategory('performance'),
          ),
          _buildActionCard(
            'Security Tests',
            'Validate security measures',
            Icons.security,
            Colors.red,
            () => _runTestCategory('security'),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Health',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_healthReport != null) _buildHealthReportCard(_healthReport!),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshHealthReport,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Health Check'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Information',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSystemInfoCard(),
          const SizedBox(height: 16),
          _buildActionCard(
            'Generate Documentation',
            'Export complete API documentation',
            Icons.description,
            Colors.blue,
            _generateDocumentation,
          ),
          _buildActionCard(
            'System Report',
            'Generate comprehensive system report',
            Icons.assessment,
            Colors.green,
            _generateSystemReport,
          ),
          _buildActionCard(
            'Emergency Recovery',
            'Reset system to safe state',
            Icons.restore,
            Colors.red,
            _emergencyRecovery,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInsightCard(ProductivityInsight insight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    insight.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getScoreColor(insight.score),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(insight.score * 100).round()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(insight.description),
            const SizedBox(height: 8),
            Text(
              insight.recommendation,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.play_arrow),
        onTap: onTap,
      ),
    );
  }

  Widget _buildHealthReportCard(AppHealthReport report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getHealthIcon(report.status),
                  color: _getHealthColor(report.status),
                ),
                const SizedBox(width: 8),
                Text(
                  'Status: ${report.status.name.toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getHealthColor(report.status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Overall Score: ${(report.overallScore * 100).round()}%'),
            const SizedBox(height: 8),
            ...report.serviceScores.entries.map((entry) => 
              Text('${entry.key}: ${(entry.value * 100).round()}%')
            ),
            if (report.recommendations.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...report.recommendations.map((rec) => Text('• $rec')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    final docSummary = DocumentationService.getDocumentationSummary();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WhispTask v1.0.0',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Services: ${docSummary['services_documented']}'),
            Text('API Methods: ${docSummary['total_methods']}'),
            Text('Platform: Flutter'),
            Text('Architecture: Multi-service'),
            const SizedBox(height: 8),
            const Text('Features:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('✓ Voice Input & Recognition'),
            const Text('✓ Advanced Analytics & AI Insights'),
            const Text('✓ Habit Tracking & Gamification'),
            const Text('✓ Focus Timer & Productivity Tools'),
            const Text('✓ Multi-language Support'),
            const Text('✓ Data Backup & Sync'),
            const Text('✓ Comprehensive Testing'),
            const Text('✓ Real-time Health Monitoring'),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getHealthColor(AppHealthStatus status) {
    switch (status) {
      case AppHealthStatus.excellent:
        return Colors.green;
      case AppHealthStatus.good:
        return Colors.blue;
      case AppHealthStatus.warning:
        return Colors.orange;
      case AppHealthStatus.critical:
        return Colors.red;
    }
  }

  IconData _getHealthIcon(AppHealthStatus status) {
    switch (status) {
      case AppHealthStatus.excellent:
        return Icons.check_circle;
      case AppHealthStatus.good:
        return Icons.thumb_up;
      case AppHealthStatus.warning:
        return Icons.warning;
      case AppHealthStatus.critical:
        return Icons.error;
    }
  }

  // Action methods
  void _showFeatureDemo(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('$feature is fully implemented and ready to use!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateNewInsights() async {
    setState(() => _isLoading = true);
    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      _insights = await AdvancedAnalyticsService.generateInsights(taskProvider.tasks);
      setState(() {});
    } catch (e) {
      SentryService.captureException(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createBackup() async {
    try {
      await BackupSyncService.createBackup();
      _showSuccessMessage('Backup created successfully!');
    } catch (e) {
      _showErrorMessage('Failed to create backup: $e');
    }
  }

  Future<void> _exportStatistics() async {
    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await StatisticsExportService.exportToJson(taskProvider.tasks);
      _showSuccessMessage('Statistics exported successfully!');
    } catch (e) {
      _showErrorMessage('Failed to export statistics: $e');
    }
  }

  Future<void> _runDiagnostics() async {
    try {
      await AppIntegrationService.runDiagnostics();
      _showSuccessMessage('Diagnostics completed successfully!');
    } catch (e) {
      _showErrorMessage('Diagnostics failed: $e');
    }
  }

  Future<void> _runAllTests() async {
    try {
      final results = await TestingService.runComprehensiveTests();
      _showSuccessMessage('Tests completed! Success rate: ${(results.successRate * 100).round()}%');
    } catch (e) {
      _showErrorMessage('Tests failed: $e');
    }
  }

  Future<void> _runTestCategory(String category) async {
    try {
      final results = await TestingService.runTestCategory(category);
      _showSuccessMessage('$category tests completed! Success rate: ${(results.successRate * 100).round()}%');
    } catch (e) {
      _showErrorMessage('$category tests failed: $e');
    }
  }

  Future<void> _refreshHealthReport() async {
    try {
      _healthReport = await AppIntegrationService.performHealthCheck();
      setState(() {});
    } catch (e) {
      _showErrorMessage('Health check failed: $e');
    }
  }

  Future<void> _generateDocumentation() async {
    try {
      await DocumentationService.exportDocumentation();
      _showSuccessMessage('Documentation generated successfully!');
    } catch (e) {
      _showErrorMessage('Documentation generation failed: $e');
    }
  }

  Future<void> _generateSystemReport() async {
    try {
      await AppIntegrationService.generateSystemReport();
      _showSuccessMessage('System report generated successfully!');
    } catch (e) {
      _showErrorMessage('System report generation failed: $e');
    }
  }

  Future<void> _emergencyRecovery() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Recovery'),
        content: const Text('This will reset the system to a safe state. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AppIntegrationService.emergencyRecovery();
        _showSuccessMessage('Emergency recovery completed!');
      } catch (e) {
        _showErrorMessage('Emergency recovery failed: $e');
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
