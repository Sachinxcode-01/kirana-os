import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/app/app.dart';
import 'package:kirana_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:kirana_mobile/features/auth/domain/models/auth_state_model.dart';
import 'package:kirana_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'auth/auth_notifier_test.dart';

class TestAuthNotifier extends AuthNotifier {
  TestAuthNotifier() : super(MockAuthRepository(), AuthRemoteDataSource());

  @override
  Future<void> restoreSession() async {
    await Future.delayed(const Duration(milliseconds: 50));
    state = AuthStateModel.unauthenticated();
  }
}

void main() {
  testWidgets('KiranaApp bootstrap smoke test', (WidgetTester tester) async {
    // Build KiranaApp wrapped in ProviderScope with test auth notifier
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith((ref) => TestAuthNotifier()),
        ],
        child: const KiranaApp(),
      ),
    );

    // Verify that the KiranaOS Splash screen renders brand header initially
    expect(find.text('KiranaOS'), findsOneWidget);
    expect(find.text('Next-Gen Retail & POS System'), findsOneWidget);

    // Step frames to settle navigation from splash to login
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Sign In'), findsOneWidget);
  });
}
