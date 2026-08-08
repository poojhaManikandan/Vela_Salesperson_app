import '../models/product.dart';

class CartStore {
  CartStore._();

  static final List<CartItem> items = [];
  static final List<Product> recentProducts = [];

  static String activeEmployee = 'Ramalingam';
  static String customerName = 'Walk-in Customer';
  static String customerPhone = '';
  static String shopName = 'Velan Main Store';
  static String paymentMode = 'Cash';
  static double discount = 0.0;

  static void add(Product product) {
    for (final item in items) {
      if (item.product.id == product.id) {
        item.quantity += 1;
        rememberProduct(product);
        return;
      }
    }
    items.add(CartItem(product: product));
    rememberProduct(product);
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
    if (quantity > 0) {
      items.add(CartItem(product: product, quantity: quantity));
      rememberProduct(product);
    }
  }

  static int quantityFor(Product product) {
    final index = items.indexWhere((item) => item.product.id == product.id);
    return index == -1 ? 0 : items[index].quantity;
  }

  static int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  static double get subtotal => items.fold(0, (sum, item) => sum + item.total);

  static double get tax => subtotal * 0.05;

  static double get total => (subtotal + tax - discount).clamp(0.0, double.infinity);

  static void clear() {
    items.clear();
  }

  static void resetSession() {
    items.clear();
    customerName = 'Walk-in Customer';
    customerPhone = '';
    paymentMode = 'Cash';
    discount = 0.0;
  }

  static void rememberProduct(Product product) {
    recentProducts.removeWhere((item) => item.id == product.id);
    recentProducts.insert(0, product);
    if (recentProducts.length > 12) {
      recentProducts.removeLast();
    }
  }
}
