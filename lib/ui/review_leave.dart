import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:test_app/ui/bottom_nav_controller.dart';

import '../const/AppColors.dart';

class LeaveReview extends StatefulWidget {
  const LeaveReview({super.key});

  @override
  State<LeaveReview> createState() => _LeaveReviewState();
}

class _LeaveReviewState extends State<LeaveReview> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text('Leave Review'),
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
