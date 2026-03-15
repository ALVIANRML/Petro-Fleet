import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget statBox(String title, String value) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1A1D),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 100),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: statBox("Total Pendapatan", "Rp 1,00 jt")),
              Expanded(child: statBox("Total Biaya Service", "Rp 1,00 jt")),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: statBox("Total Perjalanan", "2 Perjalanan")),
              Expanded(child: statBox("Total Liter Diangkut", "2.500 L")),
              const SizedBox(height: 30),
            ],
          ),
          Container(
            height: 250,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(0),
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
          ),
        ],
      ),
    );
  }
}
