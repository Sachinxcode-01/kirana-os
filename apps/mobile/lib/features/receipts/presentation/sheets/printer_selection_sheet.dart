import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/models/printer_device_model.dart';
import '../providers/printer_provider.dart';

class PrinterSelectionSheet extends ConsumerStatefulWidget {
  const PrinterSelectionSheet({super.key});

  @override
  ConsumerState<PrinterSelectionSheet> createState() =>
      _PrinterSelectionSheetState();
}

class _PrinterSelectionSheetState extends ConsumerState<PrinterSelectionSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(printerNotifierProvider.notifier).scanPrinters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final printerState = ref.watch(printerNotifierProvider);
    final notifier = ref.read(printerNotifierProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(KiranaSpacing.md),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Printer Settings', style: KiranaTypography.titleLarge),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: printerState.isScanning
                    ? null
                    : () => notifier.scanPrinters(),
              ),
            ],
          ),
          const SizedBox(height: KiranaSpacing.xs),

          // Paper Width Selector
          Row(
            children: [
              const Text('Paper Width: ', style: KiranaTypography.labelLarge),
              const SizedBox(width: KiranaSpacing.xs),
              ChoiceChip(
                label: const Text('58mm (32 Col)'),
                selected: printerState.paperWidth == PrinterPaperWidth.mm58,
                onSelected: (val) {
                  if (val) notifier.setPaperWidth(PrinterPaperWidth.mm58);
                },
              ),
              const SizedBox(width: KiranaSpacing.xs),
              ChoiceChip(
                label: const Text('80mm (48 Col)'),
                selected: printerState.paperWidth == PrinterPaperWidth.mm80,
                onSelected: (val) {
                  if (val) notifier.setPaperWidth(PrinterPaperWidth.mm80);
                },
              ),
            ],
          ),
          const Divider(height: KiranaSpacing.md),

          // Selected Printer Status
          if (printerState.selectedPrinter != null)
            Card(
              color: KiranaColors.primaryContainer,
              child: ListTile(
                leading:
                    const Icon(Icons.print, color: KiranaColors.primaryDark),
                title: Text(printerState.selectedPrinter!.name,
                    style: KiranaTypography.titleMedium),
                subtitle: Text(
                  '${printerState.selectedPrinter!.connectionType.toUpperCase()} • ${printerState.paperWidth.label} • ${printerState.isConnected ? 'Connected' : 'Disconnected'}',
                  style: KiranaTypography.bodySmall,
                ),
                trailing: TextButton(
                  onPressed: printerState.isPrinting
                      ? null
                      : () => notifier.sendTestPrint(),
                  child: const Text('Test Print'),
                ),
              ),
            ),

          if (printerState.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(top: KiranaSpacing.xs),
              padding: const EdgeInsets.all(KiranaSpacing.xs),
              decoration: BoxDecoration(
                color: KiranaColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: KiranaColors.error, size: 18),
                  const SizedBox(width: KiranaSpacing.xxs),
                  Expanded(
                    child: Text(
                      printerState.errorMessage!,
                      style: KiranaTypography.bodySmall
                          .copyWith(color: KiranaColors.error),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: KiranaSpacing.sm),
          Text('Available Devices', style: KiranaTypography.labelLarge),
          const SizedBox(height: KiranaSpacing.xs),

          Expanded(
            child: printerState.isScanning
                ? const Center(child: CircularProgressIndicator())
                : printerState.availablePrinters.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.print_disabled,
                                size: 48, color: KiranaColors.textSecondary),
                            const SizedBox(height: KiranaSpacing.xs),
                            const Text('No thermal printers found.'),
                            TextButton(
                              onPressed: () => notifier.scanPrinters(),
                              child: const Text('Scan Again'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: printerState.availablePrinters.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final device = printerState.availablePrinters[index];
                          final isSelected =
                              printerState.selectedPrinter?.id == device.id;

                          return ListTile(
                            leading: Icon(
                              device.connectionType == 'bluetooth'
                                  ? Icons.bluetooth
                                  : Icons.usb,
                              color: KiranaColors.primary,
                            ),
                            title: Text(device.name),
                            subtitle: Text(
                                '${device.address} (${device.paperWidth.label})'),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle,
                                    color: KiranaColors.success)
                                : ElevatedButton(
                                    onPressed: printerState.isConnecting
                                        ? null
                                        : () => notifier
                                            .selectAndConnectPrinter(device),
                                    child: const Text('Connect'),
                                  ),
                          );
                        },
                      ),
          ),

          const SizedBox(height: KiranaSpacing.sm),
          AppButton(
            label: 'DONE',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
