import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oasis/features/auth/presentation/providers/auth_provider.dart';
import 'package:oasis/features/auth/presentation/widgets/auth_layout_wrapper.dart';
import 'package:oasis/widgets/app_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoggingIn = false;
  bool _isResettingPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address first')),
      );
      return;
    }

    setState(() => _isResettingPassword = true);
    try {
      await context.read<AuthProvider>().resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent! Check your inbox.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResettingPassword = false);
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoggingIn = true);
      try {
        debugPrint('[LoginScreen] Starting sign in...');
        await context.read<AuthProvider>().signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        debugPrint('[LoginScreen] Sign in completed, navigating to /feed');
        if (mounted) {
          context.go('/feed');
        }
      } catch (e) {
        debugPrint('[LoginScreen] Sign in failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      } finally {
        if (mounted) setState(() => _isLoggingIn = false);
      }
    }
  }

  Future<void> _showGoogleSetPasswordDialog(BuildContext context) async {
    final emailController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;
    String? successMessage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Set Password for Google Account'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter the email associated with your Google account. We\'ll send a password reset link to set your password.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (successMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          successMessage!,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          isLoading ? null : () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                final email = emailController.text.trim();

                                if (email.isEmpty || !email.contains('@')) {
                                  setDialogState(
                                    () =>
                                        errorMessage =
                                            'Please enter a valid email',
                                  );
                                  return;
                                }

                                setDialogState(() {
                                  isLoading = true;
                                  errorMessage = null;
                                  successMessage = null;
                                });

                                try {
                                  // Use full URL for redirectTo - Supabase requires full URL, not just scheme
                                  // The actual deep link handling is done by the app via App Links/Universal Links
                                  await Supabase.instance.client.auth
                                      .resetPasswordForEmail(
                                        email,
                                        redirectTo:
                                            'https://oasis-web-red.vercel.app/reset-password',
                                      );

                                  setDialogState(() {
                                    successMessage =
                                        'Password reset email sent! Check your inbox.';
                                  });

                                  await Future.delayed(
                                    const Duration(seconds: 2),
                                  );
                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                    _showPasswordSetInstructions(
                                      context,
                                      email,
                                    );
                                  }
                                } catch (e) {
                                  setDialogState(
                                    () => errorMessage = e.toString(),
                                  );
                                } finally {
                                  setDialogState(() => isLoading = false);
                                }
                              },
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Continue'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showPasswordSetInstructions(BuildContext context, String email) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Check Your Email'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('We sent a password reset link to $email'),
                const SizedBox(height: 12),
                const Text(
                  '📋 Instructions:\n'
                  '1. Click the link in the email\n'
                  '2. You\'ll be taken to a password reset page in the app\n'
                  '3. Enter a new password\n'
                  '4. After setting password, sign in with your email + new password',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayoutWrapper(
      wrapInScroll: true,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16.0),
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8.0),
              Text(
                'Sign in to continue',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48.0),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed:
                      (_isLoggingIn || _isResettingPassword)
                          ? null
                          : _resetPassword,
                  child:
                      _isResettingPassword
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 8.0),
              // Google users: set password link
              TextButton(
                onPressed:
                    (_isLoggingIn || _isResettingPassword)
                        ? null
                        : () => _showGoogleSetPasswordDialog(context),
                child: const Text(
                  'Signed up with Google? Set a password',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16.0),
              AppButton.primary(
                text: 'Sign In',
                isLoading: _isLoggingIn,
                onPressed:
                    (_isLoggingIn || _isResettingPassword) ? null : _login,
              ),
              const SizedBox(height: 16.0),
              TextButton(
                onPressed:
                    (_isLoggingIn || _isResettingPassword)
                        ? null
                        : () {
                          final addAccount =
                              GoRouterState.of(
                                context,
                              ).uri.queryParameters['add_account'];
                          if (addAccount == 'true') {
                            context.go('/register?add_account=true');
                          } else {
                            context.go('/register');
                          }
                        },
                child: const Text("Don't have an account? Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
