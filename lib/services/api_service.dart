import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

/// Thin client for the Vela Flask backend.
class ApiService {
  ApiService._();

  static const String baseUrl = 'http://127.0.0.1:5000';

  /// Test seam: when set, [fetchProducts] returns this list instead of
  /// hitting the network (widget tests run with a stubbed HTTP client).
  static List<Product>? debugProducts;

  /// Fetches the active product catalog from the backend
  /// (which reads it from the Supabase `products` table).
  static Future<List<Product>> fetchProducts() async {
    final override = debugProducts;
    if (override != null) return override;

    final uri = Uri.parse('$baseUrl/api/products');
    final response = await http.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to load products (HTTP ${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawList = (data['products'] as List? ?? []);
    final products = rawList
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
    return products;
  }

  static Future<List<Map<String, String>>> fetchCustomers(
      {String query = ''}) async {
    final uri = Uri.parse('$baseUrl/api/customers').replace(queryParameters: {
      if (query.isNotEmpty) 'q': query,
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Failed to load customers (HTTP ${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawList = (data['customers'] as List? ?? []);
    return rawList
        .whereType<Map<String, dynamic>>()
        .map((item) => {
              'id': (item['id'] ?? '').toString(),
              'name': (item['name'] ?? '').toString(),
              'phone': (item['phone'] ?? '').toString(),
            })
        .where((item) => item['name']!.isNotEmpty)
        .map(
            (item) => item.map((key, value) => MapEntry(key, value.toString())))
        .toList();
  }
}
