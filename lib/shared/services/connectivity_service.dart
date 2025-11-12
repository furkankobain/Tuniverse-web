import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Network connectivity service
/// İnternet bağlantı durumunu izler
class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static final StreamController<bool> _connectionStatusController = 
      StreamController<bool>.broadcast();
  
  static Stream<bool> get connectionStatus => _connectionStatusController.stream;
  static bool _isConnected = true;
  
  /// Service'i başlat
  static Future<void> initialize() async {
    // İlk durumu kontrol et
    final result = await _connectivity.checkConnectivity();
    _isConnected = !result.contains(ConnectivityResult.none);
    
    // Bağlantı değişikliklerini dinle
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isConnected = !results.contains(ConnectivityResult.none);
      
      if (_isConnected != isConnected) {
        _isConnected = isConnected;
        _connectionStatusController.add(_isConnected);
        
        if (kDebugMode) {
          print('📡 Connection status: ${_isConnected ? "Online" : "Offline"}');
        }
      }
    });
    
    if (kDebugMode) {
      print('📡 Connectivity service initialized - Status: ${_isConnected ? "Online" : "Offline"}');
    }
  }
  
  /// Şu anki bağlantı durumunu al
  static bool get isConnected => _isConnected;
  
  /// Bağlantıyı kontrol et
  static Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    _isConnected = !result.contains(ConnectivityResult.none);
    return _isConnected;
  }
  
  /// Bağlantı tipini al
  static Future<String> getConnectionType() async {
    final result = await _connectivity.checkConnectivity();
    
    if (result.contains(ConnectivityResult.wifi)) {
      return 'WiFi';
    } else if (result.contains(ConnectivityResult.mobile)) {
      return 'Mobile Data';
    } else if (result.contains(ConnectivityResult.ethernet)) {
      return 'Ethernet';
    } else {
      return 'Offline';
    }
  }
  
  /// Service'i kapat
  static void dispose() {
    _connectionStatusController.close();
  }
}
