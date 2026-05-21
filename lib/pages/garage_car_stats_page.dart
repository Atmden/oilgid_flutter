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
    _availableYears = widget.records
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
      .where((r) =>
          (DateTime.tryParse(r.serviceDate)?.year ?? 0) == _selectedYear)
      .toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final total = filtered.fold<double>(0, (s, r) => s + (r.totalCost ?? 0));
    final currency = filtered
        .where((r) => r.currency != null)
        .map((r) => r.currency!)
        .fold<Map<String, int>>({}, (map, c) {
      map[c] = (map[c] ?? 0) + 1;
      return map;
    }).entries.isEmpty
        ? 'KZT'
        : (filtered
              .where((r) => r.currency != null)
              .map((r) => r.currency!)
              .fold<Map<String, int>>({}, (map, c) {
                map[c] = (map[c] ?? 0) + 1;
                return map;
              })
              .entries
              .reduce((a, b) => a.value >= b.value ? a : b))
            .key;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Год selector
        if (_availableYears.length > 1)
          _YearSelector(
            years: _availableYears,
            selected: _selectedYear,
            onChanged: (y) => setState(() => _selectedYear = y),
          ),

        if (_availableYears.length > 1) const SizedBox(height: 16),

        // Итого
        _SummaryCard(
          total: total,
          currency: currency,
          count: filtered.length,
          year: _selectedYear,
        ),

        const SizedBox(height: 20),

        // По категориям
        _CategoryBreakdown(records: filtered, currency: currency),

        const SizedBox(height: 20),

        // По месяцам
        _MonthlyChart(records: filtered, currency: currency, year: _selectedYear),
      ],
    );
  }
}

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
                    horizontal: 16, vertical: 8),
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

class _CategoryBreakdown extends StatelessWidget {
  final List<ServiceRecord> records;
  final String currency;

  const _CategoryBreakdown(
      {required this.records, required this.currency});

  @override
  Widget build(BuildContext context) {
    final Map<int?, _CatStat> map = {};
    for (final r in records) {
      final key = r.categoryId;
      final existing = map[key];
      final amount = r.totalCost ?? 0;
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

    final sorted = map.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    if (sorted.isEmpty) return const SizedBox.shrink();

    final maxAmount = sorted.first.total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'По категориям',
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
                  color: stat.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(stat.icon, color: stat.color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stat.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
              Text(
                _formatAmount(stat.total, currency),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
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
                style: const TextStyle(
                    fontSize: 11, color: Colors.black38),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
    'Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн',
    'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек',
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
        const Text(
          'По месяцам',
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

String _formatAmount(double amount, String currency) {
  if (amount >= 1000000) {
    return '${(amount / 1000000).toStringAsFixed(1)}M $currency';
  }
  if (amount >= 1000) {
    return '${(amount / 1000).toStringAsFixed(0)} тыс. $currency';
  }
  return '${amount.toStringAsFixed(0)} $currency';
}
