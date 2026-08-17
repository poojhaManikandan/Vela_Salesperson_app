import 'package:flutter/material.dart';
import '../data/bill_store.dart';
import '../models/bill.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_search_field.dart';
import '../widgets/misc_widgets.dart';
import '../widgets/bill_receipt_sheet.dart';
import '../services/backend_service.dart';

class BillHistoryScreen extends StatefulWidget {
  final bool embedded;

  const BillHistoryScreen({super.key, this.embedded = false});

  @override
  State<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

class _BillHistoryScreenState extends State<BillHistoryScreen> {
  String _query = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await BillStore.load();
    if (mounted) setState(() {});
  }

  List<Bill> get _filteredBills {
    final today = DateTime.now();
    return BillStore.bills.where((b) {
      final matchesQuery = _query.isEmpty ||
          b.billNumber.toLowerCase().contains(_query.toLowerCase()) ||
          b.employeeName.toLowerCase().contains(_query.toLowerCase()) ||
          b.customerName.toLowerCase().contains(_query.toLowerCase()) ||
          b.shopName.toLowerCase().contains(_query.toLowerCase());

      bool matchesFilter = true;
      if (_selectedFilter == 'Today') {
        matchesFilter = b.date.year == today.year &&
            b.date.month == today.month &&
            b.date.day == today.day;
      } else if (_selectedFilter == 'Cash') {
        matchesFilter = b.paymentMode.toLowerCase() == 'cash';
      } else if (_selectedFilter == 'UPI / QR') {
        matchesFilter = b.paymentMode.toLowerCase().contains('upi') ||
            b.paymentMode.toLowerCase().contains('qr');
      }

      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: Text('Bills History Database'.tr)),
      body: SafeArea(child: body),
    );
  }

  Widget _buildBody(BuildContext context) {
    final bills = _filteredBills;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.embedded) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Refresh bills',
                      onPressed: () async {
                        await BillStore.load();
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              AppSearchField(
                hintText: 'Search by bill #, customer, shop, employee...',
                onChanged: (v) => setState(() => _query = v),
              ),

              const SizedBox(height: 8),

              // Filter Chips
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['All', 'Today', 'Cash', 'UPI / QR'].map((f) {
                    final selected = _selectedFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: selected,
                        showCheckmark: false,
                        selectedColor: AppTheme.primaryGreen,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : context.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        onSelected: (_) => setState(() => _selectedFilter = f),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: bills.isEmpty
              ? const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No bills found',
                  subtitle:
                      'Try a different search term or select another filter.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: bills.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final bill = bills[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.receipt_long_rounded,
                                      color: AppTheme.primaryGreen, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          Text(
                                            bill.billNumber,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryGreen
                                                  .withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              bill.paymentMode,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.primaryGreen,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Customer: ${bill.customerName} · By ${bill.employeeName}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: context.textSecondary),
                                      ),
                                      Text(
                                        '${_formatDate(bill.date)} · ${bill.shopName}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: context.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    StatusPill(status: bill.status),
                                    if (bill.status.toUpperCase() == 'PENDING' || bill.status == 'Paid') ...[
                                      const SizedBox(width: 2),
                                      SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: PopupMenuButton<String>(
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(
                                              Icons.more_vert_rounded,
                                              size: 20,
                                              color: AppTheme.textMuted),                                           onSelected: (action) async {
                                            if (action == 'refund') {
                                              // Ask for a refund reason
                                              final reasonCtrl = TextEditingController();
                                              final reason = await showDialog<String>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('Void / Refund Bill'),
                                                  content: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('Bill: ${bill.billNumber}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                                      const SizedBox(height: 12),
                                                      TextField(
                                                        controller: reasonCtrl,
                                                        maxLines: 2,
                                                        decoration: InputDecoration(
                                                          labelText: 'Refund Reason',
                                                          hintText: 'e.g. Wrong product, Customer returned...',
                                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
                                                      onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim().isEmpty ? 'Refunded by operator' : reasonCtrl.text.trim()),
                                                      child: const Text('Confirm Refund'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (reason == null) return;
                                              final updatedBill = Bill(
                                                billNumber: bill.billNumber,
                                                date: bill.date,
                                                employeeName: bill.employeeName,
                                                customerName: bill.customerName,
                                                customerPhone: bill.customerPhone,
                                                shopName: bill.shopName,
                                                paymentMode: bill.paymentMode,
                                                items: bill.items,
                                                subtotal: bill.subtotal,
                                                tax: bill.tax,
                                                discount: bill.discount,
                                                total: bill.total,
                                                status: 'Refunded',
                                                notes: reason,
                                                refundReason: reason,
                                              );
                                              final success = await BackendService.updateBillStatus(bill.billNumber, 'Refunded');
                                              if (success) {
                                                await BillStore.save(updatedBill);
                                                setState(() {});
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      backgroundColor: AppTheme.dangerRed,
                                                      content: Text('Bill ${bill.billNumber} refunded. Reason: $reason'),
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                            if (action == 'paid') {
                                              final updatedBill = Bill(
                                                billNumber: bill.billNumber,
                                                date: bill.date,
                                                employeeName: bill.employeeName,
                                                customerName: bill.customerName,
                                                customerPhone: bill.customerPhone,
                                                shopName: bill.shopName,
                                                paymentMode: bill.paymentMode,
                                                items: bill.items,
                                                subtotal: bill.subtotal,
                                                tax: bill.tax,
                                                discount: bill.discount,
                                                total: bill.total,
                                                amountPaid: bill.total,
                                                status: 'Paid',
                                                notes: bill.notes,
                                              );
                                              final success = await BackendService.updateBillStatus(
                                                bill.billNumber, 'Paid', amountPaid: bill.total
                                              );
                                              if (success) {
                                                await BillStore.save(updatedBill);
                                                setState(() {});
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      backgroundColor: AppTheme.primaryGreen,
                                                      content: Text('Bill ${bill.billNumber} marked as Paid.'),
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                            if (action == 'update_payment') {
                                              final amtCtrl = TextEditingController(
                                                text: bill.amountPaid > 0 ? bill.amountPaid.toStringAsFixed(2) : '',
                                              );
                                              final newAmt = await showDialog<double>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text('Update Amount Paid'),
                                                  content: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('Total Bill: ₹${bill.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                                      Text('Already Paid: ₹${bill.amountPaid.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                                      Text('Due: ₹${bill.dueAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.orange)),
                                                      const SizedBox(height: 12),
                                                      TextField(
                                                        controller: amtCtrl,
                                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                        decoration: InputDecoration(
                                                          labelText: 'New Total Amount Paid (₹)',
                                                          prefixText: '₹ ',
                                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
                                                      onPressed: () => Navigator.pop(ctx, double.tryParse(amtCtrl.text)),
                                                      child: const Text('Update'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (newAmt == null) return;
                                              final newStatus = newAmt >= bill.total ? 'Paid' : 'Pending';
                                              final updatedBill = Bill(
                                                billNumber: bill.billNumber,
                                                date: bill.date,
                                                employeeName: bill.employeeName,
                                                customerName: bill.customerName,
                                                customerPhone: bill.customerPhone,
                                                shopName: bill.shopName,
                                                paymentMode: bill.paymentMode,
                                                items: bill.items,
                                                subtotal: bill.subtotal,
                                                tax: bill.tax,
                                                discount: bill.discount,
                                                total: bill.total,
                                                amountPaid: newAmt,
                                                status: newStatus,
                                                notes: bill.notes,
                                              );
                                              final success = await BackendService.updateBillStatus(
                                                bill.billNumber, newStatus, amountPaid: newAmt
                                              );
                                              if (success) {
                                                await BillStore.save(updatedBill);
                                                setState(() {});
                                                final due = (bill.total - newAmt).clamp(0.0, double.infinity);
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      backgroundColor: newStatus == 'Paid' ? AppTheme.primaryGreen : Colors.orange,
                                                      content: Text(
                                                        newStatus == 'Paid'
                                                          ? 'Bill fully paid!'
                                                          : 'Payment updated. Remaining due: ₹${due.toStringAsFixed(2)}',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            if (bill.status.toUpperCase() == 'PENDING')
                                              PopupMenuItem(
                                                value: 'paid',
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.check_circle_outline,
                                                        size: 18, color: AppTheme.primaryGreen),
                                                    const SizedBox(width: 8),
                                                    Text('Mark as Paid'.tr,
                                                        style: const TextStyle(
                                                            color: AppTheme.primaryGreen,
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                              ),
                                            if (bill.status.toUpperCase() == 'PENDING')
                                              PopupMenuItem(
                                                value: 'update_payment',
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.payments_outlined,
                                                        size: 18, color: Colors.orange),
                                                    const SizedBox(width: 8),
                                                    const Text('Update Payment',
                                                        style: TextStyle(
                                                            color: Colors.orange,
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                              ),
                                            if (bill.status.toUpperCase() == 'PENDING' || bill.status == 'Paid')
                                              PopupMenuItem(
                                                value: 'refund',
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.assignment_return_outlined,
                                                        size: 18,
                                                        color: AppTheme.dangerRed),
                                                    const SizedBox(width: 8),
                                                    Text('Void / Refund Bill'.tr,
                                                        style: const TextStyle(
                                                            color: AppTheme.dangerRed,
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
],
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${bill.items.length} items (${bill.items.fold(0, (s, i) => s + i.quantity)} units)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12, color: context.textSecondary),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '₹${bill.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: AppTheme.primaryGreen),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(40),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      showBillReceiptModal(context, bill);
                                    },
                                    icon: const Icon(Icons.visibility_outlined,
                                        size: 16),
                                    label: Text('View'.tr),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(40),
                                      backgroundColor: AppTheme.primaryGreen,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      showBillReceiptModal(context, bill);
                                    },
                                    icon: const Icon(Icons.print_outlined,
                                        size: 16),
                                    label: Text('Reprint'.tr),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }



  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final min = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$min $ampm';
  }
}
