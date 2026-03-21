import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tiviplayer/shared/testing/app_test_keys.dart';

import 'support/smoke_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('smoke strict: login, VOD e player em estado carregado real', (
    tester,
  ) async {
    final config = await launchAndLogin(tester);

    expect(
      config.strictVodId,
      isNotNull,
      reason: 'XTREAM_STRICT_VOD_ID é obrigatório para o smoke strict.',
    );

    expectNoTechnicalProviderUi(tester, config, stage: 'home strict');
    await navigateToVodAllByTap(tester);
    expectArtworkBound(tester, stage: 'lista VOD strict');
    await openVodDetailsByTap(tester, vodId: config.strictVodId);
    expectArtworkBound(tester, stage: 'detalhe VOD strict');
    expectNoTechnicalProviderUi(tester, config, stage: 'detalhe VOD strict');
    await openPlayerByTap(tester);
    await expectPlayerLoadedStrict(tester);

    expect(find.byKey(AppTestKeys.playerErrorState), findsNothing);
    expect(find.byKey(AppTestKeys.playerRetryButton), findsNothing);
    expect(find.byKey(AppTestKeys.playerLoadedState), findsOneWidget);
  });
}
