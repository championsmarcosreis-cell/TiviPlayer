import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tiviplayer/shared/testing/app_test_keys.dart';

import 'support/smoke_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'smoke tolerante: login, VOD e player com sucesso ou erro explícito',
    (tester) async {
      final config = await launchAndLogin(tester);

      await navigateToVodAllByTap(tester);
      await openVodDetailsByTap(tester, vodId: config.strictVodId);
      await openPlayerByTap(tester);
      await expectPlayerTolerant(tester);

      expect(
        find.byKey(AppTestKeys.playerLoadedState).evaluate().isNotEmpty ||
            find.byKey(AppTestKeys.playerErrorState).evaluate().isNotEmpty,
        isTrue,
      );
    },
  );
}
