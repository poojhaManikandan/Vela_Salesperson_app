import 'dart:async';
import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/bill.dart';
import '../theme/app_theme.dart';

class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> with SingleTickerProviderStateMixin {
  late List<PrinterDevice> _printers;
  String? _selectedId;
  bool _isScanning = false;
  String _selectedCategory = 'All';
  late AnimationController _scanAnimController;

  @override
  void initState() {
    super.initState();
    _printers = List.from(DummyData.printers);
    _selectedId = _printers
        .firstWhere((p) => p.isConnected, orElse: () => _printers.first)
        .id;

    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    super.dispose();
  }

  List<PrinterDevice> get _filteredPrinters {
    if (_selectedCategory == 'Bluetooth') {
      return _printers.where((p) => p.type == 'Bluetooth').toList();
    } else if (_selectedCategory == 'Wi-Fi') {
      return _printers.where((p) => p.type == 'Wi-Fi').toList();
    } else if (_selectedCategory == 'USB') {
      return _printers.where((p) => p.type == 'USB').toList();
    }
    return _printers;
  }

  void _startBluetoothScan() {
    if (_isScanning) return;
    setState(() => _isScanning = true);
    _scanAnimController.repeat();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 2),
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Scanning for nearby Bluetooth devices & printers...'),
          ],
        ),
      ),
    );

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _scanAnimController.stop();
      _scanAnimController.reset();

      // Simulate discovering a new nearby Bluetooth device if not already present
      final hasNewDev = _printers.any((p) => p.id == 'PR_DISC_01');
      if (!hasNewDev) {
        _printers.insert(
          1,
          const PrinterDevice(
            id: 'PR_DISC_01',
            name: 'POS-58BT Mobile Thermal',
            type: 'Bluetooth',
            address: '74:D0:2B:9F:88:12',
            isConnected: false,
            isPaired: false,
            signalStrength: 4,
            rssi: -42,
            paperSize: '58mm',
            isDiscovered: true,
          ),
        );
      }

      setState(() => _isScanning = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.successGreen,
          content: Text(
            'Found ${_printers.where((p) => p.type == 'Bluetooth').length} nearby Bluetooth devices!',
          ),
        ),
      );
    });
  }

  void _autoConnectStrongestBT() {
    final btDevices = _printers.where((p) => p.type == 'Bluetooth').toList();
    if (btDevices.isEmpty) return;

    btDevices.sort((a, b) => b.rssi.compareTo(a.rssi)); // highest rssi first
    final strongest = btDevices.first;

    setState(() {
      _printers = _printers.map((p) {
        return p.copyWith(isConnected: p.id == strongest.id);
      }).toList();
      _selectedId = strongest.id;
      DummyData.printers = List.from(_printers);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.primaryBlue,
        content: Text('Auto-connected to nearest Bluetooth printer: ${strongest.name} (${strongest.rssi} dBm)'),
      ),
    );
  }

  void _testPrint(PrinterDevice printer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.print_rounded,
                    size: 32,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Test Printing via ${printer.name}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Address: ${printer.address} · Format: ${printer.paperSize}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '--- VELAN POS TEST RECEIPT ---',
                        style: TextStyle(fontFamily: 'Monospace', fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Bluetooth Connectivity: OK\nPrinter Status: READY\nSignal: EXCELLENT',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Monospace', fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(
                  width: 140,
                  child: LinearProgressIndicator(minHeight: 4),
                ),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.successGreen,
          content: Text('Test print completed on ${printer.name}!'),
        ),
      );
    });
  }

  void _showAddPrinterModal() {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    String devType = 'Bluetooth';
    String paperSize = '58mm';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pair New Bluetooth / Printer',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enter details of your Bluetooth Thermal or Network printer',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Device / Printer Name',
                      hintText: 'e.g. POS-58 Bluetooth',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      labelText: 'Bluetooth MAC / IP Address',
                      hintText: 'e.g. DC:0D:30:84:1B:4E or 192.168.1.100',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: devType,
                          decoration: InputDecoration(
                            labelText: 'Connection Type',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Bluetooth', child: Text('Bluetooth')),
                            DropdownMenuItem(value: 'Wi-Fi', child: Text('Wi-Fi / LAN')),
                            DropdownMenuItem(value: 'USB', child: Text('USB OTG')),
                          ],
                          onChanged: (v) => setModalState(() => devType = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: paperSize,
                          decoration: InputDecoration(
                            labelText: 'Paper Size',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: '58mm', child: Text('58mm Thermal')),
                            DropdownMenuItem(value: '80mm', child: Text('80mm Thermal')),
                          ],
                          onChanged: (v) => setModalState(() => paperSize = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_link_rounded),
                      label: const Text('Add & Connect Device', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        final addr = addressCtrl.text.trim();
                        if (name.isEmpty) return;

                        final newDev = PrinterDevice(
                          id: 'PR_MANUAL_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          type: devType,
                          address: addr.isEmpty ? '00:11:22:33:44:55' : addr,
                          isConnected: true,
                          isPaired: true,
                          signalStrength: 4,
                          rssi: -45,
                          paperSize: paperSize,
                        );

                        setState(() {
                          _printers = _printers.map((p) => p.copyWith(isConnected: false)).toList();
                          _printers.insert(0, newDev);
                          _selectedId = newDev.id;
                          DummyData.printers = List.from(_printers);
                        });

                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.successGreen,
                            content: Text('Added and connected to $name!'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedPrinter = _printers.firstWhere(
      (p) => p.id == _selectedId,
      orElse: () => _printers.first,
    );

    final btCount = _printers.where((p) => p.type == 'Bluetooth').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth & Printer Recognition'),
        actions: [
          IconButton(
            icon: RotationTransition(
              turns: _scanAnimController,
              child: const Icon(Icons.bluetooth_searching_rounded),
            ),
            tooltip: 'Scan Bluetooth Devices',
            onPressed: _startBluetoothScan,
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Device',
            onPressed: _showAddPrinterModal,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Scanner Banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue,
                    AppTheme.primaryBlue.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
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
                        child: RotationTransition(
                          turns: _scanAnimController,
                          child: const Icon(
                            Icons.bluetooth_audio_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nearby Bluetooth Devices',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isScanning
                                  ? 'Searching for active Bluetooth printers...'
                                  : '$btCount Bluetooth devices recognized nearby',
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
                  Row(
                    children: [
                      Expanded(
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
                            _isScanning ? 'Scanning...' : 'Scan Nearby BT',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isScanning ? null : _startBluetoothScan,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryBlue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.bolt_rounded, size: 18),
                          label: const Text(
                            'Auto Nearest',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _autoConnectStrongestBT,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: ['All', 'Bluetooth', 'Wi-Fi', 'USB'].map((cat) {
                  final isSelected = _selectedCategory == cat;
                  int count = cat == 'All'
                      ? _printers.length
                      : _printers.where((p) => p.type == cat).length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$cat ($count)'),
                      selected: isSelected,
                      showCheckmark: false,
                      selectedColor: AppTheme.primaryBlue,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 4),

            // Devices List
            Expanded(
              child: _filteredPrinters.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bluetooth_disabled_rounded,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No $_selectedCategory printers found',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap "Scan Nearby BT" to discover devices nearby.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _filteredPrinters.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final printer = _filteredPrinters[index];
                        final isSelected = printer.id == _selectedId;

                        return Card(
                          elevation: isSelected ? 2 : 0.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected
                                  ? AppTheme.primaryBlue
                                  : Colors.grey.shade200,
                              width: isSelected ? 1.8 : 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              setState(() => _selectedId = printer.id);
                            },
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
                                          color: printer.type == 'Bluetooth'
                                              ? Colors.blue.shade50
                                              : printer.type == 'Wi-Fi'
                                                  ? Colors.purple.shade50
                                                  : Colors.amber.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          printer.type == 'Bluetooth'
                                              ? Icons.bluetooth_rounded
                                              : printer.type == 'Wi-Fi'
                                                  ? Icons.wifi_rounded
                                                  : Icons.usb_rounded,
                                          color: printer.type == 'Bluetooth'
                                              ? AppTheme.primaryBlue
                                              : printer.type == 'Wi-Fi'
                                                  ? Colors.purple
                                                  : Colors.amber.shade800,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: [
                                                Text(
                                                  printer.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                if (printer.isDiscovered) ...[
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange
                                                          .withValues(alpha: 0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(6),
                                                    ),
                                                    child: const Text(
                                                      'Discovered',
                                                      style: TextStyle(
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.orange,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'MAC: ${printer.address} · Format: ${printer.paperSize}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppTheme.textMuted),
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              spacing: 8,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    _SignalBars(
                                                        strength: printer
                                                            .signalStrength),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${printer.rssi} dBm',
                                                      style: TextStyle(
                                                        fontSize: 10.5,
                                                        color:
                                                            Colors.grey.shade600,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (printer.isConnected)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.successGreen
                                                          .withValues(
                                                              alpha: 0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: const Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.check_circle,
                                                            size: 10,
                                                            color: AppTheme
                                                                .successGreen),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          'Connected',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: AppTheme
                                                                .successGreen,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                else if (printer.isPaired)
                                                  Text(
                                                    'Paired',
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          isSelected
                                              ? Icons.radio_button_checked_rounded
                                              : Icons.radio_button_off_rounded,
                                          color: isSelected
                                              ? AppTheme.primaryBlue
                                              : AppTheme.textMuted,
                                        ),
                                        onPressed: () {
                                          setState(() => _selectedId = printer.id);
                                        },
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          icon: const Icon(
                                              Icons.print_outlined,
                                              size: 16),
                                          label: const Text('Test Print',
                                              style: TextStyle(fontSize: 12)),
                                          onPressed: () => _testPrint(printer),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: printer.isConnected
                                                ? AppTheme.dangerRed
                                                : AppTheme.primaryBlue,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          icon: Icon(
                                            printer.isConnected
                                                ? Icons.link_off_rounded
                                                : Icons.link_rounded,
                                            size: 16,
                                          ),
                                          label: Text(
                                            printer.isConnected
                                                ? 'Disconnect'
                                                : 'Connect',
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _printers = _printers.map((p) {
                                                if (p.id == printer.id) {
                                                  return p.copyWith(
                                                      isConnected:
                                                          !p.isConnected);
                                                }
                                                return p.copyWith(
                                                    isConnected: false);
                                              }).toList();
                                              _selectedId = printer.id;
                                              DummyData.printers =
                                                  List.from(_printers);
                                            });

                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                backgroundColor: printer.isConnected
                                                    ? AppTheme.textDark
                                                    : AppTheme.successGreen,
                                                content: Text(printer.isConnected
                                                    ? 'Disconnected from ${printer.name}'
                                                    : 'Connected to ${printer.name} (${printer.address})'),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Bottom Active Selection Bar
            SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textMuted),
                          ),
                          Text(
                            selectedPrinter.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Use Active',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        // Set selected as primary connected
                        setState(() {
                          _printers = _printers.map((p) {
                            return p.copyWith(isConnected: p.id == selectedPrinter.id);
                          }).toList();
                          DummyData.printers = List.from(_printers);
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  final int strength;

  const _SignalBars({required this.strength});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final active = i < strength;
        return Container(
          margin: const EdgeInsets.only(left: 2),
          width: 3.5,
          height: 7.0 + (i * 3.5),
          decoration: BoxDecoration(
            color: active ? AppTheme.primaryBlue : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
