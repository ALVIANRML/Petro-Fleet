import 'package:flutter/material.dart';
import './line_chart.dart';
import './stat_box.dart';
import './bar_chart.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1A1D),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 30),

            Row(
              children: const [
                Expanded(
                  child: StatBox(
                    title: "Total Pendapatan",
                    value: "Rp 10 Juta",
                  ),
                ),
                Expanded(
                  child: StatBox(
                    title: "Total Biaya Service",
                    value: "Rp 10 Juta",
                  ),
                ),
              ],
            ),
            Row(
              children: const [
                Expanded(
                  child: StatBox(
                    title: "Total Perjalanan",
                    value: "2 Perjalanan",
                  ),
                ),
                Expanded(
                  child: StatBox(
                    title: "Total Liter Diangkut",
                    value: "2.500 L",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const BarChartWidget(),
            const SizedBox(height: 20),
            const LineCharetWidget(),
          ],
        ),
      ),
    );
  }
}
