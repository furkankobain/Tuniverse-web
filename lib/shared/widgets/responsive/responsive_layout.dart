import 'package:flutter/material.dart';
import '../../../core/theme/modern_design_system.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? child;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        if (ModernDesignSystem.isDesktop(width) && desktop != null) {
          return desktop!;
        } else if (ModernDesignSystem.isTablet(width) && tablet != null) {
          return tablet!;
        } else {
          return mobile;
        }
      },
    );
  }
}

class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        EdgeInsets padding;
        if (ModernDesignSystem.isDesktop(width)) {
          padding = desktopPadding ?? const EdgeInsets.symmetric(
            horizontal: ModernDesignSystem.spacingXXL,
          );
        } else if (ModernDesignSystem.isTablet(width)) {
          padding = tabletPadding ?? const EdgeInsets.symmetric(
            horizontal: ModernDesignSystem.spacingXL,
          );
        } else {
          padding = mobilePadding ?? const EdgeInsets.symmetric(
            horizontal: ModernDesignSystem.spacingL,
          );
        }
        
        return Padding(
          padding: padding,
          child: child,
        );
      },
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double? spacing;
  final double? runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing,
    this.runSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        int columns;
        if (ModernDesignSystem.isDesktop(width)) {
          columns = desktopColumns ?? 4;
        } else if (ModernDesignSystem.isTablet(width)) {
          columns = tabletColumns ?? 3;
        } else {
          columns = mobileColumns ?? 2;
        }
        
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: spacing ?? ModernDesignSystem.spacingM,
          mainAxisSpacing: runSpacing ?? ModernDesignSystem.spacingM,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }
}

class ResponsiveWrap extends StatelessWidget {
  final List<Widget> children;
  final double? mobileSpacing;
  final double? tabletSpacing;
  final double? desktopSpacing;
  final double? runSpacing;

  const ResponsiveWrap({
    super.key,
    required this.children,
    this.mobileSpacing,
    this.tabletSpacing,
    this.desktopSpacing,
    this.runSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        double spacing;
        if (ModernDesignSystem.isDesktop(width)) {
          spacing = desktopSpacing ?? ModernDesignSystem.spacingL;
        } else if (ModernDesignSystem.isTablet(width)) {
          spacing = tabletSpacing ?? ModernDesignSystem.spacingM;
        } else {
          spacing = mobileSpacing ?? ModernDesignSystem.spacingS;
        }
        
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing ?? spacing,
          children: children,
        );
      },
    );
  }
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? mobileMaxWidth;
  final double? tabletMaxWidth;
  final double? desktopMaxWidth;
  final EdgeInsets? padding;
  final AlignmentGeometry? alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.mobileMaxWidth,
    this.tabletMaxWidth,
    this.desktopMaxWidth,
    this.padding,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        double? maxWidth;
        if (ModernDesignSystem.isDesktop(width)) {
          maxWidth = desktopMaxWidth ?? 1200;
        } else if (ModernDesignSystem.isTablet(width)) {
          maxWidth = tabletMaxWidth ?? 800;
        } else {
          maxWidth = mobileMaxWidth ?? double.infinity;
        }
        
        return Container(
          width: double.infinity,
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: padding,
          alignment: alignment,
          child: child,
        );
      },
    );
  }
}

class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? mobileStyle;
  final TextStyle? tabletStyle;
  final TextStyle? desktopStyle;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.mobileStyle,
    this.tabletStyle,
    this.desktopStyle,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        TextStyle? style;
        if (ModernDesignSystem.isDesktop(width) && desktopStyle != null) {
          style = desktopStyle;
        } else if (ModernDesignSystem.isTablet(width) && tabletStyle != null) {
          style = tabletStyle;
        } else {
          style = mobileStyle;
        }
        
        return Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

class ResponsiveIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double? mobileSize;
  final double? tabletSize;
  final double? desktopSize;

  const ResponsiveIcon(
    this.icon, {
    super.key,
    this.color,
    this.mobileSize,
    this.tabletSize,
    this.desktopSize,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        double size;
        if (ModernDesignSystem.isDesktop(width)) {
          size = desktopSize ?? ModernDesignSystem.iconL;
        } else if (ModernDesignSystem.isTablet(width)) {
          size = tabletSize ?? ModernDesignSystem.iconM;
        } else {
          size = mobileSize ?? ModernDesignSystem.iconS;
        }
        
        return Icon(
          icon,
          size: size,
          color: color,
        );
      },
    );
  }
}

class ResponsiveSpacing extends StatelessWidget {
  final Widget child;
  final double? mobileSpacing;
  final double? tabletSpacing;
  final double? desktopSpacing;
  final Axis direction;

  const ResponsiveSpacing({
    super.key,
    required this.child,
    this.mobileSpacing,
    this.tabletSpacing,
    this.desktopSpacing,
    this.direction = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        double spacing;
        if (ModernDesignSystem.isDesktop(width)) {
          spacing = desktopSpacing ?? ModernDesignSystem.spacingXL;
        } else if (ModernDesignSystem.isTablet(width)) {
          spacing = tabletSpacing ?? ModernDesignSystem.spacingL;
        } else {
          spacing = mobileSpacing ?? ModernDesignSystem.spacingM;
        }
        
        return Padding(
          padding: direction == Axis.vertical
              ? EdgeInsets.symmetric(vertical: spacing)
              : EdgeInsets.symmetric(horizontal: spacing),
          child: child,
        );
      },
    );
  }
}
