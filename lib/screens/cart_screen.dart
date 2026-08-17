import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/bill_store.dart';
import '../data/cart_store.dart';
import '../models/bill.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bill_receipt_sheet.dart';
import '../widgets/misc_widgets.dart';
import '../widgets/primary_button.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late TextEditingController _customerNameController;
  late TextEditingController _customerPhoneController;
  late TextEditingController _shopNameController;
  late TextEditingController _amountPaidController;

  final List<String> _paymentModes = ['Cash', 'UPI / QR', 'Card', 'Credit'];

  @override
  void initState() {
    super.initState();
    _customerNameController =
        TextEditingController(text: CartStore.customerName);
    _customerPhoneController =
        TextEditingController(text: CartStore.customerPhone);
    _shopNameController = TextEditingController(text: CartStore.shopName);
    _amountPaidController = TextEditingController(
        text: CartStore.amountPaid > 0
            ? (CartStore.amountPaid == CartStore.amountPaid.toInt()
                ? CartStore.amountPaid.toInt().toString()
                : CartStore.amountPaid.toString())
            : '');
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _shopNameController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  double get _subtotal => CartStore.subtotal;
  double get _tax => CartStore.tax;
  double get _total => CartStore.total;
  double get _amountPaid => CartStore.amountPaid;
  double get _balance => (_total - _amountPaid).clamp(0.0, double.infinity);

  @override
  Widget build(BuildContext context) {
    final items = CartStore.items;

    return Scaffold(
      appBar: AppBar(
        title: Text('POS Billing Cart'.tr),
        actions: [
          if (items.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                setState(() => CartStore.clear());
              },
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: Text('Clear All'.tr),
            ),
        ],
      ),
      body: SafeArea(
        child: items.isEmpty
            ? EmptyState(
                icon: Icons.shopping_cart_outlined,
                title: 'Your billing cart is empty'.tr,
                subtitle:
                    'Select products from the POS shop screen to start billing.'.tr,
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Customer & Operator Information Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.person_pin_rounded,
                                    color: AppTheme.primaryGreen, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Customer & Shop Details'.tr,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      '${'Billing Operator'.tr}: ${CartStore.activeEmployee}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('Presets: '.tr, style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w600)),
                              ActionChip(
                                label: Text('Walk-in'.tr, style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  setState(() {
                                    CartStore.customerName = 'Walk-in Customer';
                                    CartStore.customerPhone = '';
                                    _customerNameController.text = 'Walk-in Customer';
                                    _customerPhoneController.text = '';
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              ActionChip(
                                label: Text('Regular Client'.tr, style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  setState(() {
                                    CartStore.customerName = 'Anand & Co';
                                    CartStore.customerPhone = '9845230198';
                                    _customerNameController.text = 'Anand & Co';
                                    _customerPhoneController.text = '9845230198';
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _customerNameController,
                            onChanged: (val) {
                              CartStore.customerName =
                                  val.trim().isEmpty ? 'Walk-in Customer' : val;
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Customer Name / Business'.tr,
                              hintText: 'e.g. Walk-in Customer or Ramesh'.tr,
                              prefixIcon: const Icon(Icons.person_outline, size: 20),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _customerPhoneController,
                                  keyboardType: TextInputType.phone,
                                  onChanged: (val) {
                                    CartStore.customerPhone = val;
                                  },
                                  maxLength: 10,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Mobile Number'.tr,
                                    hintText: '9876543210'.tr,
                                    prefixIcon: const Icon(Icons.phone_outlined,
                                        size: 20),
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _shopNameController,
                                  onChanged: (val) {
                                    CartStore.shopName = val;
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Store Branch'.tr,
                                    prefixIcon: const Icon(Icons.store_outlined,
                                        size: 20),
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Payment Method'.tr,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _paymentModes.map((mode) {
                              final selected = CartStore.paymentMode == mode;
                              return ChoiceChip(
                                label: Text(mode),
                                selected: selected,
                                showCheckmark: false,
                                selectedColor: AppTheme.primaryGreen,
                                labelStyle: TextStyle(
                                  color: selected ? Colors.white : context.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                onSelected: (_) {
                                  setState(() {
                                    CartStore.paymentMode = mode;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items in Bill (${items.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '${CartStore.itemCount} total units',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Cart Items List
                  for (int index = 0; index < items.length; index++) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                items[index].product.imageUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 56,
                                  height: 56,
                                  color: context.surfaceAlt,
                                  child: const Icon(Icons.inventory_2_outlined,
                                      color: AppTheme.textMuted),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    items[index].product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        '₹${items[index].unitPrice.toStringAsFixed(2)} / ${items[index].product.unit} · Stock: ${items[index].product.stock}',
                                        style: TextStyle(
                                            fontSize: 12, color: context.textSecondary),
                                      ),
                                      if (CartStore.activeEmployee == '9344486055')
                                        InkWell(
                                          onTap: () async {
                                            final ctrl = TextEditingController(text: items[index].unitPrice.toString());
                                            final newPrice = await showDialog<double>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Edit Amount'),
                                                content: TextField(
                                                  controller: ctrl,
                                                  keyboardType: TextInputType.number,
                                                  decoration: const InputDecoration(labelText: 'New Amount'),
                                                ),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                                  TextButton(onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text)), child: const Text('Save')),
                                                ],
                                              ),
                                            );
                                            if (newPrice != null && mounted) {
                                              setState(() {
                                                items[index].customPrice = newPrice;
                                              });
                                            }
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.only(left: 8.0),
                                            child: Icon(Icons.edit, size: 14, color: AppTheme.primaryGreen),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _stepperButton(
                                        icon: Icons.remove,
                                        onTap: () {
                                          setState(() {
                                            if (items[index].quantity > 1) {
                                              items[index].quantity--;
                                            } else {
                                              items.removeAt(index);
                                            }
                                          });
                                        },
                                      ),
                                      Container(
                                        width: 32,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${items[index].quantity}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                      _stepperButton(
                                        icon: Icons.add,
                                        onTap: () {
                                          if (items[index].quantity <
                                              items[index].product.stock) {
                                            setState(() => items[index].quantity++);
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .hideCurrentSnackBar();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Stock limit (${items[index].product.stock}) reached for ${items[index].product.name}!'),
                                                duration:
                                                    const Duration(seconds: 1),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: AppTheme.dangerRed, size: 20),
                                  onPressed: () =>
                                      setState(() => items.removeAt(index)),
                                ),
                                Text(
                                  '₹${items[index].total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppTheme.primaryGreen),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  const SizedBox(height: 12),

                  // Amount Paid Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Amount Paid',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Leave 0 or empty to save as Pending (Credit).',
                            style: TextStyle(fontSize: 11.5, color: context.textSecondary),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _amountPaidController,
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              final parsed = double.tryParse(val) ?? 0.0;
                              setState(() {
                                CartStore.amountPaid = parsed;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Amount Paid (₹)',
                              prefixText: '₹ ',
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
      ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SummaryRow(
                        label: 'Subtotal',
                        value: '₹${_subtotal.toStringAsFixed(2)}'),
                    SummaryRow(
                        label: 'CGST (2.5%)',
                        value: '₹${(_tax / 2).toStringAsFixed(2)}'),
                    SummaryRow(
                        label: 'SGST (2.5%)',
                        value: '₹${(_tax / 2).toStringAsFixed(2)}'),
                    const Divider(height: 16),
                    SummaryRow(
                      label: 'Grand Total',
                      value: '₹${_total.toStringAsFixed(2)}',
                      isBold: true,
                    ),
                    SummaryRow(
                      label: 'Amount Paid',
                      value: '₹${_amountPaid.toStringAsFixed(2)}',
                    ),
                    if (_balance > 0)
                      SummaryRow(
                        label: 'Balance Due',
                        value: '₹${_balance.toStringAsFixed(2)}',
                        valueColor: Colors.red.shade600,
                      ),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: 'Generate Bill'.tr,
                      icon: Icons.receipt_long_rounded,
                      onPressed: () async {
                        if (CartStore.customerPhone.isNotEmpty && CartStore.customerPhone.length != 10) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.dangerRed,
                              content: Text('Customer mobile number must be exactly 10 digits.'.tr),
                            ),
                          );
                          return;
                        }

                        final nav = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        final paid = CartStore.amountPaid;
                        final isPending = paid < _total;
                        final newBill = Bill(
                          billNumber: BillStore.nextBillNumber(),
                          date: DateTime.now(),
                          employeeName: CartStore.activeEmployee,
                          customerName: CartStore.customerName,
                          customerPhone: CartStore.customerPhone,
                          shopName: CartStore.shopName,
                          paymentMode: CartStore.paymentMode,
                          items: List.from(CartStore.items),
                          subtotal: _subtotal,
                          tax: _tax,
                          discount: 0,
                          total: _total,
                          amountPaid: paid,
                          status: isPending ? 'Pending' : 'Paid',
                        );
                        await BillStore.save(newBill);
                        CartStore.clear();
                        if (!mounted) return;
                        messenger.hideCurrentSnackBar();
                        if (!mounted) return;
                        await showBillReceiptModal(this.context, newBill);
                        if (!mounted) return;
                        nav.pop();
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _stepperButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: context.surfaceAlt,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: AppTheme.primaryGreen),
        ),
      ),
    );
  }
}
