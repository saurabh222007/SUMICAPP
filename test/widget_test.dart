import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sumic/app/app.dart';

void main() {
  testWidgets('SUMIC App initialization smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: SumicApp(),
      ),
    );

    // Verify that the title or initial screen loads
    expect(find.byType(SumicApp), findsOneWidget);
  });
}
