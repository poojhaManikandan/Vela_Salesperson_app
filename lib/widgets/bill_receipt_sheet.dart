import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../services/printer_service.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';
import 'primary_button.dart';

/// Clean inline receipt modal dialog replacing the dedicated full-page screen.
Future<void> showBillReceiptModal(BuildContext context, Bill bill) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _BillReceiptModalContent(bill: bill),
  );
}

class _BillReceiptModalContent extends StatefulWidget {
  final Bill bill;
  const _BillReceiptModalContent({required this.bill});

  @override
  State<_BillReceiptModalContent> createState() =>
      __BillReceiptModalContentState();
}

class __BillReceiptModalContentState extends State<_BillReceiptModalContent> {
  bool _isPrinting = false;

  void _handlePrint() async {
    final service = PrinterService.instance;

    if (!service.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bluetooth printing requires a physical Android/iOS device. '
            'Receipt shown on screen.',
          ),
        ),
      );
      return;
    }

    if (!service.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('No printer connected. Connect one in Printer settings.'.tr),
        ),
      );
      return;
    }

    setState(() => _isPrinting = true);
    String? error;
    try {
      await service.printBill(widget.bill);
    } catch (e) {
      error = '$e';
    }
    if (!mounted) return;
    setState(() => _isPrinting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            error == null ? AppTheme.successGreen : AppTheme.dangerRed,
        content: Row(
          children: [
            Icon(
              error == null ? Icons.check_circle_outline : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                error ??
                    'Receipt for ${widget.bill.billNumber} printed successfully!',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Success Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.successGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bill Generated Successfully',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Invoice ${bill.billNumber} · ${bill.paymentMode}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const Divider(height: 24),

          // Receipt Summary Card
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Box
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/logo.jpg',
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bill.shopName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Cashier: ${bill.employeeName} · Customer: ${bill.customerName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Items List
                    const Text(
                      'Billed Items:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final item in bill.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.product.name} (x${item.quantity})',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '₹${item.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const Divider(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal:',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '₹${bill.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'GST Tax (5%):',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '₹${bill.tax.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (bill.discount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Discount:',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.successGreen),
                          ),
                          Text(
                            '-₹${bill.discount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.successGreen),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Payable:',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '₹${bill.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Amount Paid:',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '₹${bill.amountPaid.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Balance Amount:',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '₹${bill.dueAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: bill.amountPaid >= bill.total
                                ? AppTheme.successGreen
                                : AppTheme.dangerRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Final Amount:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '₹${bill.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    if (bill.status == 'Refunded' && bill.refundReason.isNotEmpty) ...[
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Refund Reason:',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.dangerRed,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bill.refundReason,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.dangerRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Bottom Action Row
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: _isPrinting ? 'Printing...' : 'Print Receipt',
                  icon: Icons.print_rounded,
                  isOutlined: true,
                  isLoading: _isPrinting,
                  onPressed: _isPrinting ? null : _handlePrint,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Done',
                  icon: Icons.check_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
