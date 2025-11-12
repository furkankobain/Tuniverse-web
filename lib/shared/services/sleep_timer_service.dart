import 'dart:async';
import 'package:flutter/foundation.dart';

/// Sleep timer service for stopping playback after a specified duration
class SleepTimerService {
  static Timer? _timer;
  static final ValueNotifier<Duration?> remainingTimeNotifier = ValueNotifier<Duration?>(null);
  static final ValueNotifier<bool> isActiveNotifier = ValueNotifier<bool>(false);
  static DateTime? _endTime;
  
  /// Start sleep timer
  static void startTimer(Duration duration, {VoidCallback? onComplete}) {
    cancelTimer();
    
    _endTime = DateTime.now().add(duration);
    isActiveNotifier.value = true;
    remainingTimeNotifier.value = duration;
    
    // Update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_endTime == null) {
        timer.cancel();
        return;
      }
      
      final remaining = _endTime!.difference(DateTime.now());
      
      if (remaining.isNegative || remaining.inSeconds <= 0) {
        timer.cancel();
        isActiveNotifier.value = false;
        remainingTimeNotifier.value = null;
        _endTime = null;
        onComplete?.call();
      } else {
        remainingTimeNotifier.value = remaining;
      }
    });
  }
  
  /// Cancel sleep timer
  static void cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _endTime = null;
    isActiveNotifier.value = false;
    remainingTimeNotifier.value = null;
  }
  
  /// Add time to current timer
  static void addTime(Duration duration) {
    if (_endTime != null) {
      _endTime = _endTime!.add(duration);
    }
  }
  
  /// Get remaining time
  static Duration? get remainingTime => remainingTimeNotifier.value;
  
  /// Check if timer is active
  static bool get isActive => isActiveNotifier.value;
  
  /// Quick timer presets in minutes
  static const List<int> presets = [5, 15, 30, 45, 60, 90, 120];
}
