class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final int stock;
  final String imageUrl;
  final String unit;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.imageUrl,
    this.unit = 'pcs',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'stock': stock,
        'imageUrl': imageUrl,
        'unit': unit,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        price: (json['price'] as num).toDouble(),
        stock: json['stock'] as int,
        imageUrl: json['imageUrl'] as String,
        unit: json['unit'] as String? ?? 'pcs',
      );
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        product: Product.fromJson(json['product'] as Map<String, dynamic>),
        quantity: json['quantity'] as int,
      );
}
