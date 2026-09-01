import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kirana_mobile/core/animation/page_transitions.dart';

void main() {
  testWidgets(
      'AppPageTransitions.fadeSlide renders and transitions via GoRouter',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => AppPageTransitions.fadeSlide(
            context: context,
            state: state,
            child: const Scaffold(body: Text('Dashboard Screen')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard Screen'), findsOneWidget);
  });

  testWidgets(
      'AppPageTransitions.slideForward renders detail route via GoRouter',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/customer/123',
      routes: [
        GoRoute(
          path: '/customer/:id',
          pageBuilder: (context, state) => AppPageTransitions.slideForward(
            context: context,
            state: state,
            child: const Scaffold(body: Text('Customer Detail Screen')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('Customer Detail Screen'), findsOneWidget);
  });

  testWidgets(
      'AppPageTransitions.modalSlideUp renders modal route via GoRouter',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/barcode',
      routes: [
        GoRoute(
          path: '/barcode',
          pageBuilder: (context, state) => AppPageTransitions.modalSlideUp(
            context: context,
            state: state,
            child: const Scaffold(body: Text('Barcode Scanner Modal')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('Barcode Scanner Modal'), findsOneWidget);
  });

  testWidgets(
      'AppPageTransitions.fade renders auth crossfade route via GoRouter',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          pageBuilder: (context, state) => AppPageTransitions.fade(
            context: context,
            state: state,
            child: const Scaffold(body: Text('Login Auth Screen')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('Login Auth Screen'), findsOneWidget);
  });
}
