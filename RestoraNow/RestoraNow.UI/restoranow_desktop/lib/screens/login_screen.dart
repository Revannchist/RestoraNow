import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/base/auth_provider.dart';
import '../theme/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _pwdFocus = FocusNode();

  bool _isLoading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();

    // If a valid token already exists, send Staff/Admin straight to /home.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        final roles = auth.roles.map((e) => e.toLowerCase()).toSet();
        final isAllowed =
            roles.contains('admin'.toLowerCase()) ||
            roles.contains('staff'.toLowerCase());
        if (isAllowed) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // Token exists but role not allowed for desktop app
          auth.logout();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This desktop app is for Admin/Staff only.'),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _emailFocus.dispose();
    _pwdFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    // Validate the form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Unfocus keyboards
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    final ok = await auth.login(_emailCtrl.text.trim(), _pwdCtrl.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.error ?? 'Login failed')));
      return;
    }

    // Only Admin/Staff can use this desktop app
    final roles = auth.roles.map((e) => e.toLowerCase()).toSet();
    final allowed =
        roles.contains('admin'.toLowerCase()) ||
        roles.contains('staff'.toLowerCase());
    if (!allowed) {
      auth.logout();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This desktop app is for Admin/Staff only.'),
        ),
      );
      return;
    }

    Navigator.pushReplacementNamed(context, '/home');
  }

  String? _validateEmail(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Email is required';
    // lightweight check; backend still validates
    if (!s.contains('@') || !s.contains('.')) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Password is required';
    if (s.length < 6) return 'Must be at least 6 characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    'Staff/Admin Login',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),
                  Text(
                    'Use your Admin or Staff credentials',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (_isLoading) const LinearProgressIndicator(minHeight: 2),

                  const SizedBox(height: 12),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailCtrl,
                          focusNode: _emailFocus,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                          onFieldSubmitted: (_) => _pwdFocus.requestFocus(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _pwdCtrl,
                          focusNode: _pwdFocus,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              tooltip: _obscure ? 'Show' : 'Hide',
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          textInputAction: TextInputAction.done,
                          validator: _validatePassword,
                          onFieldSubmitted: (_) => _handleLogin(),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            child: Text(_isLoading ? 'Logging in…' : 'Login'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Small note for clarity
                  Text(
                    'Access restricted to Admin and Staff.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
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
