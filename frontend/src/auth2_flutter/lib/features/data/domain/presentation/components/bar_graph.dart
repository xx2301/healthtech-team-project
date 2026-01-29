import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BarGraph extends StatefulWidget {
  const BarGraph({super.key});

  @override
  State<BarGraph> createState() => _BarGraphState();
}

class _BarGraphState extends State<BarGraph> {
  final List<double> values = [5.5, 0, 2, 5.0, 6.0, 6.3, 6.5];
  final double maxY = 7.0;

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        groupsSpace: 6, // small gap between days
        barTouchData: BarTouchData(enabled: false),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),

        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              getTitlesWidget: _bottomTitles,
            ),
          ),
        ),

        // 🔥 ONE rod per group, but with stacked colors
        barGroups: List.generate(values.length, (index) {
          final v = values[index];

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: maxY,
                width: 30,
                borderRadius: BorderRadius.circular(0), // almost square
                rodStackItems: [
                  // Green "filled" part
                  BarChartRodStackItem(
                    0,
                    v,
                    Colors.blue.shade200,
                  ),
                  // Grey remaining part up to max
                  BarChartRodStackItem(
                    v,
                    maxY,
                    Colors.grey.shade200,
                  ),
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

    if (index < 0 || index >= days.length) {
      return const SizedBox.shrink();
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4,
      child: Text(
        days[index],
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
