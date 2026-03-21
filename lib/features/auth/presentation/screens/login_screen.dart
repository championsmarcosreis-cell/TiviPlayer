import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/testing/app_test_keys.dart';
import '../../../../shared/presentation/layout/device_layout.dart';
import '../../../../shared/widgets/app_scaffold.dart';
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
  late final TextEditingController _baseUrlController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController();
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
    final usesDirectionalNavigation =
        MediaQuery.navigationModeOf(context) == NavigationMode.directional;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return AppScaffold(
      title: 'Acesse sua assinatura',
      subtitle: 'Layout otimizado para Android TV e Android mobile.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = DeviceLayout.of(context, constraints: constraints);
          final isWide = layout.isTv || constraints.maxWidth >= 980;

          return Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: keyboardInset + layout.cardSpacing,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: layout.isTv ? 1180 : 1080,
                    ),
                    child: IntrinsicHeight(
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 11,
                                  child: _LoginBrandPanel(
                                    isWide: true,
                                    layout: layout,
                                  ),
                                ),
                                SizedBox(width: layout.cardSpacing),
                                Expanded(
                                  flex: 10,
                                  child: _LoginFormCard(
                                    layout: layout,
                                    formKey: _formKey,
                                    baseUrlController: _baseUrlController,
                                    usernameController: _usernameController,
                                    passwordController: _passwordController,
                                    usesDirectionalNavigation:
                                        usesDirectionalNavigation,
                                    isSubmitting: isSubmitting,
                                    onSubmit: _submit,
                                    validateBaseUrl: _validateBaseUrl,
                                    validateRequired: _validateRequired,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _LoginBrandPanel(isWide: false, layout: layout),
                                SizedBox(height: layout.cardSpacing),
                                _LoginFormCard(
                                  layout: layout,
                                  formKey: _formKey,
                                  baseUrlController: _baseUrlController,
                                  usernameController: _usernameController,
                                  passwordController: _passwordController,
                                  usesDirectionalNavigation:
                                      usesDirectionalNavigation,
                                  isSubmitting: isSubmitting,
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
            ),
          );
        },
      ),
    );
  }

  String? _validateBaseUrl(String? value) {
    final text = value?.trim() ?? '';
    final uri = Uri.tryParse(text);

    if (text.isEmpty) {
      return 'Informe o endereço de acesso.';
    }

    if (uri == null ||
        !uri.hasScheme ||
        (uri.host.isEmpty && uri.path.isEmpty)) {
      return 'Use um endereço completo, por exemplo http://acesso.seuservico.com.';
    }

    return null;
  }

  String? _validateRequired(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Campo obrigatório.';
    }

    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .login(
          XtreamCredentials(
            baseUrl: _baseUrlController.text.trim(),
            username: _usernameController.text.trim(),
            password: _passwordController.text.trim(),
          ),
        );
  }
}

class _LoginBrandPanel extends StatelessWidget {
  const _LoginBrandPanel({required this.isWide, required this.layout});

  final bool isWide;
  final DeviceLayout layout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final logoWidth = layout.isTv ? 280.0 : (isWide ? 240.0 : 210.0);
    final cardPadding = isWide ? layout.cardPadding + 6 : layout.cardPadding;
    final featureWidth = layout.isMobilePortrait ? double.infinity : 220.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BrandLogo(width: logoWidth),
            SizedBox(height: layout.sectionSpacing + 8),
            Text(
              'Entre e continue assistindo sem fricção.',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: layout.isTv ? 38 : 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Acesso com navegação previsível no controle remoto, rolagem segura em telas menores e credenciais armazenadas somente neste aparelho.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: layout.sectionSpacing + 6),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _BrandFeature(
                  width: featureWidth,
                  icon: Icons.tv_rounded,
                  title: 'Pronto para TV',
                  description: 'Foco previsível e ação rápida pelo D-pad.',
                ),
                _BrandFeature(
                  width: featureWidth,
                  icon: Icons.mobile_friendly_rounded,
                  title: 'Também no celular',
                  description: 'Campos e CTA confortáveis em telas menores.',
                ),
                _BrandFeature(
                  width: featureWidth,
                  icon: Icons.lock_outline_rounded,
                  title: 'Sessão local',
                  description: 'Os dados ficam salvos apenas no dispositivo.',
                ),
              ],
            ),
            SizedBox(height: layout.sectionSpacing + 2),
            Container(
              padding: EdgeInsets.all(layout.isTv ? 20 : 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(layout.isTv ? 24 : 20),
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.65,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Use o endereço de acesso, usuário e senha fornecidos com sua assinatura.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandFeature extends StatelessWidget {
  const _BrandFeature({
    required this.width,
    required this.icon,
    required this.title,
    required this.description,
  });

  final double width;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard({
    required this.layout,
    required this.formKey,
    required this.baseUrlController,
    required this.usernameController,
    required this.passwordController,
    required this.usesDirectionalNavigation,
    required this.isSubmitting,
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
  final VoidCallback onSubmit;
  final String? Function(String?) validateBaseUrl;
  final String? Function(String?) validateRequired;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(
      context,
    ).textTheme.headlineMedium?.copyWith(fontSize: layout.isTv ? 34 : 30);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(layout.cardPadding),
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: AutofillGroup(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Conectar', style: titleStyle),
                  SizedBox(height: layout.isTv ? 10 : 8),
                  Text(
                    'Informe os dados da sua assinatura para liberar o catálogo.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: layout.sectionSpacing + 8),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(1),
                    child: TextFormField(
                      key: AppTestKeys.loginBaseUrlField,
                      controller: baseUrlController,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                      autofocus: usesDirectionalNavigation,
                      autofillHints: const [AutofillHints.url],
                      decoration: const InputDecoration(
                        labelText: 'Endereço de acesso',
                        hintText: 'http://acesso.seuservico.com',
                        prefixIcon: Icon(Icons.public_rounded),
                      ),
                      validator: validateBaseUrl,
                    ),
                  ),
                  SizedBox(height: layout.sectionSpacing),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(2),
                    child: TextFormField(
                      key: AppTestKeys.loginUsernameField,
                      controller: usernameController,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                        labelText: 'Usuário',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: validateRequired,
                    ),
                  ),
                  SizedBox(height: layout.sectionSpacing),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(3),
                    child: TextFormField(
                      key: AppTestKeys.loginPasswordField,
                      controller: passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      onFieldSubmitted: (_) => onSubmit(),
                      validator: validateRequired,
                    ),
                  ),
                  SizedBox(height: layout.sectionSpacing + 8),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(4),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: AppTestKeys.loginSubmitButton,
                        onPressed: isSubmitting ? null : onSubmit,
                        child: isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Entrar'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Os dados de acesso permanecem locais e podem ser removidos ao sair da conta.',
                    style: Theme.of(context).textTheme.bodySmall,
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
