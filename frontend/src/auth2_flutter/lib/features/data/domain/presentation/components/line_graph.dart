import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LineGraph extends StatefulWidget {
  const LineGraph({super.key});

  @override
  State<LineGraph> createState() => _LineGraphState();
}

class _LineGraphState extends State<LineGraph> {
  final List<FlSpot> _spots = const [
    FlSpot(0, 70),
    FlSpot(1, 69),
    FlSpot(2, 68),
    FlSpot(3, 72),
    FlSpot(4, 75),
    FlSpot(5, 73),
    FlSpot(6, 71),
    FlSpot(7, 72),
  ];

  @override
  Widget build(BuildContext context) {
    return LineChart(_buildLineChartData());
  }

  LineChartData _buildLineChartData() {
    return LineChartData(
      minX: 0,
      maxX: 7,
      minY: 66,
      maxY: 76,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(
          strokeWidth: 0.4,
          color: Colors.grey.withOpacity(0.3),
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: const FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineTouchData: LineTouchData(enabled: false),
      lineBarsData: [
        LineChartBarData(
          spots: _spots,
          isCurved: true,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      ],
    );
  }
}
