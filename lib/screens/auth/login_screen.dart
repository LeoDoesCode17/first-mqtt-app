import 'package:flutter/material.dart';

import 'package:first_mqtt_app/screens/auth/register_screen.dart';
import 'package:first_mqtt_app/screens/home_shell.dart';
import 'package:first_mqtt_app/widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // TODO(auth): call the login API here before navigating.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeShell()),
    );
  }

  void _openRegister() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthLayout(
      title: 'Welcome back',
      subtitle: 'Log in to monitor and control your Ecoprint.',
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  autofillHints: const [AutofillHints.password],
                  validator: (v) => AuthValidators.password(v),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: _submit,
                  child: const Text('Log in'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Don't have an account?", style: theme.textTheme.bodyMedium),
            TextButton(onPressed: _openRegister, child: const Text('Register')),
          ],
        ),
      ],
    );
  }
}
