import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kirana_mobile/app/app_providers.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/radius.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_button.dart';
import 'package:kirana_mobile/core/widgets/app_text_field.dart';
import 'package:kirana_mobile/features/barcodes/domain/utils/barcode_validator.dart';
import 'package:kirana_mobile/features/barcodes/presentation/providers/barcode_provider.dart';
import 'package:kirana_mobile/features/billing/presentation/providers/billing_provider.dart';
import 'package:kirana_mobile/features/products/presentation/screens/products_screen.dart';
import '../widgets/scan_result_sheet.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
    formats: [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.itf,
    ],
  );

  final TextEditingController _manualCodeController = TextEditingController();
  PermissionStatus _permissionStatus = PermissionStatus.denied;
  bool _isCheckingPermission = true;
  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    setState(() => _isCheckingPermission = true);
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() {
        _permissionStatus = PermissionStatus.granted;
        _isCheckingPermission = false;
      });
    } else {
      final requestStatus = await Permission.camera.request();
      if (mounted) {
        setState(() {
          _permissionStatus = requestStatus;
          _isCheckingPermission = false;
        });
      }
    }
  }

  Future<void> _handleBarcodeDetected(String rawCode) async {
    if (_isProcessing) return;

    final normalized = BarcodeValidator.normalize(rawCode);
    if (normalized.isEmpty) return;

    // Lock scanning to prevent rapid duplicate triggers (750ms debounce)
    setState(() => _isProcessing = true);

    final connectivity = ref.read(connectivityServiceProvider);
    final isOnline = await connectivity.isOnline();

    final product = await ref
        .read(barcodeNotifierProvider.notifier)
        .searchProductByBarcode(normalized);

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => ScanResultSheet(
        barcode: normalized,
        product: product,
        isOffline: !isOnline,
        onScanAgain: () {
          Navigator.pop(modalCtx);
        },
        onAddToCart: () {
          Navigator.pop(modalCtx);
          if (product != null) {
            ref.read(billingNotifierProvider.notifier).initializeDraft();
            ref.read(billingNotifierProvider.notifier).addProduct(product);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${product.name} added to cart'),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
        onViewProduct: () {
          Navigator.pop(modalCtx);
          context.go('/products');
        },
        onAddProduct: () {
          Navigator.pop(modalCtx);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) =>
                _ProductFormSheetWrapper(prefilledBarcode: normalized),
          );
        },
      ),
    );

    // Resume scanning unlock after dialog close
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handleManualSubmit() {
    final code = _manualCodeController.text.trim();
    if (code.isNotEmpty) {
      _manualCodeController.clear();
      _handleBarcodeDetected(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('POS Barcode Scanner'),
        actions: [
          if (_permissionStatus.isGranted)
            IconButton(
              icon: Icon(
                _isTorchOn ? Icons.flash_on : Icons.flash_off,
                color: _isTorchOn ? KiranaColors.warning : Colors.white,
              ),
              tooltip: 'Toggle Flashlight',
              onPressed: () async {
                await _scannerController.toggleTorch();
                setState(() => _isTorchOn = !_isTorchOn);
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isCheckingPermission) {
      return const Center(
        child: CircularProgressIndicator(color: KiranaColors.primary),
      );
    }

    if (!_permissionStatus.isGranted) {
      return _buildPermissionDeniedView();
    }

    return Stack(
      children: [
        // 1. Live Camera Scanner Viewport
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && !_isProcessing) {
              final raw = barcodes.first.rawValue;
              if (raw != null && raw.trim().isNotEmpty) {
                _handleBarcodeDetected(raw);
              }
            }
          },
        ),

        // 2. Subdued Scanner Overlay Frame
        _buildScannerOverlay(),

        // 3. Bottom Control & Manual Entry Bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(KiranaSpacing.md),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(200),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Align barcode within frame or enter manually below',
                    style: KiranaTypography.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: KiranaSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          hint: 'Manual Barcode Entry',
                          controller: _manualCodeController,
                          prefixIcon:
                              const Icon(Icons.qr_code, color: Colors.white70),
                          onSubmitted: (_) => _handleManualSubmit(),
                        ),
                      ),
                      const SizedBox(width: KiranaSpacing.xs),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KiranaColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: KiranaSpacing.md,
                            vertical: KiranaSpacing.md,
                          ),
                        ),
                        onPressed: _handleManualSubmit,
                        child: const Icon(Icons.search, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScannerOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = constraints.maxWidth * 0.75;
        final scanArea = boxSize.clamp(200.0, 320.0);

        return Stack(
          children: [
            // Darkened background around cutout
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withAlpha(140),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: scanArea,
                      height: scanArea * 0.65,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: KiranaRadius.borderMd,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scanning Bounding Corner Lines & Animated Laser
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: scanArea,
                height: scanArea * 0.65,
                child: Stack(
                  children: [
                    // Corner Borders
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: KiranaRadius.borderMd,
                        border: Border.all(
                          color: KiranaColors.primaryLight,
                          width: 2.5,
                        ),
                      ),
                    ),

                    // Animated Laser Scanning Beam
                    if (!_isProcessing)
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          height: 2.5,
                          width: scanArea - 20,
                          decoration: BoxDecoration(
                            color: KiranaColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: KiranaColors.primary.withAlpha(180),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .moveY(
                            begin: 10,
                            end: scanArea * 0.65 - 15,
                            duration: const Duration(milliseconds: 1600),
                            curve: Curves.easeInOut,
                          ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KiranaSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(KiranaSpacing.xl),
              decoration: const BoxDecoration(
                color: KiranaColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 56,
                color: KiranaColors.error,
              ),
            ),
            const SizedBox(height: KiranaSpacing.lg),
            Text(
              'Camera Access Required',
              style: KiranaTypography.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: KiranaSpacing.xs),
            Text(
              'KiranaOS requires camera permission to scan product barcodes in real-time. On-device detection runs locally without transmitting video frames.',
              style: KiranaTypography.bodyMedium.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KiranaSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                  ),
                  onPressed: () => openAppSettings(),
                  icon: const Icon(Icons.settings),
                  label: const Text('Open Settings'),
                ),
                const SizedBox(width: KiranaSpacing.md),
                AppButton(
                  label: 'Try Again',
                  onPressed: _checkPermission,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductFormSheetWrapper extends StatelessWidget {
  final String prefilledBarcode;

  const _ProductFormSheetWrapper({required this.prefilledBarcode});

  @override
  Widget build(BuildContext context) {
    return ProductsScreenFormDialog(prefilledBarcode: prefilledBarcode);
  }
}
