import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Music queue management service
/// Manages playback queue, play next/later functionality
class QueueService {
  static const String _queueKey = 'music_queue';
  static const String _currentIndexKey = 'queue_current_index';
  static const String _shuffleKey = 'queue_shuffle_enabled';
  static const String _repeatKey = 'queue_repeat_mode';

  static final ValueNotifier<List<Map<String, dynamic>>> queueNotifier = 
      ValueNotifier<List<Map<String, dynamic>>>([]);
  static final ValueNotifier<int> currentIndexNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<bool> shuffleNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<RepeatMode> repeatModeNotifier = 
      ValueNotifier<RepeatMode>(RepeatMode.off);

  static List<Map<String, dynamic>> _originalQueue = [];
  static List<Map<String, dynamic>> _shuffledQueue = [];

  /// Initialize queue service
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load queue
      final queueJson = prefs.getString(_queueKey);
      if (queueJson != null) {
        final List<dynamic> decoded = json.decode(queueJson);
        queueNotifier.value = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        _originalQueue = List.from(queueNotifier.value);
      }

      // Load current index
      currentIndexNotifier.value = prefs.getInt(_currentIndexKey) ?? 0;

      // Load shuffle state
      shuffleNotifier.value = prefs.getBool(_shuffleKey) ?? false;

      // Load repeat mode
      final repeatIndex = prefs.getInt(_repeatKey) ?? 0;
      repeatModeNotifier.value = RepeatMode.values[repeatIndex];

    } catch (e) {
      print('Error initializing queue: $e');
    }
  }

  /// Get current queue
  static List<Map<String, dynamic>> get queue => queueNotifier.value;

  /// Get current track
  static Map<String, dynamic>? get currentTrack {
    if (queue.isEmpty || currentIndexNotifier.value >= queue.length) {
      return null;
    }
    return queue[currentIndexNotifier.value];
  }

  /// Get current index
  static int get currentIndex => currentIndexNotifier.value;

  /// Is shuffle enabled
  static bool get isShuffleEnabled => shuffleNotifier.value;

  /// Get repeat mode
  static RepeatMode get repeatMode => repeatModeNotifier.value;

  /// Set queue with tracks
  static Future<void> setQueue(List<Map<String, dynamic>> tracks, {int startIndex = 0}) async {
    try {
      _originalQueue = List.from(tracks);
      
      if (shuffleNotifier.value) {
        _shuffledQueue = List.from(tracks);
        _shuffledQueue.shuffle();
        queueNotifier.value = _shuffledQueue;
      } else {
        queueNotifier.value = tracks;
      }

      currentIndexNotifier.value = startIndex;
      await _saveQueue();
    } catch (e) {
      print('Error setting queue: $e');
    }
  }

  /// Add track to end of queue
  static Future<void> addToQueue(Map<String, dynamic> track) async {
    try {
      _originalQueue.add(track);
      
      if (shuffleNotifier.value) {
        _shuffledQueue.add(track);
        queueNotifier.value = List.from(_shuffledQueue);
      } else {
        queueNotifier.value = List.from(_originalQueue);
      }
      
      await _saveQueue();
    } catch (e) {
      print('Error adding to queue: $e');
    }
  }

  /// Add tracks to end of queue
  static Future<void> addTracksToQueue(List<Map<String, dynamic>> tracks) async {
    try {
      _originalQueue.addAll(tracks);
      
      if (shuffleNotifier.value) {
        _shuffledQueue.addAll(tracks);
        queueNotifier.value = List.from(_shuffledQueue);
      } else {
        queueNotifier.value = List.from(_originalQueue);
      }
      
      await _saveQueue();
    } catch (e) {
      print('Error adding tracks to queue: $e');
    }
  }

  /// Play track next (after current track)
  static Future<void> playNext(Map<String, dynamic> track) async {
    try {
      final nextIndex = currentIndexNotifier.value + 1;
      
      _originalQueue.insert(nextIndex, track);
      
      if (shuffleNotifier.value) {
        _shuffledQueue.insert(nextIndex, track);
        queueNotifier.value = List.from(_shuffledQueue);
      } else {
        queueNotifier.value = List.from(_originalQueue);
      }
      
      await _saveQueue();
    } catch (e) {
      print('Error playing next: $e');
    }
  }

  /// Remove track from queue
  static Future<void> removeFromQueue(int index) async {
    try {
      if (index < 0 || index >= queue.length) return;

      final currentTrack = queue[currentIndexNotifier.value];
      
      _originalQueue.removeAt(index);
      
      if (shuffleNotifier.value) {
        _shuffledQueue.removeAt(index);
        queueNotifier.value = List.from(_shuffledQueue);
      } else {
        queueNotifier.value = List.from(_originalQueue);
      }

      // Adjust current index if needed
      final newIndex = queue.indexWhere((t) => t['id'] == currentTrack['id']);
      if (newIndex >= 0) {
        currentIndexNotifier.value = newIndex;
      } else if (currentIndexNotifier.value >= queue.length) {
        currentIndexNotifier.value = queue.length - 1;
      }

      await _saveQueue();
    } catch (e) {
      print('Error removing from queue: $e');
    }
  }

  /// Reorder queue
  static Future<void> reorderQueue(int oldIndex, int newIndex) async {
    try {
      if (oldIndex < 0 || oldIndex >= queue.length || 
          newIndex < 0 || newIndex >= queue.length) {
        return;
      }

      final currentTrack = queue[currentIndexNotifier.value];
      final track = _originalQueue.removeAt(oldIndex);
      _originalQueue.insert(newIndex, track);

      if (shuffleNotifier.value) {
        final shuffledTrack = _shuffledQueue.removeAt(oldIndex);
        _shuffledQueue.insert(newIndex, shuffledTrack);
        queueNotifier.value = List.from(_shuffledQueue);
      } else {
        queueNotifier.value = List.from(_originalQueue);
      }

      // Update current index to follow the current track
      final newCurrentIndex = queue.indexWhere((t) => t['id'] == currentTrack['id']);
      if (newCurrentIndex >= 0) {
        currentIndexNotifier.value = newCurrentIndex;
      }

      await _saveQueue();
    } catch (e) {
      print('Error reordering queue: $e');
    }
  }

  /// Skip to next track
  static Future<void> skipToNext() async {
    try {
      if (queue.isEmpty) return;

      if (repeatModeNotifier.value == RepeatMode.one) {
        // Stay on current track
        return;
      }

      int nextIndex = currentIndexNotifier.value + 1;

      if (nextIndex >= queue.length) {
        if (repeatModeNotifier.value == RepeatMode.all) {
          nextIndex = 0;
        } else {
          // End of queue, stay at last track
          nextIndex = queue.length - 1;
        }
      }

      currentIndexNotifier.value = nextIndex;
      await _saveCurrentIndex();
    } catch (e) {
      print('Error skipping to next: $e');
    }
  }

  /// Skip to previous track
  static Future<void> skipToPrevious() async {
    try {
      if (queue.isEmpty) return;

      int prevIndex = currentIndexNotifier.value - 1;

      if (prevIndex < 0) {
        if (repeatModeNotifier.value == RepeatMode.all) {
          prevIndex = queue.length - 1;
        } else {
          prevIndex = 0;
        }
      }

      currentIndexNotifier.value = prevIndex;
      await _saveCurrentIndex();
    } catch (e) {
      print('Error skipping to previous: $e');
    }
  }

  /// Jump to specific index
  static Future<void> jumpToIndex(int index) async {
    try {
      if (index < 0 || index >= queue.length) return;

      currentIndexNotifier.value = index;
      await _saveCurrentIndex();
    } catch (e) {
      print('Error jumping to index: $e');
    }
  }

  /// Toggle shuffle
  static Future<void> toggleShuffle() async {
    try {
      final newShuffleState = !shuffleNotifier.value;
      shuffleNotifier.value = newShuffleState;

      final currentTrack = queue[currentIndexNotifier.value];

      if (newShuffleState) {
        // Enable shuffle
        _shuffledQueue = List.from(_originalQueue);
        _shuffledQueue.shuffle();
        
        // Keep current track at current position
        _shuffledQueue.remove(currentTrack);
        _shuffledQueue.insert(currentIndexNotifier.value, currentTrack);
        
        queueNotifier.value = _shuffledQueue;
      } else {
        // Disable shuffle
        queueNotifier.value = List.from(_originalQueue);
        
        // Update current index to match position in original queue
        final newIndex = _originalQueue.indexWhere((t) => t['id'] == currentTrack['id']);
        if (newIndex >= 0) {
          currentIndexNotifier.value = newIndex;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_shuffleKey, newShuffleState);
      await _saveQueue();
    } catch (e) {
      print('Error toggling shuffle: $e');
    }
  }

  /// Cycle repeat mode
  static Future<void> cycleRepeatMode() async {
    try {
      final currentMode = repeatModeNotifier.value;
      RepeatMode newMode;

      switch (currentMode) {
        case RepeatMode.off:
          newMode = RepeatMode.all;
          break;
        case RepeatMode.all:
          newMode = RepeatMode.one;
          break;
        case RepeatMode.one:
          newMode = RepeatMode.off;
          break;
      }

      repeatModeNotifier.value = newMode;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_repeatKey, newMode.index);
    } catch (e) {
      print('Error cycling repeat mode: $e');
    }
  }

  /// Clear queue
  static Future<void> clearQueue() async {
    try {
      _originalQueue.clear();
      _shuffledQueue.clear();
      queueNotifier.value = [];
      currentIndexNotifier.value = 0;
      
      await _saveQueue();
    } catch (e) {
      print('Error clearing queue: $e');
    }
  }

  /// Save queue to storage
  static Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = json.encode(_originalQueue);
      await prefs.setString(_queueKey, queueJson);
      await _saveCurrentIndex();
    } catch (e) {
      print('Error saving queue: $e');
    }
  }

  /// Save current index
  static Future<void> _saveCurrentIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_currentIndexKey, currentIndexNotifier.value);
    } catch (e) {
      print('Error saving current index: $e');
    }
  }

  /// Has next track
  static bool get hasNext {
    if (queue.isEmpty) return false;
    if (repeatModeNotifier.value != RepeatMode.off) return true;
    return currentIndexNotifier.value < queue.length - 1;
  }

  /// Has previous track
  static bool get hasPrevious {
    if (queue.isEmpty) return false;
    if (repeatModeNotifier.value == RepeatMode.all) return true;
    return currentIndexNotifier.value > 0;
  }
}

/// Repeat mode enum
enum RepeatMode {
  off,   // No repeat
  all,   // Repeat all tracks in queue
  one,   // Repeat current track
}
