class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final int stock;
  final String imageUrl;
  final String unit;
  final bool isGst;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.imageUrl,
    this.unit = 'pcs',
    this.isGst = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'stock': stock,
        'imageUrl': imageUrl,
        'unit': unit,
        'isGst': isGst,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        price: (json['price'] as num).toDouble(),
        stock: json['stock'] as int,
        imageUrl: json['imageUrl'] as String,
        unit: json['unit'] as String? ?? 'pcs',
        isGst: json['isGst'] as bool? ?? true,
      );
}

class CartItem {
  final Product product;
  int quantity;
  double? customPrice;

  CartItem({required this.product, this.quantity = 1, this.customPrice});

  double get unitPrice => customPrice ?? product.price;

  double get total => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'quantity': quantity,
        'customPrice': customPrice,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        product: Product.fromJson(json['product'] as Map<String, dynamic>),
        quantity: json['quantity'] as int,
        customPrice: json['customPrice'] != null ? (json['customPrice'] as num).toDouble() : null,
      );
}
