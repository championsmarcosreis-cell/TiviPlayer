class DeviceInteractionProfile {
  const DeviceInteractionProfile({
    required this.isAvailable,
    required this.isTelevisionUiMode,
    required this.hasLeanbackFeature,
    required this.hasTelevisionFeature,
    required this.hasTouchscreen,
    required this.hasDirectionalNavigation,
    required this.hasHardwareKeyboard,
  });

  static const unavailable = DeviceInteractionProfile(
    isAvailable: false,
    isTelevisionUiMode: false,
    hasLeanbackFeature: false,
    hasTelevisionFeature: false,
    hasTouchscreen: true,
    hasDirectionalNavigation: false,
    hasHardwareKeyboard: false,
  );

  factory DeviceInteractionProfile.fromMap(Map<Object?, Object?> raw) {
    bool boolValue(Object? value, {required bool fallback}) {
      return value is bool ? value : fallback;
    }

    return DeviceInteractionProfile(
      isAvailable: true,
      isTelevisionUiMode: boolValue(
        raw['isTelevisionUiMode'],
        fallback: false,
      ),
      hasLeanbackFeature: boolValue(raw['hasLeanbackFeature'], fallback: false),
      hasTelevisionFeature: boolValue(
        raw['hasTelevisionFeature'],
        fallback: false,
      ),
      hasTouchscreen: boolValue(raw['hasTouchscreen'], fallback: true),
      hasDirectionalNavigation: boolValue(
        raw['hasDirectionalNavigation'],
        fallback: false,
      ),
      hasHardwareKeyboard: boolValue(
        raw['hasHardwareKeyboard'],
        fallback: false,
      ),
    );
  }

  final bool isAvailable;
  final bool isTelevisionUiMode;
  final bool hasLeanbackFeature;
  final bool hasTelevisionFeature;
  final bool hasTouchscreen;
  final bool hasDirectionalNavigation;
  final bool hasHardwareKeyboard;

  bool get stronglySuggestsTv =>
      isTelevisionUiMode || hasLeanbackFeature || hasTelevisionFeature;

  bool get isProbablyTvBox =>
      !hasTouchscreen &&
      (stronglySuggestsTv ||
          hasDirectionalNavigation ||
          hasHardwareKeyboard);

  bool get isAmbiguousHybrid =>
      isAvailable &&
      ((hasTouchscreen &&
              (stronglySuggestsTv || hasDirectionalNavigation)) ||
          (!hasTouchscreen && !stronglySuggestsTv));
}
