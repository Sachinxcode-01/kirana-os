import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../receipts/domain/models/printer_device_model.dart';
import '../../../receipts/presentation/providers/printer_provider.dart';

class PrinterSettingsScreen extends ConsumerWidget {
  const PrinterSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final printerState = ref.watch(printerNotifierProvider);
    final printerNotifier = ref.read(printerNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thermal Printer Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rescan Printers',
            onPressed: printerState.isScanning
                ? null
                : () => printerNotifier.scanPrinters(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(KiranaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Success & Error Messages
            if (printerState.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: KiranaSpacing.md),
                padding: const EdgeInsets.all(KiranaSpacing.sm),
                decoration: BoxDecoration(
                  color: KiranaColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: KiranaColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: KiranaColors.error),
                    const SizedBox(width: KiranaSpacing.xs),
                    Expanded(
                      child: Text(
                        printerState.errorMessage!,
                        style: KiranaTypography.bodySmall
                            .copyWith(color: KiranaColors.error),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => printerNotifier.clearMessages(),
                    ),
                  ],
                ),
              ),

            if (printerState.successMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: KiranaSpacing.md),
                padding: const EdgeInsets.all(KiranaSpacing.sm),
                decoration: BoxDecoration(
                  color: KiranaColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: KiranaColors.success),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: KiranaColors.success),
                    const SizedBox(width: KiranaSpacing.xs),
                    Expanded(
                      child: Text(
                        printerState.successMessage!,
                        style: KiranaTypography.bodySmall
                            .copyWith(color: KiranaColors.success),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => printerNotifier.clearMessages(),
                    ),
                  ],
                ),
              ),

            // 2. Active Printer Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(KiranaSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CONNECTED PRINTER',
                          style: KiranaTypography.labelSmall.copyWith(
                            color: KiranaColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: KiranaSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: printerState.isConnected
                                ? KiranaColors.success.withValues(alpha: 0.15)
                                : printerState.isConnecting
                                    ? KiranaColors.warning
                                        .withValues(alpha: 0.15)
                                    : KiranaColors.error
                                        .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            printerState.isConnecting
                                ? 'CONNECTING'
                                : printerState.isConnected
                                    ? 'CONNECTED'
                                    : 'DISCONNECTED',
                            style: KiranaTypography.labelSmall.copyWith(
                              color: printerState.isConnected
                                  ? KiranaColors.success
                                  : printerState.isConnecting
                                      ? KiranaColors.warning
                                      : KiranaColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: KiranaSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.print,
                          size: 32,
                          color: printerState.isConnected
                              ? KiranaColors.primary
                              : KiranaColors.textSecondary,
                        ),
                        const SizedBox(width: KiranaSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                printerState.selectedPrinter?.name ??
                                    'No Printer Configured',
                                style: KiranaTypography.titleMedium,
                              ),
                              Text(
                                printerState.selectedPrinter?.address != null
                                    ? 'Bluetooth MAC: ${printerState.selectedPrinter!.address}'
                                    : 'Scan and select a Bluetooth thermal printer below',
                                style: KiranaTypography.bodySmall.copyWith(
                                  color: KiranaColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: KiranaSpacing.lg),

                    // Test Print & Disconnect Buttons
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'TEST PRINT',
                            icon: Icons.print_outlined,
                            isLoading: printerState.isPrinting,
                            onPressed: printerState.selectedPrinter == null
                                ? null
                                : () => printerNotifier.sendTestPrint(),
                          ),
                        ),
                        if (printerState.selectedPrinter != null) ...[
                          const SizedBox(width: KiranaSpacing.xs),
                          OutlinedButton.icon(
                            onPressed: () =>
                                printerNotifier.disconnectPrinter(),
                            icon: const Icon(Icons.link_off, size: 16),
                            label: const Text('Disconnect'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().fade(duration: 200.ms),

            const SizedBox(height: KiranaSpacing.md),

            // 3. Paper Width Selection
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(KiranaSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Paper Width Setting',
                        style: KiranaTypography.titleMedium),
                    Text(
                      'Select paper roll width used by your receipt printer',
                      style: KiranaTypography.bodySmall,
                    ),
                    const SizedBox(height: KiranaSpacing.sm),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('58mm (32 Columns)'),
                          selected:
                              printerState.paperWidth == PrinterPaperWidth.mm58,
                          onSelected: (_) => printerNotifier
                              .setPaperWidth(PrinterPaperWidth.mm58),
                        ),
                        const SizedBox(width: KiranaSpacing.xs),
                        ChoiceChip(
                          label: const Text('80mm (48 Columns)'),
                          selected:
                              printerState.paperWidth == PrinterPaperWidth.mm80,
                          onSelected: (_) => printerNotifier
                              .setPaperWidth(PrinterPaperWidth.mm80),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: KiranaSpacing.md),

            // 4. Bluetooth Scanner & Devices List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bluetooth Discovery',
                    style: KiranaTypography.titleMedium),
                ElevatedButton.icon(
                  onPressed: printerState.isScanning
                      ? null
                      : () => printerNotifier.scanPrinters(),
                  icon: printerState.isScanning
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bluetooth_searching, size: 16),
                  label: Text(printerState.isScanning
                      ? 'Scanning...'
                      : 'Scan Bluetooth'),
                ),
              ],
            ),
            const SizedBox(height: KiranaSpacing.xs),

            if (printerState.availablePrinters.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(KiranaSpacing.lg),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.bluetooth,
                            size: 40, color: KiranaColors.textSecondary),
                        const SizedBox(height: KiranaSpacing.xs),
                        Text(
                          'No Bluetooth printers discovered yet.',
                          style: KiranaTypography.bodyMedium,
                        ),
                        Text(
                          'Ensure printer is turned ON and Bluetooth is enabled on device.',
                          style: KiranaTypography.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: printerState.availablePrinters.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: KiranaSpacing.xs),
                itemBuilder: (context, index) {
                  final device = printerState.availablePrinters[index];
                  final isSelected =
                      printerState.selectedPrinter?.address == device.address;

                  return Card(
                    color: isSelected
                        ? KiranaColors.primaryContainer.withValues(alpha: 0.3)
                        : null,
                    child: ListTile(
                      leading: Icon(
                        device.connectionType == 'bluetooth'
                            ? Icons.bluetooth
                            : Icons.usb,
                        color: KiranaColors.primary,
                      ),
                      title: Text(device.name,
                          style: KiranaTypography.titleMedium),
                      subtitle: Text(
                        'Address: ${device.address} · Type: ${device.connectionType.toUpperCase()}',
                        style: KiranaTypography.bodySmall,
                      ),
                      trailing: isSelected && printerState.isConnected
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: KiranaSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    KiranaColors.success.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: KiranaTypography.labelSmall.copyWith(
                                  color: KiranaColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: printerState.isConnecting
                                  ? null
                                  : () => printerNotifier
                                      .selectAndConnectPrinter(device),
                              child: const Text('Connect'),
                            ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
