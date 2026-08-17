import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/csv_downloader.dart';

class AdminReportsScreen extends StatefulWidget {
  final bool embedded;
  const AdminReportsScreen({super.key, this.embedded = false});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _reportData;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String _selectedSalesperson = 'All';
  List<String> _salespersons = ['All'];
  String _quickFilter = 'Today';

  @override
  void initState() {
    super.initState();
    _applyQuickFilter('Today');
  }

  void _applyQuickFilter(String filter) {
    final now = DateTime.now();
    setState(() {
      _quickFilter = filter;
      if (filter == 'Today') {
        _dateFrom = DateTime(now.year, now.month, now.day);
        _dateTo = DateTime(now.year, now.month, now.day);
      } else if (filter == 'Week') {
        _dateFrom = now.subtract(Duration(days: now.weekday - 1));
        _dateTo = now;
      } else if (filter == 'Month') {
        _dateFrom = DateTime(now.year, now.month, 1);
        _dateTo = now;
      } else if (filter == 'All Time') {
        _dateFrom = null;
        _dateTo = null;
      }
    });
    _loadReport();
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadReport() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final sp = _selectedSalesperson == 'All' ? null : _selectedSalesperson;
      final data = await ApiService.fetchReports(
        dateFrom: _fmtDate(_dateFrom),
        dateTo: _fmtDate(_dateTo),
        salesperson: sp,
      );
      if (!mounted) return;
      final rawSp = (data['salespersons'] as List?)?.cast<String>() ?? [];
      setState(() {
        _reportData = data;
        _salespersons = ['All', ...rawSp];
        if (!_salespersons.contains(_selectedSalesperson)) _selectedSalesperson = 'All';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? (_dateFrom ?? DateTime.now()) : (_dateTo ?? DateTime.now());
    final picked = await showDatePicker(
      context: context, initialDate: initial,
      firstDate: DateTime(2020), lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() { isFrom ? _dateFrom = picked : _dateTo = picked; _quickFilter = 'Custom'; });
      _loadReport();
    }
  }

  void _downloadCsv() {
    final orders = (_reportData?['orders'] as List?) ?? [];
    final rows = <String>['Bill Number,Salesperson,Customer,Phone,Payment,Items,Total (INR),Status,Date'];
    for (final o in orders) {
      rows.add([
        _c(o['bill_number']), _c(o['salesperson']), _c(o['customer_name']),
        _c(o['customer_phone']), _c(o['payment_type']),
        '${o['items_count'] ?? 0}',
        '${(o['grand_total'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
        _c(o['status']), _c(o['created_at']),
      ].join(','));
    }
    final csv = rows.join('\n');
    final fn = 'vela_report_${_fmtDate(_dateFrom)}_${_fmtDate(_dateTo)}.csv';
    
    downloadCsvFile(csv, fn);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Downloaded $fn (${orders.length} orders)'),
      duration: const Duration(seconds: 4),
    ));
  }

  String _c(dynamic v) { final s = (v ?? '').toString().replaceAll('"', '""'); return '"$s"'; }

  @override
  Widget build(BuildContext context) {
    final body = Column(children: [
      _buildFilterBar(context),
      const Divider(height: 1),
      Expanded(child: _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
        : _error != null ? _buildError()
        : _reportData == null ? const SizedBox()
        : _buildContent(context)),
    ]);
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Sales Reports', style: TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(child: body),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 6, children: ['Today','Week','Month','All Time','Custom'].map((f) {
          final sel = _quickFilter == f;
          return ChoiceChip(
            label: Text(f), selected: sel, showCheckmark: false,
            selectedColor: AppTheme.primaryGreen,
            labelStyle: TextStyle(color: sel ? Colors.white : null, fontWeight: FontWeight.w600, fontSize: 12.5),
            onSelected: (_) => f == 'Custom' ? setState(() => _quickFilter = 'Custom') : _applyQuickFilter(f),
          );
        }).toList()),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
          _dateTile('From', _dateFrom, () => _pickDate(isFrom: true)),
          _dateTile('To', _dateTo, () => _pickDate(isFrom: false)),
          SizedBox(width: 200, child: DropdownButtonFormField<String>(
            value: _selectedSalesperson,
            decoration: InputDecoration(labelText: 'Salesperson', isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            items: _salespersons.map((sp) => DropdownMenuItem(value: sp,
              child: Text(sp, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (val) { if (val == null) return; setState(() => _selectedSalesperson = val); _loadReport(); },
          )),
          IconButton(onPressed: _loadReport, icon: const Icon(Icons.refresh_rounded),
            style: IconButton.styleFrom(backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12), foregroundColor: AppTheme.primaryGreen)),
          ElevatedButton.icon(
            onPressed: _reportData == null ? null : _downloadCsv,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Download CSV', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ]),
      ]),
    );
  }

  Widget _dateTile(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.withValues(alpha: 0.4)), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.calendar_today_rounded, size: 15, color: AppTheme.primaryGreen),
          const SizedBox(width: 6),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(date != null ? '${date.day}/${date.month}/${date.year}' : 'All dates',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ]),
      ));
  }

  Widget _buildContent(BuildContext context) {
    final summary = _reportData!['summary'] as Map<String, dynamic>? ?? {};
    final orders = (_reportData!['orders'] as List?) ?? [];
    final breakdown = (_reportData!['salesperson_breakdown'] as List?) ?? [];
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSummaryCards(summary), const SizedBox(height: 20),
      if (breakdown.isNotEmpty) ...[ _sectionTitle('Salesperson Breakdown'), const SizedBox(height: 10), _buildBreakdown(breakdown), const SizedBox(height: 20) ],
      _sectionTitle('Orders (${orders.length})'), const SizedBox(height: 10),
      orders.isEmpty ? _buildEmpty() : _buildOrdersTable(orders),
    ]));
  }

  Widget _buildSummaryCards(Map<String, dynamic> s) {
    final rev = (s['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final cnt = (s['order_count'] as num?)?.toInt() ?? 0;
    final avg = (s['avg_order_value'] as num?)?.toDouble() ?? 0.0;
    return Row(children: [
      _card(Icons.currency_rupee_rounded, 'Total Revenue', '${String.fromCharCode(0x20B9)}${rev.toStringAsFixed(2)}', AppTheme.primaryGreen),
      const SizedBox(width: 12),
      _card(Icons.receipt_long_rounded, 'Total Orders', '$cnt', const Color(0xFF3B82F6)),
      const SizedBox(width: 12),
      _card(Icons.trending_up_rounded, 'Avg. Order', '${String.fromCharCode(0x20B9)}${avg.toStringAsFixed(2)}', const Color(0xFFF59E0B)),
    ]);
  }

  Widget _card(IconData icon, String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
        ])),
      ]),
    ));
  }

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800));

  Widget _buildBreakdown(List breakdown) {
    return Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
      child: ClipRRect(borderRadius: BorderRadius.circular(12),
        child: Table(columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(2), 2: FlexColumnWidth(1.5)},
          children: [
            TableRow(decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.10)),
              children: [_th('Salesperson'), _th('Revenue'), _th('Orders')]),
            ...breakdown.map((row) {
              final rev = (row['total_revenue'] as num?)?.toDouble() ?? 0.0;
              return TableRow(
                decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.12)))),
                children: [
                  _td(row['salesperson']?.toString() ?? '', bold: true),
                  _td('${String.fromCharCode(0x20B9)}${rev.toStringAsFixed(2)}', color: AppTheme.primaryGreen),
                  _td('${row['order_count'] ?? 0}'),
                ]);
            }),
          ])));
  }

  Widget _buildOrdersTable(List orders) {
    return Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
      child: ClipRRect(borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(scrollDirection: Axis.horizontal,
          child: Table(defaultColumnWidth: const IntrinsicColumnWidth(),
            children: [
              TableRow(decoration: BoxDecoration(color: AppTheme.primaryGreen.withValues(alpha: 0.10)),
                children: [_th('Bill #'), _th('Salesperson'), _th('Customer'), _th('Phone'), _th('Payment'), _th('Items'), _th('Total'), _th('Status'), _th('Date & Time')]),
              ...orders.asMap().entries.map((e) {
                final idx = e.key; final o = e.value as Map<String, dynamic>;
                final total = (o['grand_total'] as num?)?.toDouble() ?? 0.0;
                String ds = o['created_at']?.toString() ?? '';
                try { if (ds.isNotEmpty) { final dt = DateTime.parse(ds.replaceAll('Z','').split('+')[0]); ds = '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}'; } } catch (_) {}
                final bn = (o['bill_number'] ?? '').toString();
                return TableRow(
                  decoration: BoxDecoration(color: idx % 2 == 0 ? null : Colors.grey.withValues(alpha: 0.04),
                    border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.12)))),
                  children: [
                    _td(bn.length > 22 ? '${bn.substring(0,20)}\u2026' : bn, monospace: true, fontSize: 11),
                    _td(o['salesperson']?.toString() ?? ''),
                    _td(o['customer_name']?.toString() ?? ''),
                    _td(o['customer_phone']?.toString() ?? '', color: Colors.grey),
                    _td(o['payment_type']?.toString() ?? ''),
                    _td('${o['items_count'] ?? 0}'),
                    _td('${String.fromCharCode(0x20B9)}${total.toStringAsFixed(2)}', color: AppTheme.primaryGreen, bold: true),
                    _tdStatus(o['status']?.toString() ?? ''),
                    _td(ds, fontSize: 11),
                  ]);
              }),
            ]))));
  }

  Widget _buildEmpty() => Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey.shade400), const SizedBox(height: 14),
    Text('No orders found', style: TextStyle(fontSize: 15, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
  ])));

  Widget _buildError() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.cloud_off_outlined, size: 48, color: AppTheme.accentOrange), const SizedBox(height: 12),
    const Text('Failed to load reports', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
    const SizedBox(height: 6), Text(_error ?? '', style: const TextStyle(color: Colors.grey)), const SizedBox(height: 16),
    ElevatedButton.icon(onPressed: _loadReport, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
      icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
  ]));

  Widget _th(String t) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.primaryGreen)));

  Widget _td(String t, {bool bold = false, Color? color, bool monospace = false, double fontSize = 12.5}) =>
    Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(t, style: TextStyle(fontSize: fontSize, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, color: color, fontFamily: monospace ? 'monospace' : null)));

  Widget _tdStatus(String status) {
    Color color;
    if (status.toUpperCase() == 'PENDING') color = const Color(0xFFF59E0B);
    else if (status.toUpperCase().contains('PAID') || status.toUpperCase().contains('COMPLETE')) color = AppTheme.primaryGreen;
    else color = Colors.grey;
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Text(status, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700))));
  }
}
