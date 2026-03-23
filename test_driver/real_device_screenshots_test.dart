import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final outputDir =
      Platform.environment['REAL_SCREENSHOT_DIR'] ?? 'screenshots/real';
  final directory = Directory(outputDir);
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }

  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
      final file = File(
        '${directory.path}${Platform.pathSeparator}$safeName.png',
      );
      await file.writeAsBytes(bytes, flush: true);
      // ignore: avoid_print
      print('screenshot saved: ${file.path}');
      return true;
    },
  );
}
