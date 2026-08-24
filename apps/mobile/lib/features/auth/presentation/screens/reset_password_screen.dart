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

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await ref
        .read(authNotifierProvider.notifier)
        .updatePassword(password);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully! Please sign in.'),
            backgroundColor: KiranaColors.success,
          ),
        );
        context.go('/login');
      } else {
        setState(() => _error = 'Failed to update password. Link may have expired.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set New Password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KiranaSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create New Password',
                  style: KiranaTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: KiranaSpacing.xs),
                const Text(
                  'Enter a strong new password for your KiranaOS account.',
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
                  label: 'New Password *',
                  hint: 'Enter minimum 6 characters',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: KiranaSpacing.lg),

                AppTextField(
                  label: 'Confirm New Password *',
                  hint: 'Re-enter new password',
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                const SizedBox(height: KiranaSpacing.xxl),

                AppButton(
                  label: 'Update Password & Continue',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _handleUpdatePassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
