import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

class JsonExporter {
  JsonExporter._();

  /// Converts Map to pretty indented JSON string
  static String toPrettyJson(Map<String, dynamic> data) {
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Downloads JSON file on Web or copies to clipboard on all platforms
  static void exportJsonFile({
    required String filename,
    required Map<String, dynamic> data,
  }) {
    final jsonString = toPrettyJson(data);

    if (kIsWeb) {
      try {
        final bytes = utf8.encode(jsonString);
        final blob = html.Blob([bytes], 'application/json');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final element = html.AnchorElement(href: url)
          ..setAttribute('download', filename.endsWith('.json') ? filename : '$filename.json');
        element.click();
        html.Url.revokeObjectUrl(url);
      } catch (_) {
        Clipboard.setData(ClipboardData(text: jsonString));
      }
    } else {
      Clipboard.setData(ClipboardData(text: jsonString));
    }
  }
}
