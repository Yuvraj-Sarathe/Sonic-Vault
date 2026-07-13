import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonicvault/shared/widgets/empty_state.dart';

void main() {
  testWidgets('renders icon and title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.music_note,
            title: 'No songs found',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.music_note), findsOneWidget);
    expect(find.text('No songs found'), findsOneWidget);
  });

  testWidgets('renders subtitle when provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.search_off,
            title: 'Nothing here',
            subtitle: 'Try a different search',
          ),
        ),
      ),
    );

    expect(find.text('Try a different search'), findsOneWidget);
  });

  testWidgets('does not render subtitle when null', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.info,
            title: 'Empty',
          ),
        ),
      ),
    );

    // Only the title should be present
    expect(find.text('Empty'), findsOneWidget);
  });

  testWidgets('renders action button when label and callback provided',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.add,
            title: 'No playlists',
            actionLabel: 'Create',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Create'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);

    await tester.tap(find.text('Create'));
    expect(tapped, isTrue);
  });

  testWidgets('does not render action button when onAction is null',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.info,
            title: 'Empty',
            actionLabel: 'Do it',
          ),
        ),
      ),
    );

    expect(find.text('Do it'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('renders customWidget instead of icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.music_note,
            title: 'Custom',
            customWidget: const SizedBox(
              width: 100,
              height: 100,
              child: Placeholder(),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.music_note), findsNothing);
    expect(find.byType(Placeholder), findsOneWidget);
  });
}
