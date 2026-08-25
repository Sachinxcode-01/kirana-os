import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/radius.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_button.dart';
import 'package:kirana_mobile/core/widgets/app_text_field.dart';
import 'package:kirana_mobile/features/auth/presentation/providers/auth_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (_isLoading) return;

    final current = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (current.isEmpty) {
      setState(() => _errorMessage = 'Current password is required');
      return;
    }
    if (newPass.length < 6) {
      setState(() =>
          _errorMessage = 'New password must be at least 6 characters long');
      return;
    }
    if (newPass == current) {
      setState(() => _errorMessage =
          'New password must be different from current password');
      return;
    }
    if (newPass != confirm) {
      setState(
          () => _errorMessage = 'New password and confirmation do not match');
      return;
    }

    setState(() => _isLoading = true);

    final success =
        await ref.read(authNotifierProvider.notifier).changePassword(
              currentPassword: current,
              newPassword: newPass,
            );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        setState(() {
          _successMessage =
              'Your password has been changed successfully! Please use your new password next time you sign in.';
        });
      } else {
        final authState = ref.read(authNotifierProvider);
        setState(() {
          _errorMessage = authState.errorMessage ??
              'Failed to change password. Please check your credentials and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(KiranaSpacing.lg),
          children: [
            Text(
              'Security Settings',
              style: KiranaTypography.titleLarge
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: KiranaSpacing.xs),
            Text(
              'Choose a strong password with at least 6 characters that you have not used before.',
              style: KiranaTypography.bodyMedium
                  .copyWith(color: KiranaColors.neutral600),
            ),
            const SizedBox(height: KiranaSpacing.lg),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(KiranaSpacing.md),
                decoration: BoxDecoration(
                  color: KiranaColors.errorContainer,
                  borderRadius: KiranaRadius.borderMd,
                  border: Border.all(color: KiranaColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: KiranaColors.error),
                    const SizedBox(width: KiranaSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: KiranaTypography.bodyMedium
                            .copyWith(color: KiranaColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KiranaSpacing.md),
            ],
            if (_successMessage != null) ...[
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
                        color: KiranaColors.secondary),
                    const SizedBox(width: KiranaSpacing.sm),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: KiranaTypography.bodyMedium
                            .copyWith(color: KiranaColors.secondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KiranaSpacing.md),
            ],
            AppTextField(
              label: 'Current Password *',
              hint: 'Enter your current password',
              controller: _currentPasswordController,
              obscureText: true,
              readOnly: _isLoading,
            ),
            const SizedBox(height: KiranaSpacing.md),
            AppTextField(
              label: 'New Password *',
              hint: 'Minimum 6 characters',
              controller: _newPasswordController,
              obscureText: true,
              readOnly: _isLoading,
            ),
            const SizedBox(height: KiranaSpacing.md),
            AppTextField(
              label: 'Confirm New Password *',
              hint: 'Re-enter new password',
              controller: _confirmPasswordController,
              obscureText: true,
              readOnly: _isLoading,
            ),
            const SizedBox(height: KiranaSpacing.xl),
            AppButton(
              label: 'Update Password',
              onPressed: _isLoading ? null : _handleChangePassword,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
