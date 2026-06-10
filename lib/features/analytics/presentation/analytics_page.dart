import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/extensions/datetime_extensions.dart';
import '../application/providers.dart';

/// Spend analytics dashboard — category pie chart + monthly trend line chart (PBI-006).
class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  DateTime _month = DateTime.now();
  int _touchedPieIndex = -1;
  static const _trendMonths = 6;

  @override
  Widget build(BuildContext context) {
    final breakdownAsync = ref.watch(categoryBreakdownProvider(_month));
    final namesAsync = ref.watch(analyticsCategoryNamesProvider);
    final trendAsync = ref.watch(monthlyTrendProvider(_trendMonths));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spend Analytics'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _MonthSelector(
            current: _month,
            onChanged: (m) => setState(() => _month = m),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Category Pie Chart ──────────────────────────────────────
            Text(
              'Expenses by Category',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            breakdownAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (breakdown) => namesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
                data: (names) => _CategoryPieChart(
                  breakdown: breakdown,
                  categoryNames: names,
                  touchedIndex: _touchedPieIndex,
                  onTouched: (i) => setState(() => _touchedPieIndex = i),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Monthly Trend Line Chart ────────────────────────────────
            Text(
              'Monthly Trend (last $_trendMonths months)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            trendAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (trend) => _MonthlyTrendChart(months: trend),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category Pie Chart ──────────────────────────────────────────────────────

class _CategoryPieChart extends StatelessWidget {
  final Map<String, int> breakdown;
  final Map<String, String> categoryNames;
  final int touchedIndex;
  final void Function(int) onTouched;

  const _CategoryPieChart({
    required this.breakdown,
    required this.categoryNames,
    required this.touchedIndex,
    required this.onTouched,
  });

  static const _palette = [
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
    Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No expenses this month'),
        ),
      );
    }

    final total = breakdown.values.fold(0, (a, b) => a + b);
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      sections.add(
        PieChartSectionData(
          value: e.value.toDouble(),
          title: i == touchedIndex
              ? '${((e.value / total) * 100).toStringAsFixed(1)}%'
              : '',
          radius: i == touchedIndex ? 64 : 52,
          color: _palette[i % _palette.length],
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions ||
                      response == null ||
                      response.touchedSection == null) {
                    onTouched(-1);
                    return;
                  }
                  onTouched(response.touchedSection!.touchedSectionIndex);
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Legend
        ...List.generate(entries.length, (i) {
          final e = entries[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _palette[i % _palette.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoryNames[e.key] ?? e.key,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  fmt.format(e.value / 100),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${((e.value / total) * 100).toStringAsFixed(0)}%)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─── Monthly Trend Line Chart ────────────────────────────────────────────────

class _MonthlyTrendChart extends StatelessWidget {
  final List<MonthlyTotals> months;

  const _MonthlyTrendChart({required this.months});

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Not enough data yet'),
        ),
      );
    }

    // Reverse to chronological order (oldest left → newest right).
    final sorted = months.reversed.toList();

    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    for (var i = 0; i < sorted.length; i++) {
      incomeSpots.add(FlSpot(i.toDouble(), sorted[i].incomeMajorUnits));
      expenseSpots.add(FlSpot(i.toDouble(), sorted[i].expenseMajorUnits));
    }

    final allValues = [
      ...sorted.map((m) => m.incomeMajorUnits),
      ...sorted.map((m) => m.expenseMajorUnits),
    ];
    final maxY = allValues.fold(0.0, (a, b) => a > b ? a : b);

    final fmt = NumberFormat.compact(locale: 'en_IN');
    final theme = Theme.of(context);

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY * 1.2,
          lineBarsData: [
            // Income — green
            LineChartBarData(
              spots: incomeSpots,
              isCurved: true,
              color: Colors.green,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withValues(alpha: 0.08),
              ),
            ),
            // Expense — red
            LineChartBarData(
              spots: expenseSpots,
              isCurved: true,
              color: theme.colorScheme.error,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.error.withValues(alpha: 0.08),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= sorted.length) {
                    return const SizedBox.shrink();
                  }
                  final m = sorted[idx];
                  return Text(
                    DateTime(m.year, m.month).shortMonthYear,
                    style: const TextStyle(fontSize: 9),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) => Text(
                  '₹${fmt.format(value)}',
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

// ─── Month Selector ──────────────────────────────────────────────────────────

class _MonthSelector extends StatelessWidget {
  final DateTime current;
  final void Function(DateTime) onChanged;

  const _MonthSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onChanged(DateTime(current.year, current.month - 1)),
        ),
        Text(
          current.monthYearLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: current.isSameMonth(DateTime.now())
              ? null
              : () => onChanged(DateTime(current.year, current.month + 1)),
        ),
      ],
    );
  }
}
