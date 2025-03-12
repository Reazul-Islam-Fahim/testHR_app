import 'package:flutter/material.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../const/AppColors.dart';

class Notify extends StatefulWidget {
  const Notify({super.key});

  @override
  State<Notify> createState() => _NotifyState();
}

class _NotifyState extends State<Notify> {
  bool isSwitched = false;
  String location = 'Fetching location...';
  String lat = 'N/A';
  String lon = 'N/A';
  LatLng? currentPosition;

  Future<void> getLoc() async {
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
      return;
    }

    try {
      // Fetch the current position (latitude and longitude)
      final geoPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        location = 'Latitude: ${geoPosition.latitude}, Longitude: ${geoPosition.longitude}';
        lat = '${geoPosition.latitude}';
        lon = '${geoPosition.longitude}';
      });

      print('Location fetched: Latitude: ${geoPosition.latitude}, Longitude: ${geoPosition.longitude}');
    } catch (e) {
      print('Failed to get location: $e');
      setState(() {
        location = 'Failed to get location: $e';
      });
    }
  }


  Future<void> checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Center(
            child: Text(
              'Notification',
              style: TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: AppColors.blue,
          automaticallyImplyLeading: false,
        ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('This is notification page'),
                AnimatedToggleSwitch<bool>.size(
                  current: isSwitched,
                  values: const [false, true],
                  iconOpacity: 0.2,
                  indicatorSize: const Size.fromWidth(80),
                  customIconBuilder: (context, local, global) => Text(
                    local.value ? 'IN' : 'OUT',
                    style: TextStyle(
                      color: Color.lerp(
                          Colors.black, Colors.white, local.animationValue),
                    ),
                  ),
                  borderWidth: 1.0,
                  iconAnimationType: AnimationType.onHover,
                  style: ToggleStyle(
                      indicatorColor: isSwitched ? Colors.green : Colors.red,
                      borderColor: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 3,
                          blurRadius: 5,
                          offset: const Offset(0, 4),
                        )
                      ]),
                  selectedIconScale: 1.0,
                  onChanged: (val) {
                    setState(() {
                      isSwitched = val;
                      print(isSwitched);
                    });
                    if (isSwitched) {
                      checkPermissions();
                      getLoc();
                    }
                  },
                ),
                Text(lat),
                Text(lon),
                Text(location),

              ],
            ),
          ),
      ),
    );
  }
}


