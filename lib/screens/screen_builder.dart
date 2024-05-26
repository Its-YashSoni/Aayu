import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'Home.dart';
import 'community.dart';
import 'package:ayu/constraints.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'about.dart';
import 'classification.dart';
import 'login_screen.dart';
import 'profile.dart';

class ScreenBuilder extends StatefulWidget {
  final bool isGuest;

  ScreenBuilder({required this.isGuest});

  @override
  State<ScreenBuilder> createState() => _ScreenBuilderState();
}

class _ScreenBuilderState extends State<ScreenBuilder> {
  String _image = '';
  bool currentIndex = true;
  int index = 0;
  late List<Widget> screens;
  final user = FirebaseAuth.instance.currentUser;
  var _recognitions;
  var v = "";
  bool isloading = false;
  late Future<void> _initializeControllerFuture;
  late CameraController _controller;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
    screens = [
      Home(
        isGuest: widget.isGuest,
      ),
      Community(isGuest: widget.isGuest),
    ];
    loadmodel().then((value) {
      setState(() {});
    });
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras[0];

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );

    return _controller.initialize();
  }

  loadmodel() async {
    try {
      await Tflite.loadModel(
          model: "assets/model(updated).tflite",
          labels: "assets/labels(updated).txt");
      print("Model Loaded Successfully");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _classifyImage(File image) async {
    setState(() {
      isloading = true;
    });
    int startTime = new DateTime.now().millisecondsSinceEpoch;
    try {
      var recognitions = await Tflite.runModelOnImage(
          path: image.path,
          numResults: 6,
          threshold: 0.05,
          imageMean: 127.5,
          imageStd: 127.5);
      if (recognitions != null && recognitions.isNotEmpty) {
        setState(() {
          _recognitions = recognitions;
          v = recognitions.toString();
        });
        print("///////////////////////////////////////////////");
        print(_recognitions);
        print("///////////////////////////////////////////////");
        int endTime = new DateTime.now().millisecondsSinceEpoch;
        print("inference Took ${endTime - startTime}ms");
        setState(() {
          isloading = false;
        });
        if (_recognitions[0]['label'] == 'Unknown') {
          // Show dialog
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Unknown Detected'),
                content: Text('Model upgrade in progress'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                ClassificationScreen(predictions: _recognitions),
          ));
        }
      }
    } catch (e) {
      setState(() {
        isloading = false;
      });
      print("error classifying image: $e");
    }
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Photo Library'),
                onTap: () {
                  _imgFromGallery();
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _imgFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _imgFromCamera() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile.path;
      });
      await _classifyImage(File(_image));
    }
  }

  void _imgFromGallery() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile.path;
      });
      await _classifyImage(File(_image));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerScreen(
        isGuest: widget.isGuest,
      ),
      backgroundColor: kBackgroundColor,
      resizeToAvoidBottomInset: false,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: MediaQuery.of(context).size.width * 0.20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
                color: kPrimaryColor.withOpacity(0.7),
                blurRadius: 8,
                spreadRadius: 0)
          ],
        ),
        child: FittedBox(
          child: FloatingActionButton(
            onPressed: () => _showPicker(context),
            child: Icon(
              Icons.camera_alt,
              size: 35,
            ),
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            shape: CircleBorder(),
            elevation: 0,
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: MediaQuery.of(context).size.height * 0.09,
        color: Colors.black,
        surfaceTintColor: Colors.transparent,
        notchMargin: 5.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  currentIndex = true;
                  index = 0;
                });
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home,
                    size: MediaQuery.of(context).size.width * 0.07,
                    color: currentIndex ? kPrimaryColor : Colors.white,
                  ),
                  Text(
                    "Home",
                    style: TextStyle(
                      fontSize: 12,
                      color: currentIndex ? kPrimaryColor : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.2,
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  currentIndex = false;
                  index = 1;
                });
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.groups,
                    size: MediaQuery.of(context).size.width * 0.07,
                    color: currentIndex ? Colors.white : kPrimaryColor,
                  ),
                  Text(
                    "Community",
                    style: TextStyle(
                      fontSize: 12,
                      color: currentIndex ? Colors.white : kPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: isloading
          ? Center(child: CircularProgressIndicator())
          : screens[index],
    );
  }
}

class DrawerScreen extends StatefulWidget {
  final bool isGuest;

  DrawerScreen({required this.isGuest});

  @override
  State<DrawerScreen> createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  var user = FirebaseAuth.instance.currentUser;
  final FirebaseAuth auth = FirebaseAuth.instance;

  signOut() async {
    await auth.signOut();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.7,
      child: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.25,
            decoration: BoxDecoration(
              color: kPrimaryColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircleAvatar(
                  radius: MediaQuery.of(context).size.width * 0.1,
                  backgroundImage: widget.isGuest || user == null
                      ? AssetImage('assets/logo.png')
                      : NetworkImage('${user!.photoURL}'),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.isGuest ? "Guest" : "${user!.displayName}",
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      widget.isGuest || user == null
                          ? "not Required"
                          : "${user!.email}",
                      style: TextStyle(color: Colors.white),
                    )
                  ],
                )
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
              if (widget.isGuest) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Can't open in Guest mode")),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ProfilePage(userId: user!.uid)),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.person),
                  Text(
                    "Profile",
                    style: GoogleFonts.poppins(
                      textStyle:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.2,
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.black26)
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AboutScreen(),
                  ));
            },
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.info),
                  Text(
                    "About",
                    style: GoogleFonts.poppins(
                      textStyle:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.2,
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.black26)
                ],
              ),
            ),
          ),
          InkWell(
            onTap: signOut,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.logout),
                  Text(
                    "Logout",
                    style: GoogleFonts.poppins(
                      textStyle:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.2,
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.black26,
                  )
                ],
              ),
            ),
          ),
          Expanded(child: SizedBox()),
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Text(
              "@Designed & Developed by Team Aayu",
              style:
                  TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 12),
            ),
          )
        ],
      ),
    );
  }
}
