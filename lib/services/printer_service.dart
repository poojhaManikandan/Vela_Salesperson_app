import 'dart:async';

import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/bill.dart';
import 'esc_pos_receipt.dart';

/// Manages the real Bluetooth thermal printer lifecycle (scan / connect /
/// print) using [BluetoothPrintPlus] on Android & iOS.
///
/// On unsupported platforms (web, desktop) the service stays inert and every
/// action throws an [UnsupportedError] so the UI can fall back gracefully.
class PrinterService extends ChangeNotifier {
  PrinterService._();

  static final PrinterService instance = PrinterService._();

  final List<PrinterDevice> _devices = [];
  PrinterDevice? _connected;
  bool _scanning = false;
  StreamSubscription<List<BluetoothDevice>>? _scanSub;

  /// The most recently discovered Bluetooth devices.
  List<PrinterDevice> get devices => List.unmodifiable(_devices);

  /// The printer the app is currently connected to, if any.
  PrinterDevice? get connected => _connected;

  bool get isScanning => _scanning;

  bool get isConnected => _connected != null;

  /// Bluetooth classic SPP printing is only possible on Android/iOS.
  bool get isSupported {
    if (kIsWeb) return false;
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.android ||
        platform == TargetPlatform.iOS;
  }

  Future<List<PrinterDevice>> startScan({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    _ensureSupported();
    _scanning = true;
    _devices.clear();
    notifyListeners();

    _scanSub ??= BluetoothPrintPlus.scanResults.listen((results) {
      _devices
        ..clear()
        ..addAll(results.map(_toPrinterDevice));
      notifyListeners();
    });

    final results = await BluetoothPrintPlus.startScan(timeout: timeout);
    _scanning = false;
    _devices
      ..clear()
      ..addAll(results.map(_toPrinterDevice));
    notifyListeners();
    return devices;
  }

  Future<void> stopScan() async {
    if (_scanSub != null) {
      await _scanSub!.cancel();
      _scanSub = null;
    }
    if (_scanning) {
      _scanning = false;
      await BluetoothPrintPlus.stopScan();
      notifyListeners();
    }
  }

  Future<void> connect(PrinterDevice device) async {
    _ensureSupported();

    final completer = Completer<bool>();
    final sub = BluetoothPrintPlus.connectState.listen((state) {
      if (state == ConnectState.connected && !completer.isCompleted) {
        completer.complete(true);
      }
    });

    await BluetoothPrintPlus.connect(
      BluetoothDevice(device.name, device.address),
    );

    final ok = await completer.future
        .timeout(const Duration(seconds: 10), onTimeout: () => false);
    await sub.cancel();

    if (!ok) {
      throw Exception('Could not connect to ${device.name}. '
          'Turn on the printer and try again.');
    }

    _connected = device;
    notifyListeners();
  }

  Future<void> disconnect() async {
    if (!isSupported) return;
    if (_connected == null) return;
    try {
      await BluetoothPrintPlus.disconnect();
    } catch (_) {
      // Native disconnect can fail if the adapter dropped the link already.
    }
    _connected = null;
    notifyListeners();
  }

  /// Builds and sends the ESC/POS bytes for [bill] to the connected printer.
  Future<void> printBill(Bill bill) => printBytes(EscPosReceipt.build(bill));

  /// Sends a small connectivity test receipt to the connected printer.
  Future<void> printTestPage() => printBytes(EscPosReceipt.buildTestPage());

  Future<void> printBytes(Uint8List bytes) async {
    _ensureSupported();
    if (_connected == null) {
      throw StateError('No printer connected. Connect a printer first.');
    }
    await BluetoothPrintPlus.write(bytes);
  }

  void _ensureSupported() {
    if (!isSupported) {
      throw UnsupportedError(
        'Bluetooth printing requires a physical Android or iOS device. '
        'It is not available on this platform.',
      );
    }
  }

  PrinterDevice _toPrinterDevice(BluetoothDevice device) {
    return PrinterDevice(
      id: device.address,
      name: device.name.trim().isEmpty ? 'Unknown Device' : device.name,
      type: 'Bluetooth',
      address: device.address,
      isDiscovered: true,
      paperSize: '58mm',
    );
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }
}
