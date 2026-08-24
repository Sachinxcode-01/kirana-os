import 'package:flutter/material.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_button.dart';
import 'package:kirana_mobile/core/widgets/app_text_field.dart';

// --- DOMAIN LAYER ---
class ShopProfileEntity {
  final String name;
  final String phone;
  final String? gstin;
  final String? upiId;

  const ShopProfileEntity({
    required this.name,
    required this.phone,
    this.gstin,
    this.upiId,
  });
}

// --- PRESENTATION LAYER ---
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstinController = TextEditingController();
  final _upiController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Your Kirana Store')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(KiranaSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Shop Details', style: KiranaTypography.headlineMedium),
            const SizedBox(height: KiranaSpacing.xs),
            const Text(
              'Enter your store profile to enable billing and digital invoices.',
              style: KiranaTypography.bodyMedium,
            ),
            const SizedBox(height: KiranaSpacing.xl),
            AppTextField(
              label: 'Shop Name *',
              hint: 'e.g. Gupta Provision & General Store',
              controller: _nameController,
            ),
            const SizedBox(height: KiranaSpacing.lg),
            AppTextField(
              label: 'Contact Phone *',
              hint: '10-digit phone number',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: KiranaSpacing.lg),
            AppTextField(
              label: 'GSTIN (Optional)',
              hint: '15-character GSTIN',
              controller: _gstinController,
            ),
            const SizedBox(height: KiranaSpacing.lg),
            AppTextField(
              label: 'UPI ID for QR Payments (Optional)',
              hint: 'e.g. yourshop@okaxis',
              controller: _upiController,
            ),
            const SizedBox(height: KiranaSpacing.xxl),
            AppButton(
              label: 'Complete Setup & Open POS',
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
