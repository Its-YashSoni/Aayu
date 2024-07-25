import 'dart:async';

import 'package:ayu/screens/homepage.dart';
import 'package:ayu/screens/screen_builder.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constraints.dart';
import 'screens/login_screen.dart';
import 'package:splashify/splashify.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyCjEoF_WYc3RHI4x1SCE3wDtl3rwD2KyMc",
            appId: "1:1023165946413:android:1eb37e82e6f9112c9736a4",
            messagingSenderId: "1023165946413",
            projectId: "aayu-mpi",
            storageBucket: "aayu-mpi.appspot.com"));
    print("Connection Established");
  } catch (e) {
    print("Connection Failed $e");
  }

  runApp(MyApp());
}

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
//         useMaterial3: true,
//       ),
//
//       home: FutureBuilder(
//         future: FirebaseAuth.instance.authStateChanges().first,
//         builder: (context, AsyncSnapshot<User?> snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           } else {
//             if (snapshot.hasData) {
//               return ScreenBuilder(isGuest: false);
//             } else {
//               return Splashify(
//                 title: "Aayu",
//                 imagePath: 'assets/logo.png',
//                 navigateDuration: 3, // Navigate to the child widget after 3 seconds
//                 child: LoginPage(),
//                 blurIntroAnimation: true,
//                 colorizeTitleAnimation: true,
//                 titleSize: 35,
//                 titleBold: true,
//                 subTitle: Text("Medicinal Plant Identification App"),
//                 imageSize: MediaQuery.of(context).size.width * 0.5,
//                 frameGlowColor: Colors.green,
//                 frameBorderRadius: 25,
//               );
//             }
//           }
//         },
//       ),
//     );
//   }
// }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
        useMaterial3: true,
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Color(0xff426D51),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          contentTextStyle: GoogleFonts.poppins(
            color: Colors.white,
          )
        )
      ),
      home: FutureBuilder(
        future: FirebaseAuth.instance.authStateChanges().first,
        builder: (context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else {
            if (snapshot.hasData) {
              return SplashScreen(hasData: true);
            } else {
              return SplashScreen(
                hasData: false,
              );
            }
          }
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  bool hasData;

  SplashScreen({required this.hasData, super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      widget.hasData
          ? Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(isGuest: false),
              ))
          : Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => LoginPage(),
              ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: Colors.black,
          image: DecorationImage(
              image: AssetImage('assets/background1.jpg'),
              fit: BoxFit.fill,
              opacity: 0.5),
        ),
        child: Center(
          child: Text("Aayu",
              style: GoogleFonts.eduNswActFoundation(
                  textStyle: TextStyle(
                      decoration: TextDecoration.none,
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).textScaleFactor * 70,
                      shadows: [
                    Shadow(
                        color: Colors.black,
                        blurRadius: 20,
                        offset: Offset(0, 0))
                  ]))),
        ));
  }
}
