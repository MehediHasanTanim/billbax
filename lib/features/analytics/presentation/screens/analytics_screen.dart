import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_format.dart';
import '../../providers/analytics_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  static const _monthLabels = [
    'জানু',
    'ফেব',
    'মার্চ',
    'এপ্রি',
    'মে',
    'জুন',
    'জুলা',
    'আগ',
    'সেপ',
    'অক্টো',
    'নভে',
    'ডিসে',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(selectedAnalyticsYearProvider);
    final totals = ref.watch(monthlyTotalsProvider(year));

    return Scaffold(
      appBar: AppBar(
        title: const Text('বিল বিশ্লেষণ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'আগের বছর',
            onPressed: () =>
                ref.read(selectedAnalyticsYearProvider.notifier).state =
                    year - 1,
          ),
          Center(
            child: Text(
              '$year',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'পরের বছর',
            onPressed: year >= DateTime.now().year
                ? null
                : () => ref.read(selectedAnalyticsYearProvider.notifier).state =
                    year + 1,
          ),
        ],
      ),
      body: totals.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) => _AnalyticsBody(year: year, data: data),
      ),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({required this.year, required this.data});

  final int year;
  final List<MonthlyTotal> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('এই বছরের কোনো পেমেন্ট নেই'));
    }

    final yearTotal = data.fold<double>(0, (sum, d) => sum + d.total);
    final maxY = data.map((d) => d.total).reduce((a, b) => a > b ? a : b);
    final chartMaxY = maxY <= 0 ? 1.0 : maxY * 1.2;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$year মোট খরচ',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormat.taka(yearTotal),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${data.length} মাস',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'মাসিক খরচ',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: Padding(
            padding: const EdgeInsets.only(right: 8, top: 8),
            child: BarChart(
              BarChartData(
                maxY: chartMaxY,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMaxY / 4,
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt() - 1;
                        if (idx < 0 ||
                            idx >= AnalyticsScreen._monthLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            AnalyticsScreen._monthLabels[idx],
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == meta.max) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          '৳${value.toInt()}',
                          style: const TextStyle(fontSize: 9),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: data
                    .map(
                      (d) => BarChartGroupData(
                        x: d.month,
                        barRods: [
                          BarChartRodData(
                            toY: d.total,
                            color: Colors.blue,
                            width: 16,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ...data.reversed.map(
          (d) => ListTile(
            dense: true,
            title: Text(AnalyticsScreen._monthLabels[d.month - 1]),
            trailing: Text(
              CurrencyFormat.taka(d.total),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
