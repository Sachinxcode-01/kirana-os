import 'package:flutter/material.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store Profile')),
      body: ListView(
        padding: const EdgeInsets.all(KiranaSpacing.lg),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: KiranaColors.primaryContainer,
                  child: const Icon(
                    Icons.storefront,
                    size: 40,
                    color: KiranaColors.primary,
                  ),
                ),
                const SizedBox(height: KiranaSpacing.md),
                const Text('Gupta General & Provision Store', style: KiranaTypography.titleLarge),
                const Text('Proprietor: Ramesh Gupta', style: KiranaTypography.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: KiranaSpacing.xl),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.phone),
                  title: Text('Primary Mobile'),
                  subtitle: Text('+91 98450 11223'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.receipt),
                  title: Text('GSTIN'),
                  subtitle: Text('29AAAAA0000A1Z5'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.qr_code_2),
                  title: Text('UPI ID for Settlements'),
                  subtitle: Text('guptastore@okaxis'),
                ),
              ],
            ),
          ),
          const SizedBox(height: KiranaSpacing.xl),
          AppButton(
            label: 'Edit Store Profile',
            variant: AppButtonVariant.outlined,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
