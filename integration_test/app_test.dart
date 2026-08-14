import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:velan_app/main.dart' as app;

/// Pumps frames until [finder] matches or [timeout] elapses.
/// Needed because the app does real (async) network I/O that is not
/// driven by frame scheduling, so pumpAndSettle alone can return early.
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Wide layout: login, add item, generate bill, receipt modal appears',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    app.main();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await waitFor(tester, find.text('Login'));
    await tester.enterText(find.byType(TextField).first, '1234567890');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Active Bill Checkout'), findsOneWidget,
        reason: 'Wide-layout home with embedded cart panel not shown');

    // Product catalog is fetched from the backend over the network.
    await waitFor(tester, find.byIcon(Icons.add_rounded));
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();

    await waitFor(tester, find.text('Generate Bill'));
    await tester.tap(find.text('Generate Bill'));

    // Saving to the backend is async; poll for the receipt modal.
    await waitFor(tester, find.text('Print Receipt'));
    expect(find.text('Done'), findsOneWidget);

    await tester.ensureVisible(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Done closes the receipt modal.
    expect(find.text('Print Receipt'), findsNothing);
  });
}
