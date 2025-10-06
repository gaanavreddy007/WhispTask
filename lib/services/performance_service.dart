// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Service to manage performance optimizations and heavy computations
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  // Debounce timers for expensive operations
  final Map<String, Timer> _debounceTimers = {};
  
  // Queue for background tasks
  final List<Function> _backgroundTasks = [];
  bool _isProcessingTasks = false;

  /// Debounce expensive operations to prevent excessive calls
  void debounce(String key, VoidCallback callback, {Duration delay = const Duration(milliseconds: 300)}) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(delay, callback);
  }

  /// Schedule a task to run in the background after a delay
  void scheduleBackgroundTask(Function task, {Duration delay = const Duration(milliseconds: 100)}) {
    _backgroundTasks.add(task);
    
    if (!_isProcessingTasks) {
      _processBackgroundTasks(delay);
    }
  }

  void _processBackgroundTasks(Duration delay) async {
    _isProcessingTasks = true;
    
    while (_backgroundTasks.isNotEmpty) {
      await Future.delayed(delay);
      
      if (_backgroundTasks.isNotEmpty) {
        final task = _backgroundTasks.removeAt(0);
        try {
          await task();
        } catch (e) {
          if (kDebugMode) {
            print('Background task error: $e');
          }
        }
      }
    }
    
    _isProcessingTasks = false;
  }

  /// Compute heavy operations in isolate for better performance
  static Future<T> computeInIsolate<T>(ComputeCallback<dynamic, T> callback, dynamic message) async {
    try {
      return await compute(callback, message);
    } catch (e) {
      if (kDebugMode) {
        print('Isolate computation error: $e');
      }
      rethrow;
    }
  }

  /// Batch multiple operations together to reduce overhead
  void batchOperations(List<VoidCallback> operations, {Duration batchDelay = const Duration(milliseconds: 16)}) {
    Timer(batchDelay, () {
      for (final operation in operations) {
        try {
          operation();
        } catch (e) {
          if (kDebugMode) {
            print('Batch operation error: $e');
          }
        }
      }
    });
  }

  /// Optimize memory by clearing caches and timers
  void clearCaches() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _backgroundTasks.clear();
  }

  /// Check if device has enough memory for heavy operations
  bool get hasEnoughMemory {
    // Simple heuristic - in production, you might want to use platform channels
    // to get actual memory info
    return true; // For now, assume we have enough memory
  }

  /// Throttle function calls to prevent excessive execution
  static Timer? _throttleTimer;
  static void throttle(VoidCallback callback, {Duration duration = const Duration(milliseconds: 100)}) {
    if (_throttleTimer?.isActive ?? false) return;
    
    _throttleTimer = Timer(duration, callback);
  }

  void dispose() {
    clearCaches();
    _throttleTimer?.cancel();
  }
}

/// Extension to add performance optimizations to widgets
extension PerformanceOptimizations on Widget {
  /// Wrap widget with RepaintBoundary for better performance
  Widget withRepaintBoundary({Key? key}) {
    return RepaintBoundary(key: key, child: this);
  }

  /// Add automatic keep alive for expensive widgets
  Widget withKeepAlive() {
    return _KeepAliveWrapper(child: this);
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  
  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
