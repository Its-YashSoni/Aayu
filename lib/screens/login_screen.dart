import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screen_builder.dart';

Future<void> _requestPermissions() async {
  await [
    Permission.camera,
    Permission.storage,
    Permission.location,
  ].request();
}
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isGuest = false;

  @override
  void initState(){
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await _requestPermissions();
  }



  Future<void> _signInWithGoogle() async {
    setState(() {
      isGuest = false;
      _isLoading = true;
    });



    try {
      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Obtain the authentication details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      // Check if the user already exists in Firestore
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user!.uid).get();

      if (!userDoc.exists) {
        // User does not exist, create a new record
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'displayName': user.displayName,
          'email': user.email,
          'photoURL': user.photoURL,
          'lastSignInTime': user.metadata.lastSignInTime,
          'creationTime': user.metadata.creationTime,
          'likes': 0
        });
      }

      // Navigate to the next screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ScreenBuilder(isGuest: false),
        ),
      );
    } catch (e) {
      // Handle sign-in error
      print('Error signing in with Google: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() {
      isGuest = true;
      _isLoading = true;
    });


    await Future.delayed(Duration(seconds: 4));

    setState(() {
      _isLoading = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ScreenBuilder(isGuest: true),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: Lottie.asset(isGuest ? 'assets/guest.json' :'assets/google.json', width: MediaQuery.of(context).size.width*0.4))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/loading.json'),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          Container(
            width: MediaQuery.of(context).size.width * 0.7,
            child: ElevatedButton(
              onPressed: _signInWithGoogle,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Image.asset('assets/google.png', width: MediaQuery.of(context).size.width * 0.1),
                  Text("Sign In with Google"),
                ],
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          Container(
            width: MediaQuery.of(context).size.width * 0.7,
            child: ElevatedButton(
              onPressed: _continueAsGuest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.person, size: 30),
                  Text("Continue as guest"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
