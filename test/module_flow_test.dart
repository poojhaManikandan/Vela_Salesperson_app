import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velan_app/main.dart';
import 'package:velan_app/models/product.dart';
import 'package:velan_app/services/api_service.dart';

Future<void> login(WidgetTester tester) async {
  await tester.pumpWidget(const VelanApp());
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();

  expect(find.text('Login'), findsOneWidget);
  await tester.enterText(find.byType(TextField).first, '1234567890');
  await tester.tap(find.text('Login'));
  await tester.pumpAndSettle();
}

Future<void> addFirstProduct(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.add_rounded).first);
  await tester.pumpAndSettle();
}

void main() {
  test('Bill due amount stays positive for pending payments', () {
    final bill = Bill(
      billNumber: 'INV-101',
      date: DateTime.now(),
      employeeName: 'Cashier',
      items: const [],
      subtotal: 90,
      tax: 0,
      total: 90,
      amountPaid: 80,
    );

    expect(bill.status, 'Pending');
    expect(bill.dueAmount, 10.0);
  });

  setUp(() {
    ApiService.debugProducts = [
      const Product(
        id: 'P001',
        name: 'Aero Rice 26kg',
        category: 'Groceries',
        price: 1400.00,
        stock: 10,
        imageUrl: '',
        unit: 'bag',
        isGst: true,
      ),
    ];
  });

  tearDown(() {
    ApiService.debugProducts = null;
  });

  testWidgets(
      'Wide layout: login, add item, generate bill, receipt modal opens',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await login(tester);

    // Wide layout must render the embedded cart panel (ExpansionTile in
    // Material) — triggers the "ListTile ink splashes may be invisible"
    // assertion on wide screens if the fix regresses.
    expect(find.text('Active Bill Checkout'), findsOneWidget);

    await addFirstProduct(tester);

    // Checkout footer (incl. Generate Bill) only appears once cart is non-empty.
    expect(find.text('Generate Bill'), findsOneWidget);
    await tester.tap(find.text('Generate Bill'));
    await tester.pumpAndSettle();

    // Receipt modal (print UI) must appear after generating a bill.
    expect(find.text('Print Receipt'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
  });

  testWidgets(
      'Narrow layout: checkout via CartScreen, receipt modal, pops back',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await login(tester);

    // Narrow: no embedded panel, floating checkout bar appears after add.
    await addFirstProduct(tester);

    expect(find.text('Checkout'), findsOneWidget);
    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();

    // CartScreen summary + Generate Bill.
    expect(find.text('Generate Bill'), findsOneWidget);
    await tester.ensureVisible(find.text('Generate Bill'));
    await tester.tap(find.text('Generate Bill'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // Receipt modal shown on top of CartScreen.
    expect(find.text('Print Receipt'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Done closes the sheet, then CartScreen pops back to home.
    expect(find.text('Checkout'), findsNothing);
  });
}
