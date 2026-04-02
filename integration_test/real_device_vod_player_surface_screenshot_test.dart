import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/smoke_harness.dart';

const _captureMode = String.fromEnvironment(
  'CAPTURE_MODE',
  defaultValue: 'mobile',
);
const _captureTag = String.fromEnvironment('CAPTURE_TAG', defaultValue: '');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'captura real: superficie do player VOD',
    (tester) async {
      final config = await launchAndLogin(tester);
      await binding.convertFlutterSurfaceToImage();

      await navigateToVodAllByTap(tester);
      await openVodDetailsByTap(tester, vodId: config.strictVodId);
      await openPlayerByTap(tester);
      await expectPlayerLoadedStrict(tester);
      await tester.pump(const Duration(seconds: 6));
      await _capture(binding, _name('vod_player_surface'));
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  final bytes = await binding.takeScreenshot(name);
  final directory = Directory(
    '${Directory.systemTemp.path}/tiviplayer_captures',
  );
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }
  final file = File('${directory.path}/$name.png');
  file.writeAsBytesSync(bytes, flush: true);
  // ignore: avoid_print
  print('[capture] ${file.path}');
}

String _name(String screen) {
  final mode = _captureMode.toLowerCase();
  if (_captureTag.trim().isEmpty) {
    return '${mode}_real_$screen';
  }
  return '${mode}_${_captureTag.trim()}_$screen';
}
