import 'package:flutter/material.dart';

import '../services/reports_api.dart';
import '../theme/app_theme.dart';
import '../utils/text_format.dart';
import '../widgets/common.dart';

/// Admin-only sales dashboard: shows the total sale for a day (today by
/// default) and lets the owner search any other day or an arbitrary
/// date/time frame.
class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

enum _Preset { today, yesterday, thisWeek, thisMonth, custom }

class _SalesReportPageState extends State<SalesReportPage> {
  final _api = ReportsApi();

  late DateTime _from;
  late DateTime _to;
  _Preset _preset = _Preset.today;
  late Future<SalesReport> _future;

  @override
  void initState() {
    super.initState();
    _setPresetRange(_Preset.today);
    _future = _load();
  }

  Future<SalesReport> _load() => _api.sales(from: _from, to: _to);

  void _reload() {
    setState(() => _future = _load());
  }

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  void _setPresetRange(_Preset preset) {
    final now = DateTime.now();
    final today = _startOfDay(now);
    switch (preset) {
      case _Preset.today:
        _from = today;
        _to = today.add(const Duration(days: 1));
        break;
      case _Preset.yesterday:
        _from = today.subtract(const Duration(days: 1));
        _to = today;
        break;
      case _Preset.thisWeek:
        _from = today.subtract(Duration(days: today.weekday - 1));
        _to = today.add(const Duration(days: 1));
        break;
      case _Preset.thisMonth:
        _from = DateTime(now.year, now.month, 1);
        _to = today.add(const Duration(days: 1));
        break;
      case _Preset.custom:
        break;
    }
    _preset = preset;
  }

  void _applyPreset(_Preset preset, {bool reload = true}) {
    setState(() => _setPresetRange(preset));
    if (reload) _reload();
  }

  /// Picks a date boundary for the sales range. Sales are searched by day,
  /// so this keeps the UI simple and avoids time selection entirely.
  Future<void> _pickBoundary({required bool isStart}) async {
    final initial = isStart ? _from : _to;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    setState(() {
      if (isStart) {
        _from = _startOfDay(date);
        if (!_to.isAfter(_from)) _to = _from.add(const Duration(days: 1));
      } else {
        _to = _startOfDay(date).add(const Duration(days: 1));
        if (!_to.isAfter(_from)) _from = _to.subtract(const Duration(days: 1));
      }
      _preset = _Preset.custom;
    });
    _reload();
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _fmtDateRangeEnd(DateTime d) =>
      _fmtDate(d.subtract(const Duration(days: 1)));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Sales',
              subtitle: 'Total sale for any day or time frame',
              action: IconButton(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildFilters(),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: FutureBuilder<SalesReport>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoader();
                  }
                  if (snapshot.hasError) {
                    return EmptyState(
                      icon: Icons.error_outline,
                      title: 'Failed to load sales',
                      message: '${snapshot.error}',
                    );
                  }
                  final report = snapshot.data!;
                  return ListView(
                    children: [
                      _buildSummary(report),
                      const SizedBox(height: AppSpacing.lg),
                      if (report.daily.isNotEmpty) ...[
                        _buildDailyBreakdown(report),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      _buildPrescriptions(report),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    Widget chip(String label, _Preset preset) => ChoiceChip(
      label: Text(label),
      selected: _preset == preset,
      onSelected: (_) => _applyPreset(preset),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                chip('Today', _Preset.today),
                chip('Yesterday', _Preset.yesterday),
                chip('This Week', _Preset.thisWeek),
                chip('This Month', _Preset.thisMonth),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickBoundary(isStart: true),
                  icon: const Icon(Icons.event, size: 18),
                  label: Text('From: ${_fmtDate(_from)}'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickBoundary(isStart: false),
                  icon: const Icon(Icons.event_available, size: 18),
                  label: Text('To: ${_fmtDateRangeEnd(_to)}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(SalesReport report) {
    final average = report.prescriptionCount == 0
        ? 0.0
        : report.total / report.prescriptionCount;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        _MetricCard(
          label: 'Total Sale',
          value: '₹${report.total.toStringAsFixed(2)}',
          icon: Icons.currency_rupee,
          color: AppTheme.success,
        ),
        _MetricCard(
          label: 'Prescriptions',
          value: '${report.prescriptionCount}',
          icon: Icons.receipt_long,
          color: AppTheme.primary,
        ),
        _MetricCard(
          label: 'Average Value',
          value: '₹${average.toStringAsFixed(2)}',
          icon: Icons.trending_up,
          color: AppTheme.secondary,
        ),
      ],
    );
  }

  Widget _buildDailyBreakdown(SalesReport report) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              'Day-wise Sale',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          for (final day in report.daily)
            ListTile(
              dense: true,
              leading: const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppTheme.primary,
              ),
              title: Text(_fmtDate(DateTime.parse(day.date))),
              subtitle: Text('${day.prescriptionCount} prescription(s)'),
              trailing: Text(
                '₹${day.total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrescriptions(SalesReport report) {
    if (report.prescriptions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.xl),
        child: EmptyState(
          icon: Icons.point_of_sale_outlined,
          title: 'No sales in this period',
          message: 'Try a different day or widen the time frame.',
        ),
      );
    }
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              'Prescriptions',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          for (final entry in report.prescriptions)
            ListTile(
              leading: InitialsAvatar(text: entry.patientName),
              title: Text(
                entry.patientName.toTitleCase,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Patient #${entry.patientNumber} • '
                '${entry.itemCount} item(s) • '
                '${_fmtDate(entry.createdAt)}',
              ),
              trailing: Text(
                '₹${entry.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.success,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Three across on desktop, full width on phones — clamped so a very
    // narrow transient layout can never produce a negative width.
    final available = width - (AppSpacing.xl * 2);
    final cardWidth = width < 700
        ? (available < 0 ? 0.0 : available)
        : ((available - AppSpacing.md * 2) / 3).clamp(0.0, double.infinity);

    return SizedBox(
      width: cardWidth,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
