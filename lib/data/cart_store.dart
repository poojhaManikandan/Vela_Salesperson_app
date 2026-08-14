import '../models/product.dart';

class CartStore {
  CartStore._();

  static final List<CartItem> items = [];

  static String activeEmployee = 'Cashier';
  static String customerName = 'Walk-in Customer';
  static String customerPhone = '';
  static String shopName = 'Vela Agency Main Store';
  static String paymentMode = 'Cash';
  static double discount = 0.0;
  static double amountPaid = 0.0;

  static bool add(Product product) {
    for (final item in items) {
      if (item.product.id == product.id) {
        if (item.quantity >= product.stock) {
          return false;
        }
        item.quantity += 1;
        return true;
      }
    }
    if (product.stock > 0) {
      items.add(CartItem(product: product));
      return true;
    }
    return false;
  }

  static void decrement(Product product) {
    final index = items.indexWhere((item) => item.product.id == product.id);
    if (index == -1) return;
    if (items[index].quantity > 1) {
      items[index].quantity -= 1;
    } else {
      items.removeAt(index);
    }
  }

  static void setQuantity(Product product, int quantity) {
    items.removeWhere((item) => item.product.id == product.id);
    final clamped = quantity.clamp(0, product.stock);
    if (clamped > 0) {
      items.add(CartItem(product: product, quantity: clamped));
    }
  }

  static int quantityFor(Product product) {
    final index = items.indexWhere((item) => item.product.id == product.id);
    return index == -1 ? 0 : items[index].quantity;
  }

  static int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  static double get subtotal => items.fold(0, (sum, item) => sum + item.total);

  static double get gstSubtotal => items
      .where((item) => item.product.isGst)
      .fold(0, (sum, item) => sum + item.total);

  static double get tax => gstSubtotal * 0.05;

  static double get total =>
      (subtotal + tax - discount).clamp(0.0, double.infinity);

  static void clear() {
    items.clear();
  }

  static void resetSession() {
    items.clear();
    customerName = 'Walk-in Customer';
    customerPhone = '';
    paymentMode = 'Cash';
    discount = 0.0;
    amountPaid = 0.0;
  }
}
