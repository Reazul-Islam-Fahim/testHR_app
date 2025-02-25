import 'package:flutter/material.dart';

import '../../const/AppColors.dart';

class Notify extends StatefulWidget {
  const Notify({super.key});

  @override
  State<Notify> createState() => _NotifyState();
}

class _NotifyState extends State<Notify> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Notification',
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
                  Text('This is notification page'),
                ],
              ),
            ),
          )
      ),
    );
  }
}
