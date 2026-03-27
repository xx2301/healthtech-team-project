import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BarGraph extends StatelessWidget {
  final List<double> dataPoints;
  final List<String>? labels;

  const BarGraph({super.key, required this.dataPoints, this.labels});

  @override
  Widget build(BuildContext context) {
    final List<double> values = dataPoints;

    if (values.isEmpty) {
      return const Center(child: Text('No sleep data'));
    }

    final double maxValue = values.reduce((a, b) => a > b ? a : b);
    final double maxY = maxValue == 0 ? 1.0 : maxValue * 1.1;

    final List<String> effectiveLabels;
    if (labels != null && labels!.length == values.length) {
      effectiveLabels = labels!;
    } else {
      const defaultDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      effectiveLabels = List.generate(values.length, (i) {
        if (i < defaultDays.length) return defaultDays[i];
        return '';
      });
    }

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
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= effectiveLabels.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Text(
                    effectiveLabels[index],
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                );
              },
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
                // borderRadius: BorderRadius.circular(8),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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
}
