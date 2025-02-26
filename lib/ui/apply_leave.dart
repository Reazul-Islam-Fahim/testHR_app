import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:test_app/const/AppColors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:test_app/ui/bottom_nav_controller.dart';

class Leave_apply extends StatefulWidget {
  const Leave_apply({super.key});

  @override
  State<Leave_apply> createState() => _Leave_applyState();
}

class _Leave_applyState extends State<Leave_apply> {
  final TextEditingController _startdateController = TextEditingController();
  final TextEditingController _enddateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  List<String> leave_category = ["Medical", "Paid", "Maternity"];

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  // Validator for checking if End Date is later than Start Date
  String? _validateDateRange() {
    if (_startdateController.text.isNotEmpty && _enddateController.text.isNotEmpty) {
      DateTime fromDate = DateFormat('dd/MM/yyyy').parse(_startdateController.text);
      DateTime toDate = DateFormat('dd/MM/yyyy').parse(_enddateController.text);

      if (toDate.isBefore(fromDate)) {
        return 'End date must be later than Start date';
      }
    }
    return null;
  }

  Future<void> sendUserDataToDB() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    var currentUser = _auth.currentUser;

    // Reference to the user's leave data document in Firestore
    CollectionReference userLeaveCollection = FirebaseFirestore.instance
        .collection("users-leave-data")
        .doc(currentUser!.email)
        .collection("leave-requests");

    // Create a new document with the user's email as the ID (don't use auto ID)
    try {
      await userLeaveCollection.doc().set({
        "Start Date": _startdateController.text,
        "End Date": _enddateController.text,
        "Reason": _reasonController.text,
        "submittedAt": FieldValue.serverTimestamp(),
        "status": "Pending",
      });

      // Optionally, show success message or toast
      Fluttertoast.showToast(
        msg: "Leave request submitted successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      // Handle any errors
      Fluttertoast.showToast(
        msg: "Submission failed: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      debugPrint('Error occurred during submission: $e');
    }
  }

  void _submitForm() async {
    try {
      // Validate the form
      if (_formKey.currentState!.validate()) {
        // Form is valid, proceed with submission
        String fromDate = _startdateController.text;
        String toDate = _enddateController.text;
        String reason = _reasonController.text;

        debugPrint('Date: $fromDate');
        debugPrint('Date: $toDate');
        debugPrint('Reason: $reason');

        String? dateError = _validateDateRange();  // Validate date range
        if (dateError != null) {
          Fluttertoast.showToast(
            msg: dateError,  // Show the validation message as toast
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          return;  // Exit if there's an error in date range
        }

        setState(() {
          isLoading = true; // Set loading state
        });

        // Simulate a form submission with a delay (e.g., API call)
        await Future.delayed(Duration(seconds: 2));

        // Send data to DB
        await sendUserDataToDB();

        // Show a success toast if submission is successful
        Fluttertoast.showToast(
          msg: "Submission Successful!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        // Reset the form fields to refresh the page
        setState(() {
          _formKey.currentState!.reset();
          _startdateController.clear();
          _enddateController.clear();
          _reasonController.clear();
        });
      }
    } catch (e) {
      // Catch any errors that occur during form submission
      debugPrint('Error occurred during submission: $e');

      // Show a toast with an error message
      Fluttertoast.showToast(
        msg: "Submission Failed: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => BottomNavController(initialIndex: 0)),
    );
  }

  Future<void> _selectStartDateFromPicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),  // Set initial date to today's date
      firstDate: DateTime(DateTime.now().year - 3),  // Allow user to pick a date 3 years before
      lastDate: DateTime(DateTime.now().year + 3),  // Allow user to pick a date 3 years ahead
    );
    if (picked != null) {
      setState(() {
        // Format the selected date using the intl package
        DateFormat dateFormat = DateFormat('dd/MM/yyyy');
        _startdateController.text = dateFormat.format(picked);
      });
    }
  }

  Future<void> _selectEndDateFromPicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),  // Set initial date to today's date
      firstDate: DateTime(DateTime.now().year - 3),  // Allow user to pick a date 3 years before
      lastDate: DateTime(DateTime.now().year + 3),  // Allow user to pick a date 3 years ahead
    );
    if (picked != null) {
      setState(() {
        // Format the selected date using the intl package
        DateFormat dateFormat = DateFormat('dd/MM/yyyy');
        _enddateController.text = dateFormat.format(picked);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text('Apply for leave'),
          ),
          backgroundColor: AppColors.deep_orange,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _startdateController,
                  decoration: InputDecoration(
                    labelText: 'Leave Start Date',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => _selectStartDateFromPicker(context),
                      icon: Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select the leave date';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _enddateController,
                  decoration: InputDecoration(
                    labelText: 'Leave End Date',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => _selectEndDateFromPicker(context),
                      icon: Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last day of leave';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: 'Leave Category',
                    suffixIcon: DropdownButton<String>(
                      items: leave_category.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                          onTap: () {
                            setState(() {
                              _reasonController.text = value;
                            });
                          },
                        );
                      }).toList(),
                      onChanged: (_) {},
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please provide a reason for your leave';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : _submitForm, // Disable the button when loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deep_orange,
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Color for the indicator
                  )
                      : Text(
                    'Submit',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
