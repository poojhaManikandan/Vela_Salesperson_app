import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bill.dart';
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
    bills.removeWhere((item) => item.billNumber == bill.billNumber);
    bills.insert(0, bill);
    await _persist();
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
    final number = 1001 + bills.length;
    return 'INV-$year-${number.toString().padLeft(4, '0')}';
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
    if (bills.isEmpty) return 0.0;
    final totalSum = bills.fold(0.0, (sum, b) => sum + b.total);
    return totalSum / bills.length;
  }
}
