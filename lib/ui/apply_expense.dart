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
  final TextEditingController _imageController = TextEditingController();
  List<String> expense_category = ["A", "B", "C"];

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  File? _imageFile;  // Store the selected image
  String? _selectedImagePath;

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

  Future<void> sendUserDataToDB(String imageUrl) async {
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
        "imageUrl": imageUrl,
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


  Future<String> uploadImageToFirebase() async {
    if (_imageFile != null) {
      // Create a reference to Firebase Storage
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child('expense_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      try {
        // Upload the image file
        await ref.putFile(_imageFile!);

        // Get the image URL
        String imageUrl = await ref.getDownloadURL();
        return imageUrl;
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
    } else {
      throw Exception("No image selected.");
    }
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

        String imageUrl = '';
        if (_imageFile != null) {
          imageUrl = await uploadImageToFirebase();
        }

        // Simulate a form submission with a delay (e.g., API call)
        await Future.delayed(Duration(seconds: 2));

        // Send data to DB
        await sendUserDataToDB(imageUrl);

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
          _imageFile = null; // Reset image selection
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

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageController.text = pickedFile.name;
        _selectedImagePath = pickedFile.path;
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
                      return 'Please enter your last day of expense';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'Expense Category',
                    suffixIcon: DropdownButton<String>(
                      items: expense_category.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                          onTap: () {
                            setState(() {
                              _categoryController.text = value;
                            });
                          },
                        );
                      }).toList(),
                      onChanged: (_) {},
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please provide a reason for your expense';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Expense Amount',
                    suffixIcon: Icon(Icons
                        .attach_money), // You can add a money icon or any relevant icon
                  ),
                  keyboardType: TextInputType
                      .number, // This ensures only numbers can be input
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please provide an amount for your expense';
                    }
                    // You can add additional validation to check if the input is a valid number
                    try {
                      double.parse(value);
                    } catch (e) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller:
                      _commentsController, // Use a controller for the comments text field
                  decoration: InputDecoration(
                    labelText: 'Comments', // Set the label to "Comments"
                    hintText:
                        'Enter your comments here', // Optional: Set a hint for the user
                    border:
                        OutlineInputBorder(), // Optional: Add a border around the text field
                  ),
                  maxLines:
                      3, // Allows the user to type multiple lines (can be adjusted based on your needs)
                  keyboardType:
                      TextInputType.text, // Text input type for general text
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please provide your comments';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _imageController,  // The controller for displaying the file name
                  decoration: InputDecoration(
                    labelText: 'Attach Image',  // Label for the image field
                    hintText:
                    'Click the icon to upload attachment',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: _pickImage,  // Trigger image picker when icon is pressed
                      icon: Icon(Icons.image),  // Display image icon
                    ),
                  ),
                  readOnly: true,  // Make the TextFormField read-only to prevent typing
                ),
                SizedBox(height: 16),
                if (_imageFile != null)
                  Image.file(_imageFile!, height: 150, width: 150),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : _submitForm, // Disable the button when loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white), // Color for the indicator
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
