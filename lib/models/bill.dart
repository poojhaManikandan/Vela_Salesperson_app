import 'product.dart';

class Bill {
  final String billNumber;
  final DateTime date;
  final String employeeName;
  final String customerName;
  final String customerPhone;
  final String shopName;
  final String paymentMode;
  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final double amountPaid;
  final String status;
  final String notes;
  final String refundReason;

  const Bill({
    required this.billNumber,
    required this.date,
    required this.employeeName,
    this.customerName = 'Walk-in Customer',
    this.customerPhone = '',
    this.shopName = 'Velan Main Store',
    this.paymentMode = 'Cash',
    required this.items,
    required this.subtotal,
    required this.tax,
    this.discount = 0.0,
    required this.total,
    this.amountPaid = 0.0,
    this.status = 'Paid',
    this.notes = '',
    this.refundReason = '',
  });

  double get dueAmount => (total - amountPaid).clamp(0.0, double.infinity);

  double get extraAmount => (amountPaid - total).clamp(0.0, double.infinity);

  Map<String, dynamic> toJson() => {
        'id': null,
        'billNumber': billNumber,
        'submitted_by': employeeName,
        'customer_id': null,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'payment_type': paymentMode,
        'sales_type': 'Retail',
        'price_list': '',
        'items': items
            .map((item) => {
                  'product_id': item.product.id,
                  'product_name': item.product.name,
                  'quantity': item.quantity,
                  'unit_price': item.product.price,
                  'discount': 0,
                  'total': item.total,
                  'isGst': item.product.isGst,
                })
            .toList(),
        'grand_total': total,
        'amount_paid': amountPaid,
        'status': status,
        'created_at': date.toIso8601String(),
        'updated_at': date.toIso8601String(),
        'processed_at': null,
        'salesman_id': null,
        'notes': notes,
        'refund_reason': refundReason,
      };

  factory Bill.fromJson(Map<String, dynamic> json) {
    final double total = (json['grand_total'] ?? json['total']) is num
        ? (json['grand_total'] ?? json['total'] as num).toDouble()
        : 0.0;
    final double amountPaid = (json['amount_paid'] ?? json['amountPaid']) is num
        ? (json['amount_paid'] ?? json['amountPaid'] as num).toDouble()
        : 0.0;

    return Bill(
      billNumber:
          (json['billNumber'] ?? json['id']) as String? ?? 'INV-UNKNOWN',
      date: DateTime.tryParse(json['created_at'] ?? json['date'] as String) ??
          DateTime.now(),
      employeeName:
          json['submitted_by'] ?? json['employeeName'] as String? ?? '',
      customerName:
          (json['customer_name'] ?? json['customerName']) as String? ??
              'Walk-in Customer',
      customerPhone:
          (json['customer_phone'] ?? json['customerPhone']) as String? ?? '',
      shopName: json['shopName'] as String? ?? 'Velan Main Store',
      paymentMode:
          (json['payment_type'] ?? json['paymentMode']) as String? ?? 'Cash',
      items: (json['items'] as List<dynamic>?)?.map((item) {
            final map = item as Map<String, dynamic>;
            if (map.containsKey('product_id') ||
                map.containsKey('product_name')) {
              return CartItem(
                product: Product(
                  id: map['product_id'] as String? ?? 'P001',
                  name: map['product_name'] as String? ?? 'Item',
                  category: '',
                  price: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
                  stock: 0,
                  imageUrl: '',
                  unit: 'pcs',
                  isGst: true,
                ),
                quantity: (map['quantity'] as num?)?.toInt() ?? 1,
              );
            }
            return CartItem.fromJson(map);
          }).toList() ??
          const [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      total: total,
      amountPaid: amountPaid,
      status: (json['status'] as String?) ??
          (amountPaid >= total ? 'Paid' : 'Pending'),
      notes: json['notes'] as String? ?? '',
      refundReason: json['refund_reason'] as String? ?? json['refundReason'] as String? ?? '',
    );
  }
}

class PrinterDevice {
  final String id;
  final String name;
  final String type; // 'Bluetooth', 'Wi-Fi', 'USB'
  final String address; // e.g. "DC:0D:30:84:1B:4E" or "192.168.1.100"
  final bool isConnected;
  final bool isPaired;
  final int signalStrength; // 1-4
  final int rssi; // e.g. -45 to -90 dBm
  final String paperSize; // '58mm', '80mm'
  final bool isDiscovered;

  const PrinterDevice({
    required this.id,
    required this.name,
    required this.type,
    this.address = '00:11:22:33:44:55',
    this.isConnected = false,
    this.isPaired = false,
    this.signalStrength = 3,
    this.rssi = -65,
    this.paperSize = '58mm',
    this.isDiscovered = false,
  });

  PrinterDevice copyWith({
    String? id,
    String? name,
    String? type,
    String? address,
    bool? isConnected,
    bool? isPaired,
    int? signalStrength,
    int? rssi,
    String? paperSize,
    bool? isDiscovered,
  }) {
    return PrinterDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      isConnected: isConnected ?? this.isConnected,
      isPaired: isPaired ?? this.isPaired,
      signalStrength: signalStrength ?? this.signalStrength,
      rssi: rssi ?? this.rssi,
      paperSize: paperSize ?? this.paperSize,
      isDiscovered: isDiscovered ?? this.isDiscovered,
    );
  }
}
