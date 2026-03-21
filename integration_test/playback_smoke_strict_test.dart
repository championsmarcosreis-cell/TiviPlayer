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

    if (config.strictVodId == null) {
      // Fallback útil para CI local, mas menos determinístico do que um VOD alvo.
      // A limitação fica documentada no README.
      // ignore: avoid_print
      print('XTREAM_STRICT_VOD_ID ausente; usando o primeiro VOD disponível.');
    }

    await navigateToVodAllByTap(tester);
    await openVodDetailsByTap(tester, vodId: config.strictVodId);
    await openPlayerByTap(tester);
    await expectPlayerLoadedStrict(tester);

    expect(find.byKey(AppTestKeys.playerErrorState), findsNothing);
    expect(find.byKey(AppTestKeys.playerRetryButton), findsNothing);
    expect(find.byKey(AppTestKeys.playerLoadedState), findsOneWidget);
  });
}
