import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bill.dart';
import '../services/backend_service.dart';

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
        ..addAll(
            decoded.map((item) => Bill.fromJson(item as Map<String, dynamic>)));
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

  /// Updates a bill locally without sending the entire payload to the backend
  /// (Useful when a specific API like `updateBillStatus` has already synced the change)
  static Future<void> updateLocal(Bill bill) async {
    await load();
    bills.removeWhere((item) => item.billNumber == bill.billNumber);
    bills.insert(0, bill);
    await _persist();
  }

  static Map<String, dynamic> _toStorageJson(Bill bill) {
    final json = bill.toJson();
    json['status'] = bill.status;
    json['amount_paid'] = bill.amountPaid;
    json['notes'] = bill.notes;
    return json;
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(bills.map(_toStorageJson).toList()),
    );
  }

  static String nextBillNumber() {
    final year = DateTime.now().year;
    int maxNum = 1000;
    for (final bill in bills) {
      // Bill numbers look like INV-2026-0001 or INV-2026-0001-GST.
      // The serial is always the 3rd dash-separated part; parsing every part
      // would mistakenly treat the year (e.g. 2026) as a serial number.
      final parts = bill.billNumber.split('-');
      if (parts.length < 3) continue;
      final serial = int.tryParse(parts[2]);
      if (serial != null && serial > maxNum) {
        maxNum = serial;
      }
    }
    final nextNum = maxNum + 1;
    return 'INV-$year-${nextNum.toString().padLeft(4, '0')}';
  }

  static double get todaySales {
    final today = DateTime.now();
    return bills
        .where((b) =>
            b.date.year == today.year &&
            b.date.month == today.month &&
            b.date.day == today.day &&
            b.status == 'Paid')
        .fold(0.0, (sum, b) => sum + b.total);
  }

  static int get todayBillCount {
    final today = DateTime.now();
    return bills
        .where((b) =>
            b.date.year == today.year &&
            b.date.month == today.month &&
            b.date.day == today.day)
        .length;
  }

  static double get averageBillAmount {
    final today = DateTime.now();
    final todayPaidBills = bills
        .where((b) =>
            b.date.year == today.year &&
            b.date.month == today.month &&
            b.date.day == today.day &&
            b.status == 'Paid')
        .toList();
    if (todayPaidBills.isEmpty) return 0.0;
    return todaySales / todayPaidBills.length;
  }
}
