// // import 'package:flutter/material.dart';
// // import 'package:flutter_bloc/flutter_bloc.dart';
// // import 'package:lottie/lottie.dart';
// //
// // import 'bloc/weather_bloc_bloc.dart';
// // import 'screens/home_screen.dart';
// //
// // class MainApp extends StatefulWidget {
// //   const MainApp({super.key});
// //
// //   @override
// //   _MainAppState createState() => _MainAppState();
// // }
// //
// // class _MainAppState extends State<MainApp> {
// //   @override
// //   void initState() {
// //     super.initState();
// //     _startAnimation();
// //   }
// //
// //   void _startAnimation() async {
// //     // Delay to show the animation
// //     await Future.delayed(Duration(seconds: 3)); // Adjust the duration as needed
// //
// //     // Navigate to HomeScreen after the animation
// //     Navigator.pushReplacement(
// //       context,
// //       MaterialPageRoute(
// //         builder: (context) => BlocProvider<WeatherBlocBloc>(
// //           create: (context) => WeatherBlocBloc()..add(FetchWeather('Bhopal')),
// //           child: HomeScreen(),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //         body: Center(
// //           child: Lottie.asset('assets/images/weather.json'), // Replace with your Lottie animation asset path
// //         ),
// //       );
// //
// //   }
// // }
//
//
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:lottie/lottie.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// import 'bloc/weather_bloc_bloc.dart';
// import 'screens/home_screen.dart';
//
// class MainApp extends StatefulWidget {
//   const MainApp({super.key});
//
//   @override
//   _MainAppState createState() => _MainAppState();
// }
//
// class _MainAppState extends State<MainApp> {
//   @override
//   void initState() {
//     super.initState();
//     _startAnimation();
//   }
//
//   Future<void> _startAnimation() async {
//     // Check and request location permissions
//     await _requestLocationPermission();
//
//     // Get the current location
//     Position? position = await _getCurrentLocation();
//
//     // Delay to show the animation
//     await Future.delayed(Duration(seconds: 3)); // Adjust the duration as needed
//
//     // Navigate to HomeScreen after the animation
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (context) => BlocProvider<WeatherBlocBloc>(
//           create: (context) => WeatherBlocBloc()
//             ..add(FetchWeather(position != null ? '${position.latitude},${position.longitude}' : '')),
//           child: HomeScreen(),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _requestLocationPermission() async {
//     final status = await Permission.location.request();
//     if (!status.isGranted) {
//       // Handle the case when permission is not granted
//       print('Location permission is not granted');
//     }
//   }
//
//   Future<Position?> _getCurrentLocation() async {
//     try {
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//       return position;
//     } catch (e) {
//       print('Error getting location: $e');
//       return null;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Lottie.asset('assets/images/weather.json'), // Replace with your Lottie animation asset path
//       ),
//     );
//   }
// }
//


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'bloc/weather_bloc_bloc.dart';
import 'screens/home_screen.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    // Check and request location permissions
    await _requestLocationPermission();

    // Get the current location
    Position? position = await _getCurrentLocation();

    // Delay to show the animation
    await Future.delayed(Duration(seconds: 3)); // Adjust the duration as needed

    // Navigate to HomeScreen after the animation
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider<WeatherBlocBloc>(
          create: (context) => WeatherBlocBloc()
            ..add(FetchWeatherByCoordinates(
              position?.latitude ?? 0.0,
              position?.longitude ?? 0.0,
            )),
          child: HomeScreen(),
        ),
      ),
    );
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      // Handle the case when permission is not granted
      print('Location permission is not granted');
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Lottie.asset('assets/images/weather.json'), // Replace with your Lottie animation asset path
      ),
    );
  }
}
