// import 'dart:async';
// import 'package:ayu/screens/homepage.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:lottie/lottie.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'screen_builder.dart';
//
// Future<void> _requestPermissions() async {
//   await [
//     Permission.camera,
//     Permission.location,
//     Permission.storage,
//     Permission.photos,
//   ].request();
// }
//
// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});
//
//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }
//
// class _LoginPageState extends State<LoginPage> {
//   bool _isLoading = false;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleSignIn _googleSignIn = GoogleSignIn();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   bool isGuest = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _checkPermissions();
//   }
//
//   Future<void> _checkPermissions() async {
//     await _requestPermissions();
//   }
//
//   Future<void> _signInWithGoogle() async {
//     setState(() {
//       isGuest = false;
//       _isLoading = true;
//     });
//
//     try {
//       // Sign in with Google
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//
//       // Obtain the authentication details from the request
//       final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
//
//       // Create a new credential
//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );
//
//       // Sign in to Firebase with the Google credential
//       UserCredential userCredential = await _auth.signInWithCredential(credential);
//       User? user = userCredential.user;
//
//       // Check if the user already exists in Firestore
//       DocumentSnapshot userDoc = await _firestore.collection('users').doc(user!.uid).get();
//
//       if (!userDoc.exists) {
//         // User does not exist, create a new record
//         await _firestore.collection('users').doc(user.uid).set({
//           'uid': user.uid,
//           'displayName': user.displayName,
//           'email': user.email,
//           'photoURL': user.photoURL,
//           'lastSignInTime': user.metadata.lastSignInTime,
//           'creationTime': user.metadata.creationTime,
//           'likes': 0
//         });
//       }
//
//       // Navigate to the next screen
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => HomePage(isGuest: false),
//         ),
//       );
//     } catch (e) {
//       // Handle sign-in error
//       print('Error signing in with Google: $e');
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   Future<void> _continueAsGuest() async {
//     setState(() {
//       isGuest = true;
//       _isLoading = true;
//     });
//
//     // Simulate a delay
//     await Future.delayed(Duration(seconds: 4));
//
//     // Navigate to the next screen
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (context) => HomePage(isGuest: true),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _isLoading
//           ? Center(
//         child: CircularProgressIndicator(), // Show CircularProgressIndicator while loading
//       )
//           : Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Center(
//               child: Image(
//                   image: AssetImage('assets/images/login-graphic.png'),
//                   width: MediaQuery.of(context).size.width * 0.6)),
//           SizedBox(height: MediaQuery.of(context).size.height * 0.04),
//           Text("Sign Up", style: GoogleFonts.poppins(
//             textStyle: TextStyle(
//               fontSize: MediaQuery.of(context).textScaleFactor * 29.5,
//               fontWeight: FontWeight.bold,
//             ),
//           )),
//           Text("Continue with Gmail", style: GoogleFonts.dmSans(
//               textStyle: TextStyle(
//                 fontSize: MediaQuery.of(context).textScaleFactor * 11.7,
//               )
//           )),
//           SizedBox(height: MediaQuery.of(context).size.height * 0.03),
//           GestureDetector(
//             onTap: _signInWithGoogle,
//             child: Container(
//               decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(50),
//                   boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, spreadRadius: 1)]
//               ),
//               child: Image(
//                 image: AssetImage('assets/images/gmail-button.png'),
//                 width: MediaQuery.of(context).size.width * 0.7,
//               ),
//             ),
//           ),
//           SizedBox(height: MediaQuery.of(context).size.height * 0.02),
//           GestureDetector(
//             onTap: _continueAsGuest,
//             child: Image(
//               image: AssetImage('assets/images/guest-button.png'),
//               width: MediaQuery.of(context).size.width * 0.6,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:io';
import 'package:ayu/screens/forgot_password.dart';
import 'package:ayu/screens/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> _requestPermissions() async {
  await [
    Permission.camera,
    Permission.location,
    Permission.storage,
    Permission.photos,
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isGuest = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _imagePicker = ImagePicker();
  File? _imageFile;
  bool isObscure = true;
  bool isSignIn = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await _requestPermissions();
  }

  Future<void> _signUpWithEmail() async {
    setState(() {
      isGuest = false;
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();
      String errorMessage = '';

      final signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (signInMethods.isNotEmpty) {
        setState(() {
          errorMessage = 'Email is already in use.';
        });
        return;
      }


      // Validate email format
      if (!_isValidEmail(email)) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'The email address is badly formatted.',
        );
      }

      // Sign up with email and password
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      // Upload photo
      String photoURL = '';
      if (_imageFile != null) {
        final storageRef =
        FirebaseStorage.instance.ref().child('profile_pics/${user!.uid}');
        await storageRef.putFile(_imageFile!);
        photoURL = await storageRef.getDownloadURL();
      }

      // Create a new record in Firestore
      await _firestore.collection('users').doc(user!.uid).set({
        'uid': user.uid,
        'displayName': name,
        'email': user.email,
        'photoURL': photoURL,
        'lastSignInTime': user.metadata.lastSignInTime,
        'creationTime': user.metadata.creationTime,
        'likes': 0
      });

      // Navigate to the next screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(isGuest: false),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is badly formatted.';
          break;
        case 'email-already-in-use':
          errorMessage = 'The email address is already in use by another account.';
          break;
        case 'weak-password':
          errorMessage = 'The password is too weak.';
          break;
        default:
          errorMessage = 'Error signing up: ${e.message}';
          break;
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    } catch (e) {
      // Handle other types of errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing up: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
        return emailRegex.hasMatch(email);
  }



  Future<void> _signInWithEmail() async {
    String errorMessage = '';
    setState(() {
      isGuest = false;
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Sign in with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      // Update lastSignInTime in Firestore
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'lastSignInTime': user.metadata.lastSignInTime,
        });

        // Navigate to the next screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(isGuest: false),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided for that user.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-disabled':
          errorMessage = 'The user account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later.';
          break;
        default:
          errorMessage = e.message ?? 'An unknown error occurred.';
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    } catch (e) {
      // Handle other types of errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing in: ${e.toString()}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }







  Future<void> _continueAsGuest() async {
    setState(() {
      isGuest = true;
      _isLoading = true;
    });

    // Simulate a delay
    await Future.delayed(Duration(seconds: 4));

    // Navigate to the next screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(isGuest: true),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child:
                  CircularProgressIndicator(), // Show CircularProgressIndicator while loading
            )
          : SingleChildScrollView(
              child: isSignIn
                  ? Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.1,
                        ),
                        Center(
                            child: Hero(
                          tag: 'login-image',
                          child: Image(
                              image:
                                  AssetImage('assets/images/login-graphic.png'),
                              width: MediaQuery.of(context).size.width * 0.5),
                        )),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04),
                        Column(
                          children: [
                            Text("Sign In",
                                style: GoogleFonts.poppins(
                                  textStyle: TextStyle(
                                    fontSize: MediaQuery.of(context)
                                            .textScaleFactor *
                                        29.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                            Text("Login with your email and password",
                                style: GoogleFonts.dmSans(
                                    textStyle: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).textScaleFactor *
                                          11.7,
                                ))),
                            SizedBox(
                                height: MediaQuery.of(context).size.height *
                                    0.03),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0),
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                padding: EdgeInsets.only(left: 12),
                                decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    // boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 1, spreadRadius: 1)],
                                    border: Border.all(),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Center(
                                  child: TextField(
                                    controller: _emailController,
                                    style: GoogleFonts.poppins(
                                        color: Colors.black),
                                    decoration: InputDecoration(
                                        labelText: 'Email ID',
                                        labelStyle: GoogleFonts.poppins(
                                            color: Color(0xff426D51)),
                                        floatingLabelStyle:
                                            GoogleFonts.poppins(
                                                fontSize: 15,
                                                color: Color(0xff426D51)
                                                    .withOpacity(0.6)),
                                        border: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.03,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0),
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                padding: EdgeInsets.only(left: 12),
                                decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    // boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 1, spreadRadius: 1)],
                                    border: Border.all(),
                                    borderRadius: BorderRadius.circular(12)),
                                child: TextFormField(
                                  controller: _passwordController,
                                  style: GoogleFonts.poppins(
                                      color: Colors.black),
                                  decoration: InputDecoration(
                                      suffixIcon: InkWell(
                                          onTap: () => setState(() {
                                                isObscure = !isObscure;
                                              }),
                                          child: isObscure
                                              ? Icon(
                                                  FontAwesome.eye,
                                                  color: Color(0xff426D51),
                                                )
                                              : Icon(
                                                  FontAwesome.eye_slash,
                                                  color: Color(0xff426D51),
                                                )),
                                      labelText: 'Password',
                                      labelStyle: GoogleFonts.poppins(
                                          color: Color(0xff426D51)),
                                      floatingLabelStyle: GoogleFonts.poppins(
                                          fontSize: 15,
                                          color: Color(0xff426D51)
                                              .withOpacity(0.6)),
                                      border: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none),
                                  obscureText: isObscure,
                                ),
                              ),
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.01,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                      onPressed: () {
                                        setState(() {
                                          isSignIn = false;
                                        });
                                      },
                                      child: Text('Create an Account')),
                                  TextButton(
                                      onPressed: (){
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => ForgotPassword(),));
                                      },
                                      child: Text('Forgot Password ?')),
                                ],
                              ),
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.01,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0),
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                height:
                                    MediaQuery.of(context).size.height * 0.07,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      backgroundColor: Color(0xff426D51)),
                                  onPressed: (){
                                    if(_emailController.text.isEmpty){
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Please Enter your Email"))
                                      );
                                    }else if(_passwordController.text.isEmpty){
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Please Enter your password'))
                                      );
                                    }else{
                                      _signInWithEmail();
                                      _emailController.clear();
                                      _passwordController.clear();
                                      _nameController.clear();
                                    }

                                  },
                                  child: Text(
                                    'Sign In',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: MediaQuery.of(context)
                                                .textScaleFactor *
                                            18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.02,
                            ),
                            TextButton(
                                onPressed: _continueAsGuest,
                                child: Text("~ Continue as Guest ~"))
                          ],
                        )
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.1,
                        ),
                        Center(
                            child: Hero(
                          tag: 'login-image',
                          child: Image(
                              image:
                                  AssetImage('assets/images/login-graphic.png'),
                              width: MediaQuery.of(context).size.width * 0.4),
                        )),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Column(
                            children: [
                              Text("Sign Up",
                                  style: GoogleFonts.poppins(
                                    textStyle: TextStyle(
                                      fontSize: MediaQuery.of(context)
                                              .textScaleFactor *
                                          29.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )),
                              Text("Create an account",
                                  style: GoogleFonts.dmSans(
                                      textStyle: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).textScaleFactor *
                                            11.7,
                                  ))),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.03),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.6,
                                      padding: EdgeInsets.only(left: 12),
                                      decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          // boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 1, spreadRadius: 1)],
                                          border: Border.all(),
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: Center(
                                        child: TextField(
                                          controller: _nameController,
                                          style: GoogleFonts.poppins(
                                              color: Colors.black),
                                          decoration: InputDecoration(
                                              labelText: 'Name',
                                              labelStyle: GoogleFonts.poppins(
                                                  color: Color(0xff426D51)),
                                              floatingLabelStyle:
                                                  GoogleFonts.poppins(
                                                      fontSize: 15,
                                                      color: Color(0xff426D51)
                                                          .withOpacity(0.6)),
                                              border: InputBorder.none,
                                              errorBorder: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                        onTap: _pickImage,
                                        child: _imageFile == null
                                            ? Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.2,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.2,
                                                decoration: BoxDecoration(
                                                    color: Color(0xff426D51),
                                                    shape: BoxShape.circle),
                                                child: Center(
                                                    child: Icon(
                                                  Icons.photo,
                                                  color: Colors.white,
                                                )),
                                              )
                                            : Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.2,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.2,
                                                decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    shape: BoxShape.circle,
                                                    image: DecorationImage(
                                                        image: FileImage(
                                                            _imageFile!),
                                                        fit: BoxFit.cover,
                                                        alignment: Alignment
                                                            .topCenter)),
                                              )),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  padding: EdgeInsets.only(left: 12),
                                  decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      // boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 1, spreadRadius: 1)],
                                      border: Border.all(),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Center(
                                    child: TextField(
                                      controller: _emailController,
                                      style: GoogleFonts.poppins(
                                          color: Colors.black),
                                      decoration: InputDecoration(
                                          labelText: 'Email ID',
                                          labelStyle: GoogleFonts.poppins(
                                              color: Color(0xff426D51)),
                                          floatingLabelStyle:
                                              GoogleFonts.poppins(
                                                  fontSize: 15,
                                                  color: Color(0xff426D51)
                                                      .withOpacity(0.6)),
                                          border: InputBorder.none,
                                          errorBorder: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none),
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.03,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  padding: EdgeInsets.only(left: 12),
                                  decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      // boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 1, spreadRadius: 1)],
                                      border: Border.all(),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: TextFormField(
                                    controller: _passwordController,
                                    style: GoogleFonts.poppins(
                                        color: Colors.black),
                                    decoration: InputDecoration(
                                        suffixIcon: InkWell(
                                            onTap: () => setState(() {
                                                  isObscure = !isObscure;
                                                }),
                                            child: isObscure
                                                ? Icon(
                                                    FontAwesome.eye,
                                                    color: Color(0xff426D51),
                                                  )
                                                : Icon(
                                                    FontAwesome.eye_slash,
                                                    color: Color(0xff426D51),
                                                  )),
                                        labelText: 'Password',
                                        labelStyle: GoogleFonts.poppins(
                                            color: Color(0xff426D51)),
                                        floatingLabelStyle: GoogleFonts.poppins(
                                            fontSize: 15,
                                            color: Color(0xff426D51)
                                                .withOpacity(0.6)),
                                        border: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none),
                                    obscureText: isObscure,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.03,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  height:
                                      MediaQuery.of(context).size.height * 0.07,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        backgroundColor: Color(0xff426D51)),
                                    onPressed: (){

                                      if(_nameController.text.isEmpty){
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Please enter your name.'))
                                        );
                                      }else if(_emailController.text.isEmpty){
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Please enter your email"))
                                        );
                                      }else if(_passwordController.text.isEmpty){
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Please enter your password'))
                                        );
                                      }else if(_imageFile.isNull){
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Please upload your Image"))
                                        );
                                      }else{
                                        _signUpWithEmail();
                                        _emailController.clear();
                                        _passwordController.clear();
                                        _nameController.clear();
                                      }

                                    },
                                    child: Text(
                                      'Sign Up',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: MediaQuery.of(context)
                                                  .textScaleFactor *
                                              18,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.03,
                              ),
                              TextButton(
                                  onPressed: () {
                                    setState(() {
                                      isSignIn = true;
                                    });
                                  },
                                  child: Text(
                                    "Already Have an Account? Log In",
                                    style: GoogleFonts.poppins(
                                        fontSize: MediaQuery.of(context)
                                                .textScaleFactor *
                                            12,
                                        fontWeight: FontWeight.w600),
                                  ))
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }
}
