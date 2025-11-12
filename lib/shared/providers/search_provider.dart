import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/search_service.dart';

// Search query state
final searchQueryProvider = StateProvider<String>((ref) => '');

// Search results providers
final searchTracksProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) async {
  if (query.isEmpty) return [];
  return await SearchService.searchTracks(query);
});

final searchArtistsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) async {
  if (query.isEmpty) return [];
  return await SearchService.searchArtists(query);
});

final searchAlbumsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) async {
  if (query.isEmpty) return [];
  return await SearchService.searchAlbums(query);
});

// Search suggestions provider
final searchSuggestionsProvider = FutureProvider.family<List<String>, String>((ref, query) async {
  if (query.length < 2) return [];
  return await SearchService.getSearchSuggestions(query);
});

// Trending searches provider
final trendingSearchesProvider = Provider<List<String>>((ref) {
  return SearchService.getTrendingSearches();
});

// Search history provider
final searchHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await SearchService.getSearchHistory();
});

// Search loading state
final searchLoadingProvider = StateProvider<bool>((ref) => false);

// Search error provider
final searchErrorProvider = StateProvider<String?>((ref) => null);

// Search service provider
final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService();
});

// Search filters
final searchFiltersProvider = StateNotifierProvider<SearchFiltersNotifier, SearchFilters>((ref) {
  return SearchFiltersNotifier();
});

class SearchFilters {
  final bool showTracks;
  final bool showArtists;
  final bool showAlbums;
  final int minRating;
  final List<String> selectedTags;

  const SearchFilters({
    this.showTracks = true,
    this.showArtists = true,
    this.showAlbums = true,
    this.minRating = 0,
    this.selectedTags = const [],
  });

  SearchFilters copyWith({
    bool? showTracks,
    bool? showArtists,
    bool? showAlbums,
    int? minRating,
    List<String>? selectedTags,
  }) {
    return SearchFilters(
      showTracks: showTracks ?? this.showTracks,
      showArtists: showArtists ?? this.showArtists,
      showAlbums: showAlbums ?? this.showAlbums,
      minRating: minRating ?? this.minRating,
      selectedTags: selectedTags ?? this.selectedTags,
    );
  }
}

class SearchFiltersNotifier extends StateNotifier<SearchFilters> {
  SearchFiltersNotifier() : super(const SearchFilters());

  void toggleTracks() {
    state = state.copyWith(showTracks: !state.showTracks);
  }

  void toggleArtists() {
    state = state.copyWith(showArtists: !state.showArtists);
  }

  void toggleAlbums() {
    state = state.copyWith(showAlbums: !state.showAlbums);
  }

  void setMinRating(int rating) {
    state = state.copyWith(minRating: rating);
  }

  void addTag(String tag) {
    if (!state.selectedTags.contains(tag)) {
      state = state.copyWith(selectedTags: [...state.selectedTags, tag]);
    }
  }

  void removeTag(String tag) {
    state = state.copyWith(selectedTags: state.selectedTags.where((t) => t != tag).toList());
  }

  void clearFilters() {
    state = const SearchFilters();
  }
}
