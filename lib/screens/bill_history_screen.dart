import 'package:flutter/material.dart';
import '../data/bill_store.dart';
import '../models/bill.dart';
import '../theme/app_theme.dart';
import '../widgets/app_search_field.dart';
import '../widgets/misc_widgets.dart';
import 'bill_screen.dart';

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
      appBar: AppBar(title: const Text('Bills History Database')),
      body: SafeArea(child: body),
    );
  }

  Widget _buildBody(BuildContext context) {
    final bills = _filteredBills;
    final todaySales = BillStore.todaySales;
    final todayCount = BillStore.todayBillCount;
    final avgAmount = BillStore.averageBillAmount;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.embedded) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bill History & Analytics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () async {
                        await BillStore.load();
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // Sales Summary Header
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue,
                      AppTheme.primaryBlue.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _statItem(
                        'Today Sales',
                        '₹${todaySales.toStringAsFixed(0)}',
                        Icons.payments_outlined,
                      ),
                    ),
                    Container(height: 36, width: 1, color: Colors.white24),
                    Expanded(
                      child: _statItem(
                        'Bills Generated',
                        '$todayCount',
                        Icons.receipt_outlined,
                      ),
                    ),
                    Container(height: 36, width: 1, color: Colors.white24),
                    Expanded(
                      child: _statItem(
                        'Avg Order',
                        '₹${avgAmount.toStringAsFixed(0)}',
                        Icons.analytics_outlined,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
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
                        selectedColor: AppTheme.primaryBlue,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppTheme.textDark,
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
                                    color: AppTheme.primaryBlue
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.receipt_long_rounded,
                                      color: AppTheme.primaryBlue, size: 20),
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
                                              color: AppTheme.primaryBlue
                                                  .withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              bill.paymentMode,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.primaryBlue,
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
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textMuted),
                                      ),
                                      Text(
                                        '${_formatDate(bill.date)} · ${bill.shopName}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textMuted),
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
                                    if (bill.status == 'Paid') ...[
                                      const SizedBox(width: 2),
                                      SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: PopupMenuButton<String>(
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(
                                              Icons.more_vert_rounded,
                                              size: 20,
                                              color: AppTheme.textMuted),
                                          onSelected: (action) async {
                                            if (action == 'refund') {
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
                                                notes: 'Refunded by operator',
                                              );
                                              await BillStore.save(updatedBill);
                                              setState(() {});
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    backgroundColor:
                                                        AppTheme.dangerRed,
                                                    content: Text(
                                                        'Bill ${bill.billNumber} has been refunded/voided.'),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'refund',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                      Icons
                                                          .assignment_return_outlined,
                                                      size: 18,
                                                      color: AppTheme.dangerRed),
                                                  SizedBox(width: 8),
                                                  Text('Void / Refund Bill',
                                                      style: TextStyle(
                                                          color:
                                                              AppTheme.dangerRed,
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w600)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
                                    style: const TextStyle(
                                        fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '₹${bill.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: AppTheme.primaryBlue),
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
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              BillScreen(existingBill: bill),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.visibility_outlined,
                                        size: 16),
                                    label: const Text('View'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(40),
                                      backgroundColor: AppTheme.primaryBlue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              BillScreen(existingBill: bill),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.print_outlined,
                                        size: 16),
                                    label: const Text('Reprint'),
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

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
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
