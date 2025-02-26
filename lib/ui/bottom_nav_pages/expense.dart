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
        backgroundColor: AppColors.blue,
        automaticallyImplyLeading: false,
      ),
      body: Text('This is Expense Page'),
    );
  }
}







