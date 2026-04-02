import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../layout/device_interaction_profile.dart';

const _deviceInteractionChannelName = 'tiviplayer/device_profile_android';

final deviceInteractionProfileProvider =
    FutureProvider<DeviceInteractionProfile>((ref) async {
      const channel = MethodChannel(_deviceInteractionChannelName);
      try {
        final raw = await channel.invokeMapMethod<Object?, Object?>(
          'getDeviceProfile',
        );
        if (raw == null) {
          return DeviceInteractionProfile.unavailable;
        }
        return DeviceInteractionProfile.fromMap(raw);
      } on MissingPluginException {
        return DeviceInteractionProfile.unavailable;
      } on PlatformException {
        return DeviceInteractionProfile.unavailable;
      }
    });
