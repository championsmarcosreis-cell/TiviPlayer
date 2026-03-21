import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tiviplayer/shared/testing/app_test_keys.dart';

import 'support/smoke_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'PR4 mobile smoke: login, VOD, detalhe e player',
    (tester) async {
      final config = await launchAndLogin(tester);
      var playerClosed = false;

      try {
        expectNoTechnicalProviderUi(tester, config, stage: 'home pr4 mobile');
        await navigateToVodAllByTap(tester);
        expectArtworkBound(tester, stage: 'lista VOD pr4 mobile');
        await openVodDetailsByTap(tester, vodId: config.strictVodId);
        expectArtworkBound(tester, stage: 'detalhe VOD pr4 mobile');
        expectNoTechnicalProviderUi(
          tester,
          config,
          stage: 'detalhe VOD pr4 mobile',
        );
        await openPlayerByTap(tester);
        await expectPlayerLoadedStrict(tester);
        await closePlayerAndReturnToVodDetailsByTap(tester);
        playerClosed = true;

        expect(find.byKey(AppTestKeys.vodPlayButton), findsOneWidget);
        expect(find.byKey(AppTestKeys.playerLoadedState), findsNothing);
        expect(find.byKey(AppTestKeys.playerErrorState), findsNothing);
      } finally {
        if (!playerClosed) {
          await ensurePlayerClosedIfVisible(
            tester,
            directionalNavigation: false,
          );
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
