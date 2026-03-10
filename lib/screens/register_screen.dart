import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:morrow_v2/services/auth_service.dart';
import 'package:morrow_v2/widgets/app_button.dart';
import 'package:morrow_v2/widgets/custom_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  
  // Remove unused _confirmPasswordController
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }


  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Create the user with email and password using Supabase
      try {
        await authService.registerWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: _nameController.text.trim().toLowerCase().replaceAll(' ', '_'),
          displayName: _nameController.text.trim(),
        );
        
        if (!mounted) return;
        
        // Get the current user
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          // Send verification email
          try {
            // Send verification email using Supabase
            await Supabase.instance.client.auth.resend(
              type: OtpType.signup,
              email: user.email!,
            );
            
            // Show verification dialog
            if (mounted) {
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: const Text('Verify Your Email'),
                  content: Text(
                    'A verification email has been sent to ${user.email}. '
                    'Please verify your email to continue using the app. '
                    'You can verify later from your profile settings.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (mounted) {
                          context.go('/feed');
                        }
                      },
                      child: const Text('Continue to App'),
                    ),
                  ],
                ),
              );
            }
          } catch (e) {
            // If email verification fails, still log them in but show a message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account created! You can verify your email later from profile settings.'),
                ),
              );
              context.go('/feed');
            }
          }
        } else {
          // This should theoretically never happen since we just created the user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration successful! Please sign in.')),
            );
            context.go('/login');
          }
        }
      } on AuthException catch (e) {
        String message = 'An error occurred during registration. Please try again.';
        
        if (e.toString().contains('already registered')) {
          message = 'A user with this email already exists. Please use a different email or sign in instead.';
        } else if (e.toString().contains('weak password')) {
          message = 'The password is too weak. Please use at least 6 characters.';
        } else if (e.toString().contains('network')) {
          message = 'Network error. Please check your internet connection and try again.';
        } else if (e.toString().contains('too many requests')) {
          message = 'Too many requests. Please try again later.';
        } else if (e.toString().isNotEmpty) {
          message = 'Registration failed: ${e.toString().replaceAll('Exception: ', '')}';
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString().replaceAll('Exception: ', '')}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF111318),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Sign up',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    // Name Field
                    CustomTextField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      hint: 'Name',
                      prefixIcon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_emailFocus);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Email Field
                    CustomTextField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      hint: 'Email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_passwordFocus);
                      },
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
                    const SizedBox(height: 8),

                    // Password Field
                    CustomTextField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      hint: 'Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _register(),
                    ),
                  ],
                ),
              ),
            ),

            // Sign Up Button
            Padding(
              padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
              child: AppButton.primary(
                text: 'Sign up',
                onPressed: _isLoading ? null : _register,
                isLoading: _isLoading,
              ),
            ),

            // Sign In Link
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: Color(0xFF9DA6B9),
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : () => context.go('/login'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Sign in',
                      style: TextStyle(
                        color: Color(0xFF1152D4),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
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
