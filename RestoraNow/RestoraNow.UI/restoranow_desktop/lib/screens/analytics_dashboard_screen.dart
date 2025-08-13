import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../layouts/main_layout.dart';
import '../../providers/analytics_provider.dart';
import '../../models/analytics_models.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AnalyticsProvider>().fetchAll());
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Consumer<AnalyticsProvider>(
        builder: (context, p, _) {
          if (p.isLoading && p.summary == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (p.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: ${p.error}', style: const TextStyle(color: Colors.red)),
              ),
            );
          }

          final s = p.summary ?? SummaryResponse(totalRevenue: 0, reservations: 0, avgRating: 0, newUsers: 0);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FiltersBar(),
              const SizedBox(height: 12),
              _KpiRow(summary: s),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  children: const [
                    Expanded(child: _RevenueOverTimeCard()),
                    SizedBox(width: 12),
                    Expanded(child: _RevenueByCategoryCard()),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Expanded(child: _TopProductsCard()),
            ],
          );
        },
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();

    return Wrap(
      spacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.date_range),
          label: Text(
            p.from == null || p.to == null
                ? 'Date: last 7 days (default)'
                : 'Date: ${_d(p.from!)} → ${_d(p.to!)}',
          ),
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2023, 1, 1),
              lastDate: now.add(const Duration(days: 1)),
              initialDateRange: DateTimeRange(
                start: p.from ?? now.subtract(const Duration(days: 6)),
                end: p.to ?? now,
              ),
            );
            if (picked != null) {
              context.read<AnalyticsProvider>().setRange(from: picked.start, to: picked.end);
            }
          },
        ),
        DropdownButton<String>(
          value: p.groupBy,
          items: const [
            DropdownMenuItem(value: 'day', child: Text('Group: Day')),
            DropdownMenuItem(value: 'week', child: Text('Group: Week')),
            DropdownMenuItem(value: 'month', child: Text('Group: Month')),
          ],
          onChanged: (v) => v == null ? null : context.read<AnalyticsProvider>().setGroupBy(v),
        ),
        DropdownButton<int>(
          value: p.topTake,
          items: const [
            DropdownMenuItem(value: 5, child: Text('Top 5')),
            DropdownMenuItem(value: 10, child: Text('Top 10')),
            DropdownMenuItem(value: 15, child: Text('Top 15')),
          ],
          onChanged: (v) => v == null ? null : context.read<AnalyticsProvider>().setTopTake(v),
        ),
        if (p.isLoading)
          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      ],
    );
  }

  static String _d(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class _KpiRow extends StatelessWidget {
  final SummaryResponse summary;
  const _KpiRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    Widget kpi(String title, String value, IconData icon) {
      return Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelMedium),
                    Text(value, style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        kpi('Revenue', _money(summary.totalRevenue), Icons.payments),
        const SizedBox(width: 12),
        kpi('Reservations', summary.reservations.toString(), Icons.event_seat),
        const SizedBox(width: 12),
        kpi('Avg Rating', summary.avgRating.toStringAsFixed(2), Icons.star_rate),
        const SizedBox(width: 12),
        kpi('New Users', summary.newUsers.toString(), Icons.person_add),
      ],
    );
  }

  String _money(double v) => '${v.toStringAsFixed(2)}';
}

class _RevenueOverTimeCard extends StatelessWidget {
  const _RevenueOverTimeCard();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    final data = p.revByPeriod;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: data.isEmpty
            ? const Center(child: Text('No revenue data'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Revenue over time (${p.groupBy})', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: (data.length / 6).clamp(1, 999).toDouble(),
                              getTitlesWidget: (value, meta) {
                                final i = value.round();
                                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                                final d = data[i].period.toLocal();
                                final label = p.groupBy == 'month'
                                    ? '${d.year}-${d.month.toString().padLeft(2, '0')}'
                                    : '${d.month}/${d.day}';
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(label, style: const TextStyle(fontSize: 10)),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: true),
                        minX: 0,
                        maxX: (data.length - 1).toDouble(),
                        minY: 0,
                        maxY: _maxY(data.map((e) => e.revenue)),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            spots: List.generate(
                              data.length,
                              (i) => FlSpot(i.toDouble(), data[i].revenue),
                            ),
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

  double _maxY(Iterable<double> vals) {
    var m = 0.0;
    for (final v in vals) {
      if (v > m) m = v;
    }
    if (m == 0) return 1;
    return m * 1.2;
  }
}

class _RevenueByCategoryCard extends StatelessWidget {
  const _RevenueByCategoryCard();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    final data = p.revByCategory;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: data.isEmpty
            ? const Center(child: Text('No category data'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Revenue by category', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 36),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, _) {
                                final i = v.toInt();
                                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                                return Transform.rotate(
                                  angle: -0.7,
                                  child: Text(data[i].categoryName, style: const TextStyle(fontSize: 10)),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        barGroups: List.generate(
                          data.length,
                          (i) => BarChartGroupData(
                            x: i,
                            barRods: [BarChartRodData(toY: data[i].revenue)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    final data = p.topProducts;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: data.isEmpty
            ? const Center(child: Text('No top products'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Top products', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Product')),
                          DataColumn(label: Text('Category')),
                          DataColumn(label: Text('Sold')),
                          DataColumn(label: Text('Revenue')),
                        ],
                        rows: data
                            .map(
                              (x) => DataRow(
                                cells: [
                                  DataCell(Text(x.productName)),
                                  DataCell(Text(x.categoryName)),
                                  DataCell(Text(x.soldQty.toString())),
                                  DataCell(Text(x.revenue.toStringAsFixed(2))),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
