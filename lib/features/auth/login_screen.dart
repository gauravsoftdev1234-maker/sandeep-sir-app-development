import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import 'auth_controller.dart';
import 'validators.dart';
import 'widgets/entry_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobile = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _mobile.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _busy = true);
    final error = await ref
        .read(authProvider.notifier)
        .login(
          mobileNumber: _mobile.text.trim(),
          password: _password.text,
          // TODO: pass the real FCM token once push notifications are set up.
          fcmToken: '',
        );
    if (!mounted) return;
    setState(() => _busy = false);

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
    // On success the router redirect moves us to the shell automatically.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return EntryScaffold(
      child: Column(
        children: [
          Expanded(
            // Centres the form in the white area on tall screens while still
            // scrolling when the keyboard or a small screen squeezes it.
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Clears the crest of the wave in the artwork.
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Welcome Back',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Login to your account and continue with all services',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.brandDeep.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      EntryFieldTheme(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _mobile,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                maxLength: 10,
                                enabled: !_busy,
                                decoration: const InputDecoration(
                                  hintText: 'Mobile Number',
                                  counterText: '',
                                  prefixIcon: Icon(Icons.smartphone_rounded),
                                ),
                                validator: Validators.mobile,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                enabled: !_busy,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: Validators.loginPassword,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: ArrowLabel('Login', busy: _busy),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.brandDeep.withValues(alpha: 0.7),
                            ),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => context.push(Routes.register),
                            child: const Text('Register'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const ServiceStrip(),
        ],
      ),
    );
  }
}
