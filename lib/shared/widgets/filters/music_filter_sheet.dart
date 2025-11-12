import 'package:flutter/material.dart';
import '../../../core/theme/modern_design_system.dart';

enum SortOption {
  newest,
  popular,
  highestRated,
  alphabetical,
}

class FilterOptions {
  List<String> selectedGenres;
  int? minYear;
  int? maxYear;
  double? minPopularity;
  double? minRating;
  SortOption sortBy;

  FilterOptions({
    this.selectedGenres = const [],
    this.minYear,
    this.maxYear,
    this.minPopularity,
    this.minRating,
    this.sortBy = SortOption.newest,
  });

  FilterOptions copyWith({
    List<String>? selectedGenres,
    int? minYear,
    int? maxYear,
    double? minPopularity,
    double? minRating,
    SortOption? sortBy,
  }) {
    return FilterOptions(
      selectedGenres: selectedGenres ?? this.selectedGenres,
      minYear: minYear ?? this.minYear,
      maxYear: maxYear ?? this.maxYear,
      minPopularity: minPopularity ?? this.minPopularity,
      minRating: minRating ?? this.minRating,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get hasActiveFilters {
    return selectedGenres.isNotEmpty ||
        minYear != null ||
        maxYear != null ||
        minPopularity != null ||
        minRating != null;
  }

  void clear() {
    selectedGenres = [];
    minYear = null;
    maxYear = null;
    minPopularity = null;
    minRating = null;
    sortBy = SortOption.newest;
  }
}

class MusicFilterSheet extends StatefulWidget {
  final FilterOptions initialFilters;
  final Function(FilterOptions) onApply;

  const MusicFilterSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<MusicFilterSheet> createState() => _MusicFilterSheetState();
}

class _MusicFilterSheetState extends State<MusicFilterSheet> {
  late FilterOptions _filters;
  final List<String> _availableGenres = [
    'Pop',
    'Rock',
    'Hip Hop',
    'R&B',
    'Electronic',
    'Jazz',
    'Classical',
    'Country',
    'Metal',
    'Indie',
    'Alternative',
    'Latin',
  ];

  @override
  void initState() {
    super.initState();
    _filters = FilterOptions(
      selectedGenres: List.from(widget.initialFilters.selectedGenres),
      minYear: widget.initialFilters.minYear,
      maxYear: widget.initialFilters.maxYear,
      minPopularity: widget.initialFilters.minPopularity,
      minRating: widget.initialFilters.minRating,
      sortBy: widget.initialFilters.sortBy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? ModernDesignSystem.darkBackground
            : ModernDesignSystem.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Filtrele & Sırala',
                    style: TextStyle(
                      fontSize: ModernDesignSystem.fontSizeXL,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                if (_filters.hasActiveFilters)
                  TextButton(
                    onPressed: () {
                      setState(() => _filters.clear());
                    },
                    child: const Text('Temizle'),
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort Options
                  _buildSectionTitle('Sırala', isDark),
                  const SizedBox(height: 12),
                  _buildSortOptions(isDark),
                  const SizedBox(height: 24),

                  // Genres
                  _buildSectionTitle('Türler', isDark),
                  const SizedBox(height: 12),
                  _buildGenreChips(isDark),
                  const SizedBox(height: 24),

                  // Year Range
                  _buildSectionTitle('Yıl Aralığı', isDark),
                  const SizedBox(height: 12),
                  _buildYearRange(isDark),
                  const SizedBox(height: 24),

                  // Popularity
                  _buildSectionTitle('Minimum Popülerlik', isDark),
                  const SizedBox(height: 12),
                  _buildPopularitySlider(isDark),
                  const SizedBox(height: 24),

                  // Rating
                  _buildSectionTitle('Minimum Puan', isDark),
                  const SizedBox(height: 12),
                  _buildRatingSlider(isDark),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Apply Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? ModernDesignSystem.darkCard
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_filters);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ModernDesignSystem.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
                    ),
                  ),
                  child: const Text(
                    'Uygula',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ModernDesignSystem.fontSizeL,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: ModernDesignSystem.fontSizeL,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildSortOptions(bool isDark) {
    return Column(
      children: [
        _buildSortOption('En Yeni', SortOption.newest, Icons.access_time, isDark),
        _buildSortOption('En Popüler', SortOption.popular, Icons.trending_up, isDark),
        _buildSortOption('En Yüksek Puan', SortOption.highestRated, Icons.star, isDark),
        _buildSortOption('Alfabetik', SortOption.alphabetical, Icons.sort_by_alpha, isDark),
      ],
    );
  }

  Widget _buildSortOption(String title, SortOption option, IconData icon, bool isDark) {
    final isSelected = _filters.sortBy == option;

    return GestureDetector(
      onTap: () => setState(() => _filters.sortBy = option),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? ModernDesignSystem.primaryGreen.withValues(alpha: 0.1)
              : (isDark ? ModernDesignSystem.darkCard : Colors.grey.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
          border: Border.all(
            color: isSelected
                ? ModernDesignSystem.primaryGreen
                : (isDark ? ModernDesignSystem.darkBorder : ModernDesignSystem.lightBorder),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? ModernDesignSystem.primaryGreen
                  : (isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: ModernDesignSystem.fontSizeM,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? ModernDesignSystem.primaryGreen
                      : (isDark ? Colors.white : Colors.black),
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: ModernDesignSystem.primaryGreen,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreChips(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableGenres.map((genre) {
        final isSelected = _filters.selectedGenres.contains(genre);

        return FilterChip(
          label: Text(genre),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _filters.selectedGenres.add(genre);
              } else {
                _filters.selectedGenres.remove(genre);
              }
            });
          },
          backgroundColor: isDark ? ModernDesignSystem.darkCard : Colors.grey.withValues(alpha: 0.1),
          selectedColor: ModernDesignSystem.primaryGreen.withValues(alpha: 0.2),
          checkmarkColor: ModernDesignSystem.primaryGreen,
          labelStyle: TextStyle(
            color: isSelected
                ? ModernDesignSystem.primaryGreen
                : (isDark ? Colors.white : Colors.black),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected
                ? ModernDesignSystem.primaryGreen
                : (isDark ? ModernDesignSystem.darkBorder : ModernDesignSystem.lightBorder),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildYearRange(bool isDark) {
    final currentYear = DateTime.now().year;

    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Min',
              hintText: '1950',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _filters.minYear = int.tryParse(value);
              });
            },
            controller: TextEditingController(
              text: _filters.minYear?.toString() ?? '',
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Max',
              hintText: currentYear.toString(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _filters.maxYear = int.tryParse(value);
              });
            },
            controller: TextEditingController(
              text: _filters.maxYear?.toString() ?? '',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPopularitySlider(bool isDark) {
    return Column(
      children: [
        Slider(
          value: _filters.minPopularity ?? 0,
          min: 0,
          max: 100,
          divisions: 20,
          activeColor: ModernDesignSystem.primaryGreen,
          label: _filters.minPopularity?.round().toString() ?? '0',
          onChanged: (value) {
            setState(() => _filters.minPopularity = value);
          },
        ),
        Text(
          'Minimum: ${_filters.minPopularity?.round() ?? 0}/100',
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSlider(bool isDark) {
    return Column(
      children: [
        Slider(
          value: _filters.minRating ?? 0,
          min: 0,
          max: 5,
          divisions: 10,
          activeColor: ModernDesignSystem.accentYellow,
          label: _filters.minRating?.toStringAsFixed(1) ?? '0.0',
          onChanged: (value) {
            setState(() => _filters.minRating = value);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Minimum: ${_filters.minRating?.toStringAsFixed(1) ?? '0.0'}',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 8),
            ...List.generate(
              5,
              (index) => Icon(
                index < (_filters.minRating?.round() ?? 0) ? Icons.star : Icons.star_border,
                color: ModernDesignSystem.accentYellow,
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
