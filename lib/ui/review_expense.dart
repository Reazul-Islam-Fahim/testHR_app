import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:test_app/ui/bottom_nav_controller.dart';
import '../const/AppColors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExpenseReview extends StatefulWidget {
  final Function() onStatusUpdated;

  const ExpenseReview({super.key, required this.onStatusUpdated});

  @override
  State<ExpenseReview> createState() => _ExpenseReviewState();
}

class _ExpenseReviewState extends State<ExpenseReview> {
  bool isLoading = true;
  List<ExpenseRequest> expenseRequests = [];

  @override
  void initState() {
    super.initState();
    fetchExpenseRequests();
  }

  Future<void> fetchExpenseRequests() async {
    // Replace with your API endpoint
    final response = await http
        .get(Uri.parse('http://192.168.3.228:3000/api/expense-requests'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        expenseRequests =
            data.map((item) => ExpenseRequest.fromJson(item)).toList();
        isLoading = false; // Set loading to false after data is fetched
      });
    } else {
      throw Exception('Failed to load expense requests');
    }
  }

  Future<void> updateExpenseStatus(String expenseId, String status) async {
    // Replace with your API endpoint
    final response = await http.post(
      Uri.parse('http://192.168.3.228:3000/api/update-expense-status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'expenseId': expenseId, 'status': status}),
    );

    if (response.statusCode == 200) {
      // Update the local state
      setState(() {
        expenseRequests.removeWhere((request) =>
            request.id == expenseId); // Remove the item from the list
      });
      widget.onStatusUpdated(); // Notify the parent page
    } else {
      throw Exception('Failed to update expense status');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingExpenseRequests = expenseRequests
        .where((request) => request.status == 'Pending')
        .toList();
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
                        )),
              );
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              if (isLoading)
                Center(child: CircularProgressIndicator())
              else if (pendingExpenseRequests.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/no_data.jpg'),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true, // Allow ListView to scroll inside Column
                  physics:
                      NeverScrollableScrollPhysics(), // Disable ListView scrolling
                  itemCount: pendingExpenseRequests.length,
                  itemBuilder: (context, index) {
                    final request = pendingExpenseRequests[index];
                    return Card(
                      color: Colors.white,
                      margin: EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(
                              '${request.category}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Start Date: ${request.startDate}'),
                                Text('End Date: ${request.endDate}'),
                                Text(
                                    'Amount: \৳${request.amount.toStringAsFixed(2)}'),
                                Text('Comments: ${request.comments}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check, color: Colors.green),
                                  onPressed: () {
                                    updateExpenseStatus(request.id, 'Approved');
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.red),
                                  onPressed: () {
                                    updateExpenseStatus(request.id, 'Rejected');
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (request.attachments.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Attachments:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ...request.attachments.map((link) {
                                    return GestureDetector(
                                      onTap: () {
                                        // Open the link in a browser or handle it as needed
                                        print('Opening link: $link');
                                      },
                                      child: Text(
                                        '- $link',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpenseRequest {
  final String id;
  final String startDate;
  final String endDate;
  final String category;
  final double amount;
  final String comments;
  final List<String> attachments; // Array of links
  String status; // Pending, Approved, Rejected

  ExpenseRequest({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.category,
    required this.amount,
    required this.comments,
    required this.attachments,
    required this.status,
  });

  factory ExpenseRequest.fromJson(Map<String, dynamic> json) {
    return ExpenseRequest(
      id: json['id'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      category: json['category'],
      amount: json['amount'],
      comments: json['comments'],
      attachments:
          List<String>.from(json['attachments']), // Parse array of links
      status: json['status'],
    );
  }
}
