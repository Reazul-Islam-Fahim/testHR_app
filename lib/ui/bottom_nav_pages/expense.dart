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
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ExpenseData.isEmpty
                  ? isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Center(child: Text('No data'))
                  : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(), // Disable ListView's scrolling
                itemCount: ExpenseData.length,
                itemBuilder: (context, index) {
                  final expense = ExpenseData[index];
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5), // Add horizontal margin
                    decoration: BoxDecoration(
                      color: Colors.white, // White background
                      borderRadius: BorderRadius.circular(10), // Radial border
                      boxShadow: [ // Add a subtle shadow for elevation
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text('Category: ${expense['Category'] ?? ''}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Start Date: ${expense['Start Date'] ?? ''}'),
                          Text('End Date: ${expense['End Date'] ?? ''}'),
                          Text('Amount: ${expense['Amount'] ?? ''}'),
                          Text('Status: ${expense['status'] ?? 'Pending'}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          expense['status'] == 'Pending'
                              ? Icons.delete
                              : Icons.check_circle_outline,
                          color: expense['status'] == 'Pending'
                              ? Colors.red
                              : Colors.green,
                        ),
                        onPressed: expense['status'] == 'Pending'
                            ? () async {
                          bool confirmDelete = await showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Delete Expense Request'),
                                content: Text(
                                    'Are you sure you want to delete this Expense request?'),
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
                            await _deleteExpenseData(expense['id']);
                          }
                        }
                            : null,
                      ),
                      onTap: expense['status'] == 'Pending'
                          ? () {
                        _showEditDialog(expense); // Function to handle edit dialog
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
                    _fetchExpenseData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    minimumSize: Size(150, 40),
                  ),
                  child: Text(
                    'Load More',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
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
                  CupertinoPageRoute(builder: (context) => Expense_apply()),
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

  void _showEditDialog(Map<String, dynamic> expense) async {
    // Implement your edit dialog logic here
    // Use showDialog to display a dialog with text fields for editing
    // and call _updateExpenseData with the updated values.
    // Example:
    TextEditingController startDateController = TextEditingController(text: expense['Start Date']);
    TextEditingController endDateController = TextEditingController(text: expense['End Date']);
    TextEditingController amountController = TextEditingController(text: expense['Amount']);
    String category = expense['Category'];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Expense'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: startDateController, decoration: InputDecoration(labelText: 'Start Date')),
                    TextField(controller: endDateController, decoration: InputDecoration(labelText: 'End Date')),
                    TextField(controller: amountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Amount')),
                    DropdownButton<String>(
                      value: category,
                      items: Expense_category.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          category = newValue!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel')),
                TextButton(
                  onPressed: () async {
                    await _updateExpenseData(expense['id'], 'Start Date', startDateController.text);
                    await _updateExpenseData(expense['id'], 'End Date', endDateController.text);
                    await _updateExpenseData(expense['id'], 'Amount', amountController.text);
                    await _updateExpenseData(expense['id'], 'Category', category);
                    Navigator.of(context).pop();
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
}
