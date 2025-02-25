import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../const/AppColors.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Home',
          ),
        ),
        backgroundColor: AppColors.deep_orange,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
          child: Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('This is home page'),
            ],
          ),
        ),
      )
      ),
    );
  }
}
