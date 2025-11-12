import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Offline download service for tracks
class OfflineService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Download status notifier
  static final ValueNotifier<Map<String, DownloadStatus>> downloadStatus = 
      ValueNotifier<Map<String, DownloadStatus>>({});
  
  // Storage info
  static final ValueNotifier<StorageInfo> storageInfo = 
      ValueNotifier<StorageInfo>(StorageInfo(used: 0, available: 0, total: 0));

  // ==================== DOWNLOAD TRACKS ====================

  /// Download track for offline playback
  static Future<bool> downloadTrack({
    required String trackId,
    required String trackName,
    required String artistName,
    required String previewUrl,
    required String albumCover,
    required String userId,
  }) async {
    try {
      // Check if already downloaded
      if (await isTrackDownloaded(trackId)) {
        return true;
      }

      // Update status to downloading
      _updateDownloadStatus(trackId, DownloadStatus(
        trackId: trackId,
        status: DownloadState.downloading,
        progress: 0.0,
      ));

      // Get app directory
      final directory = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${directory.path}/offline_tracks');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Download audio file
      final audioPath = '${downloadsDir.path}/$trackId.mp3';
      final audioResponse = await http.get(Uri.parse(previewUrl));
      
      if (audioResponse.statusCode == 200) {
        final audioFile = File(audioPath);
        await audioFile.writeAsBytes(audioResponse.bodyBytes);

        // Update progress
        _updateDownloadStatus(trackId, DownloadStatus(
          trackId: trackId,
          status: DownloadState.downloading,
          progress: 0.5,
        ));

        // Download album cover
        final coverPath = '${downloadsDir.path}/${trackId}_cover.jpg';
        final coverResponse = await http.get(Uri.parse(albumCover));
        
        if (coverResponse.statusCode == 200) {
          final coverFile = File(coverPath);
          await coverFile.writeAsBytes(coverResponse.bodyBytes);
        }

        // Save metadata to Firestore
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('offline_tracks')
            .doc(trackId)
            .set({
          'trackId': trackId,
          'trackName': trackName,
          'artistName': artistName,
          'audioPath': audioPath,
          'coverPath': coverPath,
          'downloadedAt': FieldValue.serverTimestamp(),
          'fileSize': audioResponse.bodyBytes.length,
        });

        // Update local storage
        await _saveToLocalStorage(trackId, {
          'trackId': trackId,
          'trackName': trackName,
          'artistName': artistName,
          'audioPath': audioPath,
          'coverPath': coverPath,
          'fileSize': audioResponse.bodyBytes.length,
        });

        // Update status to completed
        _updateDownloadStatus(trackId, DownloadStatus(
          trackId: trackId,
          status: DownloadState.completed,
          progress: 1.0,
        ));

        // Update storage info
        await _updateStorageInfo();

        return true;
      }

      throw Exception('Failed to download track');
    } catch (e) {
      print('Error downloading track: $e');
      
      // Update status to failed
      _updateDownloadStatus(trackId, DownloadStatus(
        trackId: trackId,
        status: DownloadState.failed,
        progress: 0.0,
        error: e.toString(),
      ));

      return false;
    }
  }

  /// Download multiple tracks
  static Future<List<String>> downloadTracks(List<Map<String, dynamic>> tracks, String userId) async {
    final successful = <String>[];
    
    for (final track in tracks) {
      final success = await downloadTrack(
        trackId: track['trackId'],
        trackName: track['trackName'],
        artistName: track['artistName'],
        previewUrl: track['previewUrl'],
        albumCover: track['albumCover'],
        userId: userId,
      );
      
      if (success) {
        successful.add(track['trackId']);
      }
    }
    
    return successful;
  }

  /// Check if track is downloaded
  static Future<bool> isTrackDownloaded(String trackId) async {
    final prefs = await SharedPreferences.getInstance();
    final offline = prefs.getString('offline_tracks');
    
    if (offline == null) return false;
    
    final tracks = Map<String, dynamic>.from(jsonDecode(offline));
    return tracks.containsKey(trackId);
  }

  /// Get downloaded track info
  static Future<Map<String, dynamic>?> getDownloadedTrack(String trackId) async {
    final prefs = await SharedPreferences.getInstance();
    final offline = prefs.getString('offline_tracks');
    
    if (offline == null) return null;
    
    final tracks = Map<String, dynamic>.from(jsonDecode(offline));
    return tracks[trackId];
  }

  /// Get all downloaded tracks
  static Future<List<Map<String, dynamic>>> getDownloadedTracks() async {
    final prefs = await SharedPreferences.getInstance();
    final offline = prefs.getString('offline_tracks');
    
    if (offline == null) return [];
    
    final tracks = Map<String, dynamic>.from(jsonDecode(offline));
    return tracks.values.map((t) => Map<String, dynamic>.from(t)).toList();
  }

  // ==================== DELETE TRACKS ====================

  /// Delete downloaded track
  static Future<bool> deleteTrack(String trackId, String userId) async {
    try {
      final trackInfo = await getDownloadedTrack(trackId);
      if (trackInfo == null) return false;

      // Delete audio file
      final audioFile = File(trackInfo['audioPath']);
      if (await audioFile.exists()) {
        await audioFile.delete();
      }

      // Delete cover file
      final coverFile = File(trackInfo['coverPath']);
      if (await coverFile.exists()) {
        await coverFile.delete();
      }

      // Remove from Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('offline_tracks')
          .doc(trackId)
          .delete();

      // Remove from local storage
      await _removeFromLocalStorage(trackId);

      // Update storage info
      await _updateStorageInfo();

      return true;
    } catch (e) {
      print('Error deleting track: $e');
      return false;
    }
  }

  /// Delete all downloaded tracks
  static Future<bool> deleteAllTracks(String userId) async {
    try {
      final tracks = await getDownloadedTracks();
      
      for (final track in tracks) {
        await deleteTrack(track['trackId'], userId);
      }

      return true;
    } catch (e) {
      print('Error deleting all tracks: $e');
      return false;
    }
  }

  // ==================== OFFLINE QUEUE ====================

  /// Create offline queue from downloaded tracks
  static Future<List<Map<String, dynamic>>> getOfflineQueue() async {
    return await getDownloadedTracks();
  }

  /// Check if queue can play offline
  static Future<bool> canPlayOffline(List<String> trackIds) async {
    for (final trackId in trackIds) {
      if (!await isTrackDownloaded(trackId)) {
        return false;
      }
    }
    return true;
  }

  // ==================== SMART DOWNLOAD ====================

  /// Auto-download based on user preferences
  static Future<void> smartDownload(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final smartDownloadEnabled = prefs.getBool('smart_download_enabled') ?? false;
      
      if (!smartDownloadEnabled) return;

      // Get user's top tracks
      final topTracksSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('top_tracks')
          .limit(20)
          .get();

      final tracks = topTracksSnapshot.docs.map((doc) => doc.data()).toList();

      // Download tracks that aren't already downloaded
      for (final track in tracks) {
        if (!await isTrackDownloaded(track['trackId'])) {
          await downloadTrack(
            trackId: track['trackId'],
            trackName: track['trackName'],
            artistName: track['artistName'],
            previewUrl: track['previewUrl'],
            albumCover: track['albumCover'],
            userId: userId,
          );
        }
      }
    } catch (e) {
      print('Error in smart download: $e');
    }
  }

  /// Enable/disable smart download
  static Future<void> setSmartDownload(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('smart_download_enabled', enabled);
  }

  /// Get smart download status
  static Future<bool> getSmartDownloadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('smart_download_enabled') ?? false;
  }

  // ==================== STORAGE MANAGEMENT ====================

  /// Get storage info
  static Future<StorageInfo> getStorageInfo() async {
    final directory = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${directory.path}/offline_tracks');
    
    if (!await downloadsDir.exists()) {
      return StorageInfo(used: 0, available: 0, total: 0);
    }

    int totalSize = 0;
    await for (final file in downloadsDir.list(recursive: true)) {
      if (file is File) {
        totalSize += await file.length();
      }
    }

    // Get available space (simplified - actual implementation would check disk space)
    const totalSpace = 10 * 1024 * 1024 * 1024; // 10 GB
    final availableSpace = totalSpace - totalSize;

    return StorageInfo(
      used: totalSize,
      available: availableSpace,
      total: totalSpace,
    );
  }

  /// Update storage info notifier
  static Future<void> _updateStorageInfo() async {
    final info = await getStorageInfo();
    storageInfo.value = info;
  }

  /// Clear cache
  static Future<bool> clearCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/cache');
      
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }

      return true;
    } catch (e) {
      print('Error clearing cache: $e');
      return false;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Save track to local storage
  static Future<void> _saveToLocalStorage(String trackId, Map<String, dynamic> trackData) async {
    final prefs = await SharedPreferences.getInstance();
    final offline = prefs.getString('offline_tracks');
    
    final tracks = offline != null 
        ? Map<String, dynamic>.from(jsonDecode(offline))
        : <String, dynamic>{};
    
    tracks[trackId] = trackData;
    await prefs.setString('offline_tracks', jsonEncode(tracks));
  }

  /// Remove track from local storage
  static Future<void> _removeFromLocalStorage(String trackId) async {
    final prefs = await SharedPreferences.getInstance();
    final offline = prefs.getString('offline_tracks');
    
    if (offline == null) return;
    
    final tracks = Map<String, dynamic>.from(jsonDecode(offline));
    tracks.remove(trackId);
    await prefs.setString('offline_tracks', jsonEncode(tracks));
  }

  /// Update download status
  static void _updateDownloadStatus(String trackId, DownloadStatus status) {
    final current = Map<String, DownloadStatus>.from(downloadStatus.value);
    current[trackId] = status;
    downloadStatus.value = current;
  }
}

// ==================== MODELS ====================

/// Download state enum
enum DownloadState {
  idle,
  downloading,
  completed,
  failed,
}

/// Download status model
class DownloadStatus {
  final String trackId;
  final DownloadState status;
  final double progress;
  final String? error;

  DownloadStatus({
    required this.trackId,
    required this.status,
    required this.progress,
    this.error,
  });
}

/// Storage info model
class StorageInfo {
  final int used;
  final int available;
  final int total;

  StorageInfo({
    required this.used,
    required this.available,
    required this.total,
  });

  double get usedPercentage => total > 0 ? (used / total) * 100 : 0;
  
  String get usedFormatted => _formatBytes(used);
  String get availableFormatted => _formatBytes(available);
  String get totalFormatted => _formatBytes(total);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
