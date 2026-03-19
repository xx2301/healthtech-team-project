import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BarGraph extends StatelessWidget {
  final List<double> dataPoints;
  const BarGraph({super.key, required this.dataPoints});

  @override
  Widget build(BuildContext context) {
    final double maxY = 12.0;
    final List<double> values = dataPoints;

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        groupsSpace: 6,
        barTouchData: BarTouchData(enabled: false),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              getTitlesWidget: _bottomTitles,
            ),
          ),
        ),
        barGroups: List.generate(values.length, (index) {
          final v = values[index];
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: maxY,
                width: 30,
                borderRadius: BorderRadius.circular(0),
                rodStackItems: [
                  BarChartRodStackItem(0, v, Colors.blue.shade200),
                  BarChartRodStackItem(v, maxY, Colors.grey.shade200),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _bottomTitles(double value, TitleMeta meta) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final index = value.toInt();
    if (index < 0 || index >= days.length) return const SizedBox.shrink();
    return SideTitleWidget(
      meta: meta,
      space: 4,
      child: Text(days[index], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }
}