import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/radius.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../receipts/domain/models/printer_device_model.dart';
import '../../../receipts/presentation/providers/printer_provider.dart';

class PrinterSettingsScreen extends ConsumerWidget {
  const PrinterSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(printerNotifierProvider);
    final notifier = ref.read(printerNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi Printer Setup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi_find),
            tooltip: 'Scan for Printers',
            onPressed: state.isScanning ? null : () => notifier.scanPrinters(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(KiranaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Alerts ─────────────────────────────────────────────────
            if (state.errorMessage != null)
              _AlertBanner(
                message: state.errorMessage!,
                isError: true,
                onClose: () => notifier.clearMessages(),
              ).animate().slideY(begin: -0.3, duration: 200.ms),

            if (state.successMessage != null)
              _AlertBanner(
                message: state.successMessage!,
                isError: false,
                onClose: () => notifier.clearMessages(),
              ).animate().slideY(begin: -0.3, duration: 200.ms),

            // ── Active Printer Card ────────────────────────────────────
            _ActivePrinterCard(state: state, notifier: notifier),
            const SizedBox(height: KiranaSpacing.md),

            // ── Print Settings ─────────────────────────────────────────
            _PrintSettingsCard(state: state, notifier: notifier),
            const SizedBox(height: KiranaSpacing.md),

            // ── WiFi Printer Discovery ─────────────────────────────────
            _WifiDiscoverySection(state: state, notifier: notifier),
          ],
        ),
      ),
    );
  }
}

// ─── Active Printer Card ────────────────────────────────────────────────────

class _ActivePrinterCard extends ConsumerWidget {
  final PrinterState state;
  final PrinterNotifier notifier;

  const _ActivePrinterCard({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = state.isConnected;
    final isTesting = state.testStatus == PrinterTestStatus.testing;
    final testOk = state.testStatus == PrinterTestStatus.ok;
    final testFailed = state.testStatus == PrinterTestStatus.failed;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (state.isConnecting || isTesting) {
      statusColor = KiranaColors.warning;
      statusLabel = state.isConnecting ? 'CONNECTING...' : 'TESTING...';
      statusIcon = Icons.sync;
    } else if (isConnected) {
      if (testFailed) {
        statusColor = KiranaColors.error;
        statusLabel = 'UNREACHABLE';
        statusIcon = Icons.wifi_off;
      } else if (testOk) {
        statusColor = KiranaColors.success;
        statusLabel = 'ONLINE ✓';
        statusIcon = Icons.wifi;
      } else {
        statusColor = KiranaColors.success;
        statusLabel = 'CONNECTED';
        statusIcon = Icons.print;
      }
    } else {
      statusColor = KiranaColors.textSecondary;
      statusLabel = 'NO PRINTER';
      statusIcon = Icons.print_disabled_outlined;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: KiranaRadius.borderMd),
      child: Padding(
        padding: const EdgeInsets.all(KiranaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ACTIVE PRINTER',
                  style: KiranaTypography.labelSmall.copyWith(
                    color: KiranaColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                // Live status badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.isConnecting || isTesting)
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: statusColor,
                          ),
                        )
                      else
                        Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: KiranaTypography.labelSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: KiranaSpacing.sm),

            // Printer name & address
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: (isConnected
                          ? KiranaColors.primary
                          : KiranaColors.textSecondary)
                      .withValues(alpha: 0.12),
                  child: Icon(
                    Icons.print_outlined,
                    color: isConnected
                        ? KiranaColors.primary
                        : KiranaColors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: KiranaSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.selectedPrinter?.name ?? 'No Printer Selected',
                        style: KiranaTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              isConnected ? null : KiranaColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        state.selectedPrinter?.url ??
                            state.selectedPrinter?.address ??
                            'Scan network to discover printers',
                        style: KiranaTypography.bodySmall.copyWith(
                          color: KiranaColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Connection type chip
            if (state.selectedPrinter != null) ...[
              const SizedBox(height: KiranaSpacing.xs),
              Row(
                children: [
                  _TagChip(
                    icon:
                        _connectionIcon(state.selectedPrinter!.connectionType),
                    label: state.selectedPrinter!.connectionType.toUpperCase(),
                    color: KiranaColors.primary,
                  ),
                  const SizedBox(width: KiranaSpacing.xs),
                  _TagChip(
                    icon: Icons.straighten,
                    label: state.pageFormat.label,
                    color: KiranaColors.secondary,
                  ),
                  const SizedBox(width: KiranaSpacing.xs),
                  _TagChip(
                    icon: state.isColor
                        ? Icons.color_lens_outlined
                        : Icons.invert_colors,
                    label: state.isColor ? 'COLOR' : 'B&W',
                    color: state.isColor
                        ? Colors.indigo
                        : KiranaColors.textSecondary,
                  ),
                ],
              ),
            ],

            const Divider(height: KiranaSpacing.lg),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'TEST PRINT',
                    icon: Icons.print_outlined,
                    isLoading: state.isPrinting,
                    onPressed: state.selectedPrinter == null
                        ? null
                        : () => notifier.sendTestPrint(),
                  ),
                ),
                const SizedBox(width: KiranaSpacing.xs),
                OutlinedButton.icon(
                  onPressed: state.selectedPrinter == null ||
                          state.isConnecting ||
                          isTesting
                      ? null
                      : () => notifier.testConnection(),
                  icon: isTesting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering, size: 16),
                  label: Text(isTesting ? 'Testing...' : 'Ping'),
                ),
                if (state.selectedPrinter != null) ...[
                  const SizedBox(width: KiranaSpacing.xs),
                  OutlinedButton.icon(
                    onPressed: () => notifier.disconnectPrinter(),
                    icon: const Icon(Icons.link_off, size: 16),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KiranaColors.error,
                      side: const BorderSide(color: KiranaColors.error),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 200.ms);
  }

  IconData _connectionIcon(String type) {
    switch (type) {
      case 'wifi':
      case 'network':
        return Icons.wifi;
      case 'usb':
        return Icons.usb;
      default:
        return Icons.print;
    }
  }
}

// ─── Print Settings Card ────────────────────────────────────────────────────

class _PrintSettingsCard extends ConsumerWidget {
  final PrinterState state;
  final PrinterNotifier notifier;

  const _PrintSettingsCard({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: KiranaRadius.borderMd),
      child: Padding(
        padding: const EdgeInsets.all(KiranaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PRINT SETTINGS',
              style: KiranaTypography.labelSmall.copyWith(
                color: KiranaColors.textSecondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: KiranaSpacing.sm),

            // Color Mode
            _SettingRow(
              icon: Icons.color_lens_outlined,
              label: 'Color Mode',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ChoiceButton(
                    label: '🎨 Color',
                    selected: state.isColor,
                    onTap: () => notifier.setColorMode(true),
                    selectedColor: Colors.indigo,
                  ),
                  const SizedBox(width: KiranaSpacing.xs),
                  _ChoiceButton(
                    label: '⬛ B&W',
                    selected: !state.isColor,
                    onTap: () => notifier.setColorMode(false),
                    selectedColor: KiranaColors.textSecondary,
                  ),
                ],
              ),
            ),

            const Divider(height: KiranaSpacing.md),

            // Page Format
            _SettingRow(
              icon: Icons.straighten,
              label: 'Page Format',
              child: Wrap(
                spacing: KiranaSpacing.xs,
                children: PrinterPageFormat.values.map((fmt) {
                  return ChoiceChip(
                    label: Text(fmt.label, style: KiranaTypography.labelSmall),
                    selected: state.pageFormat == fmt,
                    onSelected: (_) => notifier.setPageFormat(fmt),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  );
                }).toList(),
              ),
            ),

            const Divider(height: KiranaSpacing.md),

            // Copies
            _SettingRow(
              icon: Icons.copy_outlined,
              label: 'Copies',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconCircleBtn(
                    icon: Icons.remove,
                    onTap: () => notifier.setCopies(state.copies - 1),
                    enabled: state.copies > 1,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: KiranaSpacing.sm),
                    child: Text(
                      '${state.copies}',
                      style: KiranaTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _IconCircleBtn(
                    icon: Icons.add,
                    onTap: () => notifier.setCopies(state.copies + 1),
                    enabled: state.copies < 9,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── WiFi Discovery Section ──────────────────────────────────────────────────

class _WifiDiscoverySection extends ConsumerWidget {
  final PrinterState state;
  final PrinterNotifier notifier;

  const _WifiDiscoverySection({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NETWORK PRINTERS',
                    style: KiranaTypography.labelSmall.copyWith(
                      color: KiranaColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    )),
                Text(
                  'Printers on your WiFi network',
                  style: KiranaTypography.bodySmall
                      .copyWith(color: KiranaColors.textSecondary),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed:
                  state.isScanning ? null : () => notifier.scanPrinters(),
              icon: state.isScanning
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.wifi_find, size: 18),
              label: Text(state.isScanning ? 'Scanning...' : 'Scan Network'),
            ),
          ],
        ),

        const SizedBox(height: KiranaSpacing.sm),

        // Scanning indicator
        if (state.isScanning)
          const LinearProgressIndicator()
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1200.ms),

        const SizedBox(height: KiranaSpacing.xs),

        // Printer list or empty state
        if (state.availablePrinters.isEmpty && !state.isScanning)
          Card(
            shape: RoundedRectangleBorder(borderRadius: KiranaRadius.borderMd),
            child: Padding(
              padding: const EdgeInsets.all(KiranaSpacing.xl),
              child: Column(
                children: [
                  Icon(Icons.wifi_find,
                      size: 48,
                      color: KiranaColors.textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: KiranaSpacing.sm),
                  Text(
                    'No Printers Found',
                    style: KiranaTypography.titleMedium.copyWith(
                      color: KiranaColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: KiranaSpacing.xs),
                  Text(
                    'Tap "Scan Network" to discover WiFi printers.\nMake sure your printer is powered ON and connected to the same WiFi.',
                    style: KiranaTypography.bodySmall.copyWith(
                      color: KiranaColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.availablePrinters.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: KiranaSpacing.xs),
            itemBuilder: (context, index) {
              final device = state.availablePrinters[index];
              final isActive = state.selectedPrinter?.url == device.url ||
                  state.selectedPrinter?.name == device.name;

              return _PrinterTile(
                device: device,
                isActive: isActive,
                isConnecting: state.isConnecting,
                onConnect: () => notifier.selectAndConnectPrinter(device),
              ).animate().slideX(
                    begin: 0.1,
                    delay: Duration(milliseconds: index * 60),
                    duration: 200.ms,
                  );
            },
          ),
      ],
    );
  }
}

// ─── Printer Tile ────────────────────────────────────────────────────────────

class _PrinterTile extends StatelessWidget {
  final PrinterDeviceModel device;
  final bool isActive;
  final bool isConnecting;
  final VoidCallback onConnect;

  const _PrinterTile({
    required this.device,
    required this.isActive,
    required this.isConnecting,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isActive ? 2 : 0.5,
      color: isActive
          ? KiranaColors.primaryContainer.withValues(alpha: 0.25)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: KiranaRadius.borderMd,
        side: isActive
            ? const BorderSide(color: KiranaColors.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: KiranaSpacing.md, vertical: KiranaSpacing.sm),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isActive
                  ? KiranaColors.primary.withValues(alpha: 0.15)
                  : KiranaColors.surfaceVariant,
              child: Icon(
                _connectionIcon(device.connectionType),
                color: isActive
                    ? KiranaColors.primary
                    : KiranaColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: KiranaSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: KiranaTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    device.url ?? device.address,
                    style: KiranaTypography.bodySmall.copyWith(
                      color: KiranaColors.textSecondary,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (device.connectionType.isNotEmpty)
                    Text(
                      device.connectionType.toUpperCase(),
                      style: KiranaTypography.labelSmall.copyWith(
                        color: KiranaColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: KiranaSpacing.xs),
            if (isActive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: KiranaColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ACTIVE',
                  style: KiranaTypography.labelSmall.copyWith(
                    color: KiranaColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              FilledButton.tonal(
                onPressed: isConnecting ? null : onConnect,
                child: isConnecting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Connect'),
              ),
          ],
        ),
      ),
    );
  }

  IconData _connectionIcon(String type) {
    switch (type) {
      case 'wifi':
      case 'network':
        return Icons.wifi;
      case 'usb':
        return Icons.usb;
      default:
        return Icons.print_outlined;
    }
  }
}

// ─── Reusable Widgets ────────────────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onClose;

  const _AlertBanner({
    required this.message,
    required this.isError,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? KiranaColors.error : KiranaColors.success;
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: KiranaSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: KiranaSpacing.sm, vertical: KiranaSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: KiranaRadius.borderSm,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: KiranaSpacing.xs),
          Expanded(
            child: Text(message,
                style: KiranaTypography.bodySmall.copyWith(color: color)),
          ),
          GestureDetector(
            onTap: onClose,
            child: Icon(Icons.close, size: 16, color: color),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _SettingRow(
      {required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: KiranaColors.primary),
        const SizedBox(width: KiranaSpacing.xs),
        Expanded(
          child: Text(label, style: KiranaTypography.bodyMedium),
        ),
        child,
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;

  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? selectedColor : KiranaColors.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: KiranaTypography.labelSmall.copyWith(
            color: selected ? selectedColor : KiranaColors.textSecondary,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _IconCircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _IconCircleBtn({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? KiranaColors.primary.withValues(alpha: 0.1)
              : KiranaColors.outlineVariant.withValues(alpha: 0.3),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? KiranaColors.primary : KiranaColors.textSecondary,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TagChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
