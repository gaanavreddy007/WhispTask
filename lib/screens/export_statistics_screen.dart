// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/task_provider.dart';
import '../services/sentry_service.dart';

class ExportStatisticsScreen extends StatefulWidget {
  const ExportStatisticsScreen({super.key});

  @override
  State<ExportStatisticsScreen> createState() => _ExportStatisticsScreenState();
}

class _ExportStatisticsScreenState extends State<ExportStatisticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  bool _isExporting = false;
  String _selectedFormat = 'json';
  String _selectedPeriod = 'all';
  bool _includeTaskDetails = true;
  bool _includeCompletionStats = true;
  bool _includeCategoryBreakdown = true;
  bool _includePriorityAnalysis = true;
  
  Map<String, dynamic>? _previewData;

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
    _generatePreview();
    
    SentryService.addBreadcrumb(
      message: 'export_statistics_screen_opened',
      category: 'navigation',
      data: {'screen': 'export_statistics'},
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExportOptions(),
              const SizedBox(height: 24),
              _buildDataSelection(),
              const SizedBox(height: 24),
              _buildPreviewSection(),
              const SizedBox(height: 24),
              _buildExportButton(),
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
              Icons.file_download_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context).exportStatistics,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOptions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1976D2).withOpacity(0.2),
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
          _buildSectionHeader('Export Format', Icons.file_present_rounded),
          const SizedBox(height: 16),
          _buildFormatSelector(),
          const SizedBox(height: 24),
          _buildSectionHeader('Time Period', Icons.date_range_rounded),
          const SizedBox(height: 16),
          _buildPeriodSelector(),
        ],
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Column(
      children: [
        _buildFormatOption(
          'json',
          'JSON',
          'Machine-readable format for developers',
          Icons.code_rounded,
        ),
        _buildFormatOption(
          'csv',
          'CSV',
          'Spreadsheet format for Excel/Google Sheets',
          Icons.table_chart_rounded,
        ),
        _buildFormatOption(
          'txt',
          'Text Report',
          'Human-readable report format',
          Icons.description_rounded,
        ),
      ],
    );
  }

  Widget _buildFormatOption(String value, String title, String description, IconData icon) {
    final isSelected = _selectedFormat == value;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected 
            ? const Color(0xFF1976D2).withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected 
              ? const Color(0xFF1976D2)
              : const Color(0xFF1976D2).withOpacity(0.2),
        ),
      ),
      child: RadioListTile<String>(
        title: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF1976D2)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        subtitle: Text(description),
        value: value,
        groupValue: _selectedFormat,
        onChanged: (newValue) {
          setState(() {
            _selectedFormat = newValue!;
            _generatePreview();
          });
        },
        activeColor: const Color(0xFF1976D2),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Wrap(
      spacing: 8,
      children: [
        _buildPeriodChip('all', 'All Time'),
        _buildPeriodChip('year', 'This Year'),
        _buildPeriodChip('month', 'This Month'),
        _buildPeriodChip('week', 'This Week'),
      ],
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _selectedPeriod == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedPeriod = value;
          _generatePreview();
        });
      },
      backgroundColor: Colors.transparent,
      selectedColor: const Color(0xFF1976D2),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF1976D2),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDataSelection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1976D2).withOpacity(0.2),
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
          _buildSectionHeader('Data to Include', Icons.checklist_rounded),
          const SizedBox(height: 16),
          _buildDataOption(
            'Task Details',
            'Individual task information and metadata',
            _includeTaskDetails,
            (value) => setState(() {
              _includeTaskDetails = value;
              _generatePreview();
            }),
          ),
          _buildDataOption(
            'Completion Statistics',
            'Task completion rates and trends',
            _includeCompletionStats,
            (value) => setState(() {
              _includeCompletionStats = value;
              _generatePreview();
            }),
          ),
          _buildDataOption(
            'Category Breakdown',
            'Analysis by task categories',
            _includeCategoryBreakdown,
            (value) => setState(() {
              _includeCategoryBreakdown = value;
              _generatePreview();
            }),
          ),
          _buildDataOption(
            'Priority Analysis',
            'Task priority distribution and completion',
            _includePriorityAnalysis,
            (value) => setState(() {
              _includePriorityAnalysis = value;
              _generatePreview();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDataOption(String title, String description, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1976D2).withOpacity(0.2),
        ),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(description),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF1976D2),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1976D2).withOpacity(0.2),
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
          _buildSectionHeader('Export Preview', Icons.preview_rounded),
          const SizedBox(height: 16),
          if (_previewData != null) ...[
            _buildPreviewStats(),
            const SizedBox(height: 16),
            _buildPreviewContent(),
          ] else
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewStats() {
    if (_previewData == null) return const SizedBox();
    
    final stats = _previewData!['summary'] as Map<String, dynamic>? ?? {};
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1976D2).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total Tasks',
              stats['totalTasks']?.toString() ?? '0',
              Icons.task_rounded,
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
              stats['completedTasks']?.toString() ?? '0',
              Icons.check_circle_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFF1976D2).withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatItem(
              'Categories',
              stats['categories']?.toString() ?? '0',
              Icons.category_rounded,
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

  Widget _buildPreviewContent() {
    if (_previewData == null) return const SizedBox();
    
    String previewText;
    switch (_selectedFormat) {
      case 'json':
        previewText = '${const JsonEncoder.withIndent('  ').convert(_previewData).substring(0, 500)}...';
        break;
      case 'csv':
        previewText = _generateCsvPreview();
        break;
      case 'txt':
        previewText = _generateTextPreview();
        break;
      default:
        previewText = 'Preview not available';
    }
    
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SingleChildScrollView(
        child: Text(
          previewText,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: _isExporting ? null : _exportStatistics,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1976D2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isExporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.file_download_rounded),
        label: Text(
          _isExporting ? 'Exporting...' : 'Export Statistics',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
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

  Future<void> _generatePreview() async {
    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final tasks = taskProvider.tasks;
      
      final filteredTasks = _filterTasksByPeriod(tasks);
      
      final data = <String, dynamic>{
        'metadata': {
          'exportDate': DateTime.now().toIso8601String(),
          'format': _selectedFormat,
          'period': _selectedPeriod,
          'appVersion': '1.0.0',
        },
        'summary': {
          'totalTasks': filteredTasks.length,
          'completedTasks': filteredTasks.where((t) => t.isCompleted).length,
          'categories': filteredTasks.map((t) => t.category).toSet().length,
        },
      };
      
      if (_includeTaskDetails) {
        data['tasks'] = filteredTasks.map((task) => {
          'id': task.id,
          'title': task.title,
          'description': task.description,
          'category': task.category,
          'priority': task.priority,
          'isCompleted': task.isCompleted,
          'createdAt': task.createdAt.toIso8601String(),
          'completedAt': task.completedAt?.toIso8601String(),
        }).toList();
      }
      
      if (_includeCompletionStats) {
        data['completionStats'] = _generateCompletionStats(filteredTasks);
      }
      
      if (_includeCategoryBreakdown) {
        data['categoryBreakdown'] = _generateCategoryBreakdown(filteredTasks);
      }
      
      if (_includePriorityAnalysis) {
        data['priorityAnalysis'] = _generatePriorityAnalysis(filteredTasks);
      }
      
      setState(() {
        _previewData = data;
      });
    } catch (e) {
      SentryService.captureException(e);
    }
  }

  List<dynamic> _filterTasksByPeriod(List<dynamic> tasks) {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (_selectedPeriod) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        return tasks;
    }
    
    return tasks.where((task) {
      final createdAt = task.createdAt;
      return createdAt.isAfter(startDate);
    }).toList();
  }

  Map<String, dynamic> _generateCompletionStats(List<dynamic> tasks) {
    final completed = tasks.where((t) => t.isCompleted).length;
    final total = tasks.length;
    
    return {
      'completionRate': total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0.0',
      'totalTasks': total,
      'completedTasks': completed,
      'pendingTasks': total - completed,
    };
  }

  Map<String, dynamic> _generateCategoryBreakdown(List<dynamic> tasks) {
    final categoryStats = <String, Map<String, int>>{};
    
    for (final task in tasks) {
      final category = task.category;
      if (!categoryStats.containsKey(category)) {
        categoryStats[category] = {'total': 0, 'completed': 0};
      }
      categoryStats[category]!['total'] = categoryStats[category]!['total']! + 1;
      if (task.isCompleted) {
        categoryStats[category]!['completed'] = categoryStats[category]!['completed']! + 1;
      }
    }
    
    return categoryStats;
  }

  Map<String, dynamic> _generatePriorityAnalysis(List<dynamic> tasks) {
    final priorityStats = <String, Map<String, int>>{};
    
    for (final task in tasks) {
      final priority = task.priority;
      if (!priorityStats.containsKey(priority)) {
        priorityStats[priority] = {'total': 0, 'completed': 0};
      }
      priorityStats[priority]!['total'] = priorityStats[priority]!['total']! + 1;
      if (task.isCompleted) {
        priorityStats[priority]!['completed'] = priorityStats[priority]!['completed']! + 1;
      }
    }
    
    return priorityStats;
  }

  String _generateCsvPreview() {
    return '''Task ID,Title,Category,Priority,Status,Created Date
task_001,Complete project proposal,Work,High,Completed,2024-10-15
task_002,Review quarterly reports,Work,Medium,Pending,2024-10-14
task_003,Plan team meeting,Work,Low,Completed,2024-10-13
...''';
  }

  String _generateTextPreview() {
    return '''WhispTask Statistics Report
Generated: ${DateTime.now().toString().split('.')[0]}

SUMMARY
=======
Total Tasks: ${_previewData?['summary']?['totalTasks'] ?? 0}
Completed Tasks: ${_previewData?['summary']?['completedTasks'] ?? 0}
Categories: ${_previewData?['summary']?['categories'] ?? 0}

COMPLETION STATISTICS
====================
Completion Rate: 75.5%
Pending Tasks: 12
...''';
  }

  Future<void> _exportStatistics() async {
    setState(() => _isExporting = true);
    
    try {
      SentryService.addBreadcrumb(
        message: 'statistics_export_started',
        category: 'export',
        data: {
          'format': _selectedFormat,
          'period': _selectedPeriod,
        },
      );
      
      String content;
      String fileName;
      
      switch (_selectedFormat) {
        case 'json':
          content = const JsonEncoder.withIndent('  ').convert(_previewData);
          fileName = 'whispTask_statistics_${_selectedPeriod}_${DateTime.now().millisecondsSinceEpoch}.json';
          break;
        case 'csv':
          content = await _generateCsvContent();
          fileName = 'whispTask_statistics_${_selectedPeriod}_${DateTime.now().millisecondsSinceEpoch}.csv';
          break;
        case 'txt':
          content = await _generateTextContent();
          fileName = 'whispTask_statistics_${_selectedPeriod}_${DateTime.now().millisecondsSinceEpoch}.txt';
          break;
        default:
          throw Exception('Unsupported format');
      }
      
      // Save to documents directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(content);
      
      SentryService.addBreadcrumb(
        message: 'statistics_exported_successfully',
        category: 'export',
        data: {'fileName': fileName},
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text('Statistics saved to: ${file.path}'),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      SentryService.captureException(e);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text('Export failed: ${e.toString()}'),
              ],
            ),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<String> _generateCsvContent() async {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Task ID,Title,Description,Category,Priority,Status,Created Date,Completed Date');
    
    // Data rows
    if (_previewData != null && _previewData!['tasks'] != null) {
      final tasks = _previewData!['tasks'] as List;
      for (final task in tasks) {
        buffer.writeln([
          task['id'],
          '"${task['title']}"',
          '"${task['description']}"',
          task['category'],
          task['priority'],
          task['isCompleted'] ? 'Completed' : 'Pending',
          task['createdAt'],
          task['completedAt'] ?? '',
        ].join(','));
      }
    }
    
    return buffer.toString();
  }

  Future<String> _generateTextContent() async {
    final buffer = StringBuffer();
    
    buffer.writeln('WhispTask Statistics Report');
    buffer.writeln('=' * 40);
    buffer.writeln('Generated: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln('Period: $_selectedPeriod');
    buffer.writeln();
    
    if (_previewData != null) {
      final summary = _previewData!['summary'] as Map<String, dynamic>;
      
      buffer.writeln('SUMMARY');
      buffer.writeln('=' * 20);
      buffer.writeln('Total Tasks: ${summary['totalTasks']}');
      buffer.writeln('Completed Tasks: ${summary['completedTasks']}');
      buffer.writeln('Categories: ${summary['categories']}');
      buffer.writeln();
      
      if (_includeCompletionStats && _previewData!['completionStats'] != null) {
        final stats = _previewData!['completionStats'] as Map<String, dynamic>;
        buffer.writeln('COMPLETION STATISTICS');
        buffer.writeln('=' * 30);
        buffer.writeln('Completion Rate: ${stats['completionRate']}%');
        buffer.writeln('Pending Tasks: ${stats['pendingTasks']}');
        buffer.writeln();
      }
      
      if (_includeCategoryBreakdown && _previewData!['categoryBreakdown'] != null) {
        final categories = _previewData!['categoryBreakdown'] as Map<String, dynamic>;
        buffer.writeln('CATEGORY BREAKDOWN');
        buffer.writeln('=' * 25);
        categories.forEach((category, stats) {
          final categoryStats = stats as Map<String, dynamic>;
          buffer.writeln('$category: ${categoryStats['completed']}/${categoryStats['total']} completed');
        });
        buffer.writeln();
      }
      
      if (_includePriorityAnalysis && _previewData!['priorityAnalysis'] != null) {
        final priorities = _previewData!['priorityAnalysis'] as Map<String, dynamic>;
        buffer.writeln('PRIORITY ANALYSIS');
        buffer.writeln('=' * 25);
        priorities.forEach((priority, stats) {
          final priorityStats = stats as Map<String, dynamic>;
          buffer.writeln('$priority: ${priorityStats['completed']}/${priorityStats['total']} completed');
        });
        buffer.writeln();
      }
    }
    
    return buffer.toString();
  }
}
