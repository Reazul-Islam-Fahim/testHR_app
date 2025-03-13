import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:test_app/ui/bottom_nav_controller.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../const/AppColors.dart';

class LeaveReview extends StatefulWidget {
  final Function() onStatusUpdated;

  const LeaveReview({super.key, required this.onStatusUpdated});

  @override
  State<LeaveReview> createState() => _LeaveReviewState();
}

class _LeaveReviewState extends State<LeaveReview> {

  bool isLoading = true;

  List<LeaveRequest> leaveRequests = [];

  @override
  void initState() {
    super.initState();
    fetchLeaveRequests();
  }

  Future<void> fetchLeaveRequests() async {
    // Replace with your API endpoint
    final response = await http.get(Uri.parse('http://192.168.3.228:4000/api/leave-requests'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        leaveRequests = data.map((item) => LeaveRequest.fromJson(item)).toList();
      });
    } else {
      throw Exception('Failed to load leave requests');
    }
  }

  Future<void> updateLeaveStatus(String leaveId, String status) async {
    // Replace with your API endpoint
    final response = await http.post(
      Uri.parse('http://192.168.3.228:4000/api/update-leave-status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'leaveId': leaveId, 'status': status}),
    );

    if (response.statusCode == 200) {
      // Update the local state
      setState(() {
        leaveRequests.removeWhere((request) => request.id == leaveId);
      });
    } else {
      throw Exception('Failed to update leave status');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text('Leave Review',
              style: TextStyle(color: Colors.white),),
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
                    )),
              );
            },
          ),
        ),
        body: leaveRequests.isEmpty
            ? isLoading
            ? CircularProgressIndicator()
            : Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/images/no_data.jpg'),
                ]))
            : ListView.builder(
          itemCount: leaveRequests.length,
          itemBuilder: (context, index) {
            final request = leaveRequests[index];
            return Card(
              color: Colors.white,
              margin: EdgeInsets.all(8),
              child: ListTile(
                title: Text('${request.employeeName} (ID: ${request.employeeId})'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start Date: ${request.startDate}'),
                    Text('End Date: ${request.endDate}'),
                    Text('Leave Type: ${request.leaveType}'),
                    Text('Status: ${request.status}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (request.status == 'Pending')
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          updateLeaveStatus(request.id, 'Approved');
                        },
                      ),
                    if (request.status == 'Pending')
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          updateLeaveStatus(request.id, 'Rejected');
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


class LeaveRequest {
  final String id;
  final String employeeName;
  final String employeeId;
  final String startDate;
  final String endDate;
  final String leaveType;
  String status;

  LeaveRequest({
    required this.id,
    required this.employeeName,
    required this.employeeId,
    required this.startDate,
    required this.endDate,
    required this.leaveType,
    required this.status,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'],
      employeeName: json['employeeName'],
      employeeId: json['employeeId'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      leaveType: json['leaveType'],
      status: json['status'],
    );
  }
}
