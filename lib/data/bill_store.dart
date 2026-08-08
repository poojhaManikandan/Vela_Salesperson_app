import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bill.dart';
import '../services/backend_service.dart';
import 'dummy_data.dart';

class BillStore {
  BillStore._();

  static const _storageKey = 'velan_generated_bills';
  static final List<Bill> bills = [];
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      bills
        ..clear()
        ..addAll(decoded.map((item) => Bill.fromJson(item as Map<String, dynamic>)));
    } else {
      // Seed with initial dummy bills on first run
      bills
        ..clear()
        ..addAll(DummyData.bills);
      await _persist();
    }
    _loaded = true;
  }

  static Future<void> save(Bill bill) async {
    await load();

    final gstItems = bill.items.where((i) => i.product.isGst).toList();
    final nongstItems = bill.items.where((i) => !i.product.isGst).toList();

    if (gstItems.isNotEmpty && nongstItems.isNotEmpty) {
      final gstSubtotal = gstItems.fold(0.0, (sum, i) => sum + i.total);
      final gstTax = (gstSubtotal * 0.05 * 100).roundToDouble() / 100;
      final gstBill = Bill(
        billNumber: '${bill.billNumber}-GST',
        date: bill.date,
        employeeName: bill.employeeName,
        customerName: bill.customerName,
        customerPhone: bill.customerPhone,
        shopName: bill.shopName,
        paymentMode: bill.paymentMode,
        items: gstItems,
        subtotal: gstSubtotal,
        tax: gstTax,
        discount: 0.0,
        total: gstSubtotal + gstTax,
        status: bill.status,
        notes: bill.notes,
      );

      final nongstSubtotal = nongstItems.fold(0.0, (sum, i) => sum + i.total);
      final nongstBill = Bill(
        billNumber: '${bill.billNumber}-NONGST',
        date: bill.date,
        employeeName: bill.employeeName,
        customerName: bill.customerName,
        customerPhone: bill.customerPhone,
        shopName: bill.shopName,
        paymentMode: bill.paymentMode,
        items: nongstItems,
        subtotal: nongstSubtotal,
        tax: 0.0,
        discount: 0.0,
        total: nongstSubtotal,
        status: bill.status,
        notes: bill.notes,
      );

      bills.insert(0, gstBill);
      bills.insert(0, nongstBill);
    } else {
      bills.removeWhere((item) => item.billNumber == bill.billNumber);
      bills.insert(0, bill);
    }

    await _persist();
    await BackendService.saveBillToBackend(bill);
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(bills.map((bill) => bill.toJson()).toList()),
    );
  }

  static String nextBillNumber() {
    final year = DateTime.now().year;
    int maxNum = 1000;
    for (final bill in bills) {
      final parts = bill.billNumber.split('-');
      for (final part in parts) {
        final parsed = int.tryParse(part);
        if (parsed != null && parsed >= 1000 && parsed > maxNum) {
          maxNum = parsed;
        }
      }
    }
    final nextNum = maxNum + 1;
    return 'INV-$year-${nextNum.toString().padLeft(4, '0')}';
  }

  static double get todaySales {
    final today = DateTime.now();
    return bills.where((b) =>
      b.date.year == today.year &&
      b.date.month == today.month &&
      b.date.day == today.day &&
      b.status == 'Paid'
    ).fold(0.0, (sum, b) => sum + b.total);
  }

  static int get todayBillCount {
    final today = DateTime.now();
    return bills.where((b) =>
      b.date.year == today.year &&
      b.date.month == today.month &&
      b.date.day == today.day
    ).length;
  }

  static double get averageBillAmount {
    final today = DateTime.now();
    final todayPaidBills = bills.where((b) =>
      b.date.year == today.year &&
      b.date.month == today.month &&
      b.date.day == today.day &&
      b.status == 'Paid'
    ).toList();
    if (todayPaidBills.isEmpty) return 0.0;
    return todaySales / todayPaidBills.length;
  }
}
