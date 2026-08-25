import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/radius.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_button.dart';
import 'package:kirana_mobile/core/widgets/app_text_field.dart';
import 'package:kirana_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:kirana_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:kirana_mobile/features/shop/presentation/providers/shop_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _EditProfileDialog(),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _ChangePasswordDialog(),
    );
  }

  void _showPhotoOptionsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _PhotoOptionsSheet(ref: ref),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final profileState = ref.watch(profileNotifierProvider);
    final user = authState.user;
    final shopId = authState.activeShopId ?? '';
    final shopDetailsAsync = ref.watch(currentShopDetailsProvider(shopId));

    final displayName = user?.displayName ?? user?.email ?? 'Store Owner';
    final email = user?.email ?? '';
    final phone = user?.phone ?? 'Not set';
    final role = (user?.role ?? 'owner').toUpperCase();
    final avatarUrl = user?.avatarUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User & Store Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(KiranaSpacing.lg),
        children: [
          if (profileState.errorMessage != null) ...[
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
                      profileState.errorMessage!,
                      style: KiranaTypography.bodyMedium
                          .copyWith(color: KiranaColors.error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KiranaSpacing.md),
          ],
          if (profileState.successMessage != null) ...[
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
                      profileState.successMessage!,
                      style: KiranaTypography.bodyMedium
                          .copyWith(color: KiranaColors.secondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KiranaSpacing.md),
          ],

          // Profile Header
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: KiranaColors.primaryContainer,
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : 'U',
                              style: KiranaTypography.headlineMedium.copyWith(
                                color: KiranaColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: () => _showPhotoOptionsSheet(context, ref),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: KiranaColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KiranaSpacing.md),
                Text(
                  displayName,
                  style: KiranaTypography.titleLarge
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: KiranaTypography.bodyMedium
                      .copyWith(color: KiranaColors.neutral600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Phone: $phone',
                  style: KiranaTypography.bodySmall
                      .copyWith(color: KiranaColors.neutral600),
                ),
                const SizedBox(height: KiranaSpacing.xs),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: KiranaColors.primary.withValues(alpha: 0.1),
                    borderRadius: KiranaRadius.borderPill,
                    border: Border.all(
                      color: KiranaColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'ROLE: $role',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: KiranaColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KiranaSpacing.xl),

          // Store Details Card
          Text(
            'Store & Account Info',
            style: KiranaTypography.titleMedium
                .copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: KiranaSpacing.sm),
          shopDetailsAsync.when(
            data: (shop) => Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.storefront,
                        color: KiranaColors.primary),
                    title: const Text('Store Name'),
                    subtitle: Text(shop?.name ??
                        authState.activeShopName ??
                        'Not Configured'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading:
                        const Icon(Icons.phone, color: KiranaColors.primary),
                    title: const Text('Store Phone'),
                    subtitle: Text(shop?.phone ?? user?.phone ?? 'Not Added'),
                  ),
                  if (shop?.gstin != null && shop!.gstin!.isNotEmpty) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.receipt_long,
                          color: KiranaColors.primary),
                      title: const Text('GSTIN'),
                      subtitle: Text(shop.gstin!),
                    ),
                  ],
                ],
              ),
            ),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(KiranaSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, st) => Card(
              child: ListTile(
                title: const Text('Store Name'),
                subtitle: Text(authState.activeShopName ?? 'Kirana Store'),
              ),
            ),
          ),
          const SizedBox(height: KiranaSpacing.xl),

          // Profile Actions
          AppButton(
            label: 'Edit Profile (Name & Phone)',
            variant: AppButtonVariant.outlined,
            onPressed: () => _showEditProfileDialog(context, ref),
          ),
          const SizedBox(height: KiranaSpacing.md),

          AppButton(
            label: 'Change Password',
            variant: AppButtonVariant.outlined,
            onPressed: () => _showChangePasswordDialog(context, ref),
          ),
          const SizedBox(height: KiranaSpacing.md),

          AppButton(
            label: 'Sign Out of KiranaOS',
            variant: AppButtonVariant.destructive,
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text(
                    'Are you sure you want to sign out? Your session will be cleared securely.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KiranaColors.error,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(authNotifierProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _EditProfileDialog extends ConsumerStatefulWidget {
  const _EditProfileDialog();

  @override
  ConsumerState<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<_EditProfileDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).user;
    _nameController.text = user?.displayName ?? '';
    _phoneController.text = user?.phone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Full name is required');
      return;
    }
    if (phone.length < 10) {
      setState(() => _error = 'Enter a valid 10-digit phone number');
      return;
    }

    setState(() => _error = null);

    final success =
        await ref.read(profileNotifierProvider.notifier).updateProfile(
              fullName: name,
              phone: phone,
            );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
      } else {
        final profileState = ref.read(profileNotifierProvider);
        setState(() =>
            _error = profileState.errorMessage ?? 'Failed to update profile');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);

    return AlertDialog(
      title: const Text('Edit Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: KiranaColors.error, fontSize: 13),
              ),
              const SizedBox(height: KiranaSpacing.sm),
            ],
            AppTextField(
              label: 'Full Name *',
              hint: 'Enter your full name',
              controller: _nameController,
            ),
            const SizedBox(height: KiranaSpacing.md),
            AppTextField(
              label: 'Phone Number *',
              hint: '10-digit mobile number',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              profileState.isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: profileState.isLoading ? null : _handleUpdate,
          child: profileState.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Profile'),
        ),
      ],
    );
  }
}

class _PhotoOptionsSheet extends StatelessWidget {
  final WidgetRef ref;

  const _PhotoOptionsSheet({required this.ref});

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    Navigator.pop(context);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        await ref.read(profileNotifierProvider.notifier).uploadProfilePhoto(
              bytes: bytes,
              fileName: picked.name,
            );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access image: ${e.toString()}'),
            backgroundColor: KiranaColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = ref.watch(authNotifierProvider).user?.avatarUrl != null;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading:
                const Icon(Icons.photo_library, color: KiranaColors.primary),
            title: const Text('Choose from Gallery'),
            onTap: () => _pickImage(context, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: KiranaColors.primary),
            title: const Text('Take a Photo'),
            onTap: () => _pickImage(context, ImageSource.camera),
          ),
          if (hasPhoto)
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: KiranaColors.error),
              title: const Text(
                'Remove Profile Photo',
                style: TextStyle(color: KiranaColors.error),
              ),
              onTap: () async {
                Navigator.pop(context);
                await ref
                    .read(profileNotifierProvider.notifier)
                    .removeProfilePhoto();
              },
            ),
        ],
      ),
    );
  }
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      __ChangePasswordDialogState();
}

class __ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    final current = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (current.isEmpty) {
      setState(() => _error = 'Please enter your current password');
      return;
    }
    if (newPass.length < 6) {
      setState(() => _error = 'New password must be at least 6 characters');
      return;
    }
    if (newPass != confirm) {
      setState(() => _error = 'New passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await ref
        .read(authNotifierProvider.notifier)
        .changePassword(currentPassword: current, newPassword: newPass);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: KiranaColors.secondary,
          ),
        );
      } else {
        final authState = ref.read(authNotifierProvider);
        setState(() =>
            _error = authState.errorMessage ?? 'Failed to change password');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: KiranaColors.error, fontSize: 13),
              ),
              const SizedBox(height: KiranaSpacing.sm),
            ],
            AppTextField(
              label: 'Current Password',
              hint: 'Enter current password',
              controller: _currentPasswordController,
              obscureText: true,
            ),
            const SizedBox(height: KiranaSpacing.md),
            AppTextField(
              label: 'New Password',
              hint: 'Min 6 characters',
              controller: _newPasswordController,
              obscureText: true,
            ),
            const SizedBox(height: KiranaSpacing.md),
            AppTextField(
              label: 'Confirm New Password',
              hint: 'Re-enter new password',
              controller: _confirmPasswordController,
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleChangePassword,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update Password'),
        ),
      ],
    );
  }
}
