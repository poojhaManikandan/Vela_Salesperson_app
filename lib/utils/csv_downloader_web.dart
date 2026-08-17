import 'dart:html' as html;
import 'dart:convert';

void downloadCsvFile(String csvData, String fileName) {
  final bytes = utf8.encode(csvData);
  final blob = html.Blob([bytes], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
    
  html.Url.revokeObjectUrl(url);
}

void downloadBytes(List<int> bytes, String fileName, {String mimeType = 'application/pdf'}) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
    
  html.Url.revokeObjectUrl(url);
}
