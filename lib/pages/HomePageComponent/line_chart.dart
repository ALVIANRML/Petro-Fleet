import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class LineCharetWidget extends StatelessWidget {
  const LineCharetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Color(0xFF0B4996),
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legenda
          Row(
            children: [
              _buildLegend(color: Colors.green, label: 'Pendapatan'),
              const SizedBox(width: 16),
              _buildLegend(color: Colors.red, label: 'Pengeluaran'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 1,
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.white12, strokeWidth: 0.8),
                  getDrawingVerticalLine: (_) =>
                      FlLine(color: Colors.white12, strokeWidth: 0.8),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.white24),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = [
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'Mei',
                          'Jun',
                          'Jul',
                          'Agu',
                          'Sep',
                          'Okt',
                          'Nov',
                          'Des',
                        ];
                        final idx = value.toInt();
                        if (idx >= 0 && idx < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              months[idx],
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 200,
                      reservedSize: 55,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          formatRupiah(value * 1000000000),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isIncome = spot.barIndex == 0;
                        double rupiah = spot.y * 1000000000;
                        return LineTooltipItem(
                          '${isIncome ? 'Pendapatan' : 'Pengeluaran'}\n${formatRupiah(rupiah)}',
                          TextStyle(
                            color: isIncome ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  // Line Pendapatan (Hijau)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 0.50),
                      FlSpot(1, 0.60),
                      FlSpot(2, 0.55),
                      FlSpot(3, 0.70),
                      FlSpot(4, 0.65),
                      FlSpot(5, 0.80),
                      FlSpot(6, 0.75),
                      FlSpot(7, 0.85),
                      FlSpot(8, 0.90),
                      FlSpot(9, 0.92),
                      FlSpot(10, 0.95),
                      FlSpot(11, 1.00),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.3,
                    barWidth: 1.5,
                    color: Colors.green,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 3,
                            color: Colors.green,
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withOpacity(0.06),
                    ),
                  ),
                  // Line Pengeluaran (Merah)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 0.00015),
                      FlSpot(1, 0.22),
                      FlSpot(2, 0.18),
                      FlSpot(3, 0.35),
                      FlSpot(4, 0.07),
                      FlSpot(5, 0.60),
                      FlSpot(6, 0.00002),
                      FlSpot(7, 0.30),
                      FlSpot(8, 0.80),
                      FlSpot(9, 0.90),
                      FlSpot(10, 0.95),
                      FlSpot(11, 1.00),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.3,
                    barWidth: 1.5,
                    color: Colors.red,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 3,
                            color: Colors.red,
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.red.withOpacity(0.06),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

String formatRupiah(double value) {
  if (value >= 1000000000000) {
    return "${(value / 1000000000000).toStringAsFixed(1)} T";
  } else if (value >= 1000000000) {
    return "${(value / 1000000000).toStringAsFixed(1)} M";
  } else if (value >= 1000000) {
    return "${(value / 1000000).toStringAsFixed(1)} Jt";
  } else if (value >= 1000) {
    return "${(value / 1000).toStringAsFixed(1)} Rb";
  } else {
    return value.toInt().toString();
  }
}
