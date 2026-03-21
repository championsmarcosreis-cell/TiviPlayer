import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tiviplayer/shared/testing/app_test_keys.dart';

import 'support/smoke_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('android tv smoke: login, D-pad, player e back', (tester) async {
    final config = await launchAndLogin(tester);
    expect(
      config.strictVodId,
      isNotNull,
      reason: 'XTREAM_STRICT_VOD_ID é obrigatório para o smoke real.',
    );

    expectNoTechnicalProviderUi(tester, config, stage: 'home tv');
    await navigateToVodAllByDpad(tester);
    await ensureVodTargetFocusedByDpad(tester, vodId: config.strictVodId);
    expectArtworkBound(tester, stage: 'lista VOD tv');
    await openVodDetailsByDpad(tester, vodId: config.strictVodId);
    expectArtworkBound(tester, stage: 'detalhe VOD tv');
    expectNoTechnicalProviderUi(tester, config, stage: 'detalhe VOD tv');
    await openPlayerByDpad(tester);
    await expectPlayerTolerant(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await pumpUntilFound(
      tester,
      find.byKey(AppTestKeys.vodPlayButton),
      timeout: const Duration(seconds: 15),
      description: 'retorno do player para detalhe VOD na TV',
    );
  });
}
