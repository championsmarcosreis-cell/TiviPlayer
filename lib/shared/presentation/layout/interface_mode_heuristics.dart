import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'device_interaction_profile.dart';
import 'interface_mode_scope.dart';

final class InterfaceModeHeuristics {
  const InterfaceModeHeuristics._();

  static InterfaceMode resolveMode({
    required InterfaceMode preferredMode,
    required NavigationMode navigationMode,
    required double viewportWidth,
    required double viewportHeight,
    DeviceInteractionProfile? deviceProfile,
  }) {
    if (preferredMode != InterfaceMode.auto) {
      return preferredMode;
    }
    return resolveAutoMode(
      navigationMode: navigationMode,
      viewportWidth: viewportWidth,
      viewportHeight: viewportHeight,
      deviceProfile: deviceProfile,
    );
  }

  static InterfaceMode resolveAutoMode({
    required NavigationMode navigationMode,
    required double viewportWidth,
    required double viewportHeight,
    DeviceInteractionProfile? deviceProfile,
  }) {
    final shortestSide = math.min(viewportWidth, viewportHeight);
    final longestSide = math.max(viewportWidth, viewportHeight);
    final directionalNavigation = navigationMode == NavigationMode.directional;

    if (deviceProfile?.stronglySuggestsTv == true) {
      return InterfaceMode.tv;
    }
    if (deviceProfile?.isProbablyTvBox == true) {
      return InterfaceMode.tv;
    }

    final hdTvFallback =
        viewportWidth > viewportHeight &&
        longestSide >= 900 &&
        shortestSide >= 500;
    final largeScreenTvFallback = longestSide >= 1500 && shortestSide >= 850;
    final autoTv =
        (directionalNavigation && shortestSide >= 480) ||
        hdTvFallback ||
        largeScreenTvFallback;
    return autoTv ? InterfaceMode.tv : InterfaceMode.mobile;
  }

  static bool shouldExposeModeSelector({
    required InterfaceMode preferredMode,
    required NavigationMode navigationMode,
    required double viewportWidth,
    required double viewportHeight,
    DeviceInteractionProfile? deviceProfile,
  }) {
    if (preferredMode != InterfaceMode.auto) {
      return true;
    }
    if (deviceProfile == null || !deviceProfile.isAvailable) {
      return false;
    }
    if (deviceProfile.isAmbiguousHybrid) {
      return true;
    }

    final shortestSide = math.min(viewportWidth, viewportHeight);
    final directionalNavigation = navigationMode == NavigationMode.directional;
    return directionalNavigation &&
        deviceProfile.hasTouchscreen &&
        shortestSide >= 600;
  }

  static String helperText({
    required InterfaceMode preferredMode,
    DeviceInteractionProfile? deviceProfile,
  }) {
    if (preferredMode == InterfaceMode.tv) {
      return 'Modo TV salvo neste aparelho. Use se a navegacao depender do controle remoto.';
    }
    if (preferredMode == InterfaceMode.mobile) {
      return 'Modo mobile salvo neste aparelho. Use em celular ou tablet com toque.';
    }
    if (deviceProfile == null || !deviceProfile.isAvailable) {
      return 'Auto detecta o melhor modo quando o aparelho oferece sinais suficientes.';
    }
    if (deviceProfile.isAmbiguousHybrid) {
      return 'Este aparelho mistura sinais de touch e controle. Se o remoto nao responder bem, escolha TV.';
    }
    if (deviceProfile.isProbablyTvBox) {
      return 'Este aparelho parece uma box sem toque. Auto deve priorizar navegacao por controle remoto.';
    }
    return 'Auto detecta o melhor modo e continua disponivel para override manual.';
  }
}
