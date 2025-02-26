import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_app/const/AppColors.dart';
import 'package:test_app/ui/splash_screen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: 'AIzaSyBzMrzSAKxp5noG28k4K_XSOrqQBCzHqII',
        appId: '1:1076831835803:android:b9ea42e621b18a482c183e',
        messagingSenderId: '1076831835803',
        projectId: 'testhr-24fd0',
    )
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(360, 690),
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: AppColors.blue,
          ),
          home: SplashScreen(),
        );
      },
    );
  }
}
