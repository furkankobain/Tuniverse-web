import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/statistics_service.dart';

// User statistics provider
final userStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await StatisticsService.getUserStatistics();
});

// Listening insights provider
final listeningInsightsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await StatisticsService.getListeningInsights();
});

// Statistics loading state
final statisticsLoadingProvider = StateProvider<bool>((ref) => false);

// Statistics error provider
final statisticsErrorProvider = StateProvider<String?>((ref) => null);

// Statistics service provider
final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  return StatisticsService();
});

// Refresh statistics provider
final refreshStatisticsProvider = FutureProvider<void>((ref) async {
  ref.invalidate(userStatisticsProvider);
  ref.invalidate(listeningInsightsProvider);
});
