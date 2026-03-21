import 'dart:math' as math;

import 'package:flutter/material.dart';

enum DeviceClass { mobilePortrait, mobileLandscape, tablet, tvCompact, tvLarge }

class DeviceLayout {
  const DeviceLayout._({
    required this.deviceClass,
    required this.width,
    required this.height,
    required this.directionalNavigation,
  });

  factory DeviceLayout.of(BuildContext context, {BoxConstraints? constraints}) {
    final mediaQuery = MediaQuery.of(context);
    final navigationMode = MediaQuery.navigationModeOf(context);
    final resolvedWidth = constraints?.maxWidth ?? mediaQuery.size.width;
    final resolvedHeight = constraints?.maxHeight ?? mediaQuery.size.height;
    final shortestSide = math.min(resolvedWidth, resolvedHeight);
    final directionalNavigation = navigationMode == NavigationMode.directional;
    final isTv = directionalNavigation && shortestSide >= 480;

    final deviceClass = switch ((isTv, resolvedWidth, resolvedHeight)) {
      (true, < 1280, _) => DeviceClass.tvCompact,
      (true, _, _) => DeviceClass.tvLarge,
      (false, < 680, >= 680) => DeviceClass.mobilePortrait,
      (false, < 840, _) => DeviceClass.mobileLandscape,
      _ => DeviceClass.tablet,
    };

    return DeviceLayout._(
      deviceClass: deviceClass,
      width: resolvedWidth,
      height: resolvedHeight,
      directionalNavigation: directionalNavigation,
    );
  }

  final DeviceClass deviceClass;
  final double width;
  final double height;
  final bool directionalNavigation;

  bool get isTv =>
      deviceClass == DeviceClass.tvCompact ||
      deviceClass == DeviceClass.tvLarge;
  bool get isTvCompact => deviceClass == DeviceClass.tvCompact;
  bool get isMobilePortrait => deviceClass == DeviceClass.mobilePortrait;
  bool get isCompactHeight => height < 700;

  double get pageHorizontalPadding => switch (deviceClass) {
    DeviceClass.mobilePortrait => 16,
    DeviceClass.mobileLandscape => 20,
    DeviceClass.tablet => 24,
    DeviceClass.tvCompact => 24,
    DeviceClass.tvLarge => 40,
  };

  double get pageTopPadding => switch (deviceClass) {
    DeviceClass.mobilePortrait => 16,
    DeviceClass.mobileLandscape => 18,
    DeviceClass.tablet => 22,
    DeviceClass.tvCompact => 24,
    DeviceClass.tvLarge => 28,
  };

  double get pageBottomPadding => switch (deviceClass) {
    DeviceClass.mobilePortrait => 16,
    DeviceClass.mobileLandscape => 18,
    DeviceClass.tablet => 20,
    DeviceClass.tvCompact => 22,
    DeviceClass.tvLarge => 24,
  };

  double get sectionSpacing => switch (deviceClass) {
    DeviceClass.mobilePortrait => 12,
    DeviceClass.mobileLandscape => 14,
    DeviceClass.tablet => 16,
    DeviceClass.tvCompact => 18,
    DeviceClass.tvLarge => 20,
  };

  double get cardSpacing => switch (deviceClass) {
    DeviceClass.mobilePortrait => 12,
    DeviceClass.mobileLandscape => 14,
    DeviceClass.tablet => 16,
    DeviceClass.tvCompact => 16,
    DeviceClass.tvLarge => 20,
  };

  double get cardPadding => switch (deviceClass) {
    DeviceClass.mobilePortrait => 18,
    DeviceClass.mobileLandscape => 20,
    DeviceClass.tablet => 22,
    DeviceClass.tvCompact => 24,
    DeviceClass.tvLarge => 28,
  };

  double get cardBorderRadius => switch (deviceClass) {
    DeviceClass.mobilePortrait => 22,
    DeviceClass.mobileLandscape => 24,
    DeviceClass.tablet => 26,
    DeviceClass.tvCompact => 28,
    DeviceClass.tvLarge => 30,
  };

  double get listTileMinHeight => switch (deviceClass) {
    DeviceClass.mobilePortrait => 92,
    DeviceClass.mobileLandscape => 96,
    DeviceClass.tablet => 104,
    DeviceClass.tvCompact => 118,
    DeviceClass.tvLarge => 128,
  };

  double get detailPosterWidth => switch (deviceClass) {
    DeviceClass.mobilePortrait => 190,
    DeviceClass.mobileLandscape => 210,
    DeviceClass.tablet => 230,
    DeviceClass.tvCompact => 256,
    DeviceClass.tvLarge => 288,
  };

  double get maxContentWidth => switch (deviceClass) {
    DeviceClass.mobilePortrait => double.infinity,
    DeviceClass.mobileLandscape => double.infinity,
    DeviceClass.tablet => 1080,
    DeviceClass.tvCompact => 1200,
    DeviceClass.tvLarge => 1320,
  };

  double get headerIconContainer => switch (deviceClass) {
    DeviceClass.mobilePortrait => 46,
    DeviceClass.mobileLandscape => 50,
    DeviceClass.tablet => 52,
    DeviceClass.tvCompact => 56,
    DeviceClass.tvLarge => 60,
  };

  int columnsForWidth(
    double availableWidth, {
    required double minTileWidth,
    int maxColumns = 4,
  }) {
    if (isMobilePortrait) {
      return 1;
    }

    final safeWidth = availableWidth.isFinite ? availableWidth : width;
    var columns = (safeWidth / minTileWidth).floor();
    if (columns < 1) {
      columns = 1;
    }
    if (columns > maxColumns) {
      columns = maxColumns;
    }

    if (deviceClass == DeviceClass.mobileLandscape && columns > 2) {
      return 2;
    }
    if (isTvCompact && columns > 3) {
      return 3;
    }
    return columns;
  }

  double itemWidth(
    double availableWidth, {
    required int columns,
    required double spacing,
  }) {
    final widthWithoutSpacing = availableWidth - (spacing * (columns - 1));
    return widthWithoutSpacing / columns;
  }
}
