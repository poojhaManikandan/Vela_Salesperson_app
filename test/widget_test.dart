import 'package:flutter_test/flutter_test.dart';
import 'package:velan_app/main.dart';

void main() {
  testWidgets('VelanApp renders smoke test', (WidgetTester tester) async {
    // Build our app and trigger frames past splash timer
    await tester.pumpWidget(const VelanApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Verify Vela app loads
    expect(find.textContaining('Vela'), findsWidgets);
  });
}
