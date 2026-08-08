import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/bill.dart';

class BackendService {
  BackendService._();

  static const String baseUrl = 'http://127.0.0.1:5000/api';

  /// Sends bill JSON payload directly to the Node.js backend server,
  /// which writes the JSON file into backend/data/bills/[billNumber].json
  static Future<bool> saveBillToBackend(Bill bill) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bills'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bill.toJson()),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('[BackendService] Stored ${bill.billNumber}.json in backend/data/bills/');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('[BackendService] Server error: ${response.statusCode} - ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[BackendService] Backend connection notice: $e');
      }
      return false;
    }
  }
}
