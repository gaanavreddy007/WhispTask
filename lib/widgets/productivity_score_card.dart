// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class ProductivityScoreCard extends StatefulWidget {
  const ProductivityScoreCard({super.key});

  @override
  State<ProductivityScoreCard> createState() => _ProductivityScoreCardState();
}

class _ProductivityScoreCardState extends State<ProductivityScoreCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final score = taskProvider.dailyProductivityScore;
        final today = DateTime.now();
        final todayTasks = taskProvider.tasks.where((task) {
          if (task.dueDate != null) {
            final dueDate = task.dueDate!;
            return dueDate.year == today.year &&
                   dueDate.month == today.month &&
                   dueDate.day == today.day;
          }
          return false;
        }).toList();
        
        final completedToday = todayTasks.where((task) => task.isCompleted).length;
        
        // Debug logging for productivity score
        // ignore: avoid_print
        print('ProductivityScoreCard: Score = $score, Today tasks = ${todayTasks.length}, Completed = $completedToday');
        
        return ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _getGradientColors(score, isDark),
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _getScoreColor(score).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.black.withOpacity(0.2)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getScoreColor(score).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getScoreIcon(score),
                          color: _getScoreColor(score),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).todaysProductivity,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$completedToday/${todayTasks.length} tasks completed',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getScoreColor(score),
                              _getScoreColor(score).withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getScoreLabel(context, score),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Progress Section
                  Row(
                    children: [
                      Text(
                        '${score.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: _getScoreColor(score),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            // Progress Bar
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: AnimatedBuilder(
                                animation: _progressAnimation,
                                builder: (context, child) {
                                  return FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: (score / 100) * _progressAnimation.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            _getScoreColor(score),
                                            _getScoreColor(score).withOpacity(0.7),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Motivational Message
                            Text(
                              _getMotivationalMessage(context, score),
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Color> _getGradientColors(double score, bool isDark) {
    if (score >= 80) {
      return isDark
          ? [const Color(0xFF10B981), const Color(0xFF059669)]
          : [const Color(0xFF34D399), const Color(0xFF10B981)];
    } else if (score >= 60) {
      return isDark
          ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
          : [const Color(0xFF60A5FA), const Color(0xFF3B82F6)];
    } else if (score >= 40) {
      return isDark
          ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
          : [const Color(0xFFFBBF24), const Color(0xFFF59E0B)];
    } else {
      return isDark
          ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
          : [const Color(0xFFF87171), const Color(0xFFEF4444)];
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFF3B82F6);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  IconData _getScoreIcon(double score) {
    if (score >= 80) return Icons.emoji_events;
    if (score >= 60) return Icons.trending_up;
    if (score >= 40) return Icons.show_chart;
    return Icons.trending_down;
  }

  String _getScoreLabel(BuildContext context, double score) {
    if (score >= 80) return "Excellent";
    if (score >= 60) return AppLocalizations.of(context).great;
    if (score >= 40) return AppLocalizations.of(context).good;
    return AppLocalizations.of(context).keepGoing;
  }

  String _getMotivationalMessage(BuildContext context, double score) {
    if (score >= 80) return "🎉 Outstanding work today!";
    if (score >= 60) return "💪 Great progress, keep it up!";
    if (score >= 40) return "📈 You're on the right track!";
    if (score > 0) return "🚀 Every step counts!";
    return "✨ Ready to start your productive day?";
  }
}
