import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../const/AppColors.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

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
                        GestureDetector(
                          onTap: _pickImage, // When the user taps the CircleAvatar, they can pick a new image
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            backgroundImage: _image != null
                                ? FileImage(_image!) // Display the selected image if available
                                : AssetImage('assets/images/user1.jpg') as ImageProvider, // No image, will show a placeholder
                            child: _image == null // If no image, show icon
                                ? Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 30,
                            )
                                : null, // No icon when image is present
                          ),
                        ),
                        Text('Employee Name', style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height / 4,// Adds space from left and right
                          color: Colors.transparent,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                          ),
                        )
                      ]
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
