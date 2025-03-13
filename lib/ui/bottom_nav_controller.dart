import 'package:flutter/material.dart';
import 'package:test_app/const/AppColors.dart';
import 'package:test_app/ui/bottom_nav_pages/leave.dart';
import 'package:test_app/ui/bottom_nav_pages/expense.dart';
import 'package:test_app/ui/bottom_nav_pages/home.dart';
import 'package:test_app/ui/bottom_nav_pages/more.dart';
import 'package:test_app/ui/bottom_nav_pages/notification.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BottomNavController extends StatefulWidget {
  final int initialIndex; // The initial index for the BottomNavigationBar

  const BottomNavController({Key? key, this.initialIndex = 2})
      : super(key: key);

  @override
  _BottomNavControllerState createState() => _BottomNavControllerState();
}

class _BottomNavControllerState extends State<BottomNavController> {
  late int _currentIndex;
  bool hasPendingLeave = false;
  bool hasPendingExpenses = false;

  String? _designation;
  // bool _isLoading = false;
  // bool _hasError = false;

  final _pages = [
    Leave(),
    Expense(),
    Home(),
    Notify(),
    More(),
  ];

  Future<void> checkPendingLeaves() async {
    // Replace with your API endpoint
    final response = await http
        .get(Uri.parse('http://192.168.3.228:4000/api/leave-requests'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        // Check if any leave request has status "Pending"
        hasPendingLeave = data.any((item) => item['status'] == 'Pending');
      });
    } else {
      throw Exception('Failed to load leave requests');
    }
  }

  Future<void> checkPendingExpenses() async {
    // Replace with your API endpoint
    final response = await http
        .get(Uri.parse('http://192.168.3.228:3000/api/expense-requests'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        // Check if any expense request has status "Pending"
        hasPendingExpenses = data.any((item) => item['status'] == 'Pending');
      });
    } else {
      throw Exception('Failed to load expense requests');
    }
  }

  Future<void> _fetchUserData() async {
    // setState(() {
    //   _isLoading = true;
    //   _hasError = false; // Reset error state
    // });

    try {
      // Replace with your API URL to fetch user data
      final response =
          await http.get(Uri.parse('http://192.168.3.228:7000/get-user-data'));

      if (response.statusCode == 200) {
        // Parse the JSON response
        final data = json.decode(response.body);

        setState(() {
          _designation = data['designation'];
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      // setState(() {
      //   _hasError = true;
      // });
      print("Error fetching data: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex =
        widget.initialIndex; // Set the initial index passed from constructor
    // Call the functions to check for pending requests
    checkPendingLeaves();
    checkPendingExpenses();
    _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          elevation: 5,
          selectedItemColor: AppColors.blue,
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
            if (_designation?.toLowerCase() == 'manager' ||
                _designation?.toLowerCase() == 'admin')
              ...[
              if (hasPendingLeave || hasPendingExpenses)
                BottomNavigationBarItem(
                  icon: Stack(
                    children: [
                      Icon(Icons.more_horiz),
                      Positioned(
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  label: "More",
                )
              else
                BottomNavigationBarItem(
                  icon: Icon(Icons.more_horiz),
                  label: "More",
                ),]
            else
              BottomNavigationBarItem(
                icon: Icon(Icons.more_horiz),
                label: "More",
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
      ),
    );
  }
}
