import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:test_app/ui/bottom_nav_controller.dart';
import '../const/AppColors.dart';
import 'package:intl/intl.dart';

class AttendanceReview extends StatefulWidget {
  const AttendanceReview({super.key});

  @override
  State<AttendanceReview> createState() => _AttendanceReviewState();
}

class _AttendanceReviewState extends State<AttendanceReview> {
  List<Map<String, dynamic>> _attendanceData = [];
  bool _isLoading = false;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  TextEditingController _dateController = TextEditingController();

  Future<void> _fetchAttendanceData(String specificDate) async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> fetchedData = [];
      QuerySnapshot employeeSnapshot = await firestore.collection('attendance').get();

      for (var employeeDoc in employeeSnapshot.docs) {
        String employeeId = employeeDoc.id;

        // Access 'days' subcollection and check for the specific date
        DocumentSnapshot dateDoc = await firestore
            .collection('attendance')
            .doc(employeeId)
            .collection('days')
            .doc(specificDate)
            .get();

        if (dateDoc.exists) {
          Map<String, dynamic> attendanceDetails =
          dateDoc.data() as Map<String, dynamic>;

          fetchedData.add({
            'employeeId': employeeId,
            'date': specificDate,
            'details': attendanceDetails,
          });

          // Debugging: Print data found
          print("Found data for $employeeId on $specificDate: $attendanceDetails");
        } else {
          // Debugging: Print if date doc doesn't exist
          print("No data found for $employeeId on $specificDate");
        }
      }

      if (fetchedData.isEmpty) {
        print("No attendance data found for $specificDate");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No attendance data found for the selected date.'),
        ));
      }

      setState(() {
        _attendanceData = fetchedData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching attendance data: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to fetch attendance data. Please try again.'),
      ));
    }
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text('Review Attendance'),
          ),
          backgroundColor: AppColors.blue,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                CupertinoPageRoute(
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
              TextField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Enter Date (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                  errorText: _dateController.text.isEmpty
                      ? 'Please enter a date'
                      : null,
                ),
                keyboardType: TextInputType.datetime,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  String specificDate = _dateController.text;
                  if (specificDate.isNotEmpty) {
                    _fetchAttendanceData(specificDate);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Please enter a valid date'),
                    ));
                  }
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
                  : _attendanceData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset('assets/images/no_data.jpg'),
                              Text(
                                  'No attendance data found for the selected date.'),
                            ],
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            itemCount: _attendanceData.length,
                            itemBuilder: (context, index) {
                              var attendance = _attendanceData[index];
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
                                          'Timestamp: ${attendance['details']['timestamp'] != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(attendance['details']['timestamp'].toDate()) : 'N/A'}'),
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
