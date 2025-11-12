import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/modern_design_system.dart';
import '../animations/enhanced_animations.dart';

class ModernBottomNavigation extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ModernBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? ModernDesignSystem.darkSurface : ModernDesignSystem.lightSurface,
        boxShadow: ModernDesignSystem.mediumShadow,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(ModernDesignSystem.radiusXL),
          topRight: Radius.circular(ModernDesignSystem.radiusXL),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ModernDesignSystem.spacingM,
            vertical: ModernDesignSystem.spacingS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home,
                activeIcon: Icons.home_filled,
                label: 'Home',
                index: 0,
                isDark: isDark,
              ),
              _buildNavItem(
                context,
                icon: Icons.explore,
                activeIcon: Icons.explore,
                label: 'Discover',
                index: 1,
                isDark: isDark,
              ),
              _buildNavItem(
                context,
                icon: Icons.search,
                activeIcon: Icons.search,
                label: 'Search',
                index: 2,
                isDark: isDark,
              ),
              _buildNavItem(
                context,
                icon: Icons.person,
                activeIcon: Icons.person,
                label: 'Profile',
                index: 3,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isDark,
  }) {
    final isSelected = currentIndex == index;
    
    Widget navItem = GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ModernDesignSystem.spacingM,
          vertical: ModernDesignSystem.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? ModernDesignSystem.primaryGreen.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: ModernDesignSystem.animationFast,
              padding: const EdgeInsets.all(ModernDesignSystem.spacingXS),
              decoration: BoxDecoration(
                color: isSelected 
                    ? ModernDesignSystem.primaryGreen
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                size: ModernDesignSystem.iconM,
                color: isSelected 
                    ? Colors.white
                    : isDark 
                        ? ModernDesignSystem.textOnDark.withValues(alpha: 0.6)
                        : ModernDesignSystem.textSecondary,
              ),
            ),
            SizedBox(height: ModernDesignSystem.spacingXS),
            AnimatedDefaultTextStyle(
              duration: ModernDesignSystem.animationFast,
              style: TextStyle(
                fontSize: ModernDesignSystem.fontSizeXS,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected 
                    ? ModernDesignSystem.primaryGreen
                    : isDark 
                        ? ModernDesignSystem.textOnDark.withValues(alpha: 0.6)
                        : ModernDesignSystem.textSecondary,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );

    if (isSelected) {
      navItem = EnhancedAnimations.scaleIn(
        duration: ModernDesignSystem.animationFast,
        child: navItem,
      );
    }

    return navItem;
  }
}

// Alternative Floating Bottom Navigation
class FloatingBottomNavigation extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(ModernDesignSystem.spacingM),
      decoration: BoxDecoration(
        gradient: ModernDesignSystem.primaryGradient,
        borderRadius: BorderRadius.circular(ModernDesignSystem.radiusXXL),
        boxShadow: [
          BoxShadow(
            color: ModernDesignSystem.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ModernDesignSystem.spacingM,
          vertical: ModernDesignSystem.spacingS,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildFloatingNavItem(
              context,
              icon: Icons.home,
              activeIcon: Icons.home_filled,
              label: 'Home',
              index: 0,
            ),
            _buildFloatingNavItem(
              context,
              icon: Icons.explore,
              activeIcon: Icons.explore,
              label: 'Discover',
              index: 1,
            ),
            _buildFloatingNavItem(
              context,
              icon: Icons.search,
              activeIcon: Icons.search,
              label: 'Search',
              index: 2,
            ),
            _buildFloatingNavItem(
              context,
              icon: Icons.person,
              activeIcon: Icons.person,
              label: 'Profile',
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = currentIndex == index;
    
    Widget navItem = GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ModernDesignSystem.spacingM,
          vertical: ModernDesignSystem.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: ModernDesignSystem.iconM,
              color: Colors.white,
            ),
            SizedBox(height: ModernDesignSystem.spacingXS),
            Text(
              label,
              style: TextStyle(
                fontSize: ModernDesignSystem.fontSizeXS,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );

    if (isSelected) {
      navItem = EnhancedAnimations.scaleIn(
        duration: ModernDesignSystem.animationFast,
        child: navItem,
      );
    }

    return navItem;
  }
}

// Modern Tab Bar
class ModernTabBar extends ConsumerWidget {
  final List<String> tabs;
  final int currentIndex;
  final Function(int) onTap;
  final bool isScrollable;

  const ModernTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    this.isScrollable = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? ModernDesignSystem.darkSurface : ModernDesignSystem.lightSurface,
        borderRadius: BorderRadius.circular(ModernDesignSystem.radiusL),
        border: Border.all(
          color: isDark ? ModernDesignSystem.darkBorder : ModernDesignSystem.lightBorder,
        ),
      ),
      child: isScrollable
          ? ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: ModernDesignSystem.spacingS),
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                return _buildTabItem(context, index, isDark);
              },
            )
          : Row(
              children: tabs.asMap().entries.map((entry) {
                return Expanded(
                  child: _buildTabItem(context, entry.key, isDark),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildTabItem(BuildContext context, int index, bool isDark) {
    final isSelected = currentIndex == index;
    
    Widget tabItem = GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: ModernDesignSystem.spacingXS),
        padding: const EdgeInsets.symmetric(
          horizontal: ModernDesignSystem.spacingM,
          vertical: ModernDesignSystem.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? ModernDesignSystem.primaryGreen
              : Colors.transparent,
          borderRadius: BorderRadius.circular(ModernDesignSystem.radiusM),
        ),
        child: Center(
          child: Text(
            tabs[index],
            style: TextStyle(
              fontSize: ModernDesignSystem.fontSizeS,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected 
                  ? Colors.white
                  : isDark 
                      ? ModernDesignSystem.textOnDark
                      : ModernDesignSystem.textPrimary,
            ),
          ),
        ),
      ),
    );

    if (isSelected) {
      tabItem = EnhancedAnimations.scaleIn(
        duration: ModernDesignSystem.animationFast,
        child: tabItem,
      );
    }

    return tabItem;
  }
}
