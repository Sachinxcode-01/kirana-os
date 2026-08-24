import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/radius.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  String? _localError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty) {
      setState(() => _localError = 'Please enter your full name');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _localError = 'Please enter a valid email address');
      return;
    }
    if (password.length < 6) {
      setState(() => _localError = 'Password must be at least 6 characters');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _localError = 'Passwords do not match');
      return;
    }

    setState(() => _localError = null);

    final success = await ref.read(authNotifierProvider.notifier).register(
          email: email,
          password: password,
          fullName: name,
          phone: phone.isNotEmpty ? phone : null,
        );

    if (success && mounted) {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final errorMessage = _localError ?? authState.errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KiranaSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Join KiranaOS',
                  style: KiranaTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: KiranaSpacing.xs),
                Text(
                  'Setup your store owner account to start billing',
                  style: KiranaTypography.bodyMedium.copyWith(
                    color: KiranaColors.neutral600,
                  ),
                ),
                const SizedBox(height: KiranaSpacing.xl),

                if (errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(KiranaSpacing.md),
                    decoration: BoxDecoration(
                      color: KiranaColors.errorContainer,
                      borderRadius: KiranaRadius.borderMd,
                      border: Border.all(color: KiranaColors.error),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 20, color: KiranaColors.error),
                        const SizedBox(width: KiranaSpacing.sm),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: const TextStyle(fontSize: 13, color: KiranaColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: KiranaSpacing.lg),
                ],

                AppTextField(
                  label: 'Full Name *',
                  hint: 'e.g. Ramesh Gupta',
                  controller: _nameController,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                const SizedBox(height: KiranaSpacing.lg),

                AppTextField(
                  label: 'Email Address *',
                  hint: 'owner@store.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                const SizedBox(height: KiranaSpacing.lg),

                AppTextField(
                  label: 'Phone Number (Optional)',
                  hint: '10-digit mobile number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                const SizedBox(height: KiranaSpacing.lg),

                AppTextField(
                  label: 'Password (min 6 characters) *',
                  hint: 'Enter strong password',
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
                const SizedBox(height: KiranaSpacing.lg),

                AppTextField(
                  label: 'Confirm Password *',
                  hint: 'Re-enter password',
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                const SizedBox(height: KiranaSpacing.xxl),

                AppButton(
                  label: 'Create Account & Continue',
                  isLoading: authState.isAuthenticating,
                  onPressed: authState.isAuthenticating ? null : _handleRegister,
                ),
                const SizedBox(height: KiranaSpacing.lg),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? ', style: TextStyle(color: KiranaColors.neutral600)),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, color: KiranaColors.primary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
