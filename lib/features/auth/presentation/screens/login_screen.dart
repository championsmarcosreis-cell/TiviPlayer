import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/providers.dart';
import '../../../../shared/presentation/controllers/device_interaction_profile_provider.dart';
import '../../../../shared/presentation/controllers/interface_mode_controller.dart';
import '../../../../shared/presentation/layout/device_layout.dart';
import '../../../../shared/presentation/layout/interface_mode_heuristics.dart';
import '../../../../shared/presentation/layout/interface_mode_scope.dart';
import '../../../../shared/testing/app_test_keys.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../../../shared/widgets/interface_mode_selector_card.dart';
import '../../domain/entities/xtream_credentials.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const routePath = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _lastBaseUrlStorageKey = 'login.last_base_url';

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _baseUrlController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final FocusNode _usernameFocusNode;
  late final FocusNode _passwordFocusNode;
  late final FocusNode _baseUrlFocusNode;
  late final AppConfig _appConfig;
  late final String _resolvedInstallationBaseUrl;

  var _showAdvancedServer = false;
  var _obscurePassword = true;
  int _lastKeyboardRequestMs = 0;
  FocusNode? _tvEditingFocusNode;

  @override
  void initState() {
    super.initState();
    _appConfig = ref.read(appConfigProvider);
    _resolvedInstallationBaseUrl = _resolveInstallationBaseUrl();
    _baseUrlController = TextEditingController(
      text: _resolvedInstallationBaseUrl,
    );
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _usernameFocusNode = FocusNode(
      debugLabel: 'login.username',
      onKeyEvent: _handleTvFieldKeyEvent,
    );
    _passwordFocusNode = FocusNode(
      debugLabel: 'login.password',
      onKeyEvent: _handleTvFieldKeyEvent,
    );
    _baseUrlFocusNode = FocusNode(
      debugLabel: 'login.base_url',
      onKeyEvent: _handleTvFieldKeyEvent,
    );
    _usernameFocusNode.addListener(_handleTvFieldFocusChanged);
    _passwordFocusNode.addListener(_handleTvFieldFocusChanged);
    _baseUrlFocusNode.addListener(_handleTvFieldFocusChanged);
    _showAdvancedServer =
        _appConfig.allowAdvancedServer && _resolvedInstallationBaseUrl.isEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_shouldHandleTvKeyboard) {
        return;
      }
      final initialTarget =
          (_showAdvancedServer && _appConfig.allowAdvancedServer)
          ? _baseUrlFocusNode
          : _usernameFocusNode;
      FocusScope.of(context).requestFocus(initialTarget);
    });
  }

  @override
  void dispose() {
    _usernameFocusNode.removeListener(_handleTvFieldFocusChanged);
    _passwordFocusNode.removeListener(_handleTvFieldFocusChanged);
    _baseUrlFocusNode.removeListener(_handleTvFieldFocusChanged);
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _baseUrlFocusNode.dispose();
    _baseUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final currentError = next.errorMessage;
      final previousError = previous?.errorMessage;

      if (currentError != null && currentError != previousError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(currentError)));
      }
    });

    final authState = ref.watch(authControllerProvider);
    final preferredInterfaceMode = ref.watch(interfaceModeControllerProvider);
    final deviceProfileAsync = ref.watch(deviceInteractionProfileProvider);
    final deviceProfile =
        deviceProfileAsync is AsyncData ? deviceProfileAsync.value : null;
    final isSubmitting = authState.status == AuthStatus.authenticating;
    final usesDirectionalNavigation =
        MediaQuery.navigationModeOf(context) == NavigationMode.directional;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF03060D), Color(0xFF09111F), Color(0xFF050912)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.58),
                      radius: 1.08,
                      colors: [Color(0x190F2440), Color(0x00030A12)],
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              top: -190,
              right: -120,
              child: _BackgroundOrb(
                size: 420,
                colors: [Color(0x3DFF7A2F), Color(0x00FF7A2F)],
              ),
            ),
            const Positioned(
              top: 140,
              left: -180,
              child: _BackgroundOrb(
                size: 420,
                colors: [Color(0x1F18C8FF), Color(0x0018C8FF)],
              ),
            ),
            const Positioned(
              bottom: -260,
              right: -180,
              child: _BackgroundOrb(
                size: 520,
                colors: [Color(0x16215EFF), Color(0x00060B13)],
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final layout = DeviceLayout.of(
                    context,
                    constraints: constraints,
                  );
                  final credentialsCard = _CredentialsCard(
                    layout: layout,
                    usernameController: _usernameController,
                    passwordController: _passwordController,
                    usernameFocusNode: _usernameFocusNode,
                    passwordFocusNode: _passwordFocusNode,
                    isUsernameEditing: _isTvFieldEditing(_usernameFocusNode),
                    isPasswordEditing: _isTvFieldEditing(_passwordFocusNode),
                    usesDirectionalNavigation:
                        usesDirectionalNavigation || layout.isTv,
                    isSubmitting: isSubmitting,
                    obscurePassword: _obscurePassword,
                    onRequestKeyboard: (focusNode) => _requestKeyboardForTv(
                      focusNode: focusNode,
                      force: true,
                    ),
                    onToggleObscurePassword: _toggleObscurePassword,
                    onSubmit: _submit,
                    validateRequired: _validateRequired,
                  );
                  final advancedServerSection = _AdvancedServerSection(
                    layout: layout,
                    baseUrlController: _baseUrlController,
                    baseUrlFocusNode: _baseUrlFocusNode,
                    isBaseUrlEditing: _isTvFieldEditing(_baseUrlFocusNode),
                    showAdvancedServer: _showAdvancedServer,
                    allowAdvancedServer: _appConfig.allowAdvancedServer,
                    embeddedBaseUrl: _resolvedInstallationBaseUrl,
                    onRequestKeyboard: (focusNode) => _requestKeyboardForTv(
                      focusNode: focusNode,
                      force: true,
                    ),
                    onToggleAdvancedServer: _toggleAdvancedServer,
                    onUseEmbeddedServer: _useEmbeddedServer,
                    validateBaseUrl: _validateBaseUrl,
                  );
                  final shouldShowInterfaceSelector =
                      InterfaceModeHeuristics.shouldExposeModeSelector(
                        preferredMode: preferredInterfaceMode,
                        navigationMode: MediaQuery.navigationModeOf(context),
                        viewportWidth: MediaQuery.sizeOf(context).width,
                        viewportHeight: MediaQuery.sizeOf(context).height,
                        deviceProfile: deviceProfile,
                      );
                  final interfaceModeSection = shouldShowInterfaceSelector
                      ? InterfaceModeSelectorCard(
                          layout: layout,
                          mode: preferredInterfaceMode,
                          compactForTv: layout.isTv,
                          eyebrow: 'Controle deste aparelho',
                          title: 'Escolha como navegar',
                          description:
                              'Use TV em box ou stick com controle remoto. Use mobile em celular ou tablet com toque.',
                          helperText: InterfaceModeHeuristics.helperText(
                            preferredMode: preferredInterfaceMode,
                            deviceProfile: deviceProfile,
                          ),
                          onChanged: (mode) {
                            ref
                                .read(interfaceModeControllerProvider.notifier)
                                .setMode(mode);
                          },
                        )
                      : null;
                  final heroSection = _LoginHeroSection(layout: layout);

                  return Scrollbar(
                    thumbVisibility: false,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        layout.pageHorizontalPadding,
                        layout.isTv ? 10 : layout.pageTopPadding,
                        layout.pageHorizontalPadding,
                        (layout.isTv ? 8 : layout.pageBottomPadding) +
                            keyboardInset,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: layout.isTv ? 640 : 620,
                            ),
                            child: Column(
                              mainAxisAlignment:
                                  layout.isTv && keyboardInset == 0
                                  ? MainAxisAlignment.center
                                  : MainAxisAlignment.start,
                              children: [
                                _LoginExperience(
                                  layout: layout,
                                  formKey: _formKey,
                                  heroSection: heroSection,
                                  interfaceModeSection: interfaceModeSection,
                                  credentialsCard: credentialsCard,
                                  advancedSection: advancedServerSection,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _defaultBaseUrl => _appConfig.defaultBaseUrl.trim();

  String _resolveInstallationBaseUrl() {
    final embedded = _defaultBaseUrl;
    if (embedded.isNotEmpty) {
      return embedded;
    }
    final prefs = ref.read(sharedPreferencesProvider);
    return (prefs.getString(_lastBaseUrlStorageKey) ?? '').trim();
  }

  void _toggleAdvancedServer() {
    if (!_appConfig.allowAdvancedServer) {
      return;
    }

    final next = !_showAdvancedServer;
    setState(() {
      _showAdvancedServer = next;
      if (_showAdvancedServer &&
          _baseUrlController.text.trim().isEmpty &&
          _resolvedInstallationBaseUrl.isNotEmpty) {
        _baseUrlController.text = _resolvedInstallationBaseUrl;
      }
    });

    if (next && _isTvDirectionalNavigation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        FocusScope.of(context).requestFocus(_baseUrlFocusNode);
      });
    }
  }

  void _useEmbeddedServer() {
    final embedded = _resolvedInstallationBaseUrl;
    if (embedded.isEmpty) {
      return;
    }

    setState(() {
      _baseUrlController.text = embedded;
    });
  }

  void _toggleObscurePassword() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  String? _validateBaseUrl(String? value) {
    if (!_showAdvancedServer) {
      return null;
    }

    final text = value?.trim() ?? '';
    final uri = Uri.tryParse(text);
    final normalizedScheme = uri?.scheme.toLowerCase();

    if (text.isEmpty) {
      if (_resolvedInstallationBaseUrl.isNotEmpty) {
        return null;
      }
      return 'Informe o servidor (URL base).';
    }

    if (uri == null ||
        !uri.hasScheme ||
        (normalizedScheme != 'http' && normalizedScheme != 'https') ||
        uri.host.trim().isEmpty) {
      return 'Use um endereco completo, por exemplo http://acesso.seuservico.com.';
    }

    return null;
  }

  String? _validateRequired(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Campo obrigatorio.';
    }

    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final resolvedBaseUrl = _resolveBaseUrl();
    if (resolvedBaseUrl.isEmpty) {
      if (_appConfig.allowAdvancedServer && !_showAdvancedServer) {
        setState(() {
          _showAdvancedServer = true;
        });
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_serverMissingMessage)));
      return;
    }

    await ref
        .read(sharedPreferencesProvider)
        .setString(_lastBaseUrlStorageKey, resolvedBaseUrl.trim());

    await ref
        .read(authControllerProvider.notifier)
        .login(
          XtreamCredentials(
            baseUrl: resolvedBaseUrl,
            username: _usernameController.text.trim(),
            password: _passwordController.text.trim(),
          ),
        );
  }

  String _resolveBaseUrl() {
    if (_appConfig.allowAdvancedServer && _showAdvancedServer) {
      final custom = _baseUrlController.text.trim();
      if (custom.isNotEmpty) {
        return custom;
      }
    }

    final embedded = _resolvedInstallationBaseUrl;
    if (embedded.isNotEmpty) {
      return embedded;
    }

    return _baseUrlController.text.trim();
  }

  String get _serverMissingMessage {
    if (_appConfig.allowAdvancedServer) {
      return 'Servidor nao configurado. Abra "Configuracoes avancadas" para informar a URL.';
    }

    return 'Servidor nao configurado nesta build. Defina XTREAM_BASE_URL no ambiente.';
  }

  bool get _isTvDirectionalNavigation {
    return MediaQuery.navigationModeOf(context) == NavigationMode.directional;
  }

  bool get _shouldHandleTvKeyboard {
    final layout = DeviceLayout.of(context);
    return layout.isTv || _isTvDirectionalNavigation;
  }

  void _handleTvFieldFocusChanged() {
    if (!_shouldHandleTvKeyboard) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final activeFocus = _activeEditableFocusNode;
      if (!identical(activeFocus, _tvEditingFocusNode) &&
          _tvEditingFocusNode != null) {
        setState(() {
          _tvEditingFocusNode = null;
        });
      }
      SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    });
  }

  bool _isTvFieldEditing(FocusNode focusNode) {
    return _shouldHandleTvKeyboard && identical(_tvEditingFocusNode, focusNode);
  }

  KeyEventResult _handleTvFieldKeyEvent(FocusNode node, KeyEvent event) {
    if (!_shouldHandleTvKeyboard || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.gameButtonA) {
      _requestKeyboardForTv(focusNode: node, force: true);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      FocusScope.of(context).nextFocus();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      FocusScope.of(context).previousFocus();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  FocusNode? get _activeEditableFocusNode {
    if (_usernameFocusNode.hasFocus) {
      return _usernameFocusNode;
    }
    if (_passwordFocusNode.hasFocus) {
      return _passwordFocusNode;
    }
    if (_baseUrlFocusNode.hasFocus) {
      return _baseUrlFocusNode;
    }
    return null;
  }

  void _requestKeyboardForTv({FocusNode? focusNode, bool force = false}) {
    if (!_shouldHandleTvKeyboard) {
      return;
    }
    final target = focusNode ?? _activeEditableFocusNode;
    if (target == null) {
      return;
    }
    if (!target.hasFocus) {
      FocusScope.of(context).requestFocus(target);
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (!force && (nowMs - _lastKeyboardRequestMs) < 220) {
      return;
    }
    _lastKeyboardRequestMs = nowMs;
    if (!identical(_tvEditingFocusNode, target)) {
      setState(() {
        _tvEditingFocusNode = target;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isTvFieldEditing(target)) {
        return;
      }
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    });
  }
}

// ignore: unused_element
class _InterfaceModeSelector extends StatelessWidget {
  const _InterfaceModeSelector({
    required this.layout,
    required this.mode,
    required this.onChanged,
  });

  final DeviceLayout layout;
  final InterfaceMode mode;
  final ValueChanged<InterfaceMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (layout.isTv) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          layout.cardPadding,
          14,
          layout.cardPadding,
          12,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xD2121C2C), Color(0xB5162234)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(layout.cardBorderRadius),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.34),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interface',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Theme(
              data: Theme.of(context).copyWith(
                segmentedButtonTheme: SegmentedButtonThemeData(
                  style: ButtonStyle(
                    minimumSize: const WidgetStatePropertyAll<Size>(
                      Size.fromHeight(50),
                    ),
                    backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return colorScheme.secondary.withValues(alpha: 0.16);
                      }
                      return const Color(0xFF111B2C);
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith<Color?>((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return colorScheme.onSurface;
                      }
                      return colorScheme.onSurface.withValues(alpha: 0.82);
                    }),
                    side: WidgetStateProperty.resolveWith<BorderSide?>((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return BorderSide(
                          color: colorScheme.secondary.withValues(alpha: 0.62),
                          width: 1.2,
                        );
                      }
                      return BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.34),
                      );
                    }),
                    textStyle: WidgetStatePropertyAll<TextStyle?>(
                      Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              child: SegmentedButton<InterfaceMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<InterfaceMode>(
                    value: InterfaceMode.auto,
                    icon: Icon(Icons.tune_rounded),
                    label: Text('Auto'),
                  ),
                  ButtonSegment<InterfaceMode>(
                    value: InterfaceMode.mobile,
                    icon: Icon(Icons.smartphone_rounded),
                    label: Text('Mobile'),
                  ),
                  ButtonSegment<InterfaceMode>(
                    value: InterfaceMode.tv,
                    icon: Icon(Icons.tv_rounded),
                    label: Text('TV'),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (selection) {
                  if (selection.isNotEmpty) {
                    onChanged(selection.first);
                  }
                },
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        layout.cardPadding,
        layout.isTv ? 18 : 16,
        layout.cardPadding,
        layout.isTv ? 16 : 14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.cardBorderRadius),
        gradient: const LinearGradient(
          colors: [Color(0xD2121C2C), Color(0xB5162234)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: colorScheme.primary.withValues(alpha: 0.14),
            ),
            child: Text(
              'Preferencia de interface',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.24,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Escolha como o app deve abrir',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: layout.isTv ? 22 : 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A identidade visual continua a mesma; aqui voce so define o comportamento de interface.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.78),
            ),
          ),
          SizedBox(height: layout.sectionSpacing - 2),
          Theme(
            data: Theme.of(context).copyWith(
              segmentedButtonTheme: SegmentedButtonThemeData(
                style: ButtonStyle(
                  minimumSize: WidgetStatePropertyAll<Size>(
                    Size.fromHeight(layout.isTv ? 58 : 52),
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                    states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return colorScheme.secondary.withValues(alpha: 0.16);
                    }
                    return const Color(0xFF111B2C);
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith<Color?>((
                    states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return colorScheme.onSurface;
                    }
                    return colorScheme.onSurface.withValues(alpha: 0.82);
                  }),
                  side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return BorderSide(
                        color: colorScheme.secondary.withValues(alpha: 0.62),
                        width: 1.2,
                      );
                    }
                    return BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.34),
                    );
                  }),
                  textStyle: WidgetStatePropertyAll<TextStyle?>(
                    Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            child: SegmentedButton<InterfaceMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment<InterfaceMode>(
                  value: InterfaceMode.auto,
                  icon: Icon(Icons.tune_rounded),
                  label: Text('Auto'),
                ),
                ButtonSegment<InterfaceMode>(
                  value: InterfaceMode.mobile,
                  icon: Icon(Icons.smartphone_rounded),
                  label: Text('Mobile'),
                ),
                ButtonSegment<InterfaceMode>(
                  value: InterfaceMode.tv,
                  icon: Icon(Icons.tv_rounded),
                  label: Text('TV'),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) {
                  onChanged(selection.first);
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            switch (mode) {
              InterfaceMode.auto =>
                'Auto (recomendado): detecta o dispositivo automaticamente.',
              InterfaceMode.mobile =>
                'Mobile: forca layout de celular/tablet nesta instalacao.',
              InterfaceMode.tv =>
                'TV: forca layout Android TV com foco por controle remoto.',
            },
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.76),
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialsCard extends StatelessWidget {
  const _CredentialsCard({
    required this.layout,
    required this.usernameController,
    required this.passwordController,
    required this.usernameFocusNode,
    required this.passwordFocusNode,
    required this.isUsernameEditing,
    required this.isPasswordEditing,
    required this.usesDirectionalNavigation,
    required this.isSubmitting,
    required this.obscurePassword,
    required this.onRequestKeyboard,
    required this.onToggleObscurePassword,
    required this.onSubmit,
    required this.validateRequired,
  });

  final DeviceLayout layout;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final FocusNode usernameFocusNode;
  final FocusNode passwordFocusNode;
  final bool isUsernameEditing;
  final bool isPasswordEditing;
  final bool usesDirectionalNavigation;
  final bool isSubmitting;
  final bool obscurePassword;
  final ValueChanged<FocusNode> onRequestKeyboard;
  final VoidCallback onToggleObscurePassword;
  final VoidCallback onSubmit;
  final String? Function(String?) validateRequired;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fieldTextStyle = layout.isTv
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          )
        : null;
    final passwordVisibilityButton = IconButton(
      icon: Icon(
        obscurePassword
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
      ),
      onPressed: onToggleObscurePassword,
      tooltip: obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.cardBorderRadius),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.34)),
        gradient: const LinearGradient(
          colors: [Color(0xF0182436), Color(0xD5172232)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 32,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(layout.isTv ? 18 : layout.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: _TvFieldNavigationShortcuts(
                enabled: usesDirectionalNavigation,
                onActivate: () => onRequestKeyboard(usernameFocusNode),
                child: _FieldShell(
                  focusNode: usernameFocusNode,
                  borderRadius: 22,
                  child: TextFormField(
                    key: AppTestKeys.loginUsernameField,
                    controller: usernameController,
                    focusNode: usernameFocusNode,
                    autofocus: usesDirectionalNavigation,
                    readOnly: usesDirectionalNavigation && !isUsernameEditing,
                    showCursor: !usesDirectionalNavigation || isUsernameEditing,
                    style: fieldTextStyle,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    onTap: () => onRequestKeyboard(usernameFocusNode),
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(passwordFocusNode);
                    },
                    decoration: _buildFieldDecoration(
                      context,
                      labelText: 'Usuario',
                      icon: Icons.person_outline_rounded,
                    ),
                    validator: validateRequired,
                  ),
                ),
              ),
            ),
            SizedBox(height: layout.isTv ? 14 : layout.sectionSpacing),
            FocusTraversalOrder(
              order: const NumericFocusOrder(2),
              child: _TvFieldNavigationShortcuts(
                enabled: usesDirectionalNavigation,
                onActivate: () => onRequestKeyboard(passwordFocusNode),
                child: _FieldShell(
                  focusNode: passwordFocusNode,
                  borderRadius: 22,
                  child: TextFormField(
                    key: AppTestKeys.loginPasswordField,
                    controller: passwordController,
                    focusNode: passwordFocusNode,
                    readOnly: usesDirectionalNavigation && !isPasswordEditing,
                    showCursor: !usesDirectionalNavigation || isPasswordEditing,
                    style: fieldTextStyle,
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onTap: () => onRequestKeyboard(passwordFocusNode),
                    decoration: _buildFieldDecoration(
                      context,
                      labelText: 'Senha',
                      icon: Icons.lock_outline_rounded,
                      suffixIcon: usesDirectionalNavigation
                          ? ExcludeFocus(child: passwordVisibilityButton)
                          : passwordVisibilityButton,
                    ),
                    onFieldSubmitted: (_) => onSubmit(),
                    validator: validateRequired,
                  ),
                ),
              ),
            ),
            SizedBox(height: layout.isTv ? 16 : layout.sectionSpacing + 4),
            FocusTraversalOrder(
              order: const NumericFocusOrder(3),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: AppTestKeys.loginSubmitButton,
                  style:
                      FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: Size(0, layout.isTv ? 54 : 60),
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: layout.isTv ? 12 : 18,
                        ),
                        textStyle: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: layout.isTv ? 24 : 19,
                              fontWeight: FontWeight.w800,
                            ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            layout.isTv ? 22 : 22,
                          ),
                        ),
                        elevation: 0,
                      ).copyWith(
                        side: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.focused)) {
                            return BorderSide(
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.9,
                              ),
                              width: 2,
                            );
                          }
                          return BorderSide.none;
                        }),
                      ),
                  onPressed: isSubmitting ? null : onSubmit,
                  icon: isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login_rounded),
                  label: Text(isSubmitting ? 'Conectando...' : 'Entrar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildFieldDecoration(
    BuildContext context, {
    required String labelText,
    required IconData icon,
    Widget? suffixIcon,
    String? hintText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(layout.isTv ? 22 : 22);

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: const Color(0xFF182436),
      prefixIcon: Icon(icon, size: layout.isTv ? 22 : 22),
      suffixIcon: suffixIcon,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: layout.isTv ? 10 : 18,
      ),
      hintStyle: TextStyle(
        color: colorScheme.onSurface.withValues(alpha: 0.52),
        fontSize: layout.isTv ? 18 : 16,
      ),
      labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.22),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.92),
          width: 1.7,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: colorScheme.error.withValues(alpha: 0.88),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: colorScheme.error, width: 1.7),
      ),
    );
  }
}

class _LoginExperience extends StatelessWidget {
  const _LoginExperience({
    required this.layout,
    required this.formKey,
    required this.heroSection,
    required this.interfaceModeSection,
    required this.credentialsCard,
    required this.advancedSection,
  });

  final DeviceLayout layout;
  final GlobalKey<FormState> formKey;
  final Widget heroSection;
  final Widget? interfaceModeSection;
  final Widget credentialsCard;
  final Widget advancedSection;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: AutofillGroup(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                heroSection,
                if (interfaceModeSection != null) ...[
                  SizedBox(height: layout.isTv ? 14 : layout.sectionSpacing + 10),
                  interfaceModeSection!,
                ],
                SizedBox(height: layout.isTv ? 16 : layout.sectionSpacing + 14),
                credentialsCard,
                SizedBox(height: layout.isTv ? 10 : layout.sectionSpacing + 8),
                advancedSection,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHeroSection extends StatelessWidget {
  const _LoginHeroSection({required this.layout});

  final DeviceLayout layout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        BrandWordmark(
          height: layout.isTv ? 64 : 62,
          compact: !layout.isTv,
          showTagline: true,
        ),
        SizedBox(height: layout.isTv ? 12 : 18),
        Text(
          'Faca login na sua conta',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: layout.isTv ? 36 : 34,
            height: 1.04,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (!layout.isTv) ...[
          const SizedBox(height: 10),
          Text(
            'Entre com suas credenciais para continuar.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.76),
            ),
          ),
        ],
      ],
    );
  }
}

class _AdvancedServerSection extends StatelessWidget {
  const _AdvancedServerSection({
    required this.layout,
    required this.baseUrlController,
    required this.baseUrlFocusNode,
    required this.isBaseUrlEditing,
    required this.showAdvancedServer,
    required this.allowAdvancedServer,
    required this.embeddedBaseUrl,
    required this.onRequestKeyboard,
    required this.onToggleAdvancedServer,
    required this.onUseEmbeddedServer,
    required this.validateBaseUrl,
  });

  final DeviceLayout layout;
  final TextEditingController baseUrlController;
  final FocusNode baseUrlFocusNode;
  final bool isBaseUrlEditing;
  final bool showAdvancedServer;
  final bool allowAdvancedServer;
  final String embeddedBaseUrl;
  final ValueChanged<FocusNode> onRequestKeyboard;
  final VoidCallback onToggleAdvancedServer;
  final VoidCallback onUseEmbeddedServer;
  final String? Function(String?) validateBaseUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasEmbeddedServer = embeddedBaseUrl.trim().isNotEmpty;

    if (!allowAdvancedServer) {
      return layout.isTv
          ? const SizedBox.shrink()
          : hasEmbeddedServer
          ? Text(
              'Servidor padrao configurado no app.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            )
          : const SizedBox.shrink();
    }

    return Column(
      children: [
        FocusTraversalOrder(
          order: const NumericFocusOrder(4),
          child: OutlinedButton.icon(
            onPressed: onToggleAdvancedServer,
            style:
                OutlinedButton.styleFrom(
                  minimumSize: Size(
                    layout.isTv ? 300 : 0,
                    layout.isTv ? 52 : 52,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: layout.isTv ? 26 : 20,
                    vertical: layout.isTv ? 12 : 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ).copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.focused)) {
                      return const Color(0x99162133);
                    }
                    return const Color(0x66111A29);
                  }),
                  foregroundColor: WidgetStatePropertyAll(
                    colorScheme.onSurface.withValues(alpha: 0.9),
                  ),
                  side: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.focused)) {
                      return BorderSide(
                        color: colorScheme.primary.withValues(alpha: 0.92),
                        width: 1.6,
                      );
                    }
                    return BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.42),
                    );
                  }),
                ),
            icon: Icon(
              showAdvancedServer
                  ? Icons.expand_less_rounded
                  : Icons.settings_rounded,
            ),
            label: Text(
              showAdvancedServer
                  ? 'Ocultar configuracoes avancadas'
                  : 'Configuracoes avancadas',
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: showAdvancedServer
              ? Container(
                  key: const ValueKey('advanced-server-visible'),
                  width: double.infinity,
                  margin: EdgeInsets.only(top: layout.sectionSpacing),
                  padding: EdgeInsets.all(
                    layout.isTv ? 18 : layout.cardPadding,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      layout.isTv ? 24 : layout.cardBorderRadius,
                    ),
                    color: const Color(0xA7172234),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Use apenas quando precisar informar ou trocar manualmente o servidor desta instalacao.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.74),
                        ),
                      ),
                      SizedBox(height: layout.sectionSpacing - 4),
                      FocusTraversalOrder(
                        order: const NumericFocusOrder(5),
                        child: _TvFieldNavigationShortcuts(
                          enabled: layout.isTv,
                          onActivate: () => onRequestKeyboard(baseUrlFocusNode),
                          child: _FieldShell(
                            focusNode: baseUrlFocusNode,
                            borderRadius: 22,
                            child: TextFormField(
                              key: AppTestKeys.loginBaseUrlField,
                              controller: baseUrlController,
                              focusNode: baseUrlFocusNode,
                              readOnly: layout.isTv && !isBaseUrlEditing,
                              showCursor: !layout.isTv || isBaseUrlEditing,
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.url],
                              onTap: () => onRequestKeyboard(baseUrlFocusNode),
                              decoration: _buildServerFieldDecoration(context),
                              validator: validateBaseUrl,
                            ),
                          ),
                        ),
                      ),
                      if (hasEmbeddedServer)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: TextButton(
                            onPressed: onUseEmbeddedServer,
                            child: const Text('Usar servidor padrao'),
                          ),
                        ),
                    ],
                  ),
                )
              : Padding(
                  key: const ValueKey('advanced-server-hidden'),
                  padding: EdgeInsets.only(top: layout.isTv ? 0 : 8),
                  child: layout.isTv
                      ? const SizedBox.shrink()
                      : Text(
                          hasEmbeddedServer
                              ? 'Servidor padrao configurado no app.'
                              : 'Servidor padrao nao configurado nesta build.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.72,
                                ),
                              ),
                        ),
                ),
        ),
      ],
    );
  }

  InputDecoration _buildServerFieldDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(layout.isTv ? 22 : 22);

    return InputDecoration(
      labelText: 'Servidor',
      hintText: 'http://acesso.seuservico.com',
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: const Color(0xFF182436),
      prefixIcon: Icon(Icons.public_rounded, size: layout.isTv ? 22 : 22),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: layout.isTv ? 10 : 18,
      ),
      hintStyle: TextStyle(
        color: colorScheme.onSurface.withValues(alpha: 0.52),
        fontSize: layout.isTv ? 18 : 16,
      ),
      labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.22),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.92),
          width: 1.7,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: colorScheme.error.withValues(alpha: 0.88),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: colorScheme.error, width: 1.7),
      ),
    );
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({
    required this.focusNode,
    required this.borderRadius,
    required this.child,
  });

  final FocusNode focusNode;
  final double borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius + 2),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.18),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                  ]
                : const [],
          ),
          child: child,
        );
      },
    );
  }
}

class _TvFieldNavigationShortcuts extends StatelessWidget {
  const _TvFieldNavigationShortcuts({
    required this.enabled,
    required this.onActivate,
    required this.child,
  });

  final bool enabled;
  final VoidCallback onActivate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.select): onActivate,
        const SingleActivator(LogicalKeyboardKey.enter): onActivate,
        const SingleActivator(LogicalKeyboardKey.gameButtonA): onActivate,
        const SingleActivator(LogicalKeyboardKey.arrowDown): () {
          SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
          FocusScope.of(context).nextFocus();
        },
        const SingleActivator(LogicalKeyboardKey.arrowUp): () {
          SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
          FocusScope.of(context).previousFocus();
        },
      },
      child: child,
    );
  }
}

class _BackgroundOrb extends StatelessWidget {
  const _BackgroundOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}
