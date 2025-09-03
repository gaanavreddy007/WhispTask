// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class ProductivityScoreCard extends StatelessWidget {
  const ProductivityScoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final score = taskProvider.dailyProductivityScore;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: score > 70
                ? Colors.green.withOpacity(0.1)
                : score > 40
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: score > 70
                  ? Colors.green
                  : score > 40
                      ? Colors.orange
                      : Colors.red,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.trending_up,
                color: score > 70
                    ? Colors.green
                    : score > 40
                        ? Colors.orange
                        : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Today\'s Productivity: ${score.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: score > 70
                      ? Colors.green[700]
                      : score > 40
                          ? Colors.orange[700]
                          : Colors.red[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: score > 70
                      ? Colors.green
                      : score > 40
                          ? Colors.orange
                          : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  score > 70 ? 'Great!' : score > 40 ? 'Good' : 'Keep Going!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
