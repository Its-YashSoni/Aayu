
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_flutter/icons_flutter.dart';


class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _emailController = TextEditingController();

  Future<void> _forgotPassword() async {
    String email = _emailController.text.trim();
    String errorMessage = '';

    setState(() {
      _isLoading = true;
    });


    try {
      if (email.isEmpty) {
        throw Exception('Please enter your email address.');
      }

      // Send password reset email
      await _auth.sendPasswordResetEmail(email: email);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent. Please check your inbox.'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        default:
          errorMessage = e.message ?? 'An unknown error occurred.';
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
          content: Text('Error sending password reset email: ${e.toString()}'),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
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
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                children: [
                  Text("Forgot Password",
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                          fontSize: MediaQuery.of(context)
                              .textScaleFactor *
                              29.5,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                  Text("Get Reset Password link to your mail",
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

                  SizedBox(height: MediaQuery.of(context).size.height*0.04,),

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
                          }else{
                            _forgotPassword();
                            _emailController.clear();
                          }

                        },
                        child: Text(
                          'Send Link',
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

                ],
              ),
            )
          ],
        ),

      ),
    );
  }
}
