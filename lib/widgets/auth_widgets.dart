import 'package:flutter/material.dart';

import 'package:first_mqtt_app/core/theme.dart';

/// Shared page layout for the login / register screens: logo, title,
/// subtitle and a centred, scrollable column that stays narrow on tablets.
class AuthLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showBack;

  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: showBack ? AppBar() : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.ok.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco,
                        size: 38,
                        color: AppColors.ok,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined text field with a leading icon, used by both auth screens.
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      autocorrect: false,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

/// Password field with a show/hide toggle.
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.autofillHints,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      autofillHints: widget.autofillHints,
      autocorrect: false,
      enableSuggestions: false,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Show password' : 'Hide password',
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

/// Input checks shared by both screens (format only, no auth logic).
class AuthValidators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? required(String? v, String message) =>
      (v == null || v.trim().isEmpty) ? message : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your email';
    return _email.hasMatch(v.trim()) ? null : 'Enter a valid email address';
  }

  static String? password(String? v, {int minLength = 1}) {
    if (v == null || v.isEmpty) return 'Enter your password';
    return v.length < minLength ? 'Use at least $minLength characters' : null;
  }
}
