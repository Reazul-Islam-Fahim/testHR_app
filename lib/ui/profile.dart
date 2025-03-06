import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:test_app/const/AppColors.dart';
import 'package:test_app/ui/bottom_nav_controller.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  TextEditingController? _phoneController;

  IconData _getGenderIcon(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return Icons.male; // Male icon
      case 'female':
        return Icons.female; // Female icon
      default:
        return Icons.transgender; // Default or other gender icon
    }
  }

  String? _imageUrl;
  String? _userName;
  String? _designation;
  bool _isLoading = false;
  bool _hasError = false;

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _hasError = false; // Reset error state
    });

    try {
      // Replace with your API URL to fetch user data
      final response =
          await http.get(Uri.parse('http://192.168.3.228:7000/get-user-data'));

      print('API Response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        // Parse the JSON response
        final data = json.decode(response.body);

        setState(() {
          _imageUrl = data['image'];
          _userName = data['name'];
          _designation = data['designation'];
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
      });
      print("Error fetching data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  setDataToTextField(data) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        children: [
          // Displaying Name (static text)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: ListTile(
              title: Text(
                "Name: ${data['name']}",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              leading: Icon(Icons.perm_identity),
            ),
          ),

          SizedBox(height: 10),

          // Displaying Employee ID (static text)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: ListTile(
              title: Text(
                "Employee ID: ${data['employee_id']}",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              leading: Icon(Icons.star),
            ),
          ),
          SizedBox(height: 10),

          // Displaying DOB (static text)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: ListTile(
              title: Text(
                "Date of Birth: ${data['dob']}",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              leading: Icon(Icons.date_range),
            ),
          ),
          SizedBox(height: 10),

          // Displaying Gender (static text)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: ListTile(
              title: Text(
                "Gender: ${data['gender']}",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              leading: Icon(
                _getGenderIcon(data['gender']) as IconData?,
              ),
            ),
          ),
          SizedBox(height: 10),
          // Editable Phone Number
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: ListTile(
              leading: Icon(Icons.phone), // Add a phone icon if desired
              title: Text(
                "Phone: ${data['phone']}",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  // Show the AlertDialog using showDialog
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Edit Phone No.'),
                        content: TextField(
                          controller: _phoneController,
                          decoration:
                              InputDecoration(hintText: 'Enter new phone no.'),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context)
                                  .pop(); // Close the dialog without returning any value
                            },
                          ),
                          TextButton(
                            child: Text('Update'),
                            onPressed: () {
                              // Close the dialog and pass the updated phone number
                              Navigator.of(context).pop(_phoneController!.text);
                            },
                          ),
                        ],
                      );
                    },
                  ).then((updatedPhone) {
                    // This block is executed after the dialog is dismissed
                    if (updatedPhone != null) {
                      // Call the updateData method with the updated phone number
                      updateData();
                    }
                  });
                },
              ),
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  updateData() {
    CollectionReference _collectionRef =
        FirebaseFirestore.instance.collection("users-form-data");
    return _collectionRef.doc(FirebaseAuth.instance.currentUser!.email).update({
      "phone": _phoneController!.text, // Update phone number
    }).then((value) => print("Updated Successfully"));
  }

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _fetchUserData();
  }

  // Dispose of the controller when the widget is disposed
  @override
  void dispose() {
    _phoneController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Center(child: Text('Profile')),
          backgroundColor: AppColors.blue,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              // Navigate to another page when the back arrow is pressed
              Navigator.pushReplacement(
                context,
                CupertinoPageRoute(
                    builder: (context) => BottomNavController(
                          initialIndex: 4,
                        )),
              );
            },
          ),
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: <Widget>[
                  Container(
                    height: MediaQuery.of(context).size.height / 3,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(150.0),
                        bottomRight: Radius.circular(150.0),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: _imageUrl != null
                              ? NetworkImage(
                                  _imageUrl!) // Use the image URL from the API
                              : AssetImage('assets/images/user1.jpg')
                                  as ImageProvider, // Placeholder image
                          child: _imageUrl == null && !_isLoading && !_hasError
                              ? Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 30,
                                )
                              : null,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: _isLoading
                              ? CircularProgressIndicator()
                              : _hasError
                                  ? Text("Error loading user data",
                                      style: TextStyle(color: Colors.red))
                                  : Center(
                                      child: Text(
                                        _userName ?? 'User Name',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        softWrap: true,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: _isLoading
                              ? CircularProgressIndicator()
                              : _hasError
                                  ? Text("Error loading user data",
                                      style: TextStyle(color: Colors.red))
                                  : Center(
                                      child: Text(
                                        _designation ?? 'Designation',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                        softWrap: true,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 50,
              ),
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("users-form-data")
                    .doc(FirebaseAuth.instance.currentUser!.email)
                    .snapshots(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  var data = snapshot.data;
                  if (data == null) {
                    return Center(child: CircularProgressIndicator());
                  }
                  return setDataToTextField(data);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
