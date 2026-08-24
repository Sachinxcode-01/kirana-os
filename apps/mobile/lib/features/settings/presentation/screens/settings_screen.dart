import 'package:flutter/material.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('POS & Hardware Settings')),
      body: ListView(
        padding: const EdgeInsets.all(KiranaSpacing.md),
        children: [
          const Text('Hardware Integrations', style: KiranaTypography.titleLarge),
          const SizedBox(height: KiranaSpacing.sm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.print),
                  title: const Text('Thermal Printer Setup'),
                  subtitle: const Text('ESC/POS Bluetooth 58mm paired'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner),
                  title: const Text('Barcode Scanner Configuration'),
                  subtitle: const Text('USB HID Barcode Gun (Auto-Enter enabled)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: KiranaSpacing.lg),
          const Text('Cloud Synchronization & Backup', style: KiranaTypography.titleLarge),
          const SizedBox(height: KiranaSpacing.sm),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.cloud_sync),
                  title: const Text('Auto Cloud Sync'),
                  subtitle: const Text('Sync transactions as soon as internet is available'),
                  value: true,
                  onChanged: (val) {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Export Local Database Backup'),
                  subtitle: const Text('Save encrypted SQLite backup to SD card/Drive'),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
