import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kirana_mobile/app/app_providers.dart';
import 'package:kirana_mobile/core/network/connectivity_status.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/radius.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_button.dart';
import 'package:kirana_mobile/core/widgets/app_text_field.dart';
import 'package:kirana_mobile/features/auth/presentation/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isResendingEmail = false;
  String? _localError;
  String? _infoMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _localError = 'Please enter a valid email address');
      return;
    }
    if (password.isEmpty) {
      setState(() => _localError = 'Please enter your password');
      return;
    }

    setState(() {
      _localError = null;
      _infoMessage = null;
    });

    final success = await ref.read(authNotifierProvider.notifier).login(
          email: email,
          password: password,
        );

    if (success && mounted) {
      final authState = ref.read(authNotifierProvider);
      if (authState.hasActiveShop) {
        context.go('/dashboard');
      } else {
        context.go('/onboarding');
      }
    }
  }

  Future<void> _handleResendVerification() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() =>
          _localError = 'Please enter your email to resend verification link');
      return;
    }

    setState(() {
      _isResendingEmail = true;
      _localError = null;
      _infoMessage = null;
    });

    final success = await ref
        .read(authNotifierProvider.notifier)
        .resendVerificationEmail(email);

    if (mounted) {
      setState(() {
        _isResendingEmail = false;
        if (success) {
          _infoMessage =
              'Verification email sent to $email. Please check your inbox.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final connectivity =
        ref.watch(connectivityStatusStreamProvider).valueOrNull ??
            ConnectivityStatus.online;
    final isOffline = connectivity == ConnectivityStatus.offline;

    final errorMessage = _localError ?? authState.errorMessage;
    final isUnconfirmedEmail = errorMessage != null &&
        errorMessage.toLowerCase().contains('email not confirmed');

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KiranaSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & Header
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 76,
                          height: 76,
                          decoration: const BoxDecoration(
                            color: KiranaColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.storefront,
                            size: 44,
                            color: KiranaColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: KiranaSpacing.lg),
                  Text(
                    'Welcome to KiranaOS',
                    style: KiranaTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: KiranaSpacing.xs),
                  Text(
                    'Sign in to access your store POS & inventory',
                    style: KiranaTypography.bodyMedium.copyWith(
                      color: KiranaColors.neutral600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: KiranaSpacing.xl),

                  // Offline Banner
                  if (isOffline) ...[
                    Container(
                      padding: const EdgeInsets.all(KiranaSpacing.md),
                      decoration: BoxDecoration(
                        color: KiranaColors.warningContainer,
                        borderRadius: KiranaRadius.borderMd,
                        border: Border.all(color: KiranaColors.warning),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.wifi_off,
                              size: 20, color: KiranaColors.warning),
                          SizedBox(width: KiranaSpacing.sm),
                          Expanded(
                            child: Text(
                              "You're offline. Connect to internet to log in with new credentials.",
                              style: TextStyle(
                                  fontSize: 12, color: KiranaColors.neutral800),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: KiranaSpacing.lg),
                  ],

                  // Info Banner
                  if (_infoMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(KiranaSpacing.md),
                      decoration: BoxDecoration(
                        color: KiranaColors.secondaryContainer,
                        borderRadius: KiranaRadius.borderMd,
                        border: Border.all(color: KiranaColors.secondary),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 20, color: KiranaColors.secondary),
                          const SizedBox(width: KiranaSpacing.sm),
                          Expanded(
                            child: Text(
                              _infoMessage!,
                              style: const TextStyle(
                                  fontSize: 13, color: KiranaColors.secondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: KiranaSpacing.lg),
                  ],

                  // Error Banner
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(KiranaSpacing.md),
                      decoration: BoxDecoration(
                        color: KiranaColors.errorContainer,
                        borderRadius: KiranaRadius.borderMd,
                        border: Border.all(color: KiranaColors.error),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 20, color: KiranaColors.error),
                              const SizedBox(width: KiranaSpacing.sm),
                              Expanded(
                                child: Text(
                                  errorMessage,
                                  style: const TextStyle(
                                      fontSize: 13, color: KiranaColors.error),
                                ),
                              ),
                            ],
                          ),
                          if (isUnconfirmedEmail) ...[
                            const SizedBox(height: KiranaSpacing.sm),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 30),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: _isResendingEmail
                                    ? null
                                    : _handleResendVerification,
                                icon: _isResendingEmail
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.send_rounded, size: 14),
                                label: const Text(
                                  'Resend Verification Email',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: KiranaSpacing.lg),
                  ],

                  // Email Field
                  AppTextField(
                    label: 'Email Address',
                    hint: 'owner@store.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  const SizedBox(height: KiranaSpacing.lg),

                  // Password Field
                  AppTextField(
                    label: 'Password',
                    hint: 'Enter your password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  const SizedBox(height: KiranaSpacing.xs),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                            fontSize: 13, color: KiranaColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: KiranaSpacing.md),

                  // Login Button
                  AppButton(
                    label: 'Sign In',
                    isLoading: authState.isAuthenticating,
                    onPressed: authState.isAuthenticating || isOffline
                        ? null
                        : _handleLogin,
                  ),
                  const SizedBox(height: KiranaSpacing.xl),

                  // Registration Link
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(color: KiranaColors.neutral600),
                      ),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: KiranaColors.primary),
                        ),
                      ),
                    ],
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
