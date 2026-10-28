import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/location/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import 'auth_controller.dart';
import 'validators.dart';
import 'widgets/entry_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _busy = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _busy = true);

    // Best effort: an unavailable fix sends 0,0 rather than blocking sign-up.
    final location = await ref.read(locationServiceProvider).current();

    final error = await ref
        .read(authProvider.notifier)
        .register(
          userName: _name.text.trim(),
          mobileNumber: _mobile.text.trim(),
          emailId: _email.text.trim(),
          password: _password.text,
          confirmPassword: _confirmPassword.text,
          latitude: location.latitude,
          longitude: location.longitude,
        );
    if (!mounted) return;
    setState(() => _busy = false);

    final messenger = ScaffoldMessenger.of(context);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Registered. You can log in now.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return EntryScaffold(
      heroFactor: 0.22,
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
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Create Account',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Join SevaHub Partner and get access to all services',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.brandDeep.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      EntryFieldTheme(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _name,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                enabled: !_busy,
                                decoration: const InputDecoration(
                                  hintText: 'User Name',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) =>
                                    Validators.required(value, 'User name'),
                              ),
                              const SizedBox(height: AppSpacing.md),
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
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                enabled: !_busy,
                                decoration: const InputDecoration(
                                  hintText: 'Email Id',
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                                validator: Validators.email,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.next,
                                enabled: !_busy,
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
                                validator: Validators.password,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: _confirmPassword,
                                obscureText: _obscureConfirm,
                                textInputAction: TextInputAction.done,
                                enabled: !_busy,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  hintText: 'Confirm Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    ),
                                  ),
                                ),
                                validator: (value) =>
                                    Validators.confirmPassword(
                                      value,
                                      _password.text,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: ArrowLabel('Register', busy: _busy),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.brandDeep.withValues(alpha: 0.7),
                            ),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
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
