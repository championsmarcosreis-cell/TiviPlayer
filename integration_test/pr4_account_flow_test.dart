import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tiviplayer/shared/testing/app_test_keys.dart';

import 'support/smoke_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'PR4 account smoke: login, conta e retorno limpo',
    (tester) async {
      final config = await launchAndLogin(tester);

      expectNoTechnicalProviderUi(tester, config, stage: 'home pr4 account');
      await openAccountAndVerifyByTap(tester, config);

      expect(find.byKey(AppTestKeys.homeMoviesCard), findsOneWidget);
      expect(find.byKey(AppTestKeys.homeLiveCard), findsOneWidget);
      expectNoTechnicalProviderUi(
        tester,
        config,
        stage: 'home pr4 account retorno',
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
