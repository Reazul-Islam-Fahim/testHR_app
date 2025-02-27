import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../const/AppColors.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String currentHour = DateFormat('HH').format(DateTime.now());
  String currentMinute = DateFormat('mm').format(DateTime.now());
  String currentSecond = DateFormat('ss').format(DateTime.now());

  bool isSwitched = false;

  late Timer _timer;

  @override
  void initState() {
    super.initState();

    // Update the time every second
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        currentHour = DateFormat('HH').format(DateTime.now());
        currentMinute = DateFormat('mm').format(DateTime.now());
        currentSecond = DateFormat('ss').format(DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    _timer.cancel();
    super.dispose();
  }

  File? _image;

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    // Pick an image from the gallery
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        // Store the image as a File object
        _image = File(image.path);
      });
    }
  }

  String _getCurrentDayOfWeek() {
    DateTime now = DateTime.now();
    return DateFormat('EEEE')
        .format(now); // Formats the current date as the full day name
  }

  String _getCurrentDayOfMonth() {
    DateTime now = DateTime.now();
    return DateFormat('dd')
        .format(now); // Formats the current date as the day of the month (DD)
  }

  String _getCurrentMonthName() {
    DateTime now = DateTime.now();
    return DateFormat('MMMM').format(
        now); // Formats the current date as the full month name (e.g., "January")
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
                            4, // Adds space from left and right
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
                                        child: Center(child: Text(' ')),
                                      ),
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
              Container(
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 30),
                child: AnimatedToggleSwitch<bool>.size(
                  current: isSwitched,
                  values: [false, true],
                  iconOpacity: 0.2,
                  indicatorSize: const Size.fromWidth(80),
                  customIconBuilder: (context, local, global) => Text(
                    local.value ? 'OUT' : 'IN',
                    style: TextStyle(
                        color: Color.lerp(
                            Colors.black, Colors.white, local.animationValue)),
                  ),
                  borderWidth: 1.0,
                  iconAnimationType: AnimationType.onHover,
                  style: ToggleStyle(
                      indicatorColor: isSwitched ? Colors.red : Colors.green,
                      borderColor: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 3,
                          blurRadius: 5,
                          offset: Offset(0, 4),
                        )
                      ]),
                  selectedIconScale: 1.0,
                  onChanged: (val) {
                    setState(() {
                      isSwitched = val;
                      print(isSwitched);
                    });
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
