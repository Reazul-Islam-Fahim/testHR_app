import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:test_app/const/AppColors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_app/ui/bottom_nav_pages/leave.dart';

class Leave_apply extends StatefulWidget {
  const Leave_apply({super.key});

  @override
  State<Leave_apply> createState() => _Leave_applyState();
}

class _Leave_applyState extends State<Leave_apply> {
  final TextEditingController _fromdateController = TextEditingController();
  final TextEditingController _todateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // Submit method to handle form submission
  void _submitForm() async {
    try {
      // Validate the form
      if (_formKey.currentState!.validate()) {
        // Form is valid, proceed with submission
        String fromDate = _fromdateController.text;
        String toDate = _todateController.text;
        String reason = _reasonController.text;

        debugPrint('Date: $fromDate');
        debugPrint('Date: $toDate');
        debugPrint('Reason: $reason');

        // Simulate a form submission with a delay (e.g., API call)
        await Future.delayed(Duration(seconds: 2));

        // Send data to DB
        await sendUserDataToDB();
        Navigator.push(context, CupertinoPageRoute(builder: (context) => Leave()),);

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
          _fromdateController.clear();
          _todateController.clear();
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
  }

  Future<void> _selectFromDateFromPicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(DateTime.now().year),
      firstDate: DateTime(DateTime.now().year - 3),
      lastDate: DateTime(DateTime.now().year + 3),
    );
    if (picked != null) {
      setState(() {
        _fromdateController.text =
        "${picked.day}/ ${picked.month}/ ${picked.year}";
      });
    }
  }

  Future<void> _selectToDateFromPicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(DateTime.now().year),
      firstDate: DateTime(DateTime.now().year - 30),
      lastDate: DateTime(DateTime.now().year + 30),
    );
    if (picked != null) {
      setState(() {
        _todateController.text =
        "${picked.day}/ ${picked.month}/ ${picked.year}";
      });
    }
  }

  Future<void> sendUserDataToDB() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    var currentUser = _auth.currentUser;

    // Reference to the user's leave data document in Firestore
    CollectionReference userLeaveCollection = FirebaseFirestore.instance
        .collection("users-leave-data")
        .doc(currentUser!.email)
        .collection("leave-requests"); // Subcollection for leave requests

    // Create a new document with the user's email as the ID (don't use auto ID)
    try {
      await userLeaveCollection.doc().set({
        "From date": _fromdateController.text,
        "To date": _todateController.text,
        "Reason": _reasonController.text,
        "submittedAt": FieldValue.serverTimestamp(), // Add timestamp for submission
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Center(
              child: Text(
                'Apply for leave',
              ),
            ),
          ),
          backgroundColor: AppColors.deep_orange,
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _fromdateController,
                  decoration: InputDecoration(
                    labelText: 'Leave Start Date',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => _selectFromDateFromPicker(context),
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
                  controller: _todateController,
                  decoration: InputDecoration(
                    labelText: 'Leave End Date',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => _selectToDateFromPicker(context),
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
                    labelText: 'Reason for Leave',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please provide a reason for your leave';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                // Submit button
                ElevatedButton(
                  onPressed: _submitForm, // Call the submit method
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deep_orange,
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                  child: Text(
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
