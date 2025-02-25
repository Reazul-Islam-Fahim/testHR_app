import 'package:flutter/material.dart';

import '../../const/AppColors.dart';

class Expense extends StatefulWidget {
  const Expense({super.key});

  @override
  State<Expense> createState() => _ExpenseState();
}

class _ExpenseState extends State<Expense> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Expense',
          ),
        ),
        backgroundColor: AppColors.deep_orange,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
          child: Container(
            child: Center(
              child: DataTable(
                  headingRowHeight: 100,
                  columns: [
                    DataColumn(label: Text('Name'),tooltip: 'Name'),
                    DataColumn(label: Text('Age'),),
                    DataColumn(label: Text('Role'),),
                  ],
                  rows: [
                    DataRow(cells: [
                      DataCell(Text('X')),
                      DataCell(Text('29')),
                      DataCell(Text('SDE')),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('y'), showEditIcon: true),
                      DataCell(Text('25')),
                      DataCell(Text('SDET')),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('Z')),
                      DataCell(Text('39')),
                      DataCell(Text('DM')),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('A')),
                      DataCell(Text('35')),
                      DataCell(Text('MD')),
                    ]),
                  ]
              ),
            ),
          )
      ),
    );
  }
}
