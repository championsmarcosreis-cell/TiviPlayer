import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/main.dart' as app;
import 'package:tiviplayer/shared/testing/app_test_keys.dart';
import 'package:tiviplayer/shared/widgets/branded_artwork.dart';
import 'package:tiviplayer/shared/widgets/content_list_tile.dart';

const _rawBaseUrl = String.fromEnvironment('XTREAM_BASE_URL');
const _username = String.fromEnvironment('XTREAM_USERNAME');
const _password = String.fromEnvironment('XTREAM_PASSWORD');
const _strictVodId = String.fromEnvironment('XTREAM_STRICT_VOD_ID');

class SmokeConfig {
  const SmokeConfig({
    required this.baseUrl,
    required this.username,
    required this.password,
    this.strictVodId,
  });

  final String baseUrl;
  final String username;
  final String password;
  final String? strictVodId;
}

SmokeConfig requireSmokeConfig() {
  expect(_rawBaseUrl, isNotEmpty, reason: 'XTREAM_BASE_URL ausente.');
  expect(_username, isNotEmpty, reason: 'XTREAM_USERNAME ausente.');
  expect(_password, isNotEmpty, reason: 'XTREAM_PASSWORD ausente.');

  final normalizedBaseUrl = normalizeBaseUrl(_rawBaseUrl);
  final strictVodId = _strictVodId.trim().isEmpty ? null : _strictVodId.trim();

  return SmokeConfig(
    baseUrl: normalizedBaseUrl,
    username: _username,
    password: _password,
    strictVodId: strictVodId,
  );
}

String normalizeBaseUrl(String value) {
  final trimmed = value.trim();
  final uri = Uri.tryParse(trimmed);

  if (trimmed.isEmpty || uri == null || uri.hasScheme) {
    return trimmed;
  }

  return 'http://$trimmed';
}

Future<SmokeConfig> launchAndLogin(WidgetTester tester) async {
  final config = requireSmokeConfig();
  _logStage('launchAndLogin:start');

  await app.main();
  await tester.pumpAndSettle(const Duration(seconds: 2));
  _logStage('launchAndLogin:app_ready');

  final initialState = await pumpUntilAnyFound(
    tester,
    [
      find.byKey(AppTestKeys.loginBaseUrlField),
      find.byKey(AppTestKeys.homeLiveCard),
    ],
    timeout: const Duration(seconds: 20),
    description: 'bootstrap inicial do app',
  );

  if (initialState == 1) {
    await pumpUntilFound(
      tester,
      find.byKey(AppTestKeys.homeLogoutButton),
      timeout: const Duration(seconds: 10),
      description: 'botão Sair da home',
    );
    _logStage('launchAndLogin:logout_saved_session');
    await tapVisible(tester, find.byKey(AppTestKeys.homeLogoutButton));
    await pumpUntilFound(
      tester,
      find.byKey(AppTestKeys.loginBaseUrlField),
      timeout: const Duration(seconds: 10),
      description: 'retorno ao login',
    );
  }

  await pumpUntilFound(
    tester,
    find.byKey(AppTestKeys.loginBaseUrlField),
    timeout: const Duration(seconds: 10),
    description: 'campo base URL no login',
  );
  await pumpUntilFound(
    tester,
    find.byKey(AppTestKeys.loginUsernameField),
    timeout: const Duration(seconds: 10),
    description: 'campo usuário no login',
  );
  await pumpUntilFound(
    tester,
    find.byKey(AppTestKeys.loginPasswordField),
    timeout: const Duration(seconds: 10),
    description: 'campo senha no login',
  );

  await tester.enterText(
    find.byKey(AppTestKeys.loginBaseUrlField),
    config.baseUrl,
  );
  await tester.enterText(
    find.byKey(AppTestKeys.loginUsernameField),
    config.username,
  );
  await tester.enterText(
    find.byKey(AppTestKeys.loginPasswordField),
    config.password,
  );
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle(const Duration(seconds: 1));
  _logStage('launchAndLogin:credentials_filled');

  if (find.byKey(AppTestKeys.homeLiveCard).evaluate().isEmpty) {
    await dismissTextInput(tester);
    await tapVisible(tester, find.byKey(AppTestKeys.loginSubmitButton));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    _logStage('launchAndLogin:submitted');
  }

  await pumpUntilFound(
    tester,
    find.byKey(AppTestKeys.homeLiveCard),
    timeout: const Duration(seconds: 30),
    description: 'home após login',
  );
  _logStage('launchAndLogin:home_ready');

  return config;
}

Future<void> navigateToVodAllByTap(WidgetTester tester) async {
  _logStage('navigateToVodAllByTap:start');
  await tapVisible(tester, find.byKey(AppTestKeys.homeMoviesCard));

  final state = await pumpUntilAnyFound(
    tester,
    [
      find.byKey(AppTestKeys.vodCategoryAll),
      find.text('Sem coleções disponíveis'),
      find.text('Falha ao carregar'),
    ],
    timeout: const Duration(seconds: 20),
    description: 'entrada em Filmes',
  );

  if (state == 1) {
    _failWithDiagnostics(
      tester,
      'entrada em Filmes',
      'A tela abriu em empty-state válido de coleções.',
    );
  }
  if (state == 2) {
    _failWithDiagnostics(
      tester,
      'entrada em Filmes',
      'A tela abriu em estado de erro ao carregar coleções.',
    );
  }

  await tapVisible(tester, find.byKey(AppTestKeys.vodCategoryAll));
  _logStage('navigateToVodAllByTap:all_category_open');

  final catalogState = await pumpUntilAnyFound(
    tester,
    [
      find.text('Catálogo completo'),
      find.text('Sem títulos disponíveis'),
      find.text('Falha ao carregar'),
    ],
    timeout: const Duration(seconds: 15),
    description: 'entrada no catálogo VOD',
  );

  if (catalogState == 1) {
    _failWithDiagnostics(
      tester,
      'entrada no catálogo VOD',
      'A lista VOD abriu em empty-state válido.',
    );
  }
  if (catalogState == 2) {
    _failWithDiagnostics(
      tester,
      'entrada no catálogo VOD',
      'A lista VOD abriu em estado de erro.',
    );
  }

  await pumpUntilFound(
    tester,
    find.byType(ContentListTile),
    timeout: const Duration(seconds: 30),
    description: 'carregamento da lista VOD',
  );
  _logStage('navigateToVodAllByTap:list_ready');
}

Future<void> navigateToVodAllByDpad(WidgetTester tester) async {
  _logStage('navigateToVodAllByDpad:start');
  await expectFocused(
    tester,
    AppTestKeys.focusMarker(AppTestKeys.homeLiveCardId),
    timeout: const Duration(seconds: 10),
  );
  await sendRemoteKey(tester, LogicalKeyboardKey.arrowRight);
  await expectFocused(
    tester,
    AppTestKeys.focusMarker(AppTestKeys.homeMoviesCardId),
    timeout: const Duration(seconds: 10),
  );
  await sendRemoteKey(tester, LogicalKeyboardKey.enter);
  _logStage('navigateToVodAllByDpad:all_category_open');

  final state = await pumpUntilAnyFound(
    tester,
    [
      find.byKey(AppTestKeys.vodCategoryAll),
      find.text('Sem coleções disponíveis'),
      find.text('Falha ao carregar'),
    ],
    timeout: const Duration(seconds: 20),
    description: 'entrada em Filmes por D-pad',
  );

  if (state == 1) {
    _failWithDiagnostics(
      tester,
      'entrada em Filmes por D-pad',
      'A tela abriu em empty-state válido de coleções.',
    );
  }
  if (state == 2) {
    _failWithDiagnostics(
      tester,
      'entrada em Filmes por D-pad',
      'A tela abriu em estado de erro ao carregar coleções.',
    );
  }

  await expectFocused(
    tester,
    AppTestKeys.focusMarker(AppTestKeys.vodCategoryAllId),
    timeout: const Duration(seconds: 10),
  );
  await sendRemoteKey(tester, LogicalKeyboardKey.enter);

  final catalogState = await pumpUntilAnyFound(
    tester,
    [
      find.byType(ContentListTile),
      find.text('Sem títulos disponíveis'),
      find.text('Falha ao carregar'),
    ],
    timeout: const Duration(seconds: 30),
    description: 'carregamento da lista VOD por D-pad',
  );

  if (catalogState == 1) {
    _failWithDiagnostics(
      tester,
      'carregamento da lista VOD por D-pad',
      'A lista VOD abriu em empty-state válido.',
    );
  }
  if (catalogState == 2) {
    _failWithDiagnostics(
      tester,
      'carregamento da lista VOD por D-pad',
      'A lista VOD abriu em estado de erro.',
    );
  }
  _logStage('navigateToVodAllByDpad:list_ready');
}

Future<void> ensureVodTargetVisibleByTap(
  WidgetTester tester, {
  required String? vodId,
}) async {
  if (vodId == null) {
    await pumpUntilFound(
      tester,
      find.byType(ContentListTile),
      timeout: const Duration(seconds: 15),
      description: 'primeiro item da lista VOD',
    );
    return;
  }

  final target = find.byKey(AppTestKeys.vodItem(vodId));
  if (target.evaluate().isNotEmpty) {
    return;
  }

  try {
    await scrollUntilVisible(tester, target);
  } catch (_) {
    _failWithDiagnostics(
      tester,
      'localização do VOD alvo',
      'O VOD alvo $vodId não apareceu na lista carregada.',
    );
  }
}

Future<void> ensureVodTargetFocusedByDpad(
  WidgetTester tester, {
  required String? vodId,
  int maxSteps = 25,
}) async {
  if (vodId == null) {
    await pumpUntilFound(
      tester,
      find.byType(ContentListTile).first,
      timeout: const Duration(seconds: 10),
      description: 'primeiro VOD focável',
    );
    return;
  }

  final focusKey = AppTestKeys.focusMarker(AppTestKeys.vodItemId(vodId));
  for (var step = 0; step < maxSteps; step++) {
    if (find.byKey(focusKey).evaluate().isNotEmpty) {
      return;
    }
    await sendRemoteKey(tester, LogicalKeyboardKey.arrowDown);
  }

  _failWithDiagnostics(
    tester,
    'foco no VOD alvo por D-pad',
    'O VOD alvo $vodId não recebeu foco após $maxSteps passos.',
  );
}

Future<void> openVodDetailsByTap(WidgetTester tester, {String? vodId}) async {
  _logStage('openVodDetailsByTap:start');
  if (vodId != null) {
    await ensureVodTargetVisibleByTap(tester, vodId: vodId);
    await tapVisible(tester, find.byKey(AppTestKeys.vodItem(vodId)));
  } else {
    await tapVisible(tester, find.byType(ContentListTile).first);
  }

  await pumpUntilFound(
    tester,
    find.byKey(AppTestKeys.vodPlayButton),
    timeout: const Duration(seconds: 30),
    description: 'abertura do detalhe VOD',
  );
  _logStage('openVodDetailsByTap:details_ready');
}

Future<void> openVodDetailsByDpad(WidgetTester tester, {String? vodId}) async {
  _logStage('openVodDetailsByDpad:start');
  await ensureVodTargetFocusedByDpad(tester, vodId: vodId);
  await sendRemoteKey(tester, LogicalKeyboardKey.enter);
  await pumpUntilFound(
    tester,
    find.byKey(AppTestKeys.vodPlayButton),
    timeout: const Duration(seconds: 30),
    description: 'abertura do detalhe VOD por D-pad',
  );
  _logStage('openVodDetailsByDpad:details_ready');
}

Future<void> openPlayerByTap(WidgetTester tester) async {
  _logStage('openPlayerByTap:start');
  await tapVisible(tester, find.byKey(AppTestKeys.vodPlayButton));
  _logStage('openPlayerByTap:submitted');
}

Future<void> openPlayerByDpad(WidgetTester tester) async {
  _logStage('openPlayerByDpad:start');
  await sendRemoteKey(tester, LogicalKeyboardKey.enter);
  _logStage('openPlayerByDpad:submitted');
}

Future<void> expectPlayerTolerant(WidgetTester tester) async {
  _logStage('expectPlayerTolerant:start');
  await pumpUntilAnyFound(
    tester,
    [
      find.byKey(AppTestKeys.playerLoadedState),
      find.byKey(AppTestKeys.playerErrorState),
    ],
    timeout: const Duration(seconds: 45),
    description: 'estado final do player',
  );
  _logStage('expectPlayerTolerant:done');
}

Future<void> expectPlayerLoadedStrict(WidgetTester tester) async {
  _logStage('expectPlayerLoadedStrict:start');
  await pumpUntilFound(
    tester,
    find.byKey(AppTestKeys.playerLoadedState),
    timeout: const Duration(seconds: 45),
    description: 'player carregado',
  );
  await tester.pump(const Duration(seconds: 3));
  expect(find.byKey(AppTestKeys.playerErrorState), findsNothing);
  _logStage('expectPlayerLoadedStrict:done');
}

Future<void> closePlayerAndReturnToVodDetailsByTap(WidgetTester tester) async {
  _logStage('closePlayerAndReturnToVodDetailsByTap:start');

  await pumpUntilFound(
    tester,
    find.byKey(AppTestKeys.playerCloseButton),
    timeout: const Duration(seconds: 15),
    description: 'botão Sair do player',
  );

  await tapVisible(tester, find.byKey(AppTestKeys.playerCloseButton));
  await tester.pumpAndSettle(const Duration(seconds: 2));

  await pumpUntilFound(
    tester,
    find.byKey(AppTestKeys.vodPlayButton),
    timeout: const Duration(seconds: 20),
    description: 'retorno do player para detalhe VOD por tap',
  );

  expect(find.byKey(AppTestKeys.playerLoadedState), findsNothing);
  expect(find.byKey(AppTestKeys.playerErrorState), findsNothing);
  _logStage('closePlayerAndReturnToVodDetailsByTap:done');
}

Future<void> closePlayerAndReturnToVodDetailsByDpad(WidgetTester tester) async {
  _logStage('closePlayerAndReturnToVodDetailsByDpad:start');

  await sendRemoteKey(tester, LogicalKeyboardKey.enter);
  await tester.pumpAndSettle(const Duration(seconds: 2));

  if (find.byKey(AppTestKeys.vodPlayButton).evaluate().isEmpty) {
    _logStage('closePlayerAndReturnToVodDetailsByDpad:fallback_pop_route');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  await pumpUntilFound(
    tester,
    find.byKey(AppTestKeys.vodPlayButton),
    timeout: const Duration(seconds: 20),
    description: 'retorno do player para detalhe VOD por D-pad',
  );

  expect(find.byKey(AppTestKeys.playerLoadedState), findsNothing);
  expect(find.byKey(AppTestKeys.playerErrorState), findsNothing);
  _logStage('closePlayerAndReturnToVodDetailsByDpad:done');
}

Future<void> ensurePlayerClosedIfVisible(
  WidgetTester tester, {
  required bool directionalNavigation,
}) async {
  final hasLoaded = find
      .byKey(AppTestKeys.playerLoadedState)
      .evaluate()
      .isNotEmpty;
  final hasError = find
      .byKey(AppTestKeys.playerErrorState)
      .evaluate()
      .isNotEmpty;
  final hasCloseButton = find
      .byKey(AppTestKeys.playerCloseButton)
      .evaluate()
      .isNotEmpty;

  if (!hasLoaded && !hasError && !hasCloseButton) {
    return;
  }

  _logStage('ensurePlayerClosedIfVisible:start');

  if (directionalNavigation) {
    await closePlayerAndReturnToVodDetailsByDpad(tester);
  } else {
    await closePlayerAndReturnToVodDetailsByTap(tester);
  }

  _logStage('ensurePlayerClosedIfVisible:done');
}

Future<void> openAccountAndVerifyByTap(
  WidgetTester tester,
  SmokeConfig config,
) async {
  _logStage('openAccountAndVerifyByTap:start');
  await pumpUntilFound(
    tester,
    find.byKey(AppTestKeys.homeAccountAction),
    timeout: const Duration(seconds: 10),
    description: 'botão Conta na home',
  );
  await tapVisible(tester, find.byKey(AppTestKeys.homeAccountAction));
  _logStage('openAccountAndVerifyByTap:account_action_tapped');

  final state = await pumpUntilAnyFound(
    tester,
    [find.text('Status'), find.text('Falha ao carregar')],
    timeout: const Duration(seconds: 20),
    description: 'abertura da conta',
  );

  if (state == 1) {
    _failWithDiagnostics(
      tester,
      'abertura da conta',
      'A tela de conta abriu em estado de erro.',
    );
  }

  expect(find.text('Status'), findsOneWidget);
  expectNoTechnicalProviderUi(tester, config, stage: 'tela de conta');

  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle(const Duration(seconds: 1));
  await pumpUntilFound(
    tester,
    find.byKey(AppTestKeys.homeMoviesCard),
    timeout: const Duration(seconds: 15),
    description: 'retorno da conta para a home',
  );
  _logStage('openAccountAndVerifyByTap:done');
}

void expectNoTechnicalProviderUi(
  WidgetTester tester,
  SmokeConfig config, {
  required String stage,
}) {
  final uri = Uri.tryParse(config.baseUrl);
  final host = uri?.host;
  final port = uri?.hasPort == true ? uri!.port.toString() : null;
  final visibleTexts = _visibleTexts(tester).toList();
  final visibleTextBlob = visibleTexts.join(' | ');

  expect(
    visibleTextBlob.contains('Xtream'),
    isFalse,
    reason: '$stage expôs o label Xtream. Textos: $visibleTextBlob',
  );
  expect(
    visibleTextBlob.contains('http://'),
    isFalse,
    reason: '$stage expôs URL técnica. Textos: $visibleTextBlob',
  );
  expect(
    visibleTextBlob.contains('https://'),
    isFalse,
    reason: '$stage expôs URL técnica. Textos: $visibleTextBlob',
  );

  if (host != null && host.isNotEmpty) {
    expect(
      visibleTexts.any((text) => text.contains(host)),
      isFalse,
      reason: '$stage expôs o host do provedor. Textos: $visibleTextBlob',
    );
  }

  if (port != null && port.isNotEmpty) {
    expect(
      visibleTexts.any((text) => text.contains(port)),
      isFalse,
      reason: '$stage expôs a porta do provedor. Textos: $visibleTextBlob',
    );
  }
}

void expectArtworkBound(WidgetTester tester, {required String stage}) {
  final artworks = tester.widgetList<BrandedArtwork>(
    find.byType(BrandedArtwork).hitTestable(),
  );
  expect(
    artworks.isNotEmpty,
    isTrue,
    reason: '$stage não renderizou nenhum widget de artwork.',
  );

  final hasRemoteImage = artworks.any(
    (artwork) => (artwork.imageUrl?.trim().isNotEmpty ?? false),
  );
  expect(
    hasRemoteImage,
    isTrue,
    reason: '$stage não vinculou nenhuma imagem remota real.',
  );
}

Future<void> expectFocused(
  WidgetTester tester,
  ValueKey<String> key, {
  required Duration timeout,
}) {
  return pumpUntilFound(
    tester,
    find.byKey(key),
    timeout: timeout,
    description: 'marcador de foco $key',
  );
}

Future<void> scrollUntilVisible(WidgetTester tester, Finder target) async {
  if (target.evaluate().isNotEmpty) {
    return;
  }

  final scrollable = find.byType(Scrollable).first;
  await tester.scrollUntilVisible(
    target,
    400,
    scrollable: scrollable,
    duration: const Duration(milliseconds: 300),
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 300));
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle(const Duration(milliseconds: 300));
  await tester.tap(finder);
  await tester.pumpAndSettle(const Duration(milliseconds: 300));
}

Future<void> dismissTextInput(WidgetTester tester) async {
  await tester.tapAt(const Offset(16, 16));
  await tester.pumpAndSettle(const Duration(milliseconds: 300));
}

Future<void> sendRemoteKey(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle(const Duration(milliseconds: 500));
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  required Duration timeout,
  required String description,
  Duration step = const Duration(milliseconds: 500),
}) async {
  final end = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  _failWithDiagnostics(tester, description, 'Elemento esperado não apareceu.');
}

Future<int> pumpUntilAnyFound(
  WidgetTester tester,
  List<Finder> finders, {
  required Duration timeout,
  required String description,
  Duration step = const Duration(milliseconds: 500),
}) async {
  final end = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    for (var index = 0; index < finders.length; index++) {
      if (finders[index].evaluate().isNotEmpty) {
        return index;
      }
    }
  }

  _failWithDiagnostics(
    tester,
    description,
    'Nenhum dos estados esperados apareceu.',
  );
}

Never _failWithDiagnostics(WidgetTester tester, String stage, String reason) {
  final texts = _visibleTexts(tester).take(18).join(' | ');
  throw TestFailure('$stage: $reason Textos visíveis: $texts');
}

void _logStage(String stage) {
  // ignore: avoid_print
  print('[smoke] $stage');
}

Iterable<String> _visibleTexts(WidgetTester tester) {
  final values = <String>{};
  for (final element in find.byType(Text).evaluate()) {
    if (_isOffstage(element)) {
      continue;
    }

    final widget = element.widget as Text;
    final text = widget.data ?? widget.textSpan?.toPlainText() ?? '';
    final trimmed = text.trim();
    if (trimmed.isNotEmpty) {
      values.add(trimmed);
    }
  }
  return values;
}

bool _isOffstage(Element element) {
  var offstage = false;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is Offstage && widget.offstage) {
      offstage = true;
      return false;
    }
    return true;
  });
  return offstage;
}
