import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/app/app.dart';

void main() {
  testWidgets('KiranaApp bootstrap smoke test', (WidgetTester tester) async {
    // Build KiranaApp wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: KiranaApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that the KiranaOS Dashboard or App shell renders cleanly
    expect(find.text('KiranaOS Dashboard'), findsOneWidget);
    expect(find.text('Quick Barcode POS'), findsOneWidget);
  });
}
