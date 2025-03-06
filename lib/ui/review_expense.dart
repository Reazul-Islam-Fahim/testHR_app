import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:test_app/ui/bottom_nav_controller.dart';

import '../const/AppColors.dart';

class ExpenseReview extends StatefulWidget {
  const ExpenseReview({super.key});

  @override
  State<ExpenseReview> createState() => _ExpenseReviewState();
}

class _ExpenseReviewState extends State<ExpenseReview> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text('Expense Review'),
          ),
          backgroundColor: AppColors.blue,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              // Navigate to another page when the back arrow is pressed
              Navigator.pushReplacement(
                context,
                CupertinoPageRoute(
                    builder: (context) => BottomNavController(
                      initialIndex: 4,
                    )),
              );
            },
          ),
        ),
      ),
    );
  }
}
