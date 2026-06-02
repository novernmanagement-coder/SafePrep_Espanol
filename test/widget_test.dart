import 'package:flutter_test/flutter_test.dart';
import 'package:safeprep_espanol/main.dart';

void main() {
  testWidgets('SafePrep Español smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SafePrepApp());
    expect(find.byType(SafePrepApp), findsOneWidget);
  });
}
