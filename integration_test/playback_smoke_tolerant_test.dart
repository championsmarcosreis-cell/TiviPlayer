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
      expect(
        config.strictVodId,
        isNotNull,
        reason: 'XTREAM_STRICT_VOD_ID é obrigatório para o smoke real.',
      );

      expectNoTechnicalProviderUi(tester, config, stage: 'home mobile');
      await openAccountAndVerifyByTap(tester, config);
      await navigateToVodAllByTap(tester);
      expectArtworkBound(tester, stage: 'lista VOD mobile');
      await openVodDetailsByTap(tester, vodId: config.strictVodId);
      expectArtworkBound(tester, stage: 'detalhe VOD mobile');
      expectNoTechnicalProviderUi(tester, config, stage: 'detalhe VOD mobile');
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
