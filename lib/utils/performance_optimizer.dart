// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class PerformanceOptimizer {
  static const bool _isDebugMode = kDebugMode;
  
  // Cache for expensive widget builds
  static final Map<String, Widget> _widgetCache = {};
  
  // Cache for computed values
  static final Map<String, dynamic> _computationCache = {};
  
  // Performance monitoring
  static final Map<String, Stopwatch> _timers = {};
  
  /// Cache a widget to avoid rebuilds
  static Widget cacheWidget(String key, Widget Function() builder) {
    if (_widgetCache.containsKey(key)) {
      return _widgetCache[key]!;
    }
    
    final widget = builder();
    _widgetCache[key] = widget;
    return widget;
  }
  
  /// Cache expensive computations
  static T cacheComputation<T>(String key, T Function() computation) {
    if (_computationCache.containsKey(key)) {
      return _computationCache[key] as T;
    }
    
    final result = computation();
    _computationCache[key] = result;
    return result;
  }
  
  /// Clear cache when memory pressure is high
  static void clearCache() {
    _widgetCache.clear();
    _computationCache.clear();
  }
  
  /// Clear specific cache entry
  static void clearCacheEntry(String key) {
    _widgetCache.remove(key);
    _computationCache.remove(key);
  }
  
  /// Start performance timer
  static void startTimer(String operation) {
    if (!_isDebugMode) return;
    _timers[operation] = Stopwatch()..start();
  }
  
  /// Stop performance timer and log result
  static void stopTimer(String operation) {
    if (!_isDebugMode) return;
    final timer = _timers[operation];
    if (timer != null) {
      timer.stop();
      debugPrint('Performance: $operation took ${timer.elapsedMilliseconds}ms');
      _timers.remove(operation);
    }
  }
  
  /// Optimize image loading with caching
  static Widget optimizedImage({
    required String assetPath,
    double? width,
    double? height,
    BoxFit? fit,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.round(),
      cacheHeight: height?.round(),
      errorBuilder: errorBuilder,
      // Enable image caching
      gaplessPlayback: true,
    );
  }
  
  /// Debounce function calls to reduce excessive operations
  static Timer? _debounceTimer;
  static void debounce(Duration delay, VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }
  
  /// Throttle function calls to limit frequency
  static DateTime? _lastThrottleTime;
  static void throttle(Duration interval, VoidCallback callback) {
    final now = DateTime.now();
    if (_lastThrottleTime == null || 
        now.difference(_lastThrottleTime!) >= interval) {
      _lastThrottleTime = now;
      callback();
    }
  }
  
  /// Memory-efficient list builder
  static Widget optimizedListView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    ScrollController? controller,
    EdgeInsets? padding,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      controller: controller,
      padding: padding,
      // Performance optimizations
      cacheExtent: 200.0, // Reduced cache extent
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      addSemanticIndexes: false,
    );
  }
  
  /// Optimized animated builder that reduces rebuilds
  static Widget optimizedAnimatedBuilder({
    required Animation<double> animation,
    required Widget Function(BuildContext, Widget?) builder,
    Widget? child,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: builder,
      child: child,
    );
  }
  
  /// Get memory usage info (debug only)
  static void logMemoryUsage(String context) {
    if (!_isDebugMode) return;
    
    // This is a simplified memory check - in production you'd use more sophisticated tools
    debugPrint('Memory check at $context - Cache entries: ${_widgetCache.length + _computationCache.length}');
  }
  
  /// Cleanup resources
  static void dispose() {
    _debounceTimer?.cancel();
    clearCache();
    _timers.clear();
  }
}

/// Timer class for debouncing
class Timer {
  final Duration _duration;
  final VoidCallback _callback;
  late final Future _future;
  bool _isActive = true;
  
  Timer(this._duration, this._callback) {
    _future = Future.delayed(_duration, () {
      if (_isActive) {
        _callback();
      }
    });
  }
  
  void cancel() {
    _isActive = false;
  }
}

/// Mixin for widgets that need performance optimization
mixin PerformanceOptimizedWidget on StatefulWidget {
  String get cacheKey => runtimeType.toString();
}

/// Optimized StatefulWidget that implements caching
abstract class OptimizedStatefulWidget extends StatefulWidget 
    with PerformanceOptimizedWidget {
  const OptimizedStatefulWidget({super.key});
}

/// Widget that automatically manages repaint boundaries
class RepaintBoundaryWrapper extends StatelessWidget {
  final Widget child;
  final String? debugLabel;
  
  const RepaintBoundaryWrapper({
    super.key,
    required this.child,
    this.debugLabel,
  });
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: child,
    );
  }
}
