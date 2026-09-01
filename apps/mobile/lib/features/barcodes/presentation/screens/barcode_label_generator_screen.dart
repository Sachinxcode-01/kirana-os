import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/radius.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../../settings/presentation/providers/shop_settings_provider.dart';
import '../../domain/models/barcode_label_models.dart';
import '../providers/barcode_label_provider.dart';
import 'barcode_label_preview_screen.dart';

class BarcodeLabelGeneratorScreen extends ConsumerStatefulWidget {
  const BarcodeLabelGeneratorScreen({super.key});

  @override
  ConsumerState<BarcodeLabelGeneratorScreen> createState() =>
      _BarcodeLabelGeneratorScreenState();
}

class _BarcodeLabelGeneratorScreenState
    extends ConsumerState<BarcodeLabelGeneratorScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _productSearchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static String _formatRupees(int paise) {
    final double rupees = paise / 100.0;
    return '₹${rupees.toStringAsFixed(2)}';
  }

  void _openAddProductSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final productsAsync = ref.watch(productsStreamProvider);
            final allProducts = productsAsync.value ?? [];
            final filtered = _productSearchQuery.trim().isEmpty
                ? allProducts
                : allProducts.where((p) {
                    final q = _productSearchQuery.toLowerCase();
                    return p.name.toLowerCase().contains(q) ||
                        (p.brand?.toLowerCase().contains(q) ?? false) ||
                        (p.barcode?.contains(q) ?? false);
                  }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(KiranaSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: KiranaSpacing.md),
                      decoration: BoxDecoration(
                        color: KiranaColors.neutral300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Select Products for Label Printing',
                    style: KiranaTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: KiranaSpacing.sm),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search product name, brand, or barcode...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _productSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setModalState(() {
                                  _searchController.clear();
                                  _productSearchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: KiranaRadius.borderMd,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onChanged: (val) {
                      setModalState(() => _productSearchQuery = val);
                    },
                  ),
                  const SizedBox(height: KiranaSpacing.md),
                  Expanded(
                    child: productsAsync.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filtered.isEmpty
                            ? const Center(
                                child: Text('No matching products found'))
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final p = filtered[idx];
                                  final hasBarcode =
                                      p.barcode != null && p.barcode!.isNotEmpty;
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          KiranaColors.primaryContainer,
                                      child: Text(
                                        p.name.isNotEmpty
                                            ? p.name[0].toUpperCase()
                                            : 'P',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: KiranaColors.primary,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      p.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      '${_formatRupees(p.sellingPricePaise)} • Unit: ${p.unit} • ${hasBarcode ? p.barcode! : 'No Barcode (Auto-generates in-store EAN)'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: hasBarcode
                                            ? KiranaColors.neutral700
                                            : KiranaColors.warning,
                                      ),
                                    ),
                                    trailing: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            KiranaColors.primaryContainer,
                                        foregroundColor: KiranaColors.primary,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                      ),
                                      onPressed: () {
                                        ref
                                            .read(barcodeLabelNotifierProvider
                                                .notifier)
                                            .addProduct(p, quantity: 10);
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Added 10 labels for "${p.name}"'),
                                            duration:
                                                const Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Add 10'),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handlePreviewAndPrint() async {
    final notifier = ref.read(barcodeLabelNotifierProvider.notifier);
    final shopSettings = ref.read(shopSettingsNotifierProvider).settings;

    try {
      final pdfBytes =
          await notifier.generatePdfBytes(shopSettings: shopSettings);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BarcodeLabelPreviewScreen(
              pdfBytes: pdfBytes,
              title: 'Print Labels Preview',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating labels: ${e.toString()}'),
            backgroundColor: KiranaColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(barcodeLabelNotifierProvider);
    final notifier = ref.read(barcodeLabelNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Label Generator'),
        backgroundColor: KiranaColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (state.items.isNotEmpty)
            TextButton.icon(
              onPressed: () => notifier.clearBatch(),
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              label: const Text('Clear', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(KiranaSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Format & Template Selector Card
                  _buildTemplateSelectorCard(state, notifier),
                  const SizedBox(height: KiranaSpacing.md),

                  // Label Presentation Options Toggle Card
                  _buildConfigOptionsCard(state, notifier),
                  const SizedBox(height: KiranaSpacing.md),

                  // Queue Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Print Queue (${state.items.length} products • ${state.totalLabelsCount} labels)',
                          style: KiranaTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: KiranaSpacing.xs),
                      OutlinedButton.icon(
                        onPressed: () => _openAddProductSheet(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('+ Add Products'),
                      ),
                    ],
                  ),
                  const SizedBox(height: KiranaSpacing.sm),

                  // Queue List or Empty State
                  if (state.items.isEmpty)
                    _buildEmptyQueueState()
                  else
                    ...state.items
                        .map((item) => _buildQueueItemCard(item, notifier)),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(KiranaSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.totalLabelsCount} Labels',
                          style: KiranaTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: KiranaColors.primary,
                          ),
                        ),
                        Text(
                          state.selectedTemplate.label,
                          style: KiranaTypography.bodySmall.copyWith(
                            color: KiranaColors.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: KiranaSpacing.md),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: state.isGenerating
                          ? 'Generating...'
                          : 'Preview & Print',
                      icon: Icons.print,
                      isLoading: state.isGenerating,
                      onPressed: state.items.isEmpty || state.isGenerating
                          ? null
                          : _handlePreviewAndPrint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelectorCard(
      BarcodeLabelState state, BarcodeLabelNotifier notifier) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: KiranaRadius.borderMd),
      child: Padding(
        padding: const EdgeInsets.all(KiranaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.aspect_ratio,
                    color: KiranaColors.primary, size: 20),
                const SizedBox(width: KiranaSpacing.xs),
                Text(
                  'LABEL FORMAT / TEMPLATE',
                  style: KiranaTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: KiranaColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: KiranaSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: BarcodeLabelTemplate.values.map((tmpl) {
                final isSelected = state.selectedTemplate == tmpl;
                return ChoiceChip(
                  label: Text(tmpl.label),
                  selected: isSelected,
                  selectedColor: KiranaColors.primaryContainer,
                  labelStyle: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? KiranaColors.primary
                        : KiranaColors.neutral800,
                  ),
                  onSelected: (val) {
                    if (val) notifier.setTemplate(tmpl);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigOptionsCard(
      BarcodeLabelState state, BarcodeLabelNotifier notifier) {
    final cfg = state.config;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: KiranaRadius.borderMd),
      child: Padding(
        padding: const EdgeInsets.all(KiranaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: KiranaColors.primary, size: 20),
                const SizedBox(width: KiranaSpacing.xs),
                Text(
                  'LABEL CONTENT OPTIONS',
                  style: KiranaTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: KiranaColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: KiranaSpacing.xs),
            SwitchListTile.adaptive(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Include Store Name'),
              value: cfg.includeShopName,
              onChanged: (v) =>
                  notifier.setConfig(cfg.copyWith(includeShopName: v)),
            ),
            SwitchListTile.adaptive(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Include Price & MRP Strikethrough'),
              value: cfg.includePrice,
              onChanged: (v) =>
                  notifier.setConfig(cfg.copyWith(includePrice: v)),
            ),
            SwitchListTile.adaptive(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Include Packing Date (PKD)'),
              value: cfg.includePackedDate,
              onChanged: (v) =>
                  notifier.setConfig(cfg.copyWith(includePackedDate: v)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQueueState() {
    return Container(
      padding: const EdgeInsets.all(KiranaSpacing.xxl),
      decoration: BoxDecoration(
        color: KiranaColors.surfaceVariant,
        borderRadius: KiranaRadius.borderMd,
        border: Border.all(color: KiranaColors.neutral200),
      ),
      child: Column(
        children: [
          const Icon(Icons.qr_code_2, size: 54, color: KiranaColors.neutral400),
          const SizedBox(height: KiranaSpacing.sm),
          Text(
            'Print Queue is Empty',
            style: KiranaTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: KiranaColors.neutral800,
            ),
          ),
          const SizedBox(height: KiranaSpacing.xs),
          Text(
            'Tap "+ Add Products" above to select products from your store catalog and start generating stickers.',
            style: KiranaTypography.bodySmall.copyWith(
              color: KiranaColors.neutral600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KiranaSpacing.md),
          ElevatedButton.icon(
            onPressed: () => _openAddProductSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Products to Queue'),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueItemCard(
      BarcodeLabelBatchItem item, BarcodeLabelNotifier notifier) {
    final p = item.product;
    return Card(
      margin: const EdgeInsets.only(bottom: KiranaSpacing.sm),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: KiranaRadius.borderMd,
        side: const BorderSide(color: KiranaColors.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(KiranaSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: KiranaColors.primaryContainer,
                  child: Text(
                    p.name.isNotEmpty ? p.name[0].toUpperCase() : 'P',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: KiranaColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: KiranaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: KiranaTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_formatRupees(item.effectiveSellingPricePaise)}  •  ${p.unit}',
                        style: KiranaTypography.bodySmall.copyWith(
                          color: KiranaColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: KiranaColors.neutral500),
                  onPressed: () => notifier.removeItem(p.id),
                  tooltip: 'Remove',
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Barcode code chip & generate button
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: KiranaColors.neutral100,
                          borderRadius: KiranaRadius.borderPill,
                          border: Border.all(color: KiranaColors.neutral300),
                        ),
                        child: Text(
                          item.barcode,
                          style: KiranaTypography.priceTabular.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.autorenew,
                            size: 18, color: KiranaColors.primary),
                        tooltip: 'Generate new in-store EAN',
                        onPressed: () =>
                            notifier.generateNewInStoreBarcodeForItem(p.id),
                      ),
                    ],
                  ),
                ),

                // Quantity Counter Stepper
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: KiranaColors.primary,
                      onPressed: () =>
                          notifier.updateQuantity(p.id, item.quantity - 5),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: KiranaColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: KiranaTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: KiranaColors.primary,
                      onPressed: () =>
                          notifier.updateQuantity(p.id, item.quantity + 5),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
