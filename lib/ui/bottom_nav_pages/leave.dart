import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../const/AppColors.dart';
import '../apply_leave.dart';
import '../bottom_nav_controller.dart';

class Leave extends StatefulWidget {
  const Leave({super.key});

  @override
  State<Leave> createState() => _LeaveState();
}

class _LeaveState extends State<Leave> {
  bool isLoading = true;
  List<Map<String, dynamic>> leaveData = [];
  List<String> leave_category = ["Medical", "Paid", "Maternity"];
  int _currentRowCount = 10;
  int _rowsPerPage = 10;
  bool _hasMoreData = true;

  Future<void> _fetchLeaveData() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    var currentUser = _auth.currentUser;

    try {
      CollectionReference leaveCollection = FirebaseFirestore.instance
          .collection("users-leave-data")
          .doc(currentUser!.email)
          .collection("leave-requests");

      QuerySnapshot querySnapshot =
          await leaveCollection
              .orderBy("submittedAt", descending: true)
              .limit(_currentRowCount)
              .get();

      _hasMoreData = querySnapshot.docs.length == _currentRowCount;

      leaveData.clear();

      querySnapshot.docs.forEach((doc) {
        Map<String, dynamic> leave = doc.data() as Map<String, dynamic>;
        leave['id'] = doc.id; // Save the document ID
        leaveData.add(leave);
      });

      await Future.delayed(Duration(seconds: 3));

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  // Function to update the leave data in Firestore
  Future<void> _updateLeaveData(
    String documentId,
    String field,
    String newValue,
  ) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    var currentUser = _auth.currentUser;

    try {
      CollectionReference leaveCollection = FirebaseFirestore.instance
          .collection("users-leave-data")
          .doc(currentUser!.email)
          .collection("leave-requests");

      await leaveCollection.doc(documentId).update({field: newValue});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Data updated successfully')));
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

      await leaveCollection.doc(documentId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Leave request deleted successfully')),
      );

      setState(() {
        leaveData.removeWhere((leave) => leave['id'] == documentId);
      });
    } catch (e) {
      debugPrint("Error deleting data: $e");
    }
  }

  void _showEditDialog(Map<String, dynamic> leave) async {
    TextEditingController startDateController = TextEditingController(
      text: leave['Start Date'],
    );
    TextEditingController endDateController = TextEditingController(
      text: leave['End Date'],
    );
    String reason = leave['Reason'];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Leave'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: startDateController,
                      decoration: InputDecoration(labelText: 'Start Date (DD/MM/YYYY)'),
                    ),
                    SizedBox(height: 15,),
                    TextField(
                      controller: endDateController,
                      decoration: InputDecoration(labelText: 'End Date (DD/MM/YYYY)'),
                    ),
                    SizedBox(height: 15,),
                    DropdownButton<String>(
                      value: reason,
                      items:
                          leave_category.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          reason = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 15),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    await _updateLeaveData(
                      leave['id'],
                      'Start Date',
                      startDateController.text,
                    );
                    await _updateLeaveData(
                      leave['id'],
                      'End Date',
                      endDateController.text,
                    );
                    await _updateLeaveData(leave['id'], 'Reason', reason);

                    Navigator.push(context, MaterialPageRoute(builder: (context)=> BottomNavController(initialIndex: 0,),),);
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchLeaveData();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text('Leave Report', style: TextStyle(color: Colors.white)),
          ),
          backgroundColor: AppColors.blue,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              leaveData.isEmpty
                  ? isLoading
                      ? Center(child: CircularProgressIndicator())
                      : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [Image.asset('assets/images/no_data.jpg')],
                        ),
                      )
                  : ListView.builder(
                    shrinkWrap: true,
                    itemCount: leaveData.length,
                    itemBuilder: (context, index) {
                      var leave = leaveData[index];
                      return Card(
                        color: Colors.white,
                        margin: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        child: ListTile(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Start Date: ${leave['Start Date'] ?? ''}'),
                              Text('End Date: ${leave['End Date'] ?? ''}'),
                              Text('Reason: ${leave['Reason'] ?? ''}'),
                              Text('Status: ${leave['status'] ?? 'Pending'}'),
                            ],
                          ),
                          trailing:
                              leave['status'] == 'Pending'
                                  ? IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      bool confirmDelete = await showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: Text('Delete Leave Request'),
                                            content: Text(
                                              'Are you sure you want to delete this leave request?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(
                                                    context,
                                                  ).pop(true);
                                                },
                                                child: Text('Yes'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(
                                                    context,
                                                  ).pop(false);
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
                                    },
                                  )
                                  : null,
                          onTap:
                              leave['status'] == 'Pending'
                                  ? () async {
                                    _showEditDialog(leave);
                                  }
                                  : null,
                        ),
                      );
                    },
                  ),
              if (_hasMoreData)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentRowCount += _rowsPerPage;
                    });
                    _fetchLeaveData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    minimumSize: Size(150, 40),
                  ),
                  child: Text(
                    'Load More',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => Leave_apply()),
                );
              },
              backgroundColor: AppColors.blue,
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
