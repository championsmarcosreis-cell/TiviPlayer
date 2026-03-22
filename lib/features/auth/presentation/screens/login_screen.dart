import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/presentation/controllers/interface_mode_controller.dart';
import '../../../../shared/presentation/layout/device_layout.dart';
import '../../../../shared/presentation/layout/interface_mode_scope.dart';
import '../../../../shared/testing/app_test_keys.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../domain/entities/xtream_credentials.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const routePath = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  static const _embeddedBaseUrlFromApi = 'http://179.42.145.74:8080';
  static const _embeddedBaseUrlPrimary = String.fromEnvironment(
    'XTREAM_BASE_URL',
    defaultValue: _embeddedBaseUrlFromApi,
  );
  static const _embeddedBaseUrlFallback = String.fromEnvironment(
    'TIVIPLAYER_BASE_URL',
    defaultValue: _embeddedBaseUrlFromApi,
  );

  late final TextEditingController _baseUrlController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  var _showAdvancedServer = false;
  var _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(text: _embeddedBaseUrl);
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
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
    final isSubmitting = authState.status == AuthStatus.authenticating;
    final interfaceMode = ref.watch(interfaceModeControllerProvider);
    final usesDirectionalNavigation =
        MediaQuery.navigationModeOf(context) == NavigationMode.directional;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF03060D), Color(0xFF0A1321), Color(0xFF060B13)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -210,
              right: -180,
              child: _BackgroundOrb(
                size: 460,
                colors: [Color(0x26FF6A1A), Color(0x00FF6A1A)],
              ),
            ),
            const Positioned(
              bottom: -260,
              left: -150,
              child: _BackgroundOrb(
                size: 520,
                colors: [Color(0x1E16C7FF), Color(0x00E33DFF)],
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final layout = DeviceLayout.of(
                    context,
                    constraints: constraints,
                  );
                  final compactHeader = constraints.maxHeight < 740;

                  return Scrollbar(
                    thumbVisibility: false,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        layout.pageHorizontalPadding,
                        layout.pageTopPadding,
                        layout.pageHorizontalPadding,
                        layout.pageBottomPadding + keyboardInset,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: layout.isTv ? 840 : 560,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                BrandWordmark(
                                  height: layout.isTv ? 68 : 52,
                                  compact: !layout.isTv,
                                  showTagline: false,
                                ),
                                SizedBox(height: layout.isTv ? 20 : 14),
                                Text(
                                  compactHeader
                                      ? 'Entre para continuar'
                                      : 'Digite suas credenciais para acessar',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.86),
                                        fontSize: layout.isTv ? 24 : 18,
                                      ),
                                ),
                                SizedBox(height: layout.sectionSpacing + 8),
                                _InterfaceModeSelector(
                                  layout: layout,
                                  mode: interfaceMode,
                                  onChanged: (mode) {
                                    ref
                                        .read(
                                          interfaceModeControllerProvider
                                              .notifier,
                                        )
                                        .setMode(mode);
                                  },
                                ),
                                SizedBox(height: layout.sectionSpacing + 8),
                                _CredentialsCard(
                                  layout: layout,
                                  formKey: _formKey,
                                  baseUrlController: _baseUrlController,
                                  usernameController: _usernameController,
                                  passwordController: _passwordController,
                                  usesDirectionalNavigation:
                                      usesDirectionalNavigation,
                                  isSubmitting: isSubmitting,
                                  showAdvancedServer: _showAdvancedServer,
                                  embeddedBaseUrl: _embeddedBaseUrl,
                                  obscurePassword: _obscurePassword,
                                  onToggleAdvancedServer: _toggleAdvancedServer,
                                  onUseEmbeddedServer: _useEmbeddedServer,
                                  onToggleObscurePassword:
                                      _toggleObscurePassword,
                                  onSubmit: _submit,
                                  validateBaseUrl: _validateBaseUrl,
                                  validateRequired: _validateRequired,
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

  static String get _embeddedBaseUrl {
    final primary = _embeddedBaseUrlPrimary.trim();
    if (primary.isNotEmpty) {
      return primary;
    }

    return _embeddedBaseUrlFallback.trim();
  }

  void _toggleAdvancedServer() {
    setState(() {
      _showAdvancedServer = !_showAdvancedServer;
      if (_showAdvancedServer &&
          _baseUrlController.text.trim().isEmpty &&
          _embeddedBaseUrl.isNotEmpty) {
        _baseUrlController.text = _embeddedBaseUrl;
      }
    });
  }

  void _useEmbeddedServer() {
    final embedded = _embeddedBaseUrl;
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

    if (text.isEmpty) {
      return null;
    }

    if (uri == null ||
        !uri.hasScheme ||
        (uri.host.isEmpty && uri.path.isEmpty)) {
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
      if (!_showAdvancedServer) {
        setState(() {
          _showAdvancedServer = true;
        });
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Servidor nao configurado. Abra "Servidor avancado" para informar a URL.',
            ),
          ),
        );
      return;
    }

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
    if (_showAdvancedServer) {
      final custom = _baseUrlController.text.trim();
      if (custom.isNotEmpty) {
        return custom;
      }
    }

    final embedded = _embeddedBaseUrl;
    if (embedded.isNotEmpty) {
      return embedded;
    }

    return _baseUrlController.text.trim();
  }
}

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

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: layout.cardPadding,
        vertical: layout.isTv ? 14 : 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.cardBorderRadius),
        color: colorScheme.surface.withValues(alpha: 0.66),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interface do app',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: layout.isTv ? 22 : 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escolha como renderizar telas antes de entrar.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.78),
            ),
          ),
          SizedBox(height: layout.sectionSpacing - 2),
          SegmentedButton<InterfaceMode>(
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
    required this.formKey,
    required this.baseUrlController,
    required this.usernameController,
    required this.passwordController,
    required this.usesDirectionalNavigation,
    required this.isSubmitting,
    required this.showAdvancedServer,
    required this.embeddedBaseUrl,
    required this.obscurePassword,
    required this.onToggleAdvancedServer,
    required this.onUseEmbeddedServer,
    required this.onToggleObscurePassword,
    required this.onSubmit,
    required this.validateBaseUrl,
    required this.validateRequired,
  });

  final DeviceLayout layout;
  final GlobalKey<FormState> formKey;
  final TextEditingController baseUrlController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool usesDirectionalNavigation;
  final bool isSubmitting;
  final bool showAdvancedServer;
  final String embeddedBaseUrl;
  final bool obscurePassword;
  final VoidCallback onToggleAdvancedServer;
  final VoidCallback onUseEmbeddedServer;
  final VoidCallback onToggleObscurePassword;
  final VoidCallback onSubmit;
  final String? Function(String?) validateBaseUrl;
  final String? Function(String?) validateRequired;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasEmbeddedServer = embeddedBaseUrl.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(layout.cardBorderRadius),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
        gradient: LinearGradient(
          colors: [
            colorScheme.surface.withValues(alpha: 0.9),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(layout.cardPadding),
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: AutofillGroup(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(1),
                    child: TextFormField(
                      key: AppTestKeys.loginUsernameField,
                      controller: usernameController,
                      autofocus: usesDirectionalNavigation,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: validateRequired,
                    ),
                  ),
                  SizedBox(height: layout.sectionSpacing),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(2),
                    child: TextFormField(
                      key: AppTestKeys.loginPasswordField,
                      controller: passwordController,
                      obscureText: obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: onToggleObscurePassword,
                          tooltip: obscurePassword
                              ? 'Mostrar senha'
                              : 'Ocultar senha',
                        ),
                      ),
                      onFieldSubmitted: (_) => onSubmit(),
                      validator: validateRequired,
                    ),
                  ),
                  SizedBox(height: layout.sectionSpacing + 4),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(3),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: AppTestKeys.loginSubmitButton,
                        onPressed: isSubmitting ? null : onSubmit,
                        icon: isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.login_rounded),
                        label: Text(isSubmitting ? 'Conectando...' : 'Entrar'),
                      ),
                    ),
                  ),
                  SizedBox(height: layout.sectionSpacing),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: onToggleAdvancedServer,
                        icon: Icon(
                          showAdvancedServer
                              ? Icons.expand_less_rounded
                              : Icons.tune_rounded,
                          size: 18,
                        ),
                        label: Text(
                          showAdvancedServer
                              ? 'Ocultar servidor avancado'
                              : 'Servidor avancado',
                        ),
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: showAdvancedServer
                        ? Padding(
                            key: const ValueKey('advanced-server-visible'),
                            padding: EdgeInsets.only(
                              top: layout.sectionSpacing - 2,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Use apenas quando precisar trocar o servidor desta instalacao.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.74,
                                        ),
                                      ),
                                ),
                                SizedBox(height: layout.sectionSpacing - 4),
                                FocusTraversalOrder(
                                  order: const NumericFocusOrder(5),
                                  child: TextFormField(
                                    key: AppTestKeys.loginBaseUrlField,
                                    controller: baseUrlController,
                                    keyboardType: TextInputType.url,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [AutofillHints.url],
                                    decoration: const InputDecoration(
                                      labelText: 'Servidor',
                                      hintText: 'http://acesso.seuservico.com',
                                      prefixIcon: Icon(Icons.public_rounded),
                                    ),
                                    validator: validateBaseUrl,
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
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
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
              ),
            ),
          ),
        ),
      ),
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
