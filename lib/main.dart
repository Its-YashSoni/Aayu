import 'package:ayu/screens/screen_builder.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'constraints.dart';
import 'screens/login_screen.dart';
import 'package:splashify/splashify.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try{
    await Firebase.initializeApp(options: FirebaseOptions(
        apiKey: "AIzaSyCjEoF_WYc3RHI4x1SCE3wDtl3rwD2KyMc",
        appId: "1:1023165946413:android:ecf8ebe07f5e45779736a4",
        messagingSenderId: "1023165946413",
        projectId: "aayu-mpi",
        storageBucket: "aayu-mpi.appspot.com"
    ));
    print("Connection Established");
  }catch(e){
    print("Connection Failed $e");
  }

  runApp(MyApp());
}



class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
        useMaterial3: true,
      ),

      home: FutureBuilder(
        future: FirebaseAuth.instance.authStateChanges().first,
        builder: (context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else {
            if (snapshot.hasData) {
              return ScreenBuilder(isGuest: false);
            } else {
              return Splashify(
                title: "Aayu",
                imagePath: 'assets/logo.png',
                navigateDuration: 3, // Navigate to the child widget after 3 seconds
                child: LoginPage(),
                blurIntroAnimation: true,
                colorizeTitleAnimation: true,
                titleSize: 35,
                titleBold: true,
                subTitle: Text("Medicinal Plant Identification App"),
                imageSize: MediaQuery.of(context).size.width * 0.5,
                frameGlowColor: Colors.green,
                frameBorderRadius: 25,
              );
            }
          }
        },
      ),
    );
  }
}