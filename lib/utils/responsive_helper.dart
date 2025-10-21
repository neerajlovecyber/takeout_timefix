import 'package:flutter/material.dart';
import 'app_constants.dart';

class ResponsiveHelper {
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > AppConstants.mobileBreakpoint;
  }

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width <= AppConstants.mobileBreakpoint;
  }

  static double getContentPadding(BuildContext context) {
    return isDesktop(context) ? AppConstants.extraLargeSpacing : AppConstants.defaultPadding;
  }

  static double getCardPadding(BuildContext context) {
    return isDesktop(context) ? AppConstants.cardPadding : AppConstants.mediumSpacing;
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    final padding = getContentPadding(context);
    return EdgeInsets.all(padding);
  }

  static BoxConstraints getContentConstraints(BuildContext context) {
    return BoxConstraints(
      maxWidth: isDesktop(context) ? AppConstants.desktopMaxWidth : double.infinity,
    );
  }

  static double getAppBarHeight(BuildContext context) {
    return isDesktop(context) ? 200.0 : 160.0;
  }

  static TextStyle? getHeadlineStyle(BuildContext context) {
    return isDesktop(context)
        ? Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700);
  }

  static double getIconSize(BuildContext context) {
    return isDesktop(context) ? 32.0 : 28.0;
  }

  static double getButtonHeight(BuildContext context) {
    return isDesktop(context) ? 56.0 : 48.0;
  }
}

class AdaptiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? desktop;
  final double breakpoint;

  const AdaptiveLayout({
    super.key,
    required this.mobile,
    this.desktop,
    this.breakpoint = AppConstants.mobileBreakpoint,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > breakpoint && desktop != null) {
          return desktop!;
        }
        return mobile;
      },
    );
  }
}