import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/models/supplier_model.dart';
import '../providers/supplier_provider.dart';
import 'add_edit_supplier_dialog.dart';

class SupplierDetailsModal extends ConsumerWidget {
  final SupplierModel supplier;

  const SupplierDetailsModal({super.key, required this.supplier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.only(
        top: KiranaSpacing.md,
        left: KiranaSpacing.md,
        right: KiranaSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + KiranaSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(supplier.name, style: KiranaTypography.titleLarge),
                    if (supplier.contactPerson != null)
                      Text('Contact: ${supplier.contactPerson}',
                          style: KiranaTypography.bodySmall),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(height: 24),
          _InfoTile(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: supplier.phone),
          if (supplier.email != null)
            _InfoTile(
                icon: Icons.email_outlined,
                label: 'Email',
                value: supplier.email!),
          if (supplier.gstin != null)
            _InfoTile(
                icon: Icons.receipt_long_outlined,
                label: 'GSTIN',
                value: supplier.gstin!),
          if (supplier.address != null)
            _InfoTile(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: supplier.address!),
          if (supplier.notes != null)
            _InfoTile(
                icon: Icons.note_outlined,
                label: 'Notes',
                value: supplier.notes!),
          const SizedBox(height: KiranaSpacing.md),
          Row(
            children: [
              if (!supplier.isArchived)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (_) =>
                            AddEditSupplierDialog(supplierToEdit: supplier),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Details'),
                  ),
                ),
              if (!supplier.isArchived) const SizedBox(width: KiranaSpacing.sm),
              if (!supplier.isArchived)
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KiranaColors.error,
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Archive Supplier'),
                          content: Text(
                              'Are you sure you want to archive "${supplier.name}"? Historical purchases will be preserved.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: KiranaColors.error),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Archive'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        final ok = await ref
                            .read(supplierFormNotifierProvider.notifier)
                            .archiveSupplier(supplier.id);
                        if (ok && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
                    icon: const Icon(Icons.archive_outlined),
                    label: const Text('Archive'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: KiranaColors.textSecondary),
          const SizedBox(width: KiranaSpacing.xs),
          Text('$label: ', style: KiranaTypography.bodySmall),
          Expanded(
            child: Text(value,
                style: KiranaTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
