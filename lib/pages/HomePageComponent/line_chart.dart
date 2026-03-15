import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class LineCharetWidget extends StatelessWidget {
  const LineCharetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: MediaQuery.of(context).size.width,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: true),
          titlesData: FlTitlesData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 3),
                FlSpot(1, 4),
                FlSpot(2, 2),
                FlSpot(3, 5),
                FlSpot(4, 3),
                FlSpot(5, 6),
                FlSpot(6, 6),
                FlSpot(7, 2),
                FlSpot(8, 6),
                FlSpot(9, 6),
                FlSpot(10, 6),
                FlSpot(11, 6),
              ],
              isCurved: true,
              barWidth: 1,
            ),
          ],
        ),
      ),
    );
  }
}
