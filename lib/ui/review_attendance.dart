import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:test_app/ui/bottom_nav_controller.dart';

import '../const/AppColors.dart'; // For date formatting

class AttendanceReview extends StatefulWidget {
  const AttendanceReview({Key? key}) : super(key: key);

  @override
  _AttendanceReviewState createState() => _AttendanceReviewState();
}

class _AttendanceReviewState extends State<AttendanceReview> {
  List<Map<String, dynamic>> _filteredAttendanceData = [];
  bool _isLoading = false;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();

  // Fetch attendance data from the API
  Future<void> _fetchAttendanceData(
      {String? specificDate, String? employeeId}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Construct the base API URL
      String apiUrl = 'http://192.168.3.228:5000/attendance';

      // Add query parameters if provided
      if (specificDate != null && specificDate.isNotEmpty) {
        apiUrl += '?date=$specificDate';
      }
      if (employeeId != null && employeeId.isNotEmpty) {
        apiUrl += specificDate != null
            ? '&employeeId=$employeeId'
            : '?employeeId=$employeeId';
      }

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> fetchedData = [];

        for (var item in data) {
          // Parsing the timestamp carefully
          var timestamp = item['details']['timestamp'] != null
              ? DateTime.tryParse(item['details']['timestamp'].toString())
              : null;

          fetchedData.add({
            'employeeId': item['employeeId'],
            'date': item['date'],
            'details': {
              'inTime': item['details']['inTime'],
              'outTime': item['details']['outTime'],
              'timestamp': timestamp,
            },
          });
        }

        setState(() {
          _filteredAttendanceData = fetchedData; // Show all data by default
        });
      } else {
        print("Failed API Response: ${response.statusCode} - ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch attendance data')),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to open the date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Default date (today)
      firstDate: DateTime(2000), // Earliest selectable date
      lastDate: DateTime(2101), // Latest selectable date
    );

    if (picked != null) {
      // Format the selected date as 'yyyy-MM-dd'
      String formattedDate = DateFormat('yyyy-MM-dd').format(picked);

      // Update the TextField with the selected date
      setState(() {
        _dateController.text = formattedDate;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text(
              'Expense Review',
              style: TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: AppColors.blue,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            color: Colors.white,
            onPressed: () {
              // Navigate to another page when the back arrow is pressed
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => BottomNavController(
                    initialIndex: 4,
                  ),
                ),
              );
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Date Picker Input Field
              TextField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Select Date (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context), // Open date picker
                  ),
                  errorText: _dateController.text.isEmpty
                      ? 'Please select a date'
                      : null,
                ),
                readOnly: true, // Prevent manual input
                onTap: () => _selectDate(context), // Open date picker on tap
              ),
              SizedBox(height: 20),
              // Employee ID Search Field
              TextField(
                controller: _employeeIdController,
                decoration: InputDecoration(
                  labelText: 'Search by Employee ID',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  String specificDate = _dateController.text;
                  String employeeId = _employeeIdController.text;

                  // Call the API with optional parameters
                  _fetchAttendanceData(
                    specificDate: specificDate.isNotEmpty ? specificDate : null,
                    employeeId: employeeId.isNotEmpty ? employeeId : null,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 20),
                  textStyle: TextStyle(fontSize: 16),
                ),
                child: Text(
                  'Fetch Attendance Data',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              SizedBox(height: 20),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _filteredAttendanceData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('assets/images/no_data.jpg'),
                              Text(
                                  'No attendance data found for the selected date or employee id.'),
                            ],
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            itemCount: _filteredAttendanceData.length,
                            itemBuilder: (context, index) {
                              var attendance = _filteredAttendanceData[index];
                              return Container(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.3),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: Offset(0, 3),
                                    )
                                  ],
                                ),
                                child: ListTile(
                                  title: Text(
                                      'Employee ID: ${attendance['employeeId']}'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Date: ${attendance['date']}'),
                                      Text(
                                          'Check-in: ${attendance['details']['inTime'] ?? 'N/A'}'),
                                      Text(
                                          'Check-out: ${attendance['details']['outTime'] ?? 'N/A'}'),
                                      Text(
                                          'Timestamp: ${attendance['details']['timestamp'] != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(attendance['details']['timestamp']!) : 'N/A'}'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }
}
