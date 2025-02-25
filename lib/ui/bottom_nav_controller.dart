import 'package:flutter/material.dart';
import 'package:test_app/const/AppColors.dart';
import 'package:test_app/ui/bottom_nav_pages/leave.dart';
import 'package:test_app/ui/bottom_nav_pages/expense.dart';
import 'package:test_app/ui/bottom_nav_pages/home.dart';
import 'package:test_app/ui/bottom_nav_pages/profile.dart';
import 'package:test_app/ui/bottom_nav_pages/notification.dart';

class BottomNavController extends StatefulWidget {
  @override
  _BottomNavControllerState createState() => _BottomNavControllerState();
}

class _BottomNavControllerState extends State<BottomNavController> {
  final _pages = [
    Leave(),
    Expense(),
    Home(),
    Notify(),
    Profile(),
  ];
  var _currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        elevation: 5,
        selectedItemColor: AppColors.deep_orange,
        backgroundColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        selectedLabelStyle:
            TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.time_to_leave),
            label: "Leave",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.money),
            label: "Expense",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Notification",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Person",
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            print(_currentIndex);
          });
        },
      ),
      body: _pages[_currentIndex],
    );
  }
}
