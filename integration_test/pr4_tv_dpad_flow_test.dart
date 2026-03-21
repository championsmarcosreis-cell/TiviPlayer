import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tiviplayer/shared/testing/app_test_keys.dart';

import 'support/smoke_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'PR4 TV smoke: login, D-pad, detalhe e player',
    (tester) async {
      final config = await launchAndLogin(tester);
      var playerClosed = false;

      try {
        expectNoTechnicalProviderUi(tester, config, stage: 'home pr4 tv');
        await navigateToVodAllByDpad(tester);
        await openVodDetailsByDpad(tester, vodId: config.strictVodId);
        expectArtworkBound(tester, stage: 'detalhe VOD pr4 tv');
        expectNoTechnicalProviderUi(
          tester,
          config,
          stage: 'detalhe VOD pr4 tv',
        );
        await openPlayerByDpad(tester);
        await expectPlayerLoadedStrict(tester);
        await closePlayerAndReturnToVodDetailsByDpad(tester);
        playerClosed = true;

        expect(find.byKey(AppTestKeys.vodPlayButton), findsOneWidget);
        expect(find.byKey(AppTestKeys.playerLoadedState), findsNothing);
        expect(find.byKey(AppTestKeys.playerErrorState), findsNothing);
      } finally {
        if (!playerClosed) {
          await ensurePlayerClosedIfVisible(
            tester,
            directionalNavigation: true,
          );
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
