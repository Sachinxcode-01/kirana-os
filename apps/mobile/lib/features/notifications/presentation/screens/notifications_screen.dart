import 'package:flutter/material.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alerts = [
      ('Low Stock Alert', 'Fortune Sunflower Oil 1L has only 3 units left.', Icons.warning, KiranaColors.error),
      ('Udhaar Due Reminder', 'Dr. Srinivas Rao outstanding balance reached ₹3,400.00.', Icons.notification_important, KiranaColors.secondary),
      ('Cloud Sync Complete', 'All 42 offline bills synchronized with Supabase.', Icons.cloud_done, KiranaColors.success),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications & Alerts')),
      body: ListView.separated(
        padding: const EdgeInsets.all(KiranaSpacing.md),
        itemCount: alerts.length,
        separatorBuilder: (_, __) => const SizedBox(height: KiranaSpacing.sm),
        itemBuilder: (context, index) {
          final (title, body, icon, color) = alerts[index];
          return Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(KiranaSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              title: Text(title, style: KiranaTypography.titleMedium),
              subtitle: Text(body, style: KiranaTypography.bodyMedium),
            ),
          );
        },
      ),
    );
  }
}
