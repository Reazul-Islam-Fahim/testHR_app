import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:test_app/ui/profile.dart';
import 'package:test_app/ui/review_attendance.dart';
import 'package:test_app/ui/review_leave.dart';
import 'dart:convert';
import '../../const/AppColors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../change_pass.dart';
import '../login_screen.dart';
import '../review_expense.dart';

class More extends StatefulWidget {
  const More({super.key});

  @override
  State<More> createState() => _MoreState();
}

class _MoreState extends State<More> {
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

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      if (context.mounted) {
        //check if context is valid.
        await Navigator.pushReplacement(
          //added await.
          context,
          CupertinoPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      //more specific error handling.
      print('Firebase Auth Error signing out: ${e.code} - ${e.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to sign out: ${e.message}'),
        ));
      }
    } catch (e) {
      print('Error signing out: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to sign out. Please try again.'),
        ));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
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
                          bottomLeft:
                              Radius.circular(90.0), // Curved bottom left
                          bottomRight:
                              Radius.circular(0.0), // Curved bottom right
                        ),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      child: Column(children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: _imageUrl != null
                              ? NetworkImage(
                                  _imageUrl!) // Use the image URL from the API
                              : AssetImage('assets/images/user1.jpg')
                                  as ImageProvider, // Placeholder image
                          child: _imageUrl == null &&
                                  !_isLoading &&
                                  !_hasError // Show camera icon if no image
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
                              ? CircularProgressIndicator() // Loading indicator while data is being fetched
                              : _hasError
                                  ? Text("Error loading user data",
                                      style: TextStyle(
                                          color: Colors.red)) // Error message
                                  : Center(
                                      child: Text(
                                        _userName ??
                                            'User Name', // Display user name or fallback
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        softWrap:
                                            true, // Automatically wraps the text
                                        overflow: TextOverflow
                                            .ellipsis, // Adds ellipsis if text overflows
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
                              ? CircularProgressIndicator() // Loading indicator while data is being fetched
                              : _hasError
                                  ? Text("Error loading user data",
                                      style: TextStyle(
                                          color: Colors.red)) // Error message
                                  : Center(
                                      child: Text(
                                        _designation ??
                                            'Designtion', // Display user name or fallback
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                        softWrap:
                                            true, // Automatically wraps the text
                                        overflow: TextOverflow
                                            .ellipsis, // Adds ellipsis if text overflows
                                        maxLines: 2,
                                      ),
                                    ),
                        ),
                      ]),
                    )
                  ],
                ),
                SizedBox(
                  height: 50,
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(
                            10), // Optional: Adjust padding inside ListTile
                        title: Column(
                          // Column as child of title
                          crossAxisAlignment: CrossAxisAlignment
                              .start, // Align children to start
                          children: [
                            Text(
                              'Profile',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                        leading: Icon(Icons.person,
                            color: AppColors.blue), // Optional: Leading icon
                        trailing: Icon(Icons.arrow_forward_ios,
                            color: AppColors.blue),
                        onTap: () {
                          Navigator.pushReplacement(
                              context,
                              CupertinoPageRoute(
                                  builder: (context) => Profile()));
                        }, // Optional: Trailing icon
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    if (_designation?.toLowerCase() == 'manager' || _designation?.toLowerCase() == 'admin')
                      if(_designation?.toLowerCase() == 'admin') ...[
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(10),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Review Attendance',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                            leading: Icon(Icons.edit_calendar_outlined, color: AppColors.blue),
                            trailing: Icon(Icons.arrow_forward_ios,
                                color: AppColors.blue),
                            onTap: () {
                              // Replace with your Leave Review page
                              Navigator.pushReplacement(
                                  context,
                                  CupertinoPageRoute(
                                      builder: (context) =>
                                          AttendanceReview())); //change to correct page
                            },
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                      // Wrap conditional widgets in a List<Widget>
                      ...<Widget>[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(10),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Leave Review',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            ],
                          ),
                          leading: Icon(Icons.article, color: AppColors.blue),
                          trailing: Icon(Icons.arrow_forward_ios,
                              color: AppColors.blue),
                          onTap: () {
                            // Replace with your Leave Review page
                            Navigator.pushReplacement(
                                context,
                                CupertinoPageRoute(
                                    builder: (context) =>
                                        LeaveReview())); //change to correct page
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(10),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expense Review',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            ],
                          ),
                          leading: Icon(Icons.account_balance_wallet,
                              color: AppColors.blue),
                          trailing: Icon(Icons.arrow_forward_ios,
                              color: AppColors.blue),
                          onTap: () {
                            // Replace with your Expense Review page
                            Navigator.pushReplacement(
                                context,
                                CupertinoPageRoute(
                                    builder: (context) =>
                                        ExpenseReview())); //change to correct page
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(
                            10), // Optional: Adjust padding inside ListTile
                        title: Column(
                          // Column as child of title
                          crossAxisAlignment: CrossAxisAlignment
                              .start, // Align children to start
                          children: [
                            Text(
                              'Change Password',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                        leading: Icon(Icons.lock,
                            color: AppColors.blue), // Optional: Leading icon
                        trailing: Icon(Icons.arrow_forward_ios,
                            color: AppColors.blue),
                        onTap: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (context) => ChangePasswordScreen()),
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(
                            10), // Optional: Adjust padding inside ListTile
                        title: Column(
                          // Column as child of title
                          crossAxisAlignment: CrossAxisAlignment
                              .start, // Align children to start
                          children: [
                            Text(
                              'Log Out',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                        leading: Icon(Icons.output,
                            color: AppColors.blue), // Optional: Leading icon
                        trailing: Icon(Icons.arrow_forward_ios,
                            color: AppColors.blue),
                        onTap: () => _signOut(context),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                  ]),
                ),
              ]),
        ),
      ),
    );
  }
}
