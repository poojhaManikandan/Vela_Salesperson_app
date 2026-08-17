import 'package:flutter/material.dart';
import '../data/bill_store.dart';
import '../data/cart_store.dart';
import '../models/bill.dart';
import '../services/printer_service.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import 'home_screen.dart';
import 'printer_screen.dart';

class BillScreen extends StatefulWidget {
  final double subtotal;
  final double tax;
  final double total;
  final double discount;
  final String customerName;
  final String customerPhone;
  final String shopName;
  final String paymentMode;
  final String employeeName;
  final Bill? existingBill;

  const BillScreen({
    super.key,
    this.subtotal = 0.0,
    this.tax = 0.0,
    this.total = 0.0,
    this.discount = 0.0,
    this.customerName = 'Walk-in Customer',
    this.customerPhone = '',
    this.shopName = 'Velan Main Store',
    this.paymentMode = 'Cash',
    this.employeeName = 'Cashier',
    this.existingBill,
  });

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  late Bill _bill;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingBill != null) {
      _bill = widget.existingBill!;
    } else {
      final billNum = BillStore.nextBillNumber();
      _bill = Bill(
        billNumber: billNum,
        date: DateTime.now(),
        employeeName: widget.employeeName,
        customerName: widget.customerName.isEmpty
            ? 'Walk-in Customer'
            : widget.customerName,
        customerPhone: widget.customerPhone,
        shopName: widget.shopName,
        paymentMode: widget.paymentMode,
        items: List.from(CartStore.items),
        subtotal: widget.subtotal,
        tax: widget.tax,
        discount: widget.discount,
        total: widget.total,
        status: 'Paid',
      );
      _autoSaveBill();
    }
  }

  Future<void> _autoSaveBill() async {
    await BillStore.save(_bill);
    CartStore.clear();
  }

  String get _printerLabel {
    final service = PrinterService.instance;
    if (!service.isSupported) return 'Bluetooth printer (Android/iOS)';
    return service.connected?.name ?? 'No printer connected';
  }

  void _printReceipt() async {
    final service = PrinterService.instance;

    if (!service.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bluetooth printing requires a physical Android/iOS device. '
            'Your receipt is shown on screen.',
          ),
        ),
      );
      return;
    }

    if (!service.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No printer connected. Tap the printer icon to scan & connect.',
          ),
        ),
      );
      return;
    }

    final printerName = service.connected!.name;
    setState(() => _isPrinting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.print_rounded,
                    size: 40,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Printing Tax Invoice...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sending data to $printerName...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 140,
                  child: LinearProgressIndicator(
                    backgroundColor: context.surfaceAlt,
                    color: AppTheme.primaryGreen,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    try {
      await service.printBill(_bill);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close Dialog
      setState(() => _isPrinting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.dangerRed,
          content: Text('Print failed: $e'),
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // Close Dialog
    setState(() => _isPrinting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.successGreen,
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Receipt printed on $printerName successfully!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tax Invoice & Receipt'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Change Printer',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrinterScreen()),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Thermal Receipt Scrollable Card
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Receipt Header
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    'assets/logo.jpg',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'VELA AGENCY',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _bill.shopName,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'GSTIN: 33AAACV1234F1Z9 · Ph: +91 98765 43210',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.successGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'TAX INVOICE · ORIGINAL RECEIPT',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.successGreen,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        _dottedLine(),
                        const SizedBox(height: 12),

                        // Bill Metadata Grid
                        _receiptMetaRow('Bill No:', _bill.billNumber, isBold: true),
                        _receiptMetaRow('Date & Time:', _formatDateTime(_bill.date)),
                        _receiptMetaRow('Cashier / Operator:', _bill.employeeName),
                        _receiptMetaRow('Customer Name:', _bill.customerName),
                        if (_bill.customerPhone.isNotEmpty)
                          _receiptMetaRow('Phone:', _bill.customerPhone),
                        _receiptMetaRow('Payment Mode:', _bill.paymentMode, isPill: true),

                        const SizedBox(height: 12),
                        _dottedLine(),
                        const SizedBox(height: 12),

                        // Items Table Header
                        const Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                'ITEM DESCRIPTION',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'QTY',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'AMOUNT',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Items List
                        for (final item in _bill.items) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        '₹${item.product.price.toStringAsFixed(2)} / ${item.product.unit}',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${item.quantity}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '₹${item.total.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 10, thickness: 0.5),
                        ],

                        const SizedBox(height: 8),

                        // Calculation Breakdown
                        _summaryRow('Subtotal:', '₹${_bill.subtotal.toStringAsFixed(2)}'),
                        _summaryRow('CGST (2.5%):', '₹${_bill.cgst.toStringAsFixed(2)}'),
                        _summaryRow('SGST (2.5%):', '₹${_bill.sgst.toStringAsFixed(2)}'),
                        if (_bill.discount > 0)
                          _summaryRow(
                            'Discount:',
                            '-₹${_bill.discount.toStringAsFixed(2)}',
                            color: AppTheme.successGreen,
                          ),

                        const SizedBox(height: 8),
                        _dottedLine(),
                        const SizedBox(height: 10),

                        // Total Payable Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'NET PAYABLE',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Text(
                              '₹${_bill.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        _dottedLine(),
                        const SizedBox(height: 16),

                        // Thermal Barcode Graphic Simulation
                        Center(
                          child: Column(
                            children: [
                              Container(
                                height: 40,
                                width: 220,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: List.generate(
                                    32,
                                    (i) => Container(
                                      width: (i % 3 == 0) ? 4 : 2,
                                      height: 30,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _bill.billNumber,
                                style: const TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  fontFamily: 'Monospace',
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Thank you for shopping with Velan!\nPlease visit again.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Printer Connection & Workflow Action Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Active Printer Bar
                  Row(
                    children: [
                      const Icon(Icons.print_rounded,
                          size: 18, color: AppTheme.primaryGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Printer: $_printerLabel',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          PrinterService.instance.isConnected ? 'Ready' : 'Off',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: PrinterService.instance.isConnected
                                ? AppTheme.successGreen
                                : context.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Actions: Print Bill & New Sale
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: _isPrinting ? 'Printing...' : 'Print Bill',
                          icon: Icons.print_rounded,
                          isOutlined: true,
                          onPressed: _isPrinting ? null : _printReceipt,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          label: 'New',
                          icon: Icons.add_shopping_cart_rounded,
                          onPressed: () {
                            CartStore.resetSession();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const HomeScreen()),
                              (route) => false,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptMetaRow(String label, String value,
      {bool isBold = false, bool isPill = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          if (isPill)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryGreen,
                ),
              ),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: isBold ? AppTheme.textDark : AppTheme.textDark,
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color ?? AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dottedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth;
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade400),
              ),
            );
          }),
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day}/${dt.month}/${dt.year}  $hour:$min $ampm';
  }
}
