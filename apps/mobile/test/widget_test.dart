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

    // Pump a single frame
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that the KiranaOS Splash screen renders brand header cleanly
    expect(find.text('KiranaOS'), findsOneWidget);
    expect(find.text('Next-Gen Retail & POS System'), findsOneWidget);
  });
}
