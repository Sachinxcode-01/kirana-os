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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await ref
        .read(authNotifierProvider.notifier)
        .sendPasswordReset(email);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _emailSent = success;
        if (!success) {
          _error = 'Failed to send reset link. Please check your email.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KiranaSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _emailSent ? _buildSuccessView() : _buildFormView(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Forgot Password?',
          style: KiranaTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: KiranaSpacing.xs),
        const Text(
          'Enter your registered email address and we will send you a secure password reset link.',
          style: KiranaTypography.bodyMedium,
        ),
        const SizedBox(height: KiranaSpacing.xl),

        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(KiranaSpacing.md),
            decoration: BoxDecoration(
              color: KiranaColors.errorContainer,
              borderRadius: KiranaRadius.borderMd,
              border: Border.all(color: KiranaColors.error),
            ),
            child: Text(_error!, style: const TextStyle(fontSize: 13, color: KiranaColors.error)),
          ),
          const SizedBox(height: KiranaSpacing.lg),
        ],

        AppTextField(
          label: 'Registered Email',
          hint: 'owner@store.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined),
        ),
        const SizedBox(height: KiranaSpacing.xl),

        AppButton(
          label: 'Send Password Reset Link',
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _handleSendReset,
        ),
        const SizedBox(height: KiranaSpacing.lg),

        Center(
          child: TextButton(
            onPressed: () => context.pop(),
            child: const Text('Back to Sign In'),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_read, size: 64, color: KiranaColors.success),
        const SizedBox(height: KiranaSpacing.lg),
        Text(
          'Check Your Email',
          style: KiranaTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: KiranaSpacing.sm),
        Text(
          'We have sent password reset instructions to ${_emailController.text.trim()}.',
          style: KiranaTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: KiranaSpacing.xxl),
        AppButton(
          label: 'Return to Sign In',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
