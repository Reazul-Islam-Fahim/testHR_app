import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../const/AppColors.dart';
import 'package:geolocator/geolocator.dart';

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
  String? _imageUrl;
  String? _userName;
  bool _isLoading = false;
  bool _hasError = false;
  String location = 'Fetching location...';
  String inLatitude = 'N/A';
  String inLongitude = 'N/A';

  @override
  void initState() {
    super.initState();
    firestore = FirebaseFirestore.instance;
    _startTimer();
    _loadState();
    fetchLeaveData();
    _fetchUserData();
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

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _hasError = false; // Reset error state
    });

    try {
      // Replace with your API URL to fetch user data
      final response = await http.get(
        Uri.parse('http://192.168.3.228:7000/get-user-data'),
      );

      if (response.statusCode == 200) {
        // Parse the JSON response
        final data = json.decode(response.body);

        setState(() {
          _imageUrl = data['image'];
          _userName = data['name'];
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

  // Fetch leave data from API
  Future<void> fetchLeaveData() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.3.228:8000/api/leave-data'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          leaveData =
              data
                  .map(
                    (item) => {
                      'Leave Type': item['leaveType'],
                      'Total Leave': item['totalLeave'],
                      'Availed': item['availed'],
                      'Balance': item['balance'],
                    },
                  )
                  .toList();
          print("Data load successful");
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
          DocumentSnapshot doc =
              await firestore
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

  Future<void> _saveState(String attendanceStatus, Position geoPosition) async {
    try {
      setState(() => isLoading = true);

      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Fetch user document from Firestore
        DocumentSnapshot userDoc =
            await firestore.collection('users-form-data').doc(user.email).get();

        if (userDoc.exists) {
          // Retrieve employee data
          employeeId = userDoc['employee_id'];

          // Get current date
          String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

          // Store attendance data in Firestore
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
                'location': location,
                'latitude': geoPosition.latitude,
                'longitude': geoPosition.longitude,
                'attendanceStatus':
                    attendanceStatus, // Store inside/outside status
                'timestamp': getCurrentDateTime(),
              });

          print('Attendance status saved: $attendanceStatus');
        }
      }
    } catch (e) {
      print("Error saving state: $e");
    } finally {
      setState(() => isLoading = false);
    }

    print('Employee ID: $employeeId');
    List<int> charCodes = employeeId.codeUnits;
    print("Character Codes: $charCodes");
  }

  Future<Position> _getLocation() async {
    // Office location (replace with actual coordinates)
    const double officeLatitude = 23.7936; // Example latitude
    const double officeLongitude = 90.4111; // Example longitude

    // First, check and request permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      // Handle case where permission is denied permanently
      print('Location permission denied forever');
      setState(() {
        location = 'Location permission denied forever.';
      });
      return Future.error('Location permission denied forever');
    }

    try {
      // Fetch the current position (latitude and longitude)
      final geoPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Calculate the distance between current location and office location
      double distanceInMeters = Geolocator.distanceBetween(
        geoPosition.latitude,
        geoPosition.longitude,
        officeLatitude,
        officeLongitude,
      );

      // Check if the employee is within 70 meters of the office
      if (distanceInMeters <= 70) {
        // Employee is inside the office, save attendance
        setState(() {
          location = 'Inside Office. Attendance added.';
          inLatitude = '${geoPosition.latitude}';
          inLongitude = '${geoPosition.longitude}';
        });
      } else {
        // Show alert dialog if outside the office
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Office Location'),
              content: Text('Are you inside the office or outside?'),
              actions: [
                TextButton(
                  onPressed: () async {
                    // If inside office, proceed with "inside" status
                    await _saveState(
                      'inside',
                      geoPosition,
                    ); // Pass 'inside' status

                    Navigator.of(context).pop();
                  },
                  child: Text('Inside'),
                ),
                TextButton(
                  onPressed: () async {
                    // If outside office, proceed with "outside" status
                    await _saveState(
                      'outside',
                      geoPosition,
                    ); // Pass 'outside' status

                    Navigator.of(context).pop();
                  },
                  child: Text('Outside'),
                ),
              ],
            );
          },
        );

        setState(() {
          location = 'Outside Office. Please confirm attendance status.';
        });
      }

      print(
        'Location fetched: Latitude: ${geoPosition.latitude}, Longitude: ${geoPosition.longitude}',
      );

      return geoPosition;
    } catch (e) {
      print('Failed to get location: $e');
      setState(() {
        location = 'Failed to get location: $e';
      });
      return Future.error('Failed to get location');
    }
  }

  Future<void> checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      print('Location permission denied forever');
      return;
    }
  }

  // Helper methods
  String getCurrentTime() => DateFormat('HH:mm:ss').format(DateTime.now());
  String getCurrentDateTime() =>
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  String _getCurrentDayOfWeek() => DateFormat('EEEE').format(DateTime.now());
  String _getCurrentDayOfMonth() => DateFormat('dd').format(DateTime.now());
  String _getCurrentMonthName() => DateFormat('MMMM').format(DateTime.now());

  // New async function to handle the switch change
  Future<void> _handleSwitchChange(bool val) async {
    Position? geoPosition;

    // First update the UI state inside setState without async operations
    setState(() {
      if (inTimeCaptured && outTimeCaptured) {
        return; // Do nothing if both inTime and outTime are captured
      }

      isSwitched = val;
      print(isSwitched);

      // Capture the current time based on the toggle state
      if (isSwitched && !inTimeCaptured) {
        inTime = getCurrentTime();
        inTimeCaptured = true; // Mark IN time as captured
      }

      // Capture time only once for OUT state
      if (!isSwitched && !outTimeCaptured) {
        outTime = getCurrentTime();
        outTimeCaptured = true; // Mark OUT time as captured
      }
    });

    // Now perform the async operations outside of setState
    if (isSwitched) {
      await checkPermissions();
      geoPosition = await _getLocation();
    }

    // After fetching location, save the state
    if (geoPosition != null) {
      String attendanceStatus =
          isSwitched
              ? 'inside'
              : 'outside'; // Determine status based on switch state
      await _saveState(
        attendanceStatus,
        geoPosition,
      ); // Pass the status and geoPosition to _saveState()
    } else {
      print('Failed to fetch location.');
    }
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
                    color: AppColors.blue,
                  ),
                  Positioned(
                    top: 20,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              _imageUrl != null
                                  ? NetworkImage(
                                    _imageUrl!,
                                  ) // Use the image URL from the API
                                  : AssetImage('assets/images/user1.jpg')
                                      as ImageProvider, // Placeholder image
                          child:
                              _imageUrl == null &&
                                      !_isLoading &&
                                      !_hasError // Show camera icon if no image
                                  ? Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 30,
                                  )
                                  : null,
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child:
                              _isLoading
                                  ? CircularProgressIndicator() // Loading indicator while data is being fetched
                                  : _hasError
                                  ? Text(
                                    "Error loading user data",
                                    style: TextStyle(color: Colors.red),
                                  ) // Error message
                                  : Text(
                                    _userName ??
                                        'User Name', // Display user name or fallback
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    softWrap:
                                        true, // Automatically wraps the text
                                    overflow:
                                        TextOverflow
                                            .ellipsis, // Adds ellipsis if text overflows
                                    maxLines: 2,
                                  ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          width: MediaQuery.of(context).size.width,
                          height:
                              MediaQuery.of(context).size.height /
                              4, // Adds space from left and right
                          color: Colors.transparent,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 1, // 1 part of the total 3
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(20),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                                  fontWeight: FontWeight.w100,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
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
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 35,
                                                ),
                                              ),
                                            ),
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
                                                  fontWeight: FontWeight.w100,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
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
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(20),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                                    right: 5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                          Radius.circular(10),
                                                        ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(
                                                              0.2,
                                                            ), // Shadow color
                                                        spreadRadius:
                                                            3, // Spread of the shadow
                                                        blurRadius:
                                                            5, // Blur effect of the shadow
                                                        offset: Offset(
                                                          0,
                                                          4,
                                                        ), // Offset of the shadow (x, y)
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
                                                    right: 10,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                          Radius.circular(10),
                                                        ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(
                                                              0.2,
                                                            ), // Shadow color
                                                        spreadRadius:
                                                            3, // Spread of the shadow
                                                        blurRadius:
                                                            5, // Blur effect of the shadow
                                                        offset: Offset(
                                                          0,
                                                          4,
                                                        ), // Offset of the shadow (x, y)
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
                                                    right: 15,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                          Radius.circular(10),
                                                        ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(
                                                              0.2,
                                                            ), // Shadow color
                                                        spreadRadius:
                                                            3, // Spread of the shadow
                                                        blurRadius:
                                                            5, // Blur effect of the shadow
                                                        offset: Offset(
                                                          0,
                                                          4,
                                                        ), // Offset of the shadow (x, y)
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
                                              ),
                                            ],
                                          ),
                                        ),
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
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  // Conditionally render the switch or the text
                  if (!(inTimeCaptured &&
                      outTimeCaptured)) // Show the switch only if both times are not captured
                  ...[
                    isLoading
                        ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.blue,
                            ),
                          ),
                        )
                        : Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 60, top: 60),
                          child: Transform.scale(
                            scale: 2,
                            child: Switch(
                              value: isSwitched,
                              onChanged: (val) async {
                                await _handleSwitchChange(val);
                              },
                              activeTrackColor: Colors.red,
                              activeColor: Colors.white,
                              inactiveTrackColor: Colors.green,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              splashRadius: 0,
                              inactiveThumbImage: AssetImage(
                                'assets/images/in.png',
                              ),
                              activeThumbImage: AssetImage(
                                'assets/images/out.png',
                              ),
                            ),
                          ),
                        ),
                  ] else ...[
                    Padding(
                      padding: EdgeInsets.only(left: 80, top: 80),
                      child: Text(
                        'Attendance Provided!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                  ],
                  // Show text if both IN and OUT times are captured
                  Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.all(20),
                    margin:
                        !(inTimeCaptured && outTimeCaptured)
                            ? EdgeInsets.only(left: 20, right: 20, top: 80)
                            : EdgeInsets.only(left: 20, right: 20, top: 180),
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
                              Text(
                                'IN TIME: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              Text(
                                inTime.isEmpty ? 'Not set' : inTime,
                              ), // Show stored IN time
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              // Show "OUT TIME"
                              Text(
                                'OUT TIME: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              Text(
                                outTime.isEmpty ? 'Not set' : outTime,
                              ), // Show stored OUT time
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
                          SizedBox(height: 20),
                          FittedBox(
                            fit: BoxFit.contain,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Leave Type')),
                                DataColumn(label: Text('Total Leave')),
                                DataColumn(label: Text('Availed')),
                                DataColumn(label: Text('Balance')),
                              ],
                              rows:
                                  leaveData.map((data) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(data['Leave Type'])),
                                        DataCell(
                                          Text(data['Total Leave'].toString()),
                                        ),
                                        DataCell(
                                          Text(data['Availed'].toString()),
                                        ),
                                        DataCell(
                                          Text(data['Balance'].toString()),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
