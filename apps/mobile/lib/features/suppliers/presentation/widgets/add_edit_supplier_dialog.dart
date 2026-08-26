import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/radius.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/models/supplier_model.dart';
import '../providers/supplier_provider.dart';

class AddEditSupplierDialog extends ConsumerStatefulWidget {
  final SupplierModel? supplierToEdit;

  const AddEditSupplierDialog({super.key, this.supplierToEdit});

  @override
  ConsumerState<AddEditSupplierDialog> createState() =>
      _AddEditSupplierDialogState();
}

class _AddEditSupplierDialogState extends ConsumerState<AddEditSupplierDialog> {
  late TextEditingController _nameController;
  late TextEditingController _contactPersonController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _gstinController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;

  String? _nameError;
  String? _phoneError;
  String? _emailError;
  String? _gstinError;

  @override
  void initState() {
    super.initState();
    final s = widget.supplierToEdit;
    _nameController = TextEditingController(text: s?.name ?? '');
    _contactPersonController =
        TextEditingController(text: s?.contactPerson ?? '');
    _phoneController = TextEditingController(text: s?.phone ?? '');
    _emailController = TextEditingController(text: s?.email ?? '');
    _gstinController = TextEditingController(text: s?.gstin ?? '');
    _addressController = TextEditingController(text: s?.address ?? '');
    _notesController = TextEditingController(text: s?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    bool valid = true;
    setState(() {
      _nameError = null;
      _phoneError = null;
      _emailError = null;
      _gstinError = null;
    });

    final name = _nameController.text.trim();
    final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final email = _emailController.text.trim();
    final gstin = _gstinController.text.trim();

    if (name.length < 2) {
      setState(() => _nameError = 'Enter supplier name (min 2 characters)');
      valid = false;
    }

    if (!SupplierModel.isValidPhone(phone)) {
      setState(() => _phoneError = 'Enter a valid 10-digit phone number');
      valid = false;
    }

    if (email.isNotEmpty && !SupplierModel.isValidEmail(email)) {
      setState(() => _emailError = 'Enter a valid email address');
      valid = false;
    }

    if (gstin.isNotEmpty && !SupplierModel.isValidGstin(gstin)) {
      setState(() => _gstinError = 'GSTIN must be 15 characters long');
      valid = false;
    }

    return valid;
  }

  Future<void> _submit() async {
    if (!_validateForm()) return;

    final notifier = ref.read(supplierFormNotifierProvider.notifier);
    bool success;

    if (widget.supplierToEdit != null) {
      final updated = widget.supplierToEdit!.copyWith(
        name: _nameController.text.trim(),
        contactPerson: _contactPersonController.text.trim().isEmpty
            ? null
            : _contactPersonController.text.trim(),
        phone: _phoneController.text.replaceAll(RegExp(r'\D'), ''),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        gstin: _gstinController.text.trim().isEmpty
            ? null
            : _gstinController.text.trim().toUpperCase(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      success = await notifier.updateSupplier(updated);
    } else {
      success = await notifier.createSupplier(
        name: _nameController.text.trim(),
        phone: _phoneController.text.replaceAll(RegExp(r'\D'), ''),
        contactPerson: _contactPersonController.text.trim().isEmpty
            ? null
            : _contactPersonController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        gstin: _gstinController.text.trim().isEmpty
            ? null
            : _gstinController.text.trim().toUpperCase(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
    }

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(supplierFormNotifierProvider);
    final isEditing = widget.supplierToEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: KiranaRadius.borderLg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KiranaSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Supplier' : 'Add New Supplier',
                    style: KiranaTypography.headlineMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: KiranaSpacing.md),
              if (formState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(KiranaSpacing.sm),
                  decoration: BoxDecoration(
                    color: KiranaColors.errorContainer,
                    borderRadius: KiranaRadius.borderSm,
                  ),
                  child: Text(
                    formState.errorMessage!,
                    style: KiranaTypography.bodySmall
                        .copyWith(color: KiranaColors.error),
                  ),
                ),
                const SizedBox(height: KiranaSpacing.md),
              ],
              AppTextField(
                label: 'Business / Company Name *',
                hint: 'e.g. Metro Wholesale Dist',
                controller: _nameController,
                errorText: _nameError,
                prefixIcon: const Icon(Icons.business),
              ),
              const SizedBox(height: KiranaSpacing.md),
              AppTextField(
                label: 'Contact Person (Optional)',
                hint: 'e.g. Rajesh Sharma',
                controller: _contactPersonController,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              const SizedBox(height: KiranaSpacing.md),
              AppTextField(
                label: 'Contact Phone Number *',
                hint: '10-digit mobile number',
                controller: _phoneController,
                errorText: _phoneError,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              const SizedBox(height: KiranaSpacing.md),
              AppTextField(
                label: 'Email Address (Optional)',
                hint: 'supplier@company.com',
                controller: _emailController,
                errorText: _emailError,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              const SizedBox(height: KiranaSpacing.md),
              AppTextField(
                label: 'GSTIN (Optional)',
                hint: '15-digit GSTIN (e.g. 29AAAAA0000A1Z5)',
                controller: _gstinController,
                errorText: _gstinError,
                prefixIcon: const Icon(Icons.receipt_long_outlined),
              ),
              const SizedBox(height: KiranaSpacing.md),
              AppTextField(
                label: 'Address (Optional)',
                hint: 'Warehouse/Office Address',
                controller: _addressController,
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
              const SizedBox(height: KiranaSpacing.md),
              AppTextField(
                label: 'Notes (Optional)',
                hint: 'Delivery schedules, payment terms...',
                controller: _notesController,
                prefixIcon: const Icon(Icons.note_outlined),
              ),
              const SizedBox(height: KiranaSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: KiranaSpacing.md),
                  Expanded(
                    child: AppButton(
                      label: isEditing ? 'Save Changes' : 'Create Supplier',
                      isLoading: formState.isLoading,
                      onPressed: formState.isLoading ? null : _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
