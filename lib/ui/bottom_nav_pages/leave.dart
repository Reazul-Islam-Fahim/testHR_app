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

  Future<void> _fetchLeaveData() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    var currentUser = _auth.currentUser;

    try {
      CollectionReference leaveCollection = FirebaseFirestore.instance
          .collection("users-leave-data")
          .doc(currentUser!.email)
          .collection("leave-requests");

      QuerySnapshot querySnapshot = await leaveCollection.get();
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Align content to the top
          children: [
            FittedBox(
              fit: BoxFit.contain,
              child: leaveData.isEmpty
                  ? CircularProgressIndicator()
                  : DataTable(
                headingRowHeight: 100,
                columns: const [
                  DataColumn(label: Text('From Date')),
                  DataColumn(label: Text('To Date')),
                  DataColumn(label: Text('Reason')),
                  DataColumn(label: Text('Status')),
                ],
                rows: leaveData.map((leave) {
                  return DataRow(cells: [
                    DataCell(Text(leave['From date'] ?? ''), onTap: () async {
                      TextEditingController controller =
                      TextEditingController(text: leave['From date']);
                      String newFromDate = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Edit From Date'),
                            content: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                  hintText: 'Enter new date'),
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
                                  Navigator.of(context)
                                      .pop(controller.text);
                                },
                              ),
                            ],
                          );
                        },
                      ) ??
                          '';

                      if (newFromDate.isNotEmpty) {
                        setState(() {
                          leave['From date'] = newFromDate;
                        });
                        // Update the Firestore data
                        await _updateLeaveData(
                            leave['id'], 'From date', newFromDate);
                      }
                    }),
                    DataCell(Text(leave['To date'] ?? ''), onTap: () async {
                      TextEditingController controller =
                      TextEditingController(text: leave['To date']);
                      String newToDate = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Edit To Date'),
                            content: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                  hintText: 'Enter new date'),
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
                                  Navigator.of(context)
                                      .pop(controller.text);
                                },
                              ),
                            ],
                          );
                        },
                      ) ??
                          '';

                      if (newToDate.isNotEmpty) {
                        setState(() {
                          leave['To date'] = newToDate;
                        });
                        // Update the Firestore data
                        await _updateLeaveData(
                            leave['id'], 'To date', newToDate);
                      }
                    }),
                    DataCell(Text(leave['Reason'] ?? ''), onTap: () async {
                      TextEditingController controller =
                      TextEditingController(text: leave['Reason']);
                      String newReason = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Edit Reason'),
                            content: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                  hintText: 'Enter new reason'),
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
                                  Navigator.of(context)
                                      .pop(controller.text);
                                },
                              ),
                            ],
                          );
                        },
                      ) ??
                          '';

                      if (newReason.isNotEmpty) {
                        setState(() {
                          leave['Reason'] = newReason;
                        });
                        // Update the Firestore data
                        await _updateLeaveData(
                            leave['id'], 'Reason', newReason);
                      }
                    }),
                    DataCell(Text('Pending')),
                  ]);
                }).toList(),
              ),
            ),
          ],
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
