import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/app/app_providers.dart';
import 'package:kirana_mobile/core/network/connectivity_status.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/radius.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:kirana_mobile/features/staff/domain/models/staff_member_model.dart';
import '../../domain/models/shop_settings_model.dart';
import '../providers/shop_settings_provider.dart';

class ShopSettingsScreen extends ConsumerStatefulWidget {
  const ShopSettingsScreen({super.key});

  @override
  ConsumerState<ShopSettingsScreen> createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends ConsumerState<ShopSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Shop Information Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _gstinController;

  // Tax & Currency Controllers / State
  String _selectedCurrencySymbol = '₹';
  bool _isTaxEnabled = true;
  late TextEditingController _taxPercentageController;

  // Default Bill Settings Controllers / State
  late TextEditingController _billPrefixController;
  late TextEditingController _nextInvoiceNumberController;
  bool _showShopAddress = true;
  bool _showCustomerDetails = true;
  bool _showTaxInformation = true;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController(text: 'Karnataka');
    _pincodeController = TextEditingController();
    _gstinController = TextEditingController();

    _taxPercentageController = TextEditingController(text: '0.0');
    _billPrefixController = TextEditingController(text: 'INV-');
    _nextInvoiceNumberController = TextEditingController(text: '1001');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeShopId = ref.read(activeShopIdProvider);
      ref
          .read(shopSettingsNotifierProvider.notifier)
          .loadSettings(activeShopId);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _gstinController.dispose();
    _taxPercentageController.dispose();
    _billPrefixController.dispose();
    _nextInvoiceNumberController.dispose();
    super.dispose();
  }

  void _populateFields(ShopSettingsModel settings) {
    if (_isInitialized) return;
    _isInitialized = true;

    _nameController.text = settings.shopName;
    _phoneController.text = settings.phone;
    _addressController.text = settings.address ?? '';
    _cityController.text = settings.city ?? '';
    _stateController.text = settings.state;
    _pincodeController.text = settings.pincode ?? '';
    _gstinController.text = settings.gstin ?? '';

    _selectedCurrencySymbol = settings.currencySymbol;
    _isTaxEnabled = settings.isTaxEnabled;
    _taxPercentageController.text = settings.defaultTaxPercentage.toString();

    _billPrefixController.text = settings.billPrefix;
    _nextInvoiceNumberController.text = settings.nextInvoiceNumber.toString();
    _showShopAddress = settings.showShopAddress;
    _showCustomerDetails = settings.showCustomerDetails;
    _showTaxInformation = settings.showTaxInformation;
  }

  Future<void> _submitSave() async {
    if (!_formKey.currentState!.validate()) return;

    final currentSettings = ref.read(shopSettingsNotifierProvider).settings ??
        ShopSettingsModel(
          shopId: ref.read(activeShopIdProvider),
          shopName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        );

    final taxPercentage =
        double.tryParse(_taxPercentageController.text.trim()) ?? 0.0;
    final nextInvoiceNo =
        int.tryParse(_nextInvoiceNumberController.text.trim()) ?? 1001;

    final updatedSettings = currentSettings.copyWith(
      shopName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      city: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      state: _stateController.text.trim().isEmpty
          ? 'Karnataka'
          : _stateController.text.trim(),
      pincode: _pincodeController.text.trim().isEmpty
          ? null
          : _pincodeController.text.trim(),
      gstin: _gstinController.text.trim().isEmpty
          ? null
          : _gstinController.text.trim(),
      currencySymbol: _selectedCurrencySymbol,
      isTaxEnabled: _isTaxEnabled,
      defaultTaxPercentage: taxPercentage,
      billPrefix: _billPrefixController.text.trim(),
      nextInvoiceNumber: nextInvoiceNo,
      showShopAddress: _showShopAddress,
      showCustomerDetails: _showCustomerDetails,
      showTaxInformation: _showTaxInformation,
    );

    final success = await ref
        .read(shopSettingsNotifierProvider.notifier)
        .saveSettings(updatedSettings);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop settings saved successfully!'),
          backgroundColor: KiranaColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(shopSettingsNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final userRole =
        StaffRoleExtension.fromString(authState.user?.role ?? 'cashier');
    final isAuthorized =
        userRole == StaffRole.owner || userRole == StaffRole.manager;

    final connectivity =
        ref.watch(connectivityStatusStreamProvider).valueOrNull ??
            ConnectivityStatus.online;
    final isOffline = connectivity == ConnectivityStatus.offline;

    if (settingsState.settings != null && !_isInitialized) {
      _populateFields(settingsState.settings!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Settings'),
        actions: [
          if (isOffline)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: KiranaColors.warning.withValues(alpha: 0.1),
                    borderRadius: KiranaRadius.borderPill,
                    border: Border.all(
                        color: KiranaColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'OFFLINE CACHED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: KiranaColors.warning,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: settingsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(KiranaSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isAuthorized) ...[
                      Container(
                        padding: const EdgeInsets.all(KiranaSpacing.md),
                        decoration: BoxDecoration(
                          color: KiranaColors.warning.withValues(alpha: 0.1),
                          borderRadius: KiranaRadius.borderMd,
                          border: Border.all(
                              color:
                                  KiranaColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_outline,
                                color: KiranaColors.warning, size: 20),
                            SizedBox(width: KiranaSpacing.sm),
                            Expanded(
                              child: Text(
                                'Only Shop Owners and Managers can modify settings. Settings are displayed in read-only mode.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: KiranaColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: KiranaSpacing.lg),
                    ],

                    if (settingsState.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(KiranaSpacing.md),
                        decoration: BoxDecoration(
                          color: KiranaColors.error.withValues(alpha: 0.1),
                          borderRadius: KiranaRadius.borderMd,
                          border: Border.all(
                              color: KiranaColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          settingsState.errorMessage!,
                          style: const TextStyle(
                              color: KiranaColors.error, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: KiranaSpacing.lg),
                    ],

                    // 1. SHOP INFORMATION SECTION
                    _buildSectionHeader(
                      icon: Icons.storefront,
                      title: 'Shop Information',
                      subtitle: 'Basic contact and GST details',
                    ),
                    const SizedBox(height: KiranaSpacing.sm),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(KiranaSpacing.md),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              enabled: isAuthorized && !settingsState.isSaving,
                              decoration: const InputDecoration(
                                labelText: 'Shop Name *',
                                prefixIcon: Icon(Icons.store),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                      ? 'Shop name is required'
                                      : null,
                            ),
                            const SizedBox(height: KiranaSpacing.md),
                            TextFormField(
                              controller: _phoneController,
                              enabled: isAuthorized && !settingsState.isSaving,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number *',
                                prefixIcon: Icon(Icons.phone),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().length < 10
                                      ? 'Valid 10-digit phone required'
                                      : null,
                            ),
                            const SizedBox(height: KiranaSpacing.md),
                            TextFormField(
                              controller: _addressController,
                              enabled: isAuthorized && !settingsState.isSaving,
                              decoration: const InputDecoration(
                                labelText: 'Street Address',
                                prefixIcon: Icon(Icons.location_on_outlined),
                              ),
                            ),
                            const SizedBox(height: KiranaSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _cityController,
                                    enabled:
                                        isAuthorized && !settingsState.isSaving,
                                    decoration: const InputDecoration(
                                      labelText: 'City',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: KiranaSpacing.md),
                                Expanded(
                                  child: TextFormField(
                                    controller: _pincodeController,
                                    enabled:
                                        isAuthorized && !settingsState.isSaving,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Pincode',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: KiranaSpacing.md),
                            TextFormField(
                              controller: _gstinController,
                              enabled: isAuthorized && !settingsState.isSaving,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'GSTIN (Optional)',
                                prefixIcon: Icon(Icons.receipt_long),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: KiranaSpacing.xl),

                    // 2. CURRENCY & TAX SECTION
                    _buildSectionHeader(
                      icon: Icons.currency_rupee,
                      title: 'Tax & Currency Settings',
                      subtitle:
                          'Configure currency symbol and default tax rates',
                    ),
                    const SizedBox(height: KiranaSpacing.sm),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(KiranaSpacing.md),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _selectedCurrencySymbol,
                              decoration: const InputDecoration(
                                labelText: 'Currency Symbol',
                                prefixIcon:
                                    Icon(Icons.monetization_on_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: '₹',
                                    child: Text('₹ (INR - Indian Rupee)')),
                                DropdownMenuItem(
                                    value: '\$',
                                    child: Text('\$ (USD - US Dollar)')),
                                DropdownMenuItem(
                                    value: '€', child: Text('€ (EUR - Euro)')),
                                DropdownMenuItem(
                                    value: '£',
                                    child: Text('£ (GBP - British Pound)')),
                              ],
                              onChanged: isAuthorized && !settingsState.isSaving
                                  ? (val) {
                                      if (val != null) {
                                        setState(() =>
                                            _selectedCurrencySymbol = val);
                                      }
                                    }
                                  : null,
                            ),
                            const SizedBox(height: KiranaSpacing.md),
                            SwitchListTile(
                              title: const Text('Enable Default Tax'),
                              subtitle: const Text(
                                  'Apply default tax percentage on billing'),
                              value: _isTaxEnabled,
                              onChanged: isAuthorized && !settingsState.isSaving
                                  ? (val) => setState(() => _isTaxEnabled = val)
                                  : null,
                            ),
                            if (_isTaxEnabled) ...[
                              const SizedBox(height: KiranaSpacing.sm),
                              TextFormField(
                                controller: _taxPercentageController,
                                enabled:
                                    isAuthorized && !settingsState.isSaving,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Default Tax Percentage (%) *',
                                  suffixText: '%',
                                  prefixIcon: Icon(Icons.percent),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Tax percentage is required';
                                  }
                                  final num = double.tryParse(val.trim());
                                  if (num == null || num < 0 || num > 100) {
                                    return 'Must be between 0% and 100%';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: KiranaSpacing.xl),

                    // 3. BILL DEFAULT SETTINGS SECTION
                    _buildSectionHeader(
                      icon: Icons.receipt,
                      title: 'Bill & Invoice Defaults',
                      subtitle:
                          'Configure default numbering and invoice header rules',
                    ),
                    const SizedBox(height: KiranaSpacing.sm),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(KiranaSpacing.md),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _billPrefixController,
                                    enabled:
                                        isAuthorized && !settingsState.isSaving,
                                    decoration: const InputDecoration(
                                      labelText: 'Invoice Prefix *',
                                      prefixIcon: Icon(Icons.tag),
                                    ),
                                    validator: (val) =>
                                        val == null || val.trim().isEmpty
                                            ? 'Prefix required'
                                            : null,
                                  ),
                                ),
                                const SizedBox(width: KiranaSpacing.md),
                                Expanded(
                                  child: TextFormField(
                                    controller: _nextInvoiceNumberController,
                                    enabled:
                                        isAuthorized && !settingsState.isSaving,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Next Invoice No. *',
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      final num = int.tryParse(val.trim());
                                      if (num == null || num < 1) {
                                        return 'Must be >= 1';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: KiranaSpacing.md),
                            CheckboxListTile(
                              title: const Text('Show Shop Address on Bill'),
                              value: _showShopAddress,
                              onChanged: isAuthorized && !settingsState.isSaving
                                  ? (val) => setState(
                                      () => _showShopAddress = val ?? true)
                                  : null,
                            ),
                            CheckboxListTile(
                              title:
                                  const Text('Show Customer Details on Bill'),
                              value: _showCustomerDetails,
                              onChanged: isAuthorized && !settingsState.isSaving
                                  ? (val) => setState(
                                      () => _showCustomerDetails = val ?? true)
                                  : null,
                            ),
                            CheckboxListTile(
                              title: const Text('Show Tax Details Breakdown'),
                              value: _showTaxInformation,
                              onChanged: isAuthorized && !settingsState.isSaving
                                  ? (val) => setState(
                                      () => _showTaxInformation = val ?? true)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: KiranaSpacing.xxl),

                    if (isAuthorized)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: KiranaColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: settingsState.isSaving ? null : _submitSave,
                        icon: settingsState.isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          settingsState.isSaving
                              ? 'SAVING SETTINGS...'
                              : 'SAVE SHOP SETTINGS',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: KiranaColors.primaryContainer,
          child: Icon(icon, color: KiranaColors.primary, size: 20),
        ),
        const SizedBox(width: KiranaSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: KiranaTypography.titleMedium),
            Text(
              subtitle,
              style: KiranaTypography.bodySmall
                  .copyWith(color: KiranaColors.neutral600),
            ),
          ],
        ),
      ],
    );
  }
}
