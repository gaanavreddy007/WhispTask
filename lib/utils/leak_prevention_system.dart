// ignore_for_file: avoid_print, unnecessary_brace_in_string_interps

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sentry_service.dart';

/// Comprehensive leak prevention and resource management system
class LeakPreventionSystem {
  static const String _tag = 'LeakPreventionSystem';
  
  // Track all active resources
  static final Set<String> _activeResources = <String>{};
  static final Map<String, Timer> _activeTimers = <String, Timer>{};
  static final Map<String, StreamSubscription> _activeSubscriptions = <String, StreamSubscription>{};
  static final Map<String, AnimationController> _activeAnimations = <String, AnimationController>{};
  
  /// Register a resource to track for leaks
  static void registerResource(String resourceId, String resourceType) {
    try {
      _activeResources.add('${resourceType}_$resourceId');
      SentryService.logUIEvent('resource_registered', data: {
        'resource_id': resourceId,
        'resource_type': resourceType,
        'total_active': '${_activeResources.length}',
      });
    } catch (e) {
      print('$_tag: Error registering resource: $e');
    }
  }
  
  /// Unregister a resource
  static void unregisterResource(String resourceId, String resourceType) {
    try {
      final removed = _activeResources.remove('${resourceType}_$resourceId');
      if (removed) {
        SentryService.logUIEvent('resource_unregistered', data: {
          'resource_id': resourceId,
          'resource_type': resourceType,
          'total_active': '${_activeResources.length}',
        });
      }
    } catch (e) {
      print('$_tag: Error unregistering resource: $e');
    }
  }
  
  /// Register and track a timer
  static void registerTimer(String timerId, Timer timer) {
    try {
      // Cancel existing timer if exists
      _activeTimers[timerId]?.cancel();
      
      _activeTimers[timerId] = timer;
      registerResource(timerId, 'timer');
      
      SentryService.logUIEvent('timer_registered', data: {
        'timer_id': timerId,
        'total_timers': '${_activeTimers.length}',
      });
    } catch (e) {
      print('$_tag: Error registering timer: $e');
    }
  }
  
  /// Cancel and unregister a timer
  static void cancelTimer(String timerId) {
    try {
      final timer = _activeTimers.remove(timerId);
      if (timer != null) {
        timer.cancel();
        unregisterResource(timerId, 'timer');
        
        SentryService.logUIEvent('timer_cancelled', data: {
          'timer_id': timerId,
          'total_timers': '${_activeTimers.length}',
        });
      }
    } catch (e) {
      print('$_tag: Error cancelling timer: $e');
    }
  }
  
  /// Register and track a stream subscription
  static void registerSubscription(String subscriptionId, StreamSubscription subscription) {
    try {
      // Cancel existing subscription if exists
      _activeSubscriptions[subscriptionId]?.cancel();
      
      _activeSubscriptions[subscriptionId] = subscription;
      registerResource(subscriptionId, 'subscription');
      
      SentryService.logUIEvent('subscription_registered', data: {
        'subscription_id': subscriptionId,
        'total_subscriptions': '${_activeSubscriptions.length}',
      });
    } catch (e) {
      print('$_tag: Error registering subscription: $e');
    }
  }
  
  /// Cancel and unregister a subscription
  static void cancelSubscription(String subscriptionId) {
    try {
      final subscription = _activeSubscriptions.remove(subscriptionId);
      if (subscription != null) {
        subscription.cancel();
        unregisterResource(subscriptionId, 'subscription');
        
        SentryService.logUIEvent('subscription_cancelled', data: {
          'subscription_id': subscriptionId,
          'total_subscriptions': '${_activeSubscriptions.length}',
        });
      }
    } catch (e) {
      print('$_tag: Error cancelling subscription: $e');
    }
  }
  
  /// Register and track an animation controller
  static void registerAnimation(String animationId, AnimationController controller) {
    try {
      // Dispose existing animation if exists
      _activeAnimations[animationId]?.dispose();
      
      _activeAnimations[animationId] = controller;
      registerResource(animationId, 'animation');
      
      SentryService.logUIEvent('animation_registered', data: {
        'animation_id': animationId,
        'total_animations': '${_activeAnimations.length}',
      });
    } catch (e) {
      print('$_tag: Error registering animation: $e');
    }
  }
  
  /// Dispose and unregister an animation controller
  static void disposeAnimation(String animationId) {
    try {
      final controller = _activeAnimations.remove(animationId);
      if (controller != null) {
        controller.dispose();
        unregisterResource(animationId, 'animation');
        
        SentryService.logUIEvent('animation_disposed', data: {
          'animation_id': animationId,
          'total_animations': '${_activeAnimations.length}',
        });
      }
    } catch (e) {
      print('$_tag: Error disposing animation: $e');
    }
  }
  
  /// Perform comprehensive leak check
  static Future<Map<String, dynamic>> performLeakCheck() async {
    try {
      SentryService.logUIEvent('leak_check_start');
      
      final results = <String, dynamic>{
        'total_active_resources': _activeResources.length,
        'active_timers': _activeTimers.length,
        'active_subscriptions': _activeSubscriptions.length,
        'active_animations': _activeAnimations.length,
        'potential_leaks': <String>[],
        'warnings': <String>[],
      };
      
      // Check for potential timer leaks
      if (_activeTimers.length > 10) {
        results['warnings'].add('High number of active timers: ${_activeTimers.length}');
        SentryService.logUIEvent('potential_timer_leak', data: {
          'timer_count': _activeTimers.length.toString(),
        });
      }
      
      // Check for potential subscription leaks
      if (_activeSubscriptions.length > 20) {
        results['warnings'].add('High number of active subscriptions: ${_activeSubscriptions.length}');
        SentryService.logUIEvent('potential_subscription_leak', data: {
          'subscription_count': _activeSubscriptions.length.toString(),
        });
      }
      
      // Check for potential animation leaks
      if (_activeAnimations.length > 15) {
        results['warnings'].add('High number of active animations: ${_activeAnimations.length}');
        SentryService.logUIEvent('potential_animation_leak', data: {
          'animation_count': _activeAnimations.length.toString(),
        });
      }
      
      SentryService.logUIEvent('leak_check_complete', data: results);
      return results;
      
    } catch (e, stackTrace) {
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Error during leak check',
      );
      
      return {
        'error': e.toString(),
        'total_active_resources': _activeResources.length,
      };
    }
  }
  
  /// Emergency cleanup - dispose all tracked resources
  static Future<void> emergencyCleanup() async {
    try {
      SentryService.logUIEvent('emergency_cleanup_start', data: {
        'timers_to_cancel': '${_activeTimers.length}',
        'subscriptions_to_cancel': '${_activeSubscriptions.length}',
        'animations_to_dispose': '${_activeAnimations.length}',
      });
      
      // Cancel all timers
      for (final timer in _activeTimers.values) {
        try {
          timer.cancel();
        } catch (e) {
          print('$_tag: Error cancelling timer during cleanup: $e');
        }
      }
      _activeTimers.clear();
      
      // Cancel all subscriptions
      for (final subscription in _activeSubscriptions.values) {
        try {
          await subscription.cancel();
        } catch (e) {
          print('$_tag: Error cancelling subscription during cleanup: $e');
        }
      }
      _activeSubscriptions.clear();
      
      // Dispose all animations
      for (final controller in _activeAnimations.values) {
        try {
          controller.dispose();
        } catch (e) {
          print('$_tag: Error disposing animation during cleanup: $e');
        }
      }
      _activeAnimations.clear();
      
      // Clear all resources
      _activeResources.clear();
      
      SentryService.logUIEvent('emergency_cleanup_complete');
      
    } catch (e, stackTrace) {
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Error during emergency cleanup',
      );
    }
  }
  
  /// Get resource usage statistics
  static Map<String, dynamic> getResourceStats() {
    return {
      'total_active_resources': _activeResources.length,
      'active_timers': _activeTimers.length,
      'active_subscriptions': _activeSubscriptions.length,
      'active_animations': _activeAnimations.length,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Mixin for automatic resource management in StatefulWidgets
mixin LeakPreventionMixin<T extends StatefulWidget> on State<T> {
  final Set<String> _widgetResources = <String>{};
  
  /// Register a resource for this widget
  void registerWidgetResource(String resourceId, String resourceType) {
    final fullId = '${widget.runtimeType}_${resourceId}';
    _widgetResources.add(fullId);
    LeakPreventionSystem.registerResource(fullId, resourceType);
  }
  
  /// Register a timer for this widget
  void registerWidgetTimer(String timerId, Timer timer) {
    final fullId = '${widget.runtimeType}_${timerId}';
    _widgetResources.add(fullId);
    LeakPreventionSystem.registerTimer(fullId, timer);
  }
  
  /// Register a subscription for this widget
  void registerWidgetSubscription(String subscriptionId, StreamSubscription subscription) {
    final fullId = '${widget.runtimeType}_${subscriptionId}';
    _widgetResources.add(fullId);
    LeakPreventionSystem.registerSubscription(fullId, subscription);
  }
  
  /// Register an animation for this widget
  void registerWidgetAnimation(String animationId, AnimationController controller) {
    final fullId = '${widget.runtimeType}_${animationId}';
    _widgetResources.add(fullId);
    LeakPreventionSystem.registerAnimation(fullId, controller);
  }
  
  @override
  void dispose() {
    // Automatically cleanup all widget resources
    for (final resourceId in _widgetResources) {
      try {
        // Try to cancel/dispose based on resource type
        LeakPreventionSystem.cancelTimer(resourceId);
        LeakPreventionSystem.cancelSubscription(resourceId);
        LeakPreventionSystem.disposeAnimation(resourceId);
        LeakPreventionSystem.unregisterResource(resourceId, 'widget');
      } catch (e) {
        print('LeakPreventionMixin: Error disposing resource $resourceId: $e');
      }
    }
    _widgetResources.clear();
    
    super.dispose();
  }
}

/// Safe wrapper for async operations to prevent leaks
class SafeAsyncOperation<T> {
  final String operationId;
  final Future<T> _future;
  bool _isCompleted = false;
  bool _isCancelled = false;
  
  SafeAsyncOperation(this.operationId, this._future) {
    LeakPreventionSystem.registerResource(operationId, 'async_operation');
  }
  
  /// Execute the async operation safely
  Future<T?> execute() async {
    try {
      if (_isCancelled) return null;
      
      final result = await _future;
      _isCompleted = true;
      
      LeakPreventionSystem.unregisterResource(operationId, 'async_operation');
      return result;
      
    } catch (e, stackTrace) {
      _isCompleted = true;
      LeakPreventionSystem.unregisterResource(operationId, 'async_operation');
      
      SentryService.captureException(
        e,
        stackTrace: stackTrace,
        hint: 'Safe async operation failed',
        extra: {'operation_id': operationId},
      );
      
      rethrow;
    }
  }
  
  /// Cancel the operation
  void cancel() {
    _isCancelled = true;
    if (!_isCompleted) {
      LeakPreventionSystem.unregisterResource(operationId, 'async_operation');
    }
  }
  
  bool get isCompleted => _isCompleted;
  bool get isCancelled => _isCancelled;
}
