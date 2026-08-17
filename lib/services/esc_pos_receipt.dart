import 'dart:convert';
import 'dart:typed_data';

import '../models/bill.dart';

/// Builds raw ESC/POS byte streams for 58mm thermal receipt printers.
///
/// Pure Dart: no platform channels, so it works on every target (web, mobile,
/// desktop). The resulting bytes are sent over Bluetooth SPP via
/// [BluetoothPrintPlus.write].
class EscPosReceipt {
  EscPosReceipt._();

  /// Printable characters per line on a 58mm thermal printer at font size A.
  static const int lineWidth = 32;

  static Uint8List build(Bill bill) {
    final b = BytesBuilder();

    void raw(List<int> bytes) => b.add(bytes);

    void text(String s) {
      final out = StringBuffer();
      for (final code in s.runes) {
        out.write(code >= 32 && code <= 255 ? String.fromCharCode(code) : '?');
      }
      b.add(latin1.encode(out.toString()));
    }

    void feed([int lines = 1]) {
      for (var i = 0; i < lines; i++) {
        b.addByte(0x0A);
      }
    }

    void init() => raw(const [0x1B, 0x40]);
    void align(int n) => raw([0x1B, 0x61, n]); // 0 left, 1 center, 2 right
    void bold(bool on) => raw([0x1B, 0x45, on ? 1 : 0]);
    void doubleSize(bool on) => raw([0x1D, 0x21, on ? 0x11 : 0x00]);

    String truncate(String s, int width) {
      if (s.length <= width) return s;
      return '${s.substring(0, width - 1)}~';
    }

    void line([String fill = '-']) {
      text(fill * lineWidth);
      feed();
    }

    void centered(String s, {bool isBold = false, bool isDouble = false}) {
      align(1);
      bold(isBold);
      doubleSize(isDouble);
      text(s);
      bold(false);
      doubleSize(false);
      align(0);
      feed();
    }

    void left(String s) {
      align(0);
      text(s);
      feed();
    }

    /// "Label .... value" row with value right aligned.
    void summaryRow(String label, String value) {
      final total = label.length + value.length;
      if (total > lineWidth - 1) {
        left(label);
        align(2);
        text(value);
        align(0);
      } else {
        text(label.padRight(lineWidth - value.length));
        align(2);
        text(value);
        align(0);
      }
      feed();
    }

    // ---------------------------------------------------------------------
    // Header
    // ---------------------------------------------------------------------
    init();
    feed(1);
    centered('VELA AGENCY', isBold: true, isDouble: true);
    centered(bill.shopName);
    centered('GSTIN: 33AAACV1234F1Z9');
    centered('Ph: +91 98765 43210');
    line();

    // ---------------------------------------------------------------------
    // Bill metadata
    // ---------------------------------------------------------------------
    summaryRow('Bill No:', bill.billNumber);
    summaryRow('Date:', _formatDate(bill.date));
    summaryRow('Cashier:', bill.employeeName);
    summaryRow('Customer:', bill.customerName);
    if (bill.customerPhone.isNotEmpty) {
      summaryRow('Phone:', bill.customerPhone);
    }
    summaryRow('Payment:', bill.paymentMode);
    line();

    // ---------------------------------------------------------------------
    // Items
    // ---------------------------------------------------------------------
    bold(true);
    text('ITEM'.padRight(18));
    text('QTY'.padLeft(3).padRight(4));
    text('AMOUNT'.padLeft(10));
    bold(false);
    feed();

    for (final item in bill.items) {
      final name = truncate(item.product.name, 18);
      final qty = '${item.quantity}'.padLeft(4);
      final amount = _money(item.total).padLeft(10);
      text(name.padRight(18) + qty + amount);
      feed();
    }
    line();

    // ---------------------------------------------------------------------
    // Totals
    // ---------------------------------------------------------------------
    summaryRow('Subtotal:', _money(bill.subtotal));
    summaryRow('CGST (2.5%):', _money(bill.cgst));
    summaryRow('SGST (2.5%):', _money(bill.sgst));
    if (bill.discount > 0) {
      summaryRow('Discount:', '-${_money(bill.discount)}');
    }
    line();

    bold(true);
    text('NET PAYABLE'.padRight(20));
    text(_money(bill.total).padLeft(12));
    bold(false);
    feed(1);
    
    if (bill.amountPaid != bill.total) {
      summaryRow('Amount Paid:', _money(bill.amountPaid));
      summaryRow('Balance Due:', _money(bill.dueAmount));
    }
    
    if (bill.status == 'Refunded' && bill.refundReason.isNotEmpty) {
      line();
      centered('VOID / REFUNDED', isBold: true);
      left('Reason: ${bill.refundReason}');
    }
    line();

    // ---------------------------------------------------------------------
    // Barcode (Code 128 of the bill number)
    // ---------------------------------------------------------------------
    final code = bill.billNumber;
    final codeBytes = ascii.encode(code);
    raw([0x1D, 0x48, 2]); // HRI below
    raw([0x1D, 0x77, 2]); // barcode width
    raw([0x1D, 0x68, 60]); // barcode height
    align(1);
    raw([0x1D, 0x6B, 73, codeBytes.length]);
    raw(codeBytes);
    align(0);
    feed(1);
    centered(code, isBold: false);

    // ---------------------------------------------------------------------
    // Footer
    // ---------------------------------------------------------------------
    feed(1);
    centered('Thank you for shopping');
    centered('with Velan!');
    centered('Please visit again.');
    feed(2);

    // Feed & partial cut
    raw([0x1D, 0x56, 0x41]);

    return b.toBytes();
  }

  static Uint8List buildTestPage() {
    final b = BytesBuilder();

    void raw(List<int> bytes) => b.add(bytes);

    void text(String s) {
      final out = StringBuffer();
      for (final code in s.runes) {
        out.write(code >= 32 && code <= 255 ? String.fromCharCode(code) : '?');
      }
      b.add(latin1.encode(out.toString()));
    }

    void feed([int lines = 1]) {
      for (var i = 0; i < lines; i++) {
        b.addByte(0x0A);
      }
    }

    void align(int n) => raw([0x1B, 0x61, n]);
    void bold(bool on) => raw([0x1B, 0x45, on ? 1 : 0]);

    raw(const [0x1B, 0x40]);
    feed(1);
    align(1);
    bold(true);
    text('VELAN PRINTER TEST');
    bold(false);
    feed();
    text('Bluetooth connection: OK');
    text('Printer status: READY');
    text('ESC/POS protocol: ACTIVE');
    feed();
    align(0);
    bold(true);
    text('abcdefghijklmnopqrstuvwxyz');
    text('01234567890123456789012345678901');
    bold(false);
    feed(1);
    align(1);
    raw([0x1D, 0x48, 2]);
    raw([0x1D, 0x77, 2]);
    raw([0x1D, 0x68, 40]);
    raw([0x1D, 0x6B, 73, 8]);
    text('VELAN-01');
    align(0);
    feed(2);
    raw([0x1D, 0x56, 0x41]);
    return b.toBytes();
  }

  static String _money(double value) {
    final abs = value.abs().toStringAsFixed(2);
    return value < 0 ? '-Rs.$abs' : 'Rs.$abs';
  }

  static String _formatDate(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day/$month/${dt.year} $hour:$min $ampm';
  }
}
