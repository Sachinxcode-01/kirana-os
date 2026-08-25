import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/radius.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_button.dart';
import 'package:kirana_mobile/core/widgets/app_text_field.dart';
import 'package:kirana_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:kirana_mobile/features/staff/domain/models/staff_member_model.dart';
import 'package:kirana_mobile/features/staff/presentation/providers/staff_provider.dart';

class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _InviteStaffDialog(),
    );
  }

  void _showEditRoleDialog(BuildContext context, StaffMemberModel member) {
    showDialog(
      context: context,
      builder: (context) => _EditStaffRoleDialog(member: member),
    );
  }

  void _showToggleStatusConfirmation(
    BuildContext context,
    WidgetRef ref,
    StaffMemberModel member,
  ) {
    final isDeactivating = member.isActive || member.isPending;
    final newStatus =
        isDeactivating ? StaffStatus.deactivated : StaffStatus.active;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDeactivating ? 'Deactivate Staff' : 'Activate Staff'),
        content: Text(
          isDeactivating
              ? 'Are you sure you want to deactivate ${member.email}? They will lose access to the shop immediately. Historical sales and audit logs will be preserved.'
              : 'Are you sure you want to activate ${member.email}? They will regain shop access according to their assigned role.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDeactivating ? KiranaColors.error : KiranaColors.secondary,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(staffNotifierProvider.notifier).toggleStatus(
                    targetMember: member,
                    newStatus: newStatus,
                  );
            },
            child: Text(
              isDeactivating ? 'Deactivate' : 'Activate',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffState = ref.watch(staffNotifierProvider);
    final currentUser = ref.watch(authNotifierProvider).user;
    final canManageStaff =
        currentUser?.role == 'owner' || currentUser?.role == 'manager';

    final staffList = staffState.filteredStaffList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Staff Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(staffNotifierProvider.notifier)
                .loadStaff(forceRefresh: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(staffNotifierProvider.notifier)
            .loadStaff(forceRefresh: true),
        child: ListView(
          padding: const EdgeInsets.all(KiranaSpacing.lg),
          children: [
            // Header Card
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Staff Roster',
                        style: KiranaTypography.titleLarge
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${staffState.staffList.length} total team member(s)',
                        style: KiranaTypography.bodyMedium
                            .copyWith(color: KiranaColors.neutral600),
                      ),
                    ],
                  ),
                ),
                if (canManageStaff)
                  AppButton(
                    label: 'Invite Staff',
                    icon: Icons.person_add,
                    onPressed: () => _showInviteDialog(context),
                  ),
              ],
            ),
            const SizedBox(height: KiranaSpacing.md),

            // Notification Error / Success Banners
            if (staffState.errorMessage != null) ...[
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
                        staffState.errorMessage!,
                        style: KiranaTypography.bodyMedium
                            .copyWith(color: KiranaColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KiranaSpacing.md),
            ],

            if (staffState.successMessage != null) ...[
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
                        staffState.successMessage!,
                        style: KiranaTypography.bodyMedium
                            .copyWith(color: KiranaColors.secondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: KiranaSpacing.md),
            ],

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: staffState.filterStatus == null,
                    onSelected: (_) => ref
                        .read(staffNotifierProvider.notifier)
                        .setFilterStatus(null),
                  ),
                  const SizedBox(width: KiranaSpacing.xs),
                  FilterChip(
                    label: const Text('Active'),
                    selected: staffState.filterStatus == StaffStatus.active,
                    onSelected: (_) => ref
                        .read(staffNotifierProvider.notifier)
                        .setFilterStatus(StaffStatus.active),
                  ),
                  const SizedBox(width: KiranaSpacing.xs),
                  FilterChip(
                    label: const Text('Pending'),
                    selected: staffState.filterStatus == StaffStatus.pending,
                    onSelected: (_) => ref
                        .read(staffNotifierProvider.notifier)
                        .setFilterStatus(StaffStatus.pending),
                  ),
                  const SizedBox(width: KiranaSpacing.xs),
                  FilterChip(
                    label: const Text('Deactivated'),
                    selected:
                        staffState.filterStatus == StaffStatus.deactivated,
                    onSelected: (_) => ref
                        .read(staffNotifierProvider.notifier)
                        .setFilterStatus(StaffStatus.deactivated),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KiranaSpacing.md),

            // Content Loading / Empty / Staff List
            if (staffState.isLoading && staffList.isEmpty) ...[
              const SizedBox(height: 40),
              const Center(child: CircularProgressIndicator()),
            ] else if (staffList.isEmpty) ...[
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.group_outlined,
                        size: 48, color: KiranaColors.neutral400),
                    const SizedBox(height: KiranaSpacing.sm),
                    Text(
                      'No staff members found',
                      style: KiranaTypography.titleMedium
                          .copyWith(color: KiranaColors.neutral600),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ...staffList.map((member) {
                return _StaffCard(
                  member: member,
                  canManage: canManageStaff,
                  onEditRole: () => _showEditRoleDialog(context, member),
                  onToggleStatus: () =>
                      _showToggleStatusConfirmation(context, ref, member),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final StaffMemberModel member;
  final bool canManage;
  final VoidCallback onEditRole;
  final VoidCallback onToggleStatus;

  const _StaffCard({
    required this.member,
    required this.canManage,
    required this.onEditRole,
    required this.onToggleStatus,
  });

  Color _getRoleColor() {
    switch (member.role) {
      case StaffRole.owner:
        return KiranaColors.primary;
      case StaffRole.manager:
        return KiranaColors.secondary;
      case StaffRole.cashier:
        return KiranaColors.neutral700;
      case StaffRole.inventoryStaff:
        return Colors.teal;
    }
  }

  Color _getStatusColor() {
    switch (member.status) {
      case StaffStatus.active:
        return KiranaColors.secondary;
      case StaffStatus.pending:
        return Colors.amber.shade800;
      case StaffStatus.deactivated:
        return KiranaColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = member.displayName ?? member.email.split('@').first;
    final formattedDate =
        '${member.createdAt.day}/${member.createdAt.month}/${member.createdAt.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: KiranaSpacing.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KiranaSpacing.md,
          vertical: KiranaSpacing.xs,
        ),
        leading: CircleAvatar(
          backgroundColor: _getRoleColor().withValues(alpha: 0.15),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'S',
            style: TextStyle(
              color: _getRoleColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: KiranaTypography.bodyLarge
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor().withValues(alpha: 0.1),
                borderRadius: KiranaRadius.borderPill,
                border:
                    Border.all(color: _getRoleColor().withValues(alpha: 0.3)),
              ),
              child: Text(
                member.role.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getRoleColor(),
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(member.email, style: KiranaTypography.bodySmall),
            if (member.phone != null && member.phone!.isNotEmpty)
              Text('Phone: ${member.phone}', style: KiranaTypography.bodySmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.1),
                    borderRadius: KiranaRadius.borderSm,
                  ),
                  child: Text(
                    member.status.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                    ),
                  ),
                ),
                const SizedBox(width: KiranaSpacing.sm),
                Text(
                  'Joined: $formattedDate',
                  style: KiranaTypography.bodySmall
                      .copyWith(color: KiranaColors.neutral500),
                ),
              ],
            ),
          ],
        ),
        trailing: canManage && !member.isOwner
            ? PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'role') {
                    onEditRole();
                  } else if (val == 'status') {
                    onToggleStatus();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'role',
                    child: Row(
                      children: [
                        Icon(Icons.badge_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Change Role'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'status',
                    child: Row(
                      children: [
                        Icon(
                          member.isDeactivated
                              ? Icons.check_circle_outline
                              : Icons.block,
                          size: 18,
                          color: member.isDeactivated
                              ? KiranaColors.secondary
                              : KiranaColors.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          member.isDeactivated ? 'Activate' : 'Deactivate',
                          style: TextStyle(
                            color: member.isDeactivated
                                ? KiranaColors.secondary
                                : KiranaColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : member.isOwner
                ? const Tooltip(
                    message: 'Protected Owner Role',
                    child: Icon(Icons.shield,
                        color: KiranaColors.primary, size: 20),
                  )
                : null,
      ),
    );
  }
}

class _InviteStaffDialog extends ConsumerStatefulWidget {
  const _InviteStaffDialog();

  @override
  ConsumerState<_InviteStaffDialog> createState() => _InviteStaffDialogState();
}

class _InviteStaffDialogState extends ConsumerState<_InviteStaffDialog> {
  final _emailController = TextEditingController();
  StaffRole _selectedRole = StaffRole.cashier;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleInvite() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Valid email address is required');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await ref
        .read(staffNotifierProvider.notifier)
        .inviteStaff(email: email, role: _selectedRole);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
      } else {
        final staffState = ref.read(staffNotifierProvider);
        setState(() =>
            _error = staffState.errorMessage ?? 'Failed to send invitation');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite Staff Member'),
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
              label: 'Staff Email *',
              hint: 'e.g. staff@kirana.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              readOnly: _isLoading,
            ),
            const SizedBox(height: KiranaSpacing.md),
            Text('Select Staff Role *', style: KiranaTypography.labelLarge),
            const SizedBox(height: KiranaSpacing.xs),
            DropdownButtonFormField<StaffRole>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(
                  value: StaffRole.manager,
                  child: Text('MANAGER (Full Store Ops & Staff)'),
                ),
                DropdownMenuItem(
                  value: StaffRole.cashier,
                  child: Text('CASHIER (POS Billing & Customer Khata)'),
                ),
                DropdownMenuItem(
                  value: StaffRole.inventoryStaff,
                  child: Text('INVENTORY STAFF (Products & Stock)'),
                ),
              ],
              onChanged: _isLoading
                  ? null
                  : (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
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
          onPressed: _isLoading ? null : _handleInvite,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Invitation'),
        ),
      ],
    );
  }
}

class _EditStaffRoleDialog extends ConsumerStatefulWidget {
  final StaffMemberModel member;

  const _EditStaffRoleDialog({required this.member});

  @override
  ConsumerState<_EditStaffRoleDialog> createState() =>
      _EditStaffRoleDialogState();
}

class _EditStaffRoleDialogState extends ConsumerState<_EditStaffRoleDialog> {
  late StaffRole _selectedRole;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.member.role == StaffRole.owner
        ? StaffRole.manager
        : widget.member.role;
  }

  Future<void> _handleUpdateRole() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await ref
        .read(staffNotifierProvider.notifier)
        .updateRole(targetMember: widget.member, newRole: _selectedRole);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
      } else {
        final staffState = ref.read(staffNotifierProvider);
        setState(
            () => _error = staffState.errorMessage ?? 'Failed to update role');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Change Role for ${widget.member.email}'),
      content: Column(
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
          Text('Select New Role', style: KiranaTypography.labelLarge),
          const SizedBox(height: KiranaSpacing.xs),
          DropdownButtonFormField<StaffRole>(
            initialValue: _selectedRole,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(
                value: StaffRole.manager,
                child: Text('MANAGER'),
              ),
              DropdownMenuItem(
                value: StaffRole.cashier,
                child: Text('CASHIER'),
              ),
              DropdownMenuItem(
                value: StaffRole.inventoryStaff,
                child: Text('INVENTORY STAFF'),
              ),
            ],
            onChanged: _isLoading
                ? null
                : (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleUpdateRole,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Role'),
        ),
      ],
    );
  }
}
