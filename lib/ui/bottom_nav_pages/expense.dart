import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart'; // For efficient image loading
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase storage
import 'dart:io';
import '../../const/AppColors.dart';
import '../apply_Expense.dart';
import '../bottom_nav_controller.dart';

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

  int _currentRowCount = 10;
  int _rowsPerPage = 10;
  bool _hasMoreData = true;

  List<File> _pickedImages = [];

  // Picked images for the expense
  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _pickedImages = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  // Upload images to Firebase Storage
  Future<List<String>> _uploadImages() async {
    FirebaseStorage storage = FirebaseStorage.instance;
    List<String> imageUrls = [];

    for (var image in _pickedImages) {
      try {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference storageRef = storage.ref().child('expense_images/$fileName');
        UploadTask uploadTask = storageRef.putFile(image);
        TaskSnapshot snapshot = await uploadTask;

        String imageUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(imageUrl);
      } catch (e) {
        print("Error uploading image: $e");
      }
    }

    return imageUrls;
  }

  Future<void> _fetchExpenseData() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    var currentUser = _auth.currentUser;

    try {
      CollectionReference ExpenseCollection = FirebaseFirestore.instance
          .collection("users-expense-data")
          .doc(currentUser!.email)
          .collection("expense-requests");

      QuerySnapshot querySnapshot =
      await ExpenseCollection.orderBy("submittedAt", descending: true)
          .limit(_currentRowCount)
          .get();

      _hasMoreData = querySnapshot.docs.length == _currentRowCount;

      ExpenseData.clear();

      querySnapshot.docs.forEach((doc) {
        Map<String, dynamic> Expense = doc.data() as Map<String, dynamic>;
        Expense['id'] = doc.id;
        ExpenseData.add(Expense);
      });

      await Future.delayed(Duration(seconds: 3));

      if (_isDisposed) return;
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  Future<void> _updateExpenseData(
      String documentId, String field, String newValue) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    var currentUser = _auth.currentUser;

    try {
      CollectionReference ExpenseCollection = FirebaseFirestore.instance
          .collection("users-expense-data")
          .doc(currentUser!.email)
          .collection("expense-requests");

      await ExpenseCollection.doc(documentId).update({field: newValue});
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Data updated successfully')));
    } catch (e) {
      debugPrint("Error updating data: $e");
    }
  }

  Future<void> _deleteExpenseData(String documentId) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    var currentUser = _auth.currentUser;

    try {
      CollectionReference ExpenseCollection = FirebaseFirestore.instance
          .collection("users-expense-data")
          .doc(currentUser!.email)
          .collection("expense-requests");

      await ExpenseCollection.doc(documentId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expense request deleted successfully')));

      setState(() {
        ExpenseData.removeWhere((Expense) => Expense['id'] == documentId);
      });
    } catch (e) {
      debugPrint("Error deleting data: $e");
    }
  }

  void _showEditDialog(Map<String, dynamic> expense) async {
    TextEditingController startDateController =
    TextEditingController(text: expense['Start Date']);
    TextEditingController endDateController =
    TextEditingController(text: expense['End Date']);
    TextEditingController amountController =
    TextEditingController(text: expense['Amount']);
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
                    TextField(
                        controller: startDateController,
                        decoration: InputDecoration(labelText: 'Start Date (DD/MM/YYYY)')),
                    TextField(
                        controller: endDateController,
                        decoration: InputDecoration(labelText: 'End Date (DD/MM/YYYY)')),
                    TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Amount')),
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
                    SizedBox(height: 10),
                    Text('Selected Images:'),
                    _pickedImages.isEmpty
                        ? Text('No images selected')
                        : Wrap(
                      spacing: 10,
                      children: _pickedImages
                          .map((image) => Image.file(image, width: 50, height: 50))
                          .toList(),
                    ),
                    TextButton(
                      onPressed: _pickImages,
                      child: Text('Pick Images'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel')),
                TextButton(
                  onPressed: () async {
                    await _updateExpenseData(
                        expense['id'], 'Start Date', startDateController.text);
                    await _updateExpenseData(
                        expense['id'], 'End Date', endDateController.text);
                    await _updateExpenseData(
                        expense['id'], 'Amount', amountController.text);
                    await _updateExpenseData(
                        expense['id'], 'Category', category);

                    if (_pickedImages.isNotEmpty) {
                      List<String> imageUrls = await _uploadImages();
                      await _updateExpenseData(
                          expense['id'], 'imageUrls', imageUrls as String);
                    }

                    Navigator.push(context, MaterialPageRoute(builder: (context)=> BottomNavController(initialIndex: 1,),),);
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
    _fetchExpenseData();
  }

  @override
  void dispose() {
    _isDisposed = true;
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
              style: TextStyle(color: Colors.white),
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
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/no_data.jpg'),
                  ],
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: ExpenseData.length,
                itemBuilder: (context, index) {
                  final expense = ExpenseData[index];
                  return Container(
                    margin: EdgeInsets.symmetric(
                        horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
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
                          if (expense['imageUrls'] != null &&
                              expense['imageUrls'] is List &&
                              expense['imageUrls'].isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text('View Attachments'),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            for (var imageUrl in expense['imageUrls'])
                                              CachedNetworkImage(
                                                imageUrl: imageUrl,
                                                placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                                                errorWidget: (context, url, error) => Icon(Icons.error),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Text(
                                'View Attachments',
                                style: TextStyle(
                                  color: AppColors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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
                          ? () async {
                        _showEditDialog(expense);
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
}
