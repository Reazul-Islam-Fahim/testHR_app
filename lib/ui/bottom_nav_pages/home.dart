import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../const/AppColors.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // State variables
  List<Map<String, dynamic>> leaveData = [];
  bool isLoading = false;
  String currentHour = DateFormat('HH').format(DateTime.now());
  String currentMinute = DateFormat('mm').format(DateTime.now());
  String currentSecond = DateFormat('ss').format(DateTime.now());
  bool isSwitched = false;
  String inTime = '';
  String outTime = '';
  bool inTimeCaptured = false;
  bool outTimeCaptured = false;
  String employeeId = '';
  late FirebaseFirestore firestore;
  late Timer _timer;
  File? _image;

  @override
  void initState() {
    super.initState();
    firestore = FirebaseFirestore.instance;
    _startTimer();
    _loadState();
    fetchLeaveData();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Start a timer to update time every second
  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        currentHour = DateFormat('HH').format(DateTime.now());
        currentMinute = DateFormat('mm').format(DateTime.now());
        currentSecond = DateFormat('ss').format(DateTime.now());
      });
    });
  }

  // Fetch leave data from API
  Future<void> fetchLeaveData() async {
    try {
      final response =
          await http.get(Uri.parse('https://example.com/api/leave-data'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          leaveData = data
              .map((item) => {
                    'Leave Type': item['leaveType'],
                    'Total Leave': item['totalLeave'],
                    'Availed': item['availed'],
                    'Balance': item['balance'],
                  })
              .toList();
        });
      } else {
        throw Exception('Failed to load leave data');
      }
    } catch (e) {
      print("Error fetching leave data: $e");
    }
  }

  // Load attendance state from Firestore
  Future<void> _loadState() async {
    try {
      setState(() => isLoading = true);
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
            await firestore.collection('users-form-data').doc(user.email).get();
        if (userDoc.exists) {
          employeeId = userDoc['employee_id'];
          String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
          DocumentSnapshot doc = await firestore
              .collection('attendance')
              .doc(employeeId)
              .collection('days')
              .doc(currentDate)
              .get();

          if (doc.exists) {
            setState(() {
              isSwitched = doc['isSwitched'] ?? false;
              inTimeCaptured = doc['inTimeCaptured'] ?? false;
              outTimeCaptured = doc['outTimeCaptured'] ?? false;
              inTime = doc['inTime'] ?? '';
              outTime = doc['outTime'] ?? '';
            });
          }
        }
      }
    } catch (e) {
      print("Error loading state: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Save attendance state to Firestore
  Future<void> _saveState() async {
    try {
      setState(() => isLoading = true);
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
            await firestore.collection('users-form-data').doc(user.email).get();
        if (userDoc.exists) {
          employeeId = userDoc['employee_id'];
          String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
          await firestore
              .collection('attendance')
              .doc(employeeId)
              .collection('days')
              .doc(currentDate)
              .set({
            'isSwitched': isSwitched,
            'inTimeCaptured': inTimeCaptured,
            'outTimeCaptured': outTimeCaptured,
            'inTime': inTime,
            'outTime': outTime,
            'timestamp': getCurrentDateTime(),
          });
        }
      }
    } catch (e) {
      print("Error saving state: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _image = File(image.path));
    }
  }

  // Helper methods
  String getCurrentTime() => DateFormat('HH:mm:ss').format(DateTime.now());
  String getCurrentDateTime() =>
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  String _getCurrentDayOfWeek() => DateFormat('EEEE').format(DateTime.now());
  String _getCurrentDayOfMonth() => DateFormat('dd').format(DateTime.now());
  String _getCurrentMonthName() => DateFormat('MMMM').format(DateTime.now());

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
                    color: AppColors.blue,
                  ),
                  Positioned(
                    top: 20,
                    child: Column(children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap:
                            _pickImage, // When the user taps the CircleAvatar, they can pick a new image
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: _image != null
                              ? FileImage(
                                  _image!) // Display the selected image if available
                              : AssetImage('assets/images/user1.jpg')
                                  as ImageProvider, // No image, will show a placeholder
                          child: _image == null // If no image, show icon
                              ? Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 30,
                                )
                              : null, // No icon when image is present
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Ikhtiar Uddin Mohammad Bin Bokhtiar Kholji',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          softWrap: true, // Automatically wraps the text
                          overflow: TextOverflow
                              .ellipsis, // Adds ellipsis if text overflows
                          maxLines: 2,
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height /
                            5, // Adds space from left and right
                        color: Colors.transparent,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 1, // 1 part of the total 3
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(20)),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // First child container inside the left red container
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          color: Colors.transparent,
                                          margin: EdgeInsets.only(top: 20),
                                          child: Center(
                                              child: Text(
                                                  _getCurrentDayOfWeek(),
                                                  style: TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.w100,
                                                      fontSize: 18))),
                                        ),
                                      ),
                                      // Second child container inside the left red container
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          color: Colors.transparent,
                                          child: Center(
                                              child: Text(
                                                  _getCurrentDayOfMonth(),
                                                  style: TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 35))),
                                        ),
                                      ),
                                      // Third child container inside the left red container
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          color: Colors.transparent,
                                          margin: EdgeInsets.only(bottom: 20),
                                          child: Center(
                                              child: Text(
                                                  _getCurrentMonthName(),
                                                  style: TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.w100,
                                                      fontSize: 18))),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Right Container with 2/3 width and green color
                              Expanded(
                                flex: 2, // 2 parts of the total 3
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(20)),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                          flex: 1,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                flex: 1,
                                                child: Container(
                                                  height: 50,
                                                  margin: EdgeInsets.only(
                                                      top: 10,
                                                      bottom: 10,
                                                      left: 15,
                                                      right: 5),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                10)),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(
                                                                0.2), // Shadow color
                                                        spreadRadius:
                                                            3, // Spread of the shadow
                                                        blurRadius:
                                                            5, // Blur effect of the shadow
                                                        offset: Offset(0,
                                                            4), // Offset of the shadow (x, y)
                                                      ),
                                                    ],
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      currentHour, // Display the current hour (HH)
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 1,
                                                child: Container(
                                                  height: 50,
                                                  margin: EdgeInsets.only(
                                                      top: 10,
                                                      bottom: 10,
                                                      left: 10,
                                                      right: 10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                10)),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(
                                                                0.2), // Shadow color
                                                        spreadRadius:
                                                            3, // Spread of the shadow
                                                        blurRadius:
                                                            5, // Blur effect of the shadow
                                                        offset: Offset(0,
                                                            4), // Offset of the shadow (x, y)
                                                      ),
                                                    ],
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      currentMinute, // Display the current hour (HH)
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 1,
                                                child: Container(
                                                  height: 50,
                                                  margin: EdgeInsets.only(
                                                      top: 10,
                                                      bottom: 10,
                                                      left: 5,
                                                      right: 15),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                10)),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(
                                                                0.2), // Shadow color
                                                        spreadRadius:
                                                            3, // Spread of the shadow
                                                        blurRadius:
                                                            5, // Blur effect of the shadow
                                                        offset: Offset(0,
                                                            4), // Offset of the shadow (x, y)
                                                      ),
                                                    ],
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      currentSecond, // Display the current hour (HH)
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ],
                                          )),
                                      Expanded(
                                        flex: 1,
                                        child: Center(child: Text(' ')),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  )
                ],
              ),
              Column(
                children: [
                  // Conditionally render the switch or the text
                  if (!(inTimeCaptured &&
                      outTimeCaptured)) // Show the switch only if both times are not captured
                    isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.blue)))
                        : Container(
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(
                              right: 60,
                              top: 30,
                            ),
                            child: Transform.scale(
                              scale: 2,
                              child: Switch(
                                value: isSwitched,
                                onChanged: (val) {
                                  setState(() {
                                    if (inTimeCaptured && outTimeCaptured) {
                                      return; // Do nothing if both inTime and outTime are captured
                                    }

                                    isSwitched = val;
                                    print(isSwitched);

                                    // Capture the current time based on the toggle state
                                    if (isSwitched && !inTimeCaptured) {
                                      inTime = getCurrentTime();
                                      inTimeCaptured =
                                          true; // Mark IN time as captured
                                    }

                                    // Capture time only once for OUT state
                                    if (!isSwitched && !outTimeCaptured) {
                                      outTime = getCurrentTime();
                                      outTimeCaptured =
                                          true; // Mark OUT time as captured
                                    }

                                    _saveState();
                                  });
                                },
                                activeTrackColor: Colors.red,
                                activeColor: Colors.white,
                                inactiveTrackColor: Colors.green,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                splashRadius: 0,
                                inactiveThumbImage:
                                    AssetImage('assets/images/in.png'),
                                activeThumbImage:
                                    AssetImage('assets/images/out.png'),
                              ),
                            ),
                          ),
                  // Show text if both IN and OUT times are captured
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.all(20),
                    margin: !(inTimeCaptured && outTimeCaptured)
                        ? EdgeInsets.only(left: 20, right: 20, top: 60)
                        : EdgeInsets.only(left: 20, right: 20, top: 130),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              // Show "IN TIME"
                              Text('IN TIME: ',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
                              Text(inTime.isEmpty
                                  ? 'Not set'
                                  : inTime), // Show stored IN time
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              // Show "OUT TIME"
                              Text('OUT TIME: ',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
                              Text(outTime.isEmpty
                                  ? 'Not set'
                                  : outTime), // Show stored OUT time
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.all(20),
                    margin: EdgeInsets.only(left: 20, right: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Monthly Attendance Summary',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.all(20),
                    margin: EdgeInsets.only(left: 20, right: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Leave Balance',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            FittedBox(
                              fit: BoxFit.contain,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Leave Type')),
                                  DataColumn(label: Text('Total Leave')),
                                  DataColumn(label: Text('Availed')),
                                  DataColumn(label: Text('Balance')),
                                ],
                                rows: leaveData.map((data) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(data['Leave Type'])),
                                      DataCell(
                                          Text(data['Total Leave'].toString())),
                                      DataCell(
                                          Text(data['Availed'].toString())),
                                      DataCell(
                                          Text(data['Balance'].toString())),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ]),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
