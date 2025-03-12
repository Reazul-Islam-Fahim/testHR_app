import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:test_app/const/AppColors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:test_app/ui/bottom_nav_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class Expense_apply extends StatefulWidget {
  const Expense_apply({super.key});

  @override
  State<Expense_apply> createState() => _Expense_applyState();
}

class _Expense_applyState extends State<Expense_apply> {
  final TextEditingController _startdateController = TextEditingController();
  final TextEditingController _enddateController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  List<String> expense_category = ["A", "B", "C"];

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  List<File>? _imageFiles = [];  // Store multiple images

  // Validator for checking if End Date is later than Start Date
  String? _validateDateRange() {
    if (_startdateController.text.isNotEmpty &&
        _enddateController.text.isNotEmpty) {
      DateTime fromDate =
      DateFormat('dd/MM/yyyy').parse(_startdateController.text);
      DateTime toDate = DateFormat('dd/MM/yyyy').parse(_enddateController.text);

      if (toDate.isBefore(fromDate)) {
        return 'End date must be later than Start date';
      }
    }
    return null;
  }

  Future<void> sendUserDataToDB(List<String> imageUrls) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    var currentUser = _auth.currentUser;

    // Reference to the user's Expense_apply data document in Firestore
    CollectionReference userExpense_applyCollection = FirebaseFirestore.instance
        .collection("users-expense-data")
        .doc(currentUser!.email)
        .collection("expense-requests");

    // Create a new document with the user's email as the ID (don't use auto ID)
    try {
      await userExpense_applyCollection.doc().set({
        "Start Date": _startdateController.text,
        "End Date": _enddateController.text,
        "Category": _categoryController.text,
        "Amount": _amountController.text,
        "Comments": _commentsController.text,
        "submittedAt": FieldValue.serverTimestamp(),
        "status": "Pending",
        "imageUrls": imageUrls,  // Store the list of image URLs
      });

      // Optionally, show success message or toast
      Fluttertoast.showToast(
        msg: "Expense request submitted successfully!",
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

  Future<List<String>> uploadImagesToFirebase() async {
    List<String> imageUrls = [];

    if (_imageFiles != null && _imageFiles!.isNotEmpty) {
      FirebaseStorage storage = FirebaseStorage.instance;

      for (var file in _imageFiles!) {
        Reference ref = storage.ref().child('expense_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

        try {
          // Upload the image file
          await ref.putFile(file);

          // Get the image URL
          String imageUrl = await ref.getDownloadURL();
          imageUrls.add(imageUrl);  // Add the URL to the list
        } catch (e) {
          Fluttertoast.showToast(
            msg: "Image upload failed: $e",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          throw Exception("Image upload failed: $e");
        }
      }
    }

    return imageUrls;  // Return the list of URLs
  }

  void _submitForm() async {
    try {
      // Validate the form
      if (_formKey.currentState!.validate()) {
        // Form is valid, proceed with submission
        String fromDate = _startdateController.text;
        String toDate = _enddateController.text;
        String category = _categoryController.text;
        String amount = _amountController.text;
        String comments = _commentsController.text;

        debugPrint('Date: $fromDate');
        debugPrint('Date: $toDate');
        debugPrint('Category: $category');
        debugPrint('Amount: $amount');
        debugPrint('Comments: $comments');

        String? dateError = _validateDateRange(); // Validate date range
        if (dateError != null) {
          Fluttertoast.showToast(
            msg: dateError, // Show the validation message as toast
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          return; // Exit if there's an error in date range
        }

        setState(() {
          isLoading = true; // Set loading state
        });

        List<String> imageUrls = [];
        if (_imageFiles != null && _imageFiles!.isNotEmpty) {
          imageUrls = await uploadImagesToFirebase();  // Upload multiple images and get their URLs
        }

        // Simulate a form submission with a delay (e.g., API call)
        await Future.delayed(Duration(seconds: 2));

        // Send data to DB
        await sendUserDataToDB(imageUrls);

        setState(() {
          isLoading = false;
        });

        // Reset form fields
        _formKey.currentState!.reset();
        _startdateController.clear();
        _enddateController.clear();
        _categoryController.clear();
        _amountController.clear();
        _commentsController.clear();
        setState(() {
          _imageFiles = []; // Reset image selection
        });

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

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => BottomNavController(initialIndex: 1)),
        );
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

  Future<void> _pickImages() async {
    final ImagePicker _picker = ImagePicker();
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();  // Pick multiple images

    if (pickedFiles != null) {
      setState(() {
        _imageFiles = pickedFiles.map((pickedFile) => File(pickedFile.path)).toList();  // Store the selected images
      });
    }
  }

  Future<void> _selectStartDateFromPicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Set initial date to today's date
      firstDate: DateTime(
          DateTime.now().year - 1), // Allow user to pick a date 3 years before
      lastDate: DateTime(
          DateTime.now().year + 1), // Allow user to pick a date 3 years ahead
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
      initialDate: DateTime.now(), // Set initial date to today's date
      firstDate: DateTime(
          DateTime.now().year - 1), // Allow user to pick a date 3 years before
      lastDate: DateTime(
          DateTime.now().year + 1), // Allow user to pick a date 3 years ahead
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
          iconTheme: IconThemeData(
            color: Colors.white,  // Set the color of the leading icon to white
          ),
          title: Center(
            child: Text('Apply for Expense', style: TextStyle(color: Colors.white,),),
          ),
          backgroundColor: AppColors.blue,
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
                    labelText: 'Expense Start Date',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => _selectStartDateFromPicker(context),
                      icon: Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select the expense date';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _enddateController,
                  decoration: InputDecoration(
                    labelText: 'Expense End Date',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => _selectEndDateFromPicker(context),
                      icon: Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select the expense date';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: expense_category.first,
                  items: expense_category.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _categoryController.text = newValue!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Expense Category',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the amount';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _commentsController,
                  decoration: InputDecoration(
                    labelText: 'Comments',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please add some comments';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                // Image selection widget
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 70.0),
                  child: ElevatedButton(
                    onPressed: _pickImages,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('Select Images', style: TextStyle(color: Colors.white),),
                        SizedBox(width: 10,),
                        Icon(Icons.add_a_photo, color: Colors.white,)
                      ],
                    ),
                  ),
                ),
                if (_imageFiles != null && _imageFiles!.isNotEmpty)
                  Column(
                    children: _imageFiles!.map((file) {
                      return Image.file(file, height: 150, width: 150);
                    }).toList(),
                  ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Submit',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
