import '../models/product.dart';
import 'dummy_data.dart';

class CartStore {
  CartStore._();

  static final List<CartItem> items = [];
  static final List<Product> recentProducts = [];

  static String activeEmployee = 'Ramalingam';
  static String customerName = 'Walk-in Customer';
  static String customerPhone = '';
  static String shopName = 'Vela Agency Main Store';
  static String paymentMode = 'Cash';
  static double discount = 0.0;
  static final Set<String> wishlistProductIds = {'P001', 'P003'};

  static bool isWishlisted(String productId) => wishlistProductIds.contains(productId);

  static void toggleWishlist(String productId) {
    if (wishlistProductIds.contains(productId)) {
      wishlistProductIds.remove(productId);
    } else {
      wishlistProductIds.add(productId);
    }
  }

  static int get wishlistCount => DummyData.products.where((p) => isWishlisted(p.id)).length;

  static bool add(Product product) {
    for (final item in items) {
      if (item.product.id == product.id) {
        if (item.quantity >= product.stock) {
          return false;
        }
        item.quantity += 1;
        rememberProduct(product);
        return true;
      }
    }
    if (product.stock > 0) {
      items.add(CartItem(product: product));
      rememberProduct(product);
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
      rememberProduct(product);
    }
  }

  static int quantityFor(Product product) {
    final index = items.indexWhere((item) => item.product.id == product.id);
    return index == -1 ? 0 : items[index].quantity;
  }

  static int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  static double get subtotal => items.fold(0, (sum, item) => sum + item.total);

  static double get gstSubtotal =>
      items.where((item) => item.product.isGst).fold(0, (sum, item) => sum + item.total);

  static double get tax => gstSubtotal * 0.05;

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
