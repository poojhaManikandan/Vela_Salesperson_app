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
  final String status;
  final String notes;

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
    this.status = 'Paid',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'billNumber': billNumber,
        'date': date.toIso8601String(),
        'employeeName': employeeName,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'shopName': shopName,
        'paymentMode': paymentMode,
        'items': items.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'tax': tax,
        'discount': discount,
        'total': total,
        'status': status,
        'notes': notes,
      };

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
        billNumber: json['billNumber'] as String,
        date: DateTime.tryParse(json['date'] as String) ?? DateTime.now(),
        employeeName: json['employeeName'] as String,
        customerName: json['customerName'] as String? ?? 'Walk-in Customer',
        customerPhone: json['customerPhone'] as String? ?? '',
        shopName: json['shopName'] as String? ?? 'Velan Main Store',
        paymentMode: json['paymentMode'] as String? ?? 'Cash',
        items: (json['items'] as List<dynamic>)
            .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        subtotal: (json['subtotal'] as num).toDouble(),
        tax: (json['tax'] as num).toDouble(),
        discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
        total: (json['total'] as num).toDouble(),
        status: json['status'] as String? ?? 'Paid',
        notes: json['notes'] as String? ?? '',
      );
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
