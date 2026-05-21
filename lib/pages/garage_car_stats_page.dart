import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:oil_gid/features/garage/domain/entities/service_record.dart';
import 'package:oil_gid/features/garage/presentation/garage_route_args.dart';
import 'package:oil_gid/includes/main_app_bar.dart';
import 'package:oil_gid/themes/app_colors.dart';

class GarageCarStatsPage extends StatelessWidget {
  const GarageCarStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final statsArgs = args is GarageCarStatsArgs
        ? args
        : GarageCarStatsArgs(carId: 0, carDisplayName: '', records: const []);

    final records = statsArgs.records
        .where((r) => r.totalCost != null && r.totalCost! > 0)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MainAppBar(title: 'Расходы · ${statsArgs.carDisplayName}'),
      body: records.isEmpty
          ? const Center(
              child: Text(
                'Нет записей с суммами',
                style: TextStyle(color: Colors.black45),
              ),
            )
          : _StatsBody(records: records),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _StatsBody extends StatefulWidget {
  final List<ServiceRecord> records;

  const _StatsBody({required this.records});

  @override
  State<_StatsBody> createState() => _StatsBodyState();
}

class _StatsBodyState extends State<_StatsBody> {
  late int _selectedYear;
  late List<int> _availableYears;

  @override
  void initState() {
    super.initState();
    _availableYears =
        widget.records
            .map((r) => DateTime.tryParse(r.serviceDate)?.year ?? 0)
            .where((y) => y > 0)
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    _selectedYear = _availableYears.isNotEmpty
        ? _availableYears.first
        : DateTime.now().year;
  }

  List<ServiceRecord> get _filtered => widget.records
      .where(
        (r) => (DateTime.tryParse(r.serviceDate)?.year ?? 0) == _selectedYear,
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final total = filtered.fold<double>(0, (s, r) => s + (r.totalCost ?? 0));
    final currency = _dominantCurrency(filtered);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (_availableYears.length > 1)
            _YearSelector(
              years: _availableYears,
              selected: _selectedYear,
              onChanged: (y) => setState(() => _selectedYear = y),
            ),

          if (_availableYears.length > 1) const SizedBox(height: 16),

          _DonutCard(
            records: filtered,
            currency: currency,
            year: _selectedYear,
          ),
          const SizedBox(height: 20),
          _SummaryCard(
            total: total,
            currency: currency,
            count: filtered.length,
            year: _selectedYear,
          ),

          const SizedBox(height: 20),

          _CategoryBreakdown(
            records: filtered,
            currency: currency,
            year: _selectedYear,
          ),

          const SizedBox(height: 20),

          _MonthlyChart(
            records: filtered,
            currency: currency,
            year: _selectedYear,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Year selector
// ---------------------------------------------------------------------------

class _YearSelector extends StatelessWidget {
  final List<int> years;
  final int selected;
  final ValueChanged<int> onChanged;

  const _YearSelector({
    required this.years,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: years.map((year) {
          final isSelected = year == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(year),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primarySoft : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primarySoft
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  '$year',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary card
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  final double total;
  final String currency;
  final int count;
  final int year;

  const _SummaryCard({
    required this.total,
    required this.currency,
    required this.count,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Итого за $year год',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            _formatAmount(total, currency),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count ${_recordsWord(count)}',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _recordsWord(int n) {
    if (n % 100 >= 11 && n % 100 <= 14) return 'записей';
    switch (n % 10) {
      case 1:
        return 'запись';
      case 2:
      case 3:
      case 4:
        return 'записи';
      default:
        return 'записей';
    }
  }
}

// ---------------------------------------------------------------------------
// Donut card
// ---------------------------------------------------------------------------

enum _DonutPeriod { year, quarter, month }

class _DonutCard extends StatefulWidget {
  final List<ServiceRecord> records;
  final String currency;
  final int year;

  const _DonutCard({
    required this.records,
    required this.currency,
    required this.year,
  });

  @override
  State<_DonutCard> createState() => _DonutCardState();
}

class _DonutCardState extends State<_DonutCard> {
  _DonutPeriod _period = _DonutPeriod.year;
  late int _selectedQuarter;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    final months = widget.records
        .map((r) => DateTime.tryParse(r.serviceDate)?.month ?? 0)
        .where((m) => m > 0)
        .toList();

    if (months.isNotEmpty) {
      final latest = months.reduce((a, b) => a > b ? a : b);
      _selectedMonth = latest;
      _selectedQuarter = ((latest - 1) ~/ 3) + 1;
    } else {
      _selectedMonth = DateTime.now().month;
      _selectedQuarter = ((DateTime.now().month - 1) ~/ 3) + 1;
    }
  }

  @override
  void didUpdateWidget(_DonutCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.records != widget.records) {
      final months = widget.records
          .map((r) => DateTime.tryParse(r.serviceDate)?.month ?? 0)
          .where((m) => m > 0)
          .toList();
      if (months.isNotEmpty) {
        final latest = months.reduce((a, b) => a > b ? a : b);
        _selectedMonth = latest;
        _selectedQuarter = ((latest - 1) ~/ 3) + 1;
      }
    }
  }

  List<ServiceRecord> get _periodRecords {
    switch (_period) {
      case _DonutPeriod.year:
        return widget.records;
      case _DonutPeriod.quarter:
        final start = (_selectedQuarter - 1) * 3 + 1;
        final end = _selectedQuarter * 3;
        return widget.records.where((r) {
          final m = DateTime.tryParse(r.serviceDate)?.month ?? 0;
          return m >= start && m <= end;
        }).toList();
      case _DonutPeriod.month:
        return widget.records.where((r) {
          return DateTime.tryParse(r.serviceDate)?.month == _selectedMonth;
        }).toList();
    }
  }

  List<int> get _availableQuarters =>
      widget.records
          .map((r) => DateTime.tryParse(r.serviceDate)?.month ?? 0)
          .where((m) => m > 0)
          .map((m) => ((m - 1) ~/ 3) + 1)
          .toSet()
          .toList()
        ..sort();

  List<int> get _availableMonths =>
      widget.records
          .map((r) => DateTime.tryParse(r.serviceDate)?.month ?? 0)
          .where((m) => m > 0)
          .toSet()
          .toList()
        ..sort();

  @override
  Widget build(BuildContext context) {
    final pr = _periodRecords;
    final cats = _groupByCategory(pr);
    final total = pr.fold<double>(0, (s, r) => s + (r.totalCost ?? 0));

    final segments = total > 0
        ? cats
              .map(
                (c) => _DonutSegment(
                  color: c.color,
                  fraction: c.total / total,
                  name: c.name,
                  total: c.total,
                  icon: c.icon,
                ),
              )
              .toList()
        : <_DonutSegment>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Статистика расходов',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: _PeriodSwitcher(
                  period: _period,
                  onChanged: (p) => setState(() => _period = p),
                ),
              ),
              if (_period == _DonutPeriod.quarter)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: _QuarterSelector(
                    available: _availableQuarters,
                    selected: _selectedQuarter,
                    onChanged: (q) => setState(() => _selectedQuarter = q),
                  ),
                ),
              if (_period == _DonutPeriod.month)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: _MonthChips(
                    available: _availableMonths,
                    selected: _selectedMonth,
                    onChanged: (m) => setState(() => _selectedMonth = m),
                  ),
                ),
              if (segments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Text(
                    'Нет данных за выбранный период',
                    style: TextStyle(color: Colors.black38, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                )
              else ...[
                const SizedBox(height: 20),
                _DonutChart(
                  segments: segments,
                  total: total,
                  currency: widget.currency,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                _DonutLegend(segments: segments, currency: widget.currency),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Period switcher (Год / Квартал / Месяц)
// ---------------------------------------------------------------------------

class _PeriodSwitcher extends StatelessWidget {
  final _DonutPeriod period;
  final ValueChanged<_DonutPeriod> onChanged;

  const _PeriodSwitcher({required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _tab(_DonutPeriod.year, 'За год'),
          _tab(_DonutPeriod.quarter, 'Квартал'),
          _tab(_DonutPeriod.month, 'Месяц'),
        ],
      ),
    );
  }

  Widget _tab(_DonutPeriod p, String label) {
    final isSelected = period == p;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(p),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    const BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.black87 : Colors.black45,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quarter selector (Q1 – Q4)
// ---------------------------------------------------------------------------

class _QuarterSelector extends StatelessWidget {
  final List<int> available;
  final int selected;
  final ValueChanged<int> onChanged;

  const _QuarterSelector({
    required this.available,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (i) {
        final q = i + 1;
        final hasData = available.contains(q);
        final isSelected = q == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: hasData ? () => onChanged(q) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primarySoft : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primarySoft
                      : hasData
                      ? AppColors.border
                      : AppColors.border.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                'Q$q',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : hasData
                      ? Colors.black87
                      : Colors.black26,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Month chips (Янв – Дек)
// ---------------------------------------------------------------------------

class _MonthChips extends StatelessWidget {
  final List<int> available;
  final int selected;
  final ValueChanged<int> onChanged;

  const _MonthChips({
    required this.available,
    required this.selected,
    required this.onChanged,
  });

  static const _labels = [
    'Янв',
    'Фев',
    'Мар',
    'Апр',
    'Май',
    'Июн',
    'Июл',
    'Авг',
    'Сен',
    'Окт',
    'Ноя',
    'Дек',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(12, (i) {
          final month = i + 1;
          final hasData = available.contains(month);
          final isSelected = month == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: hasData ? () => onChanged(month) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primarySoft
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primarySoft
                        : hasData
                        ? AppColors.border
                        : AppColors.border.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : hasData
                        ? Colors.black87
                        : Colors.black26,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Donut chart
// ---------------------------------------------------------------------------

class _DonutSegment {
  final Color color;
  final double fraction;
  final String name;
  final double total;
  final IconData icon;

  const _DonutSegment({
    required this.color,
    required this.fraction,
    required this.name,
    required this.total,
    required this.icon,
  });
}

class _DonutChart extends StatelessWidget {
  final List<_DonutSegment> segments;
  final double total;
  final String currency;

  const _DonutChart({
    required this.segments,
    required this.total,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(170, 170),
            painter: _DonutPainter(segments),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatAmount(total, currency),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              const Text(
                'итого',
                style: TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSegment> segments;

  const _DonutPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 28.0;
    final radius = size.shortestSide / 2 - strokeWidth / 2 - 4;
    const gapAngle = 0.025;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    double startAngle = -math.pi / 2;

    for (final seg in segments) {
      final sweep = seg.fraction * 2 * math.pi;
      final actualSweep = (sweep - gapAngle).clamp(0.001, 2 * math.pi);
      paint.color = seg.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + gapAngle / 2,
        actualSweep,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.segments != segments;
}

// ---------------------------------------------------------------------------
// Donut legend
// ---------------------------------------------------------------------------

class _DonutLegend extends StatelessWidget {
  final List<_DonutSegment> segments;
  final String currency;

  const _DonutLegend({required this.segments, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: segments.asMap().entries.map((e) {
          final i = e.key;
          final seg = e.value;
          final pct = (seg.fraction * 100);
          final pctStr = pct < 1 ? '<1%' : '${pct.toStringAsFixed(0)}%';
          return Column(
            children: [
              if (i > 0) const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: seg.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(seg.icon, size: 14, color: seg.color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      seg.name,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    pctStr,
                    style: const TextStyle(fontSize: 12, color: Colors.black38),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatAmount(seg.total, currency),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category breakdown (horizontal bars)
// ---------------------------------------------------------------------------

class _CategoryBreakdown extends StatelessWidget {
  final List<ServiceRecord> records;
  final String currency;
  final int year;

  const _CategoryBreakdown({
    required this.records,
    required this.currency,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = _groupByCategory(records);
    if (sorted.isEmpty) return const SizedBox.shrink();

    final maxAmount = sorted.first.total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'По категориям за $year год',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: sorted.asMap().entries.map((entry) {
              final i = entry.key;
              final stat = entry.value;
              return Column(
                children: [
                  if (i > 0)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  _CategoryRow(
                    stat: stat,
                    maxAmount: maxAmount,
                    currency: currency,
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final _CatStat stat;
  final double maxAmount;
  final String currency;

  const _CategoryRow({
    required this.stat,
    required this.maxAmount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxAmount > 0 ? stat.total / maxAmount : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: stat.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(stat.icon, color: stat.color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stat.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                _formatAmount(stat.total, currency),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: 42),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          height: 4,
                          width: constraints.maxWidth * fraction,
                          decoration: BoxDecoration(
                            color: stat.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${stat.count} зап.',
                style: const TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Monthly bar chart
// ---------------------------------------------------------------------------

class _MonthlyChart extends StatelessWidget {
  final List<ServiceRecord> records;
  final String currency;
  final int year;

  const _MonthlyChart({
    required this.records,
    required this.currency,
    required this.year,
  });

  static const _months = [
    'Янв',
    'Фев',
    'Мар',
    'Апр',
    'Май',
    'Июн',
    'Июл',
    'Авг',
    'Сен',
    'Окт',
    'Ноя',
    'Дек',
  ];

  @override
  Widget build(BuildContext context) {
    final totals = List.filled(12, 0.0);
    for (final r in records) {
      final date = DateTime.tryParse(r.serviceDate);
      if (date != null && date.year == year) {
        totals[date.month - 1] += r.totalCost ?? 0;
      }
    }

    final maxVal = totals.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'По месяцам за $year год',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(12, (i) {
              final val = totals[i];
              final frac = val / maxVal;
              final hasData = val > 0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 80,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            width: double.infinity,
                            height: hasData ? (frac * 80).clamp(4.0, 80.0) : 3,
                            decoration: BoxDecoration(
                              color: hasData
                                  ? AppColors.primarySoft
                                  : AppColors.border,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _months[i],
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.black45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared models & helpers
// ---------------------------------------------------------------------------

class _CatStat {
  final String name;
  final IconData icon;
  final Color color;
  final double total;
  final int count;

  const _CatStat({
    required this.name,
    required this.icon,
    required this.color,
    required this.total,
    required this.count,
  });
}

List<_CatStat> _groupByCategory(List<ServiceRecord> records) {
  final Map<int?, _CatStat> map = {};
  for (final r in records) {
    final key = r.categoryId;
    final amount = r.totalCost ?? 0;
    final existing = map[key];
    if (existing == null) {
      map[key] = _CatStat(
        name: r.category?.name ?? 'Без категории',
        icon: r.category?.icon ?? Icons.receipt_outlined,
        color: r.category?.color ?? Colors.grey,
        total: amount,
        count: 1,
      );
    } else {
      map[key] = _CatStat(
        name: existing.name,
        icon: existing.icon,
        color: existing.color,
        total: existing.total + amount,
        count: existing.count + 1,
      );
    }
  }
  return map.values.toList()..sort((a, b) => b.total.compareTo(a.total));
}

String _dominantCurrency(List<ServiceRecord> records) {
  final counts = <String, int>{};
  for (final r in records) {
    if (r.currency != null)
      counts[r.currency!] = (counts[r.currency!] ?? 0) + 1;
  }
  if (counts.isEmpty) return 'KZT';
  return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

String _formatAmount(double amount, String currency) {
  if (amount >= 1000000) {
    return '${(amount / 1000000).toStringAsFixed(1)}M $currency';
  }
  if (amount >= 1000) {
    return '${(amount / 1000).toStringAsFixed(0)} тыс. $currency';
  }
  return '${amount.toStringAsFixed(0)} $currency';
}
