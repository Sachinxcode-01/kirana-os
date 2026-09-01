import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/features/barcodes/presentation/providers/barcode_label_provider.dart';
import 'package:kirana_mobile/features/barcodes/presentation/screens/barcode_label_generator_screen.dart';
import 'package:kirana_mobile/features/products/domain/models/product_model.dart';
import 'package:kirana_mobile/features/products/presentation/providers/product_provider.dart';

void main() {
  final sampleProduct = ProductModel(
    id: 'prod-001',
    shopId: 'shop-1',
    name: 'Aashirvaad Shudh Chakki Atta',
    unit: 'KG',
    sellingPricePaise: 42000, // ₹420
    mrpPaise: 45000,
    barcode: '8901030383458',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Widget createWidgetUnderTest({BarcodeLabelNotifier? customNotifier}) {
    return ProviderScope(
      overrides: [
        productsStreamProvider.overrideWith((ref) => Stream.value([sampleProduct])),
      ],
      child: const MaterialApp(
        home: BarcodeLabelGeneratorScreen(),
      ),
    );
  }

  group('BarcodeLabelGeneratorScreen Widget Tests', () {
    testWidgets('Renders empty queue state when no products added', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Barcode Label Generator'), findsOneWidget);
      expect(find.text('Print Queue is Empty'), findsOneWidget);
      expect(find.text('0 Labels'), findsOneWidget);
      expect(find.text('Preview & Print'), findsOneWidget);
    });

    testWidgets('Selecting template updates template chips', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap on A4 Sheet (24 labels • 3×8)
      final a4Chip = find.text('A4 Sheet (24 labels • 3×8)');
      expect(a4Chip, findsOneWidget);
      await tester.tap(a4Chip);
      await tester.pumpAndSettle();

      // Bottom bar reflects updated template label
      expect(find.text('A4 Sheet (24 labels • 3×8)'), findsWidgets);
    });

    testWidgets('Adding product to queue renders queue item card and updates counter', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [
          productsStreamProvider.overrideWith((ref) => Stream.value([sampleProduct])),
        ],
      );

      // Add product programmatically
      container.read(barcodeLabelNotifierProvider.notifier).addProduct(sampleProduct, quantity: 15);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: BarcodeLabelGeneratorScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should now show product in queue
      expect(find.text('Aashirvaad Shudh Chakki Atta'), findsOneWidget);
      expect(find.text('15 Labels'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);

      // Tap '+' icon to increase quantity by 5
      final addIcon = find.byIcon(Icons.add_circle_outline);
      expect(addIcon, findsOneWidget);
      await tester.tap(addIcon);
      await tester.pumpAndSettle();

      expect(find.text('20 Labels'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);

      // Tap Clear button
      final clearBtn = find.text('Clear');
      expect(clearBtn, findsOneWidget);
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      expect(find.text('Print Queue is Empty'), findsOneWidget);
      expect(find.text('0 Labels'), findsOneWidget);
    });
  });
}
