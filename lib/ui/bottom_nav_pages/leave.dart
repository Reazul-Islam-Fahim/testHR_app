import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../const/AppColors.dart';
import '../apply_leave.dart';

class Leave extends StatefulWidget {
  const Leave({super.key});

  @override
  State<Leave> createState() => _LeaveState();
}

class _LeaveState extends State<Leave> {
  List<Map<String, dynamic>> leaveData = [];
  List<String> leave_category = ["Medical", "Paid", "Maternity"];

  int _currentRowCount = 10; // Initial rows to show
  int _rowsPerPage = 10; // Rows to load on each "Load More" click
  bool _hasMoreData = true; // Flag to check if there is more data to load


  Future<void> _fetchLeaveData() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    var currentUser = _auth.currentUser;

    try {
      CollectionReference leaveCollection = FirebaseFirestore.instance
          .collection("users-leave-data")
          .doc(currentUser!.email)
          .collection("leave-requests");

      QuerySnapshot querySnapshot = await leaveCollection
          .orderBy("submittedAt", descending: true)
          .limit(_currentRowCount)
          .get();

      _hasMoreData = querySnapshot.docs.length == _currentRowCount;

      leaveData.clear();

      querySnapshot.docs.forEach((doc) {
        // Include the document ID as part of the data
        Map<String, dynamic> leave = doc.data() as Map<String, dynamic>;
        leave['id'] = doc.id; // Save the document ID
        leaveData.add(leave);
      });

      setState(() {});
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  // Function to update the leave data in Firestore
  Future<void> _updateLeaveData(
      String documentId, String field, String newValue) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    var currentUser = _auth.currentUser;

    try {
      CollectionReference leaveCollection = FirebaseFirestore.instance
          .collection("users-leave-data")
          .doc(currentUser!.email)
          .collection("leave-requests");

      // Update the specific field in the Firestore document
      await leaveCollection.doc(documentId).update({field: newValue});

      // Show a success toast or dialog
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Data updated successfully')));
    } catch (e) {
      debugPrint("Error updating data: $e");
    }
  }


  // Function to delete the leave data from Firestore
  Future<void> _deleteLeaveData(String documentId) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    var currentUser = _auth.currentUser;

    try {
      CollectionReference leaveCollection = FirebaseFirestore.instance
          .collection("users-leave-data")
          .doc(currentUser!.email)
          .collection("leave-requests");

      // Delete the Firestore document
      await leaveCollection.doc(documentId).delete();

      // Show a success toast or dialog
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Leave request deleted successfully')));

      // Remove the deleted leave from the local list and refresh the UI
      setState(() {
        leaveData.removeWhere((leave) => leave['id'] == documentId);
      });
    } catch (e) {
      debugPrint("Error deleting data: $e");
    }
  }



  @override
  void initState() {
    super.initState();
    _fetchLeaveData(); // Fetch data when the widget is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Leave Report',
          ),
        ),
        backgroundColor: AppColors.deep_orange,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // Align content to the top
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: leaveData.isEmpty
                    ? CircularProgressIndicator()
                    : DataTable(
                  headingRowHeight: 100,
                  columns: const [
                    DataColumn(label: Text('Start Date')),
                    DataColumn(label: Text('End Date')),
                    DataColumn(label: Text('Reason')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')), // Add actions column
                  ],
                  rows: leaveData.map((leave) {
                    return DataRow(cells: [
                      DataCell(
                        Text(leave['Start date'] ?? ''),
                        onTap: leave['status'] == 'Pending' ? () async {
                          TextEditingController controller = TextEditingController(text: leave['Start Date']);
                          String newFromDate = await showDialog<String>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Edit Start Date (DD/MM/YYYY)'),
                                content: TextField(
                                  controller: controller,
                                  decoration: InputDecoration(hintText: 'Enter new date'),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text('Cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: Text('Update'),
                                    onPressed: () {
                                      Navigator.of(context).pop(controller.text);
                                    },
                                  ),
                                ],
                              );
                            },
                          ) ?? '';

                          if (newFromDate.isNotEmpty) {
                            setState(() {
                              leave['Start Date'] = newFromDate;
                            });
                            await _updateLeaveData(leave['id'], 'Start Date', newFromDate);
                          }
                        } : null, // Only allow editing if status is 'Pending'
                      ),
                      DataCell(
                        Text(leave['End date'] ?? ''),
                        onTap: leave['status'] == 'Pending' ? () async {
                          TextEditingController controller = TextEditingController(text: leave['End Date']);
                          String newToDate = await showDialog<String>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Edit End Date (DD/MM/YYYY)'),
                                content: TextField(
                                  controller: controller,
                                  decoration: InputDecoration(hintText: 'Enter new date'),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text('Cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: Text('Update'),
                                    onPressed: () {
                                      Navigator.of(context).pop(controller.text);
                                    },
                                  ),
                                ],
                              );
                            },
                          ) ?? '';

                          if (newToDate.isNotEmpty) {
                            setState(() {
                              leave['End Date'] = newToDate;
                            });
                            await _updateLeaveData(leave['id'], 'End Date', newToDate);
                          }
                        } : null, // Only allow editing if status is 'Pending'
                      ),
                      DataCell(
                        Text(leave['Reason'] ?? ''),
                        onTap: leave['status'] == 'Pending'
                            ? () async {
                          TextEditingController controller =
                          TextEditingController(
                              text: leave['Reason']);
                              await showDialog<String>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('Edit Leave Category'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        DropdownButton<String>(
                                          value: leave['Reason'] ?? leave_category[0],
                                          items: leave_category
                                              .map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          }).toList(),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              leave['Reason'] = newValue!;
                                            });
                                            _updateLeaveData(leave['id'], 'Reason', newValue!);
                                            Navigator.of(context).pop(
                                                controller.text);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ) ??
                                  '';
                        }
                            : null, // Only allow editing if status is 'Pending'
                      ),
                      DataCell(Text(leave['status'] ?? 'Pending')), // Status should not be editable
                      DataCell(IconButton(
                        icon: Icon(
                          leave['status'] == 'Pending' ?
                          Icons.delete : Icons.check_circle_outline,
                          color: leave['status'] == 'Pending' ?
                          Colors.red : Colors.green,),
                        onPressed: leave['status'] == 'Pending' ? () async {
                          bool confirmDelete = await showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Delete Leave Request'),
                                content: Text('Are you sure you want to delete this leave request?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                    child: Text('Yes'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                    child: Text('No'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmDelete) {
                            await _deleteLeaveData(leave['id']);
                          }
                        } : null, // Only allow delete if status is 'Pending'
                      )),
                    ]);
                  }).toList(),
                ),),
                  if(_hasMoreData)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentRowCount += _rowsPerPage; // Increase the number of rows to show
                  });
                  _fetchLeaveData(); // Fetch the next set of rows
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deep_orange,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  minimumSize: Size(150, 40),
                ),
                child: Text('Load More', style: TextStyle(color: Colors.white, fontSize: 10, ),),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Align(
          alignment: Alignment.bottomRight, // Align the button to the bottom-right
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (context) => Leave_apply()),
              );
            },
            backgroundColor: AppColors.deep_orange, // Add color to the button
            child: Icon(Icons.add), // Add a plus icon
          ),
        ),
      ),
    );
  }
}
