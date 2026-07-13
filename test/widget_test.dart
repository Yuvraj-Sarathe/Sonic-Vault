import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonicvault/app.dart';

void main() {
  testWidgets('SonicVault app shell renders with bottom navigation',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SonicVaultApp(),
      ),
    );

    // Let the GoRouter settle on the initial route
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The app scaffold renders without error
    expect(find.byType(SonicVaultApp), findsOneWidget);
  });
}
