import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BarChartWidget extends StatelessWidget {
  const BarChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Revenue from Fuel per Month',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: 7000,
                backgroundColor: Colors.black,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1000,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.white12, strokeWidth: 0.8),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    bottom: BorderSide(color: Colors.white24),
                    left: BorderSide(color: Colors.white24),
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = [
                          'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                          'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Des',
                        ];
                        final idx = value.toInt();
                        if (idx >= 0 && idx < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
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
                      interval: 1000,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      const months = [
                        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Des',
                      ];
                      return BarTooltipItem(
                        '${months[group.x]}\n${rod.toY.toInt()}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                barGroups: _buildBarGroups(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    // Ganti data ini sesuai kebutuhan
    const data = [
      4500.0, // Jan
      5000.0, // Feb
      5500.0, // Mar
      4800.0, // Apr
      5200.0, // Mei
      6000.0, // Jun
      5800.0, // Jul
      4200.0, // Aug
      5600.0, // Sep
      5900.0, // Okt
      5300.0, // Nov
      6200.0, // Des
    ];

    return List.generate(data.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data[index],
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(3),
              topRight: Radius.circular(3),
            ),
            // Gradient hijau seperti di gambar
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Color(0xFF1B5E20), // hijau gelap di bawah
                Color(0xFF4CAF50), // hijau terang di atas
              ],
            ),
          ),
        ],
      );
    });
  }
}