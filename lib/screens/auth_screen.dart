import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/ui.dart';
import 'policy_screen.dart';

/// Sign in / create account. Pops with `true` once the person is signed in,
/// so callers (e.g. checkout) can continue what they were doing.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.startOnRegister = false});
  final bool startOnRegister;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late bool _register = widget.startOnRegister;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final auth = ref.read(authProvider.notifier);
      if (_register) {
        await auth.register(_name.text, _email.text, _password.text);
      } else {
        await auth.login(_email.text, _password.text);
      }
      TextInput.finishAutofillContext();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final mapped = ApiException.from(error);
      setState(() {
        _error = mapped.statusCode == 401 || mapped.statusCode == 400
            ? (_register
                ? mapped.message
                : 'Incorrect email or password. Please try again.')
            : mapped.message;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _register = !_register;
      _error = null;
      _obscure = true;
    });
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_register ? 'Create account' : 'Sign in')),
      body: SafeArea(
        child: ContentWidth(
          maxWidth: 480,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              const SizedBox(height: 8),
              const Center(child: BrandLogo(size: 88, radius: 22)),
              const SizedBox(height: 20),
              Text(
                _register ? 'Join NaijaMart' : 'Welcome back',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                _register
                    ? 'Create an account to checkout and track your orders.'
                    : 'Sign in to checkout and see your orders.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.error.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: scheme.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_error!,
                              style: TextStyle(color: scheme.error, height: 1.35)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_register) ...[
                        TextFormField(
                          controller: _name,
                          enabled: !_busy,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                          validator: (v) => (v == null || v.trim().length < 2)
                              ? 'Please enter your full name'
                              : null,
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: _email,
                        focusNode: _emailFocus,
                        enabled: !_busy,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                        validator: (v) {
                          final input = v?.trim() ?? '';
                          if (input.isEmpty) return 'Please enter your email address';
                          if (!isValidEmail(input)) return 'Enter a valid email address';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        focusNode: _passwordFocus,
                        enabled: !_busy,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        autofillHints: [
                          _register
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          helperText:
                              _register ? 'At least 10 characters' : null,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _obscure ? 'Show password' : 'Hide password',
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                          ),
                        ),
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please enter your password';
                          if (_register && v.length < 10) {
                            return 'Password must be at least 10 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: scheme.onPrimary,
                        ),
                      )
                    : Text(_register ? 'Create account' : 'Sign in'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : _toggleMode,
                child: Text(_register
                    ? 'Already have an account? Sign in'
                    : 'New here? Create an account'),
              ),
              if (_register) ...[
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                    children: [
                      const TextSpan(text: 'By creating an account you agree to our '),
                      _link(context, 'Terms', PolicyKind.terms),
                      const TextSpan(text: ' and '),
                      _link(context, 'Privacy Policy', PolicyKind.privacy),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 4),
              TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                child: const Text('Continue as guest'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InlineSpan _link(BuildContext context, String text, PolicyKind kind) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: InkWell(
        onTap: () => openPolicy(context, kind),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
