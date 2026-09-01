import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/products/domain/models/product_model.dart';
import '../../../../features/settings/domain/models/shop_settings_model.dart';
import '../../domain/models/barcode_label_models.dart';
import '../../domain/services/barcode_label_pdf_builder.dart';
import '../../domain/utils/in_store_barcode_generator.dart';

class BarcodeLabelState {
  final List<BarcodeLabelBatchItem> items;
  final BarcodeLabelTemplate selectedTemplate;
  final BarcodeLabelConfig config;
  final bool isGenerating;
  final String? errorMessage;

  const BarcodeLabelState({
    this.items = const [],
    this.selectedTemplate = BarcodeLabelTemplate.roll50x25,
    this.config = const BarcodeLabelConfig(),
    this.isGenerating = false,
    this.errorMessage,
  });

  int get totalLabelsCount =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  BarcodeLabelState copyWith({
    List<BarcodeLabelBatchItem>? items,
    BarcodeLabelTemplate? selectedTemplate,
    BarcodeLabelConfig? config,
    bool? isGenerating,
    String? errorMessage,
  }) {
    return BarcodeLabelState(
      items: items ?? this.items,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
      config: config ?? this.config,
      isGenerating: isGenerating ?? this.isGenerating,
      errorMessage: errorMessage,
    );
  }
}

class BarcodeLabelNotifier extends StateNotifier<BarcodeLabelState> {
  final BarcodeLabelPdfBuilder _pdfBuilder;

  BarcodeLabelNotifier(this._pdfBuilder) : super(const BarcodeLabelState());

  void addProduct(
    ProductModel product, {
    int quantity = 1,
    String? customBarcode,
  }) {
    final existingIdx =
        state.items.indexWhere((it) => it.product.id == product.id);

    final barcodeToUse = customBarcode?.trim().isNotEmpty == true
        ? customBarcode!.trim()
        : (product.barcode?.trim().isNotEmpty == true
            ? product.barcode!.trim()
            : InStoreBarcodeGenerator.generateInStoreEan13());

    if (existingIdx >= 0) {
      final existing = state.items[existingIdx];
      final updated = existing.copyWith(
        quantity: existing.quantity + quantity,
        barcode: barcodeToUse,
      );
      final list = [...state.items];
      list[existingIdx] = updated;
      state = state.copyWith(items: list);
    } else {
      final newItem = BarcodeLabelBatchItem(
        product: product,
        barcode: barcodeToUse,
        quantity: quantity,
        packedDate: DateTime.now(),
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final list = state.items.map((it) {
      if (it.product.id == productId) {
        return it.copyWith(quantity: quantity);
      }
      return it;
    }).toList();
    state = state.copyWith(items: list);
  }

  void updateItemBarcode(String productId, String newBarcode) {
    final list = state.items.map((it) {
      if (it.product.id == productId) {
        return it.copyWith(barcode: newBarcode.trim());
      }
      return it;
    }).toList();
    state = state.copyWith(items: list);
  }

  void generateNewInStoreBarcodeForItem(String productId) {
    final newEan = InStoreBarcodeGenerator.generateInStoreEan13();
    updateItemBarcode(productId, newEan);
  }

  void removeItem(String productId) {
    final list = state.items.where((it) => it.product.id != productId).toList();
    state = state.copyWith(items: list);
  }

  void clearBatch() {
    state = state.copyWith(items: []);
  }

  void setTemplate(BarcodeLabelTemplate template) {
    state = state.copyWith(selectedTemplate: template);
  }

  void setConfig(BarcodeLabelConfig config) {
    state = state.copyWith(config: config);
  }

  Future<Uint8List> generatePdfBytes({ShopSettingsModel? shopSettings}) async {
    state = state.copyWith(isGenerating: true, errorMessage: null);
    try {
      final pdfBytes = await _pdfBuilder.buildLabelPdf(
        batchItems: state.items,
        template: state.selectedTemplate,
        config: state.config,
        shopSettings: shopSettings,
      );
      state = state.copyWith(isGenerating: false);
      return pdfBytes;
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        errorMessage: 'Failed to generate PDF labels: ${e.toString()}',
      );
      rethrow;
    }
  }
}

final barcodeLabelNotifierProvider =
    StateNotifierProvider<BarcodeLabelNotifier, BarcodeLabelState>((ref) {
  final pdfBuilder = ref.watch(barcodeLabelPdfBuilderProvider);
  return BarcodeLabelNotifier(pdfBuilder);
});
