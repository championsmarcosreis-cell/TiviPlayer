import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tiviplayer/shared/testing/app_test_keys.dart';

import 'support/smoke_harness.dart';

const _captureMode = String.fromEnvironment(
  'CAPTURE_MODE',
  defaultValue: 'mobile',
);
const _captureTag = String.fromEnvironment('CAPTURE_TAG', defaultValue: '');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captura real: home apos login', (tester) async {
    final isMobileCapture = _captureMode.toLowerCase() == 'mobile';
    final previousImageHttpClientProvider = debugNetworkImageHttpClientProvider;
    debugNetworkImageHttpClientProvider = () {
      final client = HttpClient();
      client.autoUncompress = false;
      return client;
    };
    if (isMobileCapture) {
      HttpOverrides.global = _NoAutoUncompressHttpOverrides();
    }
    addTearDown(() {
      debugNetworkImageHttpClientProvider = previousImageHttpClientProvider;
      HttpOverrides.global = null;
    });

    final config = await launchAndLogin(tester);
    expectNoTechnicalProviderUi(tester, config, stage: 'home screenshot');

    await pumpUntilAnyFound(
      tester,
      [
        find.byKey(AppTestKeys.homeLiveCard),
        find.byKey(AppTestKeys.homeMoviesCard),
        find.byKey(AppTestKeys.homeSeriesCard),
      ],
      timeout: const Duration(seconds: 30),
      description: 'cards principais na home',
    );

    await tester.pump(const Duration(seconds: 1));
    await binding.convertFlutterSurfaceToImage();
    await binding.takeScreenshot(_name('home'));
  }, timeout: const Timeout(Duration(minutes: 4)));
}

String _name(String screen) {
  final mode = _captureMode.toLowerCase();
  if (_captureTag.trim().isEmpty) {
    return '${mode}_real_$screen';
  }
  return '${mode}_${_captureTag.trim()}_$screen';
}

class _NoAutoUncompressHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.autoUncompress = false;
    return client;
  }
}
