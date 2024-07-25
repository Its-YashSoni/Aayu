import 'package:ayu/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeleteAccountPage extends StatefulWidget {
  @override
  _DeleteAccountPageState createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _deleteAccount() async {
    _isLoading = true;
    final String password = _passwordController.text.trim();

    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('No user is currently signed in.');
      }

      // Reauthenticate user with password
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      // Delete user posts, likes, and comments
      await _deleteUserPosts(user.uid);
      await _deleteUserLikes(user.uid);
      await _deleteUserComments(user.uid);

      // Delete the user's document from the 'users' collection
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

      // Delete the user account
      await user.delete();

      // Navigate to a different page, e.g., login or home
      Navigator.of(context).pushReplacementNamed('/login');
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          _errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'requires-recent-login':
          _errorMessage = 'Please reauthenticate to perform this action.';
          break;
        default:
          _errorMessage = e.message ?? 'An unknown error occurred.';
      }
    } catch (e) {
      _errorMessage = 'Error deleting account: ${e.toString()}';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    _isLoading = false;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage(),));
  }


  Future<void> _deleteUserPosts(String userId) async {
    final postsQuery = FirebaseFirestore.instance.collection('posts').where(
        'userId', isEqualTo: userId);
    final postsSnapshot = await postsQuery.get();

    for (final doc in postsSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _deleteUserLikes(String userId) async {
    final likesQuery = FirebaseFirestore.instance.collection('likes').where(
        'userId', isEqualTo: userId);
    final likesSnapshot = await likesQuery.get();

    for (final doc in likesSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _deleteUserComments(String userId) async {
    final commentsQuery = FirebaseFirestore.instance.collection('comments')
        .where('userId', isEqualTo: userId);
    final commentsSnapshot = await commentsQuery.get();

    for (final doc in commentsSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _confirmDeleteAccount() async {
    // Show confirmation dialog
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete your account? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    // Proceed with account deletion if confirmed
    if (shouldDelete == true) {
      _deleteAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading ? Center(child: CircularProgressIndicator(),)  : SingleChildScrollView(
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
                  Text("Delete Account",
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                          fontSize: MediaQuery.of(context)
                              .textScaleFactor *
                              29.5,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                  Text("Enter password to delete account",
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
                          controller: _passwordController,
                          style: GoogleFonts.poppins(
                              color: Colors.black),
                          decoration: InputDecoration(
                              labelText: 'Enter your Password',
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

                          if(_passwordController.text.isEmpty){
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Please Enter your Password"))
                            );
                          }else{
                            _confirmDeleteAccount();
                            _passwordController.clear();
                          }

                        },
                        child: Text(
                          'Delete Account',
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
