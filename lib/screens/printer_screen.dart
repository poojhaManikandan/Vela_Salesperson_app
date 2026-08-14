import 'package:flutter/material.dart';

import '../models/bill.dart';
import 'package:flutter/services.dart';
import '../services/printer_service.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';

/// Real Bluetooth printer discovery & pairing.
///
/// On Android/iOS this scans with [BluetoothPrintPlus] and lists actual
/// devices. On web/desktop (where Bluetooth SPP printing is impossible) it
/// shows an honest "unsupported" state instead of faking devices.
class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  final _service = PrinterService.instance;
  String? _connectingId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _startScan() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _service.startScan(timeout: const Duration(seconds: 8));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.successGreen,
          content: Text(
            'Scan complete. Found ${_service.devices.length} Bluetooth device(s).',
          ),
        ),
      );
    } catch (e) {
      _showError('Scan failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connect(PrinterDevice device) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _connectingId = device.id;
    });
    try {
      await _service.connect(device);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.successGreen,
          content: Text('Connected to ${device.name}!'),
        ),
      );
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _connectingId = null;
        });
      }
    }
  }

  Future<void> _disconnect() async {
    await _service.disconnect();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Printer disconnected.')),
    );
  }

  Future<void> _testPrint() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _service.printTestPage();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.successGreen,
          content: Text('Test receipt sent to the printer!'),
        ),
      );
    } catch (e) {
      _showError('Test print failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.dangerRed,
        content: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Printer'.tr),
        actions: [
          IconButton(
            icon: _service.isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bluetooth_searching_rounded),
            tooltip: 'Scan Bluetooth Devices',
            onPressed: _busy ? null : _startScan,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!_service.isSupported) ...[
              _buildUnsupportedBanner(),
            ] else ...[
              _buildScannerBanner(),
            ],
            const SizedBox(height: 4),
            Expanded(child: _buildDeviceList()),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildUnsupportedBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: context.textSecondary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bluetooth printing is unavailable here',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Thermal Bluetooth printers connect over classic Bluetooth SPP, '
            'which is only supported on physical Android/iOS devices. This app '
            'is currently running on a platform that cannot scan or print. '
            'Build the app for an Android phone or tablet to use live printing.',
            style: TextStyle(fontSize: 12, color: context.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreen.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: _service.isScanning
                    ? const Padding(
                        padding: EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.bluetooth_audio_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nearby Bluetooth Printers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _service.isScanning
                          ? 'Scanning for 8 seconds...'
                          : '${_service.devices.length} Bluetooth device(s) discovered',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.radar_rounded, size: 18),
              label: Text(
                _busy && _service.isScanning
                    ? 'Scanning...'
                    : 'Scan Nearby Printers',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: (_busy || _service.isScanning) ? null : _startScan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    if (!_service.isSupported) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_disabled_rounded,
                size: 48, color: context.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No Bluetooth devices available',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Bluetooth printing needs an Android/iOS build.',
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_service.devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_searching_rounded,
                size: 48, color: context.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No devices discovered yet',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap "Scan Nearby Printers" and make sure the printer is on.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _service.devices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final device = _service.devices[index];
        final isConnected = _service.connected?.address == device.address;
        final isConnecting = _connectingId == device.id;

        return Card(
          elevation: isConnected ? 2 : 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isConnected ? AppTheme.primaryGreen : context.borderColor,
              width: isConnected ? 1.8 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bluetooth_rounded,
                        color: AppTheme.primaryGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'MAC: ${device.address}',
                            style: TextStyle(
                                fontSize: 11, color: context.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          if (isConnected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.successGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 10, color: AppTheme.successGreen),
                                  SizedBox(width: 4),
                                  Text(
                                    'Connected',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.successGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isConnecting)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      Icon(
                        isConnected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: isConnected
                            ? AppTheme.primaryGreen
                            : context.textSecondary,
                      ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.print_outlined, size: 16),
                        label: Text('Test Print'.tr,
                            style: TextStyle(fontSize: 12)),
                        onPressed:
                            isConnected && !_busy ? _testPrint : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: isConnected
                              ? AppTheme.dangerRed
                              : AppTheme.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: Icon(
                          isConnected
                              ? Icons.link_off_rounded
                              : Icons.link_rounded,
                          size: 16,
                        ),
                        label: Text(
                          isConnected ? 'Disconnect' : 'Connect',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: _busy
                            ? null
                            : () => isConnected
                                ? _disconnect()
                                : _connect(device),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    final connected = _service.connected;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border(top: BorderSide(color: context.borderColor)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Active Printer:',
                    style: TextStyle(fontSize: 11),
                  ),
                  Text(
                    connected?.name ?? 'No printer connected',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: connected != null
                          ? AppTheme.primaryGreen
                          : context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text('Use Active'.tr,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: connected == null ? null : () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
