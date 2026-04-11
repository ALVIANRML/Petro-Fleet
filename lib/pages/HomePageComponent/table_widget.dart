import 'package:flutter/material.dart';

class TableWidget extends StatelessWidget {
  const TableWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: const Color(0xFF0B4996),
        borderRadius: BorderRadius.circular(0),
        border: Border.all(color: Colors.white),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(
              label: Text('No', style: TextStyle(color: Colors.white)),
            ),
            DataColumn(
              label: Text('Nama', style: TextStyle(color: Colors.white)),
            ),
            DataColumn(
              label: Text('Umur', style: TextStyle(color: Colors.white)),
            ),
            DataColumn(
              label: Text('Kota', style: TextStyle(color: Colors.white)),
            ),
          ],
          rows: const [
            DataRow(
              cells: [
                DataCell(Text('1', style: TextStyle(color: Colors.white))),
                DataCell(Text('Alvian', style: TextStyle(color: Colors.white))),
                DataCell(Text('22', style: TextStyle(color: Colors.white))),
                DataCell(Text('Medan', style: TextStyle(color: Colors.white))),
              ],
            ),
            DataRow(
              cells: [
                DataCell(Text('2', style: TextStyle(color: Colors.white))),
                DataCell(Text('Budi', style: TextStyle(color: Colors.white))),
                DataCell(Text('23', style: TextStyle(color: Colors.white))),
                DataCell(
                  Text('Jakarta', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
