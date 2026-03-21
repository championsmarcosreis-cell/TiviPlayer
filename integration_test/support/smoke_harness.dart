import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiviplayer/main.dart' as app;
import 'package:tiviplayer/shared/testing/app_test_keys.dart';
import 'package:tiviplayer/shared/widgets/content_list_tile.dart';
import 'package:tiviplayer/shared/widgets/section_card.dart';

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

  await app.main();
  await tester.pumpAndSettle(const Duration(seconds: 2));

  if (find.byKey(AppTestKeys.homeLogoutButton).evaluate().isNotEmpty &&
      find.byKey(AppTestKeys.loginBaseUrlField).evaluate().isEmpty) {
    await tapVisible(tester, find.byKey(AppTestKeys.homeLogoutButton));
    await pumpUntilFound(
      tester,
      find.byKey(AppTestKeys.loginBaseUrlField),
      timeout: const Duration(seconds: 10),
    );
  }

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

  if (find.byKey(AppTestKeys.homeLiveCard).evaluate().isEmpty) {
    await dismissTextInput(tester);
    await tapVisible(tester, find.byKey(AppTestKeys.loginSubmitButton));
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  await pumpUntilFound(
    tester,
    find.byKey(AppTestKeys.homeLiveCard),
    timeout: const Duration(seconds: 30),
  );

  return config;
}

Future<void> navigateToVodAllByTap(WidgetTester tester) async {
  final homeMoviesFinder = find.byType(SectionCard).at(1);
  await tapVisible(tester, homeMoviesFinder);
  if (find.byKey(AppTestKeys.vodCategoryAll).evaluate().isEmpty) {
    await tapVisible(tester, homeMoviesFinder);
  }

  await pumpUntilFound(
    tester,
    find.byKey(AppTestKeys.vodCategoryAll),
    timeout: const Duration(seconds: 20),
  );
  final vodAllFinder = find.text('Todos').first;
  await tapVisible(tester, vodAllFinder);

  await pumpUntilFound(
    tester,
    find.text('Catálogo completo'),
    timeout: const Duration(seconds: 15),
  );

  await pumpUntilFound(
    tester,
    find.byType(ContentListTile),
    timeout: const Duration(seconds: 30),
  );
}

Future<void> navigateToVodAllByDpad(WidgetTester tester) async {
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
  await pumpUntilFound(
    tester,
    find.byKey(AppTestKeys.vodCategoryAll),
    timeout: const Duration(seconds: 20),
  );
  await expectFocused(
    tester,
    AppTestKeys.focusMarker(AppTestKeys.vodCategoryAllId),
    timeout: const Duration(seconds: 10),
  );
  await sendRemoteKey(tester, LogicalKeyboardKey.enter);
  await pumpUntilFound(
    tester,
    find.byType(ContentListTile),
    timeout: const Duration(seconds: 30),
  );
}

Future<void> openVodDetailsByTap(WidgetTester tester, {String? vodId}) async {
  if (vodId != null) {
    final target = find.byKey(AppTestKeys.vodItem(vodId));
    await scrollUntilVisible(tester, target);
    await tapVisible(tester, target);
  } else {
    await tapVisible(tester, find.byType(ContentListTile).first);
  }

  await pumpUntilFound(
    tester,
    find.byKey(AppTestKeys.vodPlayButton),
    timeout: const Duration(seconds: 30),
  );
}

Future<void> openVodDetailsByDpad(WidgetTester tester) async {
  await sendRemoteKey(tester, LogicalKeyboardKey.enter);
  await pumpUntilFound(
    tester,
    find.byKey(AppTestKeys.vodPlayButton),
    timeout: const Duration(seconds: 30),
  );
}

Future<void> openPlayerByTap(WidgetTester tester) async {
  await tapVisible(tester, find.byKey(AppTestKeys.vodPlayButton));
}

Future<void> openPlayerByDpad(WidgetTester tester) async {
  await sendRemoteKey(tester, LogicalKeyboardKey.enter);
}

Future<void> expectPlayerTolerant(WidgetTester tester) async {
  await pumpUntilAnyFound(tester, [
    find.byKey(AppTestKeys.playerLoadedState),
    find.byKey(AppTestKeys.playerErrorState),
  ], timeout: const Duration(seconds: 45));
}

Future<void> expectPlayerLoadedStrict(WidgetTester tester) async {
  await pumpUntilFound(
    tester,
    find.byKey(AppTestKeys.playerLoadedState),
    timeout: const Duration(seconds: 45),
  );
  await tester.pump(const Duration(seconds: 3));
  expect(find.byKey(AppTestKeys.playerErrorState), findsNothing);
}

Future<void> expectFocused(
  WidgetTester tester,
  ValueKey<String> key, {
  required Duration timeout,
}) {
  return pumpUntilFound(tester, find.byKey(key), timeout: timeout);
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
  Duration step = const Duration(milliseconds: 500),
}) async {
  final end = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  throw TestFailure('Elemento não encontrado: $finder');
}

Future<void> pumpUntilAnyFound(
  WidgetTester tester,
  List<Finder> finders, {
  required Duration timeout,
  Duration step = const Duration(milliseconds: 500),
}) async {
  final end = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (finders.any((finder) => finder.evaluate().isNotEmpty)) {
      return;
    }
  }

  throw TestFailure('Nenhum dos elementos esperados foi encontrado.');
}
