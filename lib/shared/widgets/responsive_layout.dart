import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (Responsive.isDesktop(context)) {
          return desktop ?? tablet ?? mobile;
        } else if (Responsive.isTablet(context)) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

class DesktopScaffold extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final Function(int) onNavigationChanged;

  const DesktopScaffold({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onNavigationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // Logo
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Image.asset('assets/images/logos/logo.png', height: 40),
                      const SizedBox(width: 12),
                      const Text(
                        'Tuniverse',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                
                // Navigation items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildNavItem(
                        context,
                        icon: Icons.home,
                        label: 'Home',
                        index: 0,
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.search,
                        label: 'Search',
                        index: 1,
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.explore,
                        label: 'Discover',
                        index: 2,
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.music_note,
                        label: 'My Music',
                        index: 3,
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.person,
                        label: 'Profile',
                        index: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.background,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.getMaxWidth(context),
                  ),
                  child: body,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor:
          Theme.of(context).colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () => onNavigationChanged(index),
    );
  }
}
