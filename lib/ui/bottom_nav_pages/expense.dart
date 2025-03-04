import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../const/AppColors.dart';
import '../apply_Expense.dart';

class Expense extends StatefulWidget {
  const Expense({super.key});

  @override
  State<Expense> createState() => _ExpenseState();
}

class _ExpenseState extends State<Expense> {

  bool isLoading = true;
  bool _isDisposed = false;

  List<Map<String, dynamic>> ExpenseData = [];
  List<String> Expense_category = ["A", "B", "C"];

  int _currentRowCount = 10; // Initial rows to show
  int _rowsPerPage = 10; // Rows to load on each "Load More" click
  bool _hasMoreData = true; // Flag to check if there is more data to load


  Future<void> _fetchExpenseData() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    var currentUser = _auth.currentUser;

    try {
      CollectionReference ExpenseCollection = FirebaseFirestore.instance
          .collection("users-expense-data")
          .doc(currentUser!.email)
          .collection("expense-requests");

      QuerySnapshot querySnapshot = await ExpenseCollection
          .orderBy("submittedAt", descending: true)
          .limit(_currentRowCount)
          .get();

      _hasMoreData = querySnapshot.docs.length == _currentRowCount;

      ExpenseData.clear();

      querySnapshot.docs.forEach((doc) {
        // Include the document ID as part of the data
        Map<String, dynamic> Expense = doc.data() as Map<String, dynamic>;
        Expense['id'] = doc.id; // Save the document ID
        ExpenseData.add(Expense);
      });

      await Future.delayed(Duration(seconds: 3));

      if (_isDisposed) return;
      // Check if the widget is still mounted before calling setState
      setState(() {
        isLoading = false;
      });

    } catch (e) {
      print("Error fetching data: $e");
    }
  }


  // Function to update the Expense data in Firestore
  Future<void> _updateExpenseData(
      String documentId, String field, String newValue) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    var currentUser = _auth.currentUser;

    try {
      CollectionReference ExpenseCollection = FirebaseFirestore.instance
          .collection("users-expense-data")
          .doc(currentUser!.email)
          .collection("expense-requests");

      // Update the specific field in the Firestore document
      await ExpenseCollection.doc(documentId).update({field: newValue});

      // Show a success toast or dialog
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Data updated successfully')));
    } catch (e) {
      debugPrint("Error updating data: $e");
    }
  }


  // Function to delete the Expense data from Firestore
  Future<void> _deleteExpenseData(String documentId) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    var currentUser = _auth.currentUser;

    try {
      CollectionReference ExpenseCollection = FirebaseFirestore.instance
          .collection("users-expense-data")
          .doc(currentUser!.email)
          .collection("expense-requests");

      // Delete the Firestore document
      await ExpenseCollection.doc(documentId).delete();

      // Show a success toast or dialog
      ScaffoldMessenger.of(context)
          .showSnackBar(
          SnackBar(content: Text('Expense request deleted successfully')));

      // Remove the deleted Expense from the local list and refresh the UI
      setState(() {
        ExpenseData.removeWhere((Expense) => Expense['id'] == documentId);
      });
    } catch (e) {
      debugPrint("Error deleting data: $e");
    }
  }



  @override
  void initState() {
    super.initState();
    _fetchExpenseData(); // Fetch data when the widget is initialized
  }


  @override
  void dispose() {
    _isDisposed = true;  // Mark the widget as disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text(
              'Expense Report',
            ),
          ),
          backgroundColor: AppColors.blue,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // Align content to the top
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: ExpenseData.isEmpty
                    ? isLoading
                    ? CircularProgressIndicator()
                    : Center(child: Text('No data'))
                    : DataTable(
                  headingRowHeight: 100,
                  columns: const [
                    DataColumn(label: Text('Start Date')),
                    DataColumn(label: Text('End Date')),
                    DataColumn(label: Text('Category')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')), // Add actions column
                  ],
                  rows: ExpenseData.map((Expense) {
                    return DataRow(cells: [
                      DataCell(
                        Text(Expense['Start Date'] ?? ''),
                        onTap: Expense['status'] == 'Pending' ? () async {
                          TextEditingController controller = TextEditingController(text: Expense['Start Date']);
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
                              Expense['Start Date'] = newFromDate;
                            });
                            await _updateExpenseData(Expense['id'], 'Start Date', newFromDate);
                          }
                        } : null, // Only allow editing if status is 'Pending'
                      ),
                      DataCell(
                        Text(Expense['End Date'] ?? ''),
                        onTap: Expense['status'] == 'Pending' ? () async {
                          TextEditingController controller = TextEditingController(text: Expense['End Date']);
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
                              Expense['End Date'] = newToDate;
                            });
                            await _updateExpenseData(Expense['id'], 'End Date', newToDate);
                          }
                        } : null, // Only allow editing if status is 'Pending'
                      ),
                      DataCell(
                        Text(Expense['Category'] ?? ''),
                        onTap: Expense['status'] == 'Pending'
                            ? () async {
                          TextEditingController controller =
                          TextEditingController(
                              text: Expense['Category']);
                          await showDialog<String>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Edit Expense Category'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    DropdownButton<String>(
                                      value: Expense['Category'] != null && Expense_category.contains(Expense['Category'])
                                          ? Expense['Category']
                                          : Expense_category[0], // Fallback to the first category if invalid
                                      items: Expense_category
                                          .map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          Expense['Category'] = newValue!;
                                        });
                                        _updateExpenseData(Expense['id'], 'Category', newValue!);
                                        Navigator.of(context).pop();  // Removed 'controller.text' which was incorrect
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
                      DataCell(
                        Text(Expense['Amount'] ?? ''), // Display the current Amount instead of Category
                        onTap: Expense['status'] == 'Pending'
                            ? () async {
                          TextEditingController controller = TextEditingController(
                              text: Expense['Amount']); // Treat 'Amount' as a number, using controller
                          await showDialog<String>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Edit Expense Amount'), // Change the title to reflect Amount
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: controller,
                                      keyboardType: TextInputType.numberWithOptions(decimal: true), // Allow numeric and decimal input
                                      decoration: InputDecoration(
                                        labelText: 'Amount', // Label the field as Amount
                                        hintText: 'Enter the amount', // Optional hint text
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          // Update value in Expense as amount
                                          Expense['Amount'] = value; // Store the new value in Amount
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(); // Close the dialog without saving
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Update the amount (Amount) in Firestore or wherever you want
                                      if (controller.text.isNotEmpty) {
                                        _updateExpenseData(Expense['id'], 'Amount', controller.text);
                                      }
                                      Navigator.of(context).pop(); // Close the dialog and save the value
                                    },
                                    child: Text('Update'),
                                  ),
                                ],
                              );
                            },
                          ) ?? '';
                        }
                            : null, // Only allow editing if status is 'Pending'
                      ),

                      DataCell(Text(Expense['status'] ?? 'Pending')), // Status should not be editable
                      DataCell(IconButton(
                        icon: Icon(
                          Expense['status'] == 'Pending' ?
                          Icons.delete : Icons.check_circle_outline,
                          color: Expense['status'] == 'Pending' ?
                          Colors.red : Colors.green,),
                        onPressed: Expense['status'] == 'Pending' ? () async {
                          bool confirmDelete = await showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Delete Expense Request'),
                                content: Text('Are you sure you want to delete this Expense request?'),
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
                            await _deleteExpenseData(Expense['id']);
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
                    _fetchExpenseData(); // Fetch the next set of rows
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    minimumSize: Size(150, 40),
                  ),
                  child: Text('Load More', style: TextStyle(color: Colors.white, fontSize: 10, ),),
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
                  CupertinoPageRoute(builder: (context) => Expense_apply()),
                );
              },
              backgroundColor: AppColors.blue, // Add color to the button
              child: Icon(Icons.add, color: Colors.white), // Add a plus icon
            ),
          ),
        ),
      ),
    );
  }
}
