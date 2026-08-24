import 'package:flutter/material.dart';
import '../extensions/context_extensions.dart';

/// Renders alternative layouts based on Phone (<600dp) vs Tablet POS (>=600dp).
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
    if (context.isDesktop && desktop != null) {
      return desktop!;
    }
    if (context.isWideScreen && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}
