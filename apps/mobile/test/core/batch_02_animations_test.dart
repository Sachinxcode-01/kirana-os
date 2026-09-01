import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_mobile/core/widgets/animated_list_item.dart';
import 'package:kirana_mobile/core/widgets/empty_state.dart';
import 'package:kirana_mobile/core/widgets/error_view.dart';
import 'package:kirana_mobile/core/widgets/state_transition_switcher.dart';

void main() {
  group('Batch 02 — StateTransitionSwitcher Tests', () {
    testWidgets('Renders child smoothly inside AnimatedSwitcher',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StateTransitionSwitcher(
              child: Text('Content Loaded', key: ValueKey('content')),
            ),
          ),
        ),
      );

      expect(find.text('Content Loaded'), findsOneWidget);
    });

    testWidgets('Transitions smoothly between loading and content states',
        (tester) async {
      Widget currentWidget = const Text('Loading...', key: ValueKey('loading'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return StateTransitionSwitcher(
                  child: currentWidget,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);

      currentWidget = const Text('Data Ready', key: ValueKey('data'));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StateTransitionSwitcher(
              child: currentWidget,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Data Ready'), findsOneWidget);
    });
  });

  group('Batch 02 — EmptyState Tests', () {
    testWidgets('Renders EmptyState with staggered animations and CTA callback',
        (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No Items Found',
              description: 'Your inventory is currently empty.',
              actionLabel: 'Add Product',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      // Settle animations
      await tester.pumpAndSettle();

      expect(find.text('No Items Found'), findsOneWidget);
      expect(find.text('Your inventory is currently empty.'), findsOneWidget);
      expect(find.text('Add Product'), findsOneWidget);

      await tester.tap(find.text('Add Product'));
      expect(actionTriggered, isTrue);
    });
  });

  group('Batch 02 — ErrorView Tests', () {
    testWidgets('Renders ErrorView with Failure message and handles Retry',
        (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              customMessage: 'Database query timeout',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unable to Complete Request'), findsOneWidget);
      expect(find.text('Database query timeout'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retried, isTrue);
    });
  });

  group('Batch 02 — AnimatedListItem Tests', () {
    testWidgets('Renders list item at index 0 with entrance animation',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedListItem(
              index: 0,
              child: Text('Product Item #1'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Product Item #1'), findsOneWidget);
    });

    testWidgets('Renders items at index >= 8 immediately without stagger delay',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedListItem(
              index: 12,
              child: Text('Scrolled Item #13'),
            ),
          ),
        ),
      );

      expect(find.text('Scrolled Item #13'), findsOneWidget);
    });
  });
}
