import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tiviplayer/shared/testing/app_test_keys.dart';

import 'support/smoke_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('android tv smoke: login, D-pad, player e back', (tester) async {
    await launchAndLogin(tester);

    await navigateToVodAllByDpad(tester);
    await openVodDetailsByDpad(tester);
    await openPlayerByDpad(tester);
    await expectPlayerTolerant(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await pumpUntilFound(
      tester,
      find.byKey(AppTestKeys.vodPlayButton),
      timeout: const Duration(seconds: 15),
    );
  });
}
