import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/testing/app_test_keys.dart';
import '../../../../shared/widgets/app_scaffold.dart';
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

    return AppScaffold(
      title: 'TiviPlayer',
      subtitle: 'Login Xtream para Android TV e mobile',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text(
                      'Conectar',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'As credenciais são validadas diretamente em '
                      '`player_api.php` e não ficam hardcoded no app.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      key: AppTestKeys.loginBaseUrlField,
                      controller: _baseUrlController,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.url],
                      decoration: const InputDecoration(
                        labelText: 'Base URL',
                        hintText: 'http://servidor:porta',
                      ),
                      validator: _validateBaseUrl,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: AppTestKeys.loginUsernameField,
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(labelText: 'Usuário'),
                      validator: _validateRequired,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: AppTestKeys.loginPasswordField,
                      controller: _passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(labelText: 'Senha'),
                      onFieldSubmitted: (_) => _submit(),
                      validator: _validateRequired,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      key: AppTestKeys.loginSubmitButton,
                      onPressed: isSubmitting ? null : _submit,
                      child: isSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Dica: mantenha `api.txt` apenas local para referência '
                      'operacional. O app usa entrada manual e o Git ignora esse arquivo.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateBaseUrl(String? value) {
    final text = value?.trim() ?? '';
    final uri = Uri.tryParse(text);

    if (text.isEmpty) {
      return 'Informe a base URL.';
    }

    if (uri == null ||
        !uri.hasScheme ||
        (uri.host.isEmpty && uri.path.isEmpty)) {
      return 'Use uma URL completa, por exemplo http://host:porta.';
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
