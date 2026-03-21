import 'package:flutter/widgets.dart';

abstract final class AppTestKeys {
  static const loginBaseUrlField = ValueKey<String>('login.base_url');
  static const loginUsernameField = ValueKey<String>('login.username');
  static const loginPasswordField = ValueKey<String>('login.password');
  static const loginSubmitButton = ValueKey<String>('login.submit');

  static const homeLiveCard = ValueKey<String>('home.card.live');
  static const homeMoviesCard = ValueKey<String>('home.card.movies');
  static const homeSeriesCard = ValueKey<String>('home.card.series');
  static const homeLogoutButton = ValueKey<String>('home.logout');

  static const homeLiveCardId = 'home.card.live';
  static const homeMoviesCardId = 'home.card.movies';
  static const homeSeriesCardId = 'home.card.series';

  static const vodCategoryAll = ValueKey<String>('vod.category.all');
  static const vodCategoryAllId = 'vod.category.all';

  static const vodPlayButton = ValueKey<String>('vod.detail.play');
  static const vodPlayButtonId = 'vod.detail.play';

  static const playerLoadedState = ValueKey<String>('player.state.loaded');
  static const playerErrorState = ValueKey<String>('player.state.error');
  static const playerRetryButton = ValueKey<String>('player.retry');
  static const playerCloseButton = ValueKey<String>('player.close');
  static const playerCloseButtonId = 'player.close';

  static ValueKey<String> vodItem(String itemId) =>
      ValueKey<String>('vod.item.$itemId');

  static String vodItemId(String itemId) => 'vod.item.$itemId';

  static ValueKey<String> focusMarker(String testId) =>
      ValueKey<String>('focus.$testId');
}
