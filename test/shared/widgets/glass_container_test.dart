import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonicvault/shared/widgets/glass_container.dart';

void main() {
  testWidgets('renders with default properties', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassContainer(
            child: const Text('Hello'),
          ),
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
    expect(find.byType(AnimatedContainer), findsOneWidget);
  });

  testWidgets('renders without child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassContainer(),
        ),
      ),
    );

    expect(find.byType(AnimatedContainer), findsOneWidget);
  });

  testWidgets('respects custom dimensions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassContainer(
            width: 300,
            height: 100,
            child: const Text('Sized'),
          ),
        ),
      ),
    );

    expect(find.text('Sized'), findsOneWidget);
  });

  testWidgets('applies custom padding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassContainer(
            padding: const EdgeInsets.all(24),
            child: const Text('Padded'),
          ),
        ),
      ),
    );

    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(container.padding, const EdgeInsets.all(24));
  });

  testWidgets('applies margin', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassContainer(
            margin: const EdgeInsets.all(16),
            child: const Text('Margined'),
          ),
        ),
      ),
    );

    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(container.margin, const EdgeInsets.all(16));
  });
}
