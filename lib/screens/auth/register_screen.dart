import 'package:flutter/material.dart';

import 'package:first_mqtt_app/widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const int _minPasswordLength = 8;

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // TODO(auth): call the register API here before navigating.

    // The login screen is right underneath, so going back = going to login.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Account created. Please log in.'),
        ),
      );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthLayout(
      showBack: true,
      title: 'Create account',
      subtitle: 'Register to start using the Ecoprint app.',
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  controller: _name,
                  label: 'Name',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  validator: (v) =>
                      AuthValidators.required(v, 'Enter your name'),
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _email,
                  label: 'Email',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: AuthValidators.email,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _password,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) =>
                      AuthValidators.password(v, minLength: _minPasswordLength),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: _submit,
                  child: const Text('Register'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Already have an account?', style: theme.textTheme.bodyMedium),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Log in'),
            ),
          ],
        ),
      ],
    );
  }
}
