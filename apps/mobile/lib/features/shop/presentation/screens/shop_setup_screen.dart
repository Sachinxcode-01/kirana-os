import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kirana_mobile/core/services/pincode_service.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/radius.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_button.dart';
import 'package:kirana_mobile/core/widgets/app_text_field.dart';
import 'package:kirana_mobile/features/shop/presentation/providers/shop_provider.dart';

class ShopSetupScreen extends ConsumerStatefulWidget {
  const ShopSetupScreen({super.key});

  @override
  ConsumerState<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends ConsumerState<ShopSetupScreen> {
  int _currentStep = 0;

  // Step 1 Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController(text: 'Karnataka');
  final _pincodeController = TextEditingController();

  // PIN code auto-fill state
  Timer? _pincodeDebounceTimer;
  bool _isFetchingPincode = false;
  String? _pincodeError;
  List<String> _localities = [];
  String? _selectedLocality;
  final _pincodeService = PincodeService();

  // Step 2 Controllers
  final _gstinController = TextEditingController();
  final _fssaiController = TextEditingController();
  final _upiController = TextEditingController();

  String? _step1Error;

  @override
  void dispose() {
    _pincodeDebounceTimer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _gstinController.dispose();
    _fssaiController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _onPincodeChanged(String value) {
    _pincodeDebounceTimer?.cancel();
    final clean = value.trim();

    if (clean.length < 6) {
      if (_pincodeError != null || _localities.isNotEmpty) {
        setState(() {
          _pincodeError = null;
          _localities = [];
          _selectedLocality = null;
        });
      }
      return;
    }

    if (clean.length == 6) {
      _pincodeDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        _lookupPincode(clean);
      });
    }
  }

  Future<void> _lookupPincode(String pincode) async {
    setState(() {
      _isFetchingPincode = true;
      _pincodeError = null;
    });

    final result = await _pincodeService.fetchAddressFromPincode(pincode);

    if (!mounted) return;

    result.fold(
      (data) {
        setState(() {
          _isFetchingPincode = false;
          _stateController.text = data.state;
          _cityController.text = data.district;
          _localities = data.localities;
          _selectedLocality =
              data.localities.isNotEmpty ? data.localities.first : null;
          _pincodeError = null;
        });
      },
      (failure) {
        setState(() {
          _isFetchingPincode = false;
          _pincodeError = failure.message;
          _stateController.text = '';
          _cityController.text = '';
          _localities = [];
          _selectedLocality = null;
        });
      },
    );
  }

  bool _validateStep1() {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _step1Error = 'Store name is required');
      return false;
    }
    if (_phoneController.text.trim().length < 10) {
      setState(() => _step1Error = 'Enter a valid 10-digit phone number');
      return false;
    }
    setState(() => _step1Error = null);
    return true;
  }

  Future<void> _submitShopCreation() async {
    final success = await ref.read(shopNotifierProvider.notifier).createShop(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          stateName: _stateController.text.trim(),
          pincode: _pincodeController.text.trim(),
          gstin: _gstinController.text.trim().isEmpty
              ? null
              : _gstinController.text.trim(),
          fssaiLicense: _fssaiController.text.trim().isEmpty
              ? null
              : _fssaiController.text.trim(),
          upiId: _upiController.text.trim().isEmpty
              ? null
              : _upiController.text.trim(),
        );

    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Profile Setup'),
        automaticallyImplyLeading: _currentStep > 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentStep--),
              )
            : null,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KiranaSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step Indicator
                Row(
                  children: [
                    _StepCircle(
                        step: 1,
                        currentStep: _currentStep + 1,
                        label: 'Basics'),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: _currentStep >= 1
                            ? KiranaColors.primary
                            : KiranaColors.neutral200,
                      ),
                    ),
                    _StepCircle(
                        step: 2,
                        currentStep: _currentStep + 1,
                        label: 'Business'),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: _currentStep >= 2
                            ? KiranaColors.primary
                            : KiranaColors.neutral200,
                      ),
                    ),
                    _StepCircle(
                        step: 3,
                        currentStep: _currentStep + 1,
                        label: 'Confirm'),
                  ],
                ),
                const SizedBox(height: KiranaSpacing.xxl),

                if (shopState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(KiranaSpacing.md),
                    decoration: BoxDecoration(
                      color: KiranaColors.errorContainer,
                      borderRadius: KiranaRadius.borderMd,
                      border: Border.all(color: KiranaColors.error),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: KiranaColors.error),
                        const SizedBox(width: KiranaSpacing.sm),
                        Expanded(
                          child: Text(
                            shopState.errorMessage!,
                            style: KiranaTypography.bodyMedium
                                .copyWith(color: KiranaColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: KiranaSpacing.lg),
                ],

                if (_currentStep == 0) _buildStep1(),
                if (_currentStep == 1) _buildStep2(),
                if (_currentStep == 2) _buildStep3(shopState.isLoading),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Store Basic Details',
          style: KiranaTypography.headlineMedium
              .copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: KiranaSpacing.xs),
        const Text(
          'Enter your store name and contact information for receipts and billing.',
          style: KiranaTypography.bodyMedium,
        ),
        if (_step1Error != null) ...[
          const SizedBox(height: KiranaSpacing.md),
          Text(_step1Error!,
              style: const TextStyle(color: KiranaColors.error, fontSize: 13)),
        ],
        const SizedBox(height: KiranaSpacing.xl),
        AppTextField(
          label: 'Store Name *',
          hint: 'e.g. Mahadev Provision Store',
          controller: _nameController,
          prefixIcon: const Icon(Icons.storefront_outlined),
        ),
        const SizedBox(height: KiranaSpacing.lg),
        AppTextField(
          label: 'Store Contact Phone *',
          hint: '10-digit mobile number',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(Icons.phone_outlined),
        ),
        const SizedBox(height: KiranaSpacing.lg),
        AppTextField(
          label: 'Store Address',
          hint: 'Shop No, Market Road, Landmark',
          controller: _addressController,
          prefixIcon: const Icon(Icons.location_on_outlined),
        ),
        const SizedBox(height: KiranaSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                label: 'Pincode (Auto-fills Address)',
                hint: '6-digit PIN (e.g. 560038)',
                controller: _pincodeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: _onPincodeChanged,
                suffixIcon: _isFetchingPincode
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.pin_drop_outlined),
              ),
            ),
            const SizedBox(width: KiranaSpacing.md),
            Expanded(
              child: AppTextField(
                label: 'City / District',
                hint: 'e.g. Bangalore',
                controller: _cityController,
              ),
            ),
          ],
        ),
        if (_pincodeError != null) ...[
          const SizedBox(height: KiranaSpacing.xs),
          Text(
            _pincodeError!,
            style: const TextStyle(color: KiranaColors.error, fontSize: 13),
          ),
        ],
        if (_localities.isNotEmpty) ...[
          const SizedBox(height: KiranaSpacing.lg),
          Text(
            'Select Locality / Area',
            style: KiranaTypography.labelLarge.copyWith(
              color: KiranaColors.textSecondary,
            ),
          ),
          const SizedBox(height: KiranaSpacing.xs),
          DropdownButtonFormField<String>(
            initialValue: _selectedLocality,
            decoration: const InputDecoration(
              filled: true,
              fillColor: KiranaColors.surfaceVariant,
              contentPadding: EdgeInsets.symmetric(
                horizontal: KiranaSpacing.lg,
                vertical: KiranaSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: KiranaRadius.borderMd,
                borderSide: BorderSide(color: KiranaColors.outline),
              ),
            ),
            items: _localities.map((locality) {
              return DropdownMenuItem<String>(
                value: locality,
                child: Text(locality, style: KiranaTypography.bodyLarge),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedLocality = val;
                  if (_addressController.text.trim().isEmpty) {
                    _addressController.text = val;
                  }
                });
              }
            },
          ),
        ],
        const SizedBox(height: KiranaSpacing.lg),
        AppTextField(
          label: 'State',
          hint: 'e.g. Karnataka',
          controller: _stateController,
          readOnly: true,
        ),
        const SizedBox(height: KiranaSpacing.xxl),
        AppButton(
          label: 'Next: Business & Tax Info →',
          onPressed: () {
            if (_validateStep1()) {
              setState(() => _currentStep = 1);
            }
          },
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Business & Tax Details (Optional)',
          style: KiranaTypography.headlineMedium
              .copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: KiranaSpacing.xs),
        const Text(
          'Add GSTIN, FSSAI license, or UPI ID to print instant dynamic QR codes on bills.',
          style: KiranaTypography.bodyMedium,
        ),
        const SizedBox(height: KiranaSpacing.xl),
        AppTextField(
          label: 'GSTIN (Optional)',
          hint: '15-character GSTIN (e.g. 29AAAAA0000A1Z5)',
          controller: _gstinController,
          prefixIcon: const Icon(Icons.receipt_outlined),
        ),
        const SizedBox(height: KiranaSpacing.lg),
        AppTextField(
          label: 'FSSAI License (Optional)',
          hint: '14-digit FSSAI Number',
          controller: _fssaiController,
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.verified_outlined),
        ),
        const SizedBox(height: KiranaSpacing.lg),
        AppTextField(
          label: 'UPI ID for QR Payments (Optional)',
          hint: 'e.g. yourstore@okhdfcbank',
          controller: _upiController,
          prefixIcon: const Icon(Icons.qr_code_2_outlined),
        ),
        const SizedBox(height: KiranaSpacing.xxl),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 0),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: KiranaSpacing.md),
            Expanded(
              child: AppButton(
                label: 'Review & Finish →',
                onPressed: () => setState(() => _currentStep = 2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Confirm Store Creation',
          style: KiranaTypography.headlineMedium
              .copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: KiranaSpacing.xs),
        const Text(
          'Verify your details before initializing the store ledger and product catalog.',
          style: KiranaTypography.bodyMedium,
        ),
        const SizedBox(height: KiranaSpacing.xl),
        Container(
          padding: const EdgeInsets.all(KiranaSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: KiranaRadius.borderMd,
            border: Border.all(color: KiranaColors.neutral200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryRow(
                  label: 'Store Name', value: _nameController.text.trim()),
              _SummaryRow(label: 'Phone', value: _phoneController.text.trim()),
              if (_addressController.text.isNotEmpty)
                _SummaryRow(
                    label: 'Address', value: _addressController.text.trim()),
              if (_cityController.text.isNotEmpty)
                _SummaryRow(
                    label: 'City & State',
                    value:
                        '${_cityController.text.trim()}, ${_stateController.text}'),
              if (_gstinController.text.isNotEmpty)
                _SummaryRow(
                    label: 'GSTIN', value: _gstinController.text.trim()),
              if (_upiController.text.isNotEmpty)
                _SummaryRow(label: 'UPI ID', value: _upiController.text.trim()),
            ],
          ),
        ),
        const SizedBox(height: KiranaSpacing.xxl),
        AppButton(
          label: 'Create Store & Open POS Dashboard',
          isLoading: isLoading,
          onPressed: isLoading ? null : _submitShopCreation,
        ),
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int step;
  final int currentStep;
  final String label;

  const _StepCircle({
    required this.step,
    required this.currentStep,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentStep >= step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? KiranaColors.primary : KiranaColors.neutral200,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : KiranaColors.neutral700,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? KiranaColors.primary : KiranaColors.neutral500,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KiranaSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: KiranaTypography.bodySmall
                  .copyWith(color: KiranaColors.neutral600)),
          Text(value,
              style: KiranaTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
