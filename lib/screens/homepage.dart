import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:ayu/controller/scan_controller.dart';
import 'package:ayu/main_weather.dart';
import 'package:ayu/screens/Settings.dart';
import 'package:ayu/screens/about.dart';
import 'package:ayu/screens/community.dart';
import 'package:ayu/screens/custom_camera.dart';
import 'package:ayu/screens/login_screen.dart';
import 'package:ayu/screens/profile.dart';
import 'package:ayu/screens/weather_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'classification.dart';
import 'plantinfo.dart';
import 'allplants.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

class HomePage extends StatefulWidget {
  final bool isGuest;

  HomePage({required this.isGuest, Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ScanController controller = ScanController();

  late var user = FirebaseAuth.instance.currentUser;


  bool isDay = true;
  String temperature = '';
  String weatherType = '';
  String location = 'Bhopal';
  String searchQuery = '';
  List<Map<String, dynamic>> plantDataList = [];
  bool isLoading = false;
  bool isloading = false;
  double value = 0.0;
  String Category = 'Explore Plants';
  String _image = '';
  var _recognitions;
  var v = "";

  var _name;
  var _email;
  var _profilePicUrl;


  @override
  void initState() {
    super.initState();
    setState(() {
      isloading = true;
    });
    fetchWeatherData();
    determineTimeOfDay();
    fetchPlantData();
    loadmodel().then((value) {
      setState(() {});
    });

    user?.reload();
    setState(() {
      user = FirebaseAuth.instance.currentUser;
    });
    setState(() {
      isloading = false;
    });
    fetchData();
    print('Every thing is loaded');
    print("User data : ${user}");
  }

  void fetchData() async {
    try {
      // Fetch user data
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();

      // Fetch user posts
      setState(() {
        _name = userData['displayName'];
        _email = userData['email'];
        _profilePicUrl = userData['photoURL'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile data: $e')),
      );
    }
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
            builder: (context) => ClassificationScreen(
              predictions: _recognitions,
              image: image,
              isGuest: widget.isGuest,
            ),
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
    // final pickedFile = await _picker.pickImage(
    //   source: ImageSource.camera,
    //   imageQuality: 50,
    // );
    // if (pickedFile != null) {
    //   setState(() {
    //     _image = pickedFile.path;
    //   });
    //   await _classifyImage(File(_image));
    // }
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomCameraScreen(
            isGuest: widget.isGuest,
          ),
        ));
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

  Future<void> onRefresh() async {
    await fetchPlantData();
    await fetchWeatherData();
    return;
  }

  void determineTimeOfDay() {
    DateTime now = DateTime.now();
    int hour = now.hour;
    // Assuming day time is between 6:00 AM and 6:00 PM
    setState(() {
      isDay = (hour >= 6 && hour < 20);
    });
  }

  Future<void> fetchWeatherData() async {
    final apiKey = '8810a0a1c6e61c7ff6b519d6890c1a1b';
    final city = 'Bhopal';
    final apiUrl =
        'http://api.openweathermap.org/data/2.5/weather?q=${city}&appid=${apiKey}';
    try {
      http.Response response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          temperature = '${(data['main']['temp'] - 273.15).round()} °C';
          weatherType = data['weather'][0]['main'];
        });
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> fetchPlantData() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('plantsinfo').get();
      setState(() {
        plantDataList = querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching plant data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> getFilteredPlantInfo() {
    if (searchQuery.isEmpty) {
      // Show only the first four items when no search query is entered
      return plantDataList.toList();
    } else {
      // Filter plantinfo based on the search query
      return plantDataList.where((plant) {
        String plantName = plant['plantname'].toString().toLowerCase();
        return plantName.contains(searchQuery.toLowerCase());
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      tileMode: TileMode.mirror,
                      colors: [
                        Color(0xff426D51).withOpacity(0.6),
                        Color(0xff426D51).withOpacity(0.7),
                        Color(0xff426D51).withOpacity(1)
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter)),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  value == 0 ? value = 1 : value = 0;
                });
              },
              child: SafeArea(
                  child: Container(
                width: MediaQuery.of(context).size.width * 0.6,
                padding: EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    DrawerHeader(
                        child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          widget.isGuest
                              ? CircleAvatar(
                                  radius: 50.0,
                                  backgroundImage:
                                      AssetImage('assets/images/guest.png'),
                                )
                              : CircleAvatar(
                                  radius: 50.0,
                                  backgroundImage:
                                      NetworkImage(_profilePicUrl.toString(),),
                                ),
                          SizedBox(
                            height: 10.0,
                          ),
                          Text(
                            widget.isGuest ? 'Welcome Guest' :user!.email.toString().split(' ').first,
                            style: GoogleFonts.poppins(
                                textStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        MediaQuery.of(context).textScaleFactor *
                                            10)),
                          ),
                        ],
                      ),
                    )),
                    Expanded(
                        child: ListView(
                      children: [
                        ListTile(
                          onTap: () {
                            setState(() {
                              value == 0 ? value = 1 : value = 0;
                            });
                          },
                          leading: Icon(
                            FontAwesome.home,
                            color: Colors.white,
                          ),
                          title: Text(
                            "Home",
                            style: GoogleFonts.poppins(
                                textStyle: TextStyle(
                                    shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                  )
                                ],
                                    color: Colors.white,
                                    fontSize:
                                        MediaQuery.of(context).textScaleFactor *
                                            25)),
                          ),
                        ),
                        ListTile(
                          onTap: () {
                            widget.isGuest ? ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("You are in Guest Mode"))
                            ) :
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(userId: user!.uid),));
                          },
                          leading: Icon(
                            Icons.person,
                            color: Colors.white,
                          ),
                          title: Text(
                            "Profile",
                            style: GoogleFonts.poppins(
                                textStyle: TextStyle(
                                    shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                  )
                                ],
                                    color: Colors.white,
                                    fontSize:
                                        MediaQuery.of(context).textScaleFactor *
                                            25)),
                          ),
                        ),
                        ListTile(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => AboutScreen(),));
                          },
                          leading: Icon(
                            FontAwesome.info,
                            color: Colors.white,
                          ),
                          title: Text(
                            "About Us",
                            style: GoogleFonts.poppins(
                                textStyle: TextStyle(
                                    shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                  )
                                ],
                                    color: Colors.white,
                                    fontSize:
                                        MediaQuery.of(context).textScaleFactor *
                                            25)),
                          ),
                        ),

                        ListTile(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage(),));
                          },
                          leading: Icon(
                            FontAwesome.gear,
                            color: Colors.white,
                          ),
                          title: Text(
                            "Settings",
                            style: GoogleFonts.poppins(
                                textStyle: TextStyle(
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                      )
                                    ],
                                    color: Colors.white,
                                    fontSize:
                                    MediaQuery.of(context).textScaleFactor *
                                        25)),
                          ),
                        ),
                        ListTile(
                          onTap: () {
                            FirebaseAuth.instance.signOut();
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage(),));
                          },
                          leading: Icon(
                            FontAwesome.power_off,
                            color: Colors.white,
                          ),
                          title: Text(
                            "Log Out",
                            style: GoogleFonts.poppins(
                                textStyle: TextStyle(
                                    shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                  )
                                ],
                                    color: Colors.white,
                                    fontSize:
                                        MediaQuery.of(context).textScaleFactor *
                                            25)),
                          ),
                        ),
                      ],
                    ))
                  ],
                ),
              )),
            ),
            TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: value ),
                duration: Duration(milliseconds: 500),
                curve: Curves.easeIn,
                builder: (_, double val, __) {
                  return (Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..setEntry(0, 3, 250 * val)
                      ..rotateY((pi / 6) * val),
                    child: buildScreen(),
                  ));
                })
          ],
        ));
  }

  Widget buildScreen() {
    return isloading ? Center(child: CircularProgressIndicator(),) :ClipRRect(
      borderRadius: value == 0
          ? BorderRadius.zero
          : BorderRadius.only(
              topLeft: Radius.circular(50), bottomLeft: Radius.circular(50)),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: RefreshIndicator(
          onRefresh: onRefresh,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  // height: MediaQuery.of(context).size.height * 0.70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(60),
                        bottomRight: Radius.circular(60)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SafeArea(
                            child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                                onTap: () {
                                  setState(() {
                                    value == 0 ? value = 1 : value = 0;
                                  });
                                },
                                child: Icon(Icons.menu)),
                            Text(
                              "Hello ${widget.isGuest ? 'Guest' : _name.toString().split(' ').first}",
                              style: GoogleFonts.poppins(
                                  fontSize:
                                      MediaQuery.of(context).textScaleFactor *
                                          20,
                                  fontWeight: FontWeight.w500),
                            ),
                            InkWell(
                                onTap: () async => await Permission
                                        .location.isGranted
                                    ? Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MainApp(),
                                        ))
                                    : ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                            content: Text(
                                                "Please Enable location Permission First 📍"))),
                                child: Icon(Icons.cloud_outlined)),
                          ],
                        )),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02,
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 0.065,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                spreadRadius: 0,
                              )
                            ],
                          ),
                          padding: EdgeInsets.all(8.0),
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: "Search",
                              hintStyle: TextStyle(
                                  color: Colors.black.withOpacity(0.3)),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              suffixIcon: Icon(
                                Icons.search,
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.02),
                        _buildCategorySelector(),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04),
                        Category == 'Explore Plants'
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Featured Plants",
                                    style: GoogleFonts.poppins(
                                        textStyle: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .textScaleFactor *
                                                15,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.02),
                                  Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: MediaQuery.of(context).size.height * 0.32,
                                    child: isLoading
                                        ?  Center(
                                            child: CircularProgressIndicator())
                                        : getFilteredPlantInfo().length == 0
                                        ?  Center(child: Text("Sorry! Plant not found,\nWe are working on it.", textAlign: TextAlign.center,style: GoogleFonts.poppins(
                                      fontSize: MediaQuery.of(context).textScaleFactor *15,
                                      fontWeight: FontWeight.w500
                                    ),), )
                                        : ListView.builder(
                                            itemCount:
                                                getFilteredPlantInfo().length,
                                            scrollDirection: Axis.horizontal,
                                            itemBuilder: (context, index) {
                                              Map<String, dynamic> plant =
                                                  getFilteredPlantInfo()[index];
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: GestureDetector(
                                                  onTap: () => Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            PlantInfoPage(
                                                                plantName: plant[
                                                                    'plantname'],
                                                                plantData:
                                                                    plant),
                                                      )),
                                                  child: Container(
                                                    height:
                                                        MediaQuery.of(context)
                                                            .size
                                                            .height,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.4,
                                                    decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                    0.1),
                                                            blurRadius: 5,
                                                            spreadRadius: 5,
                                                          )
                                                        ],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12)),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        Stack(
                                                          alignment: Alignment
                                                              .bottomCenter,
                                                          children: [
                                                            CircleAvatar(
                                                              radius: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  0.10,
                                                              backgroundColor:
                                                                  Color(
                                                                      0xff426D51),
                                                            ),
                                                            Hero(
                                                              tag:
                                                                  'plant-${plant['plantname']}',
                                                              child:
                                                                  Image.network(
                                                                plant['plantimg']
                                                                        .toString() ??
                                                                    '',
                                                                width: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.34,
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                        Text(
                                                          plant['plantname'] ??
                                                              '',
                                                          style: GoogleFonts
                                                              .poppins(
                                                            textStyle:
                                                                TextStyle(
                                                              color:
                                                                  Colors.black,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: MediaQuery.of(
                                                                          context)
                                                                      .textScaleFactor *
                                                                  15,
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 6.0,
                                                                  right: 6.0),
                                                          child: Text(
                                                            plant['tagline'] ??
                                                                '',
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: GoogleFonts
                                                                .poppins(
                                                              textStyle:
                                                                  TextStyle(
                                                                fontSize: MediaQuery.of(
                                                                            context)
                                                                        .textScaleFactor *
                                                                    6,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .height *
                                                              0.02,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  GestureDetector(
                                    onTap: () async => await Permission
                                            .camera.isGranted
                                        ? _imgFromCamera()
                                        : ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    "Please Enable Camera Permission"))),
                                    child: Container(
                                      width: MediaQuery.of(context).size.width,
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.15,
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.grey,
                                                blurRadius: 2,
                                                spreadRadius: 0)
                                          ],
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: Transform.scale(
                                          scale: 0.7,
                                          child: Image.asset(
                                              'assets/images/click.png')),
                                    ),
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.02,
                                  ),
                                  GestureDetector(
                                    onTap: () async => await Permission
                                            .photos.isGranted
                                        ? _imgFromGallery()
                                        : ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    "Please enable Storage Permission"))),
                                    child: Container(
                                      width: MediaQuery.of(context).size.width,
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.15,
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.grey,
                                                blurRadius: 2,
                                                spreadRadius: 0)
                                          ],
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: Transform.scale(
                                          scale: 0.7,
                                          child: Image.asset(
                                              'assets/images/select.png')),
                                    ),
                                  )
                                ],
                              )
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    // height: MediaQuery.of(context).size.height * 0.4,
                    child: Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02,
                        ),
                        Text(
                          "Wondering About Your Plant’s Details?",
                          style: GoogleFonts.poppins(
                              textStyle: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      MediaQuery.of(context).textScaleFactor *
                                          15,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Lottie.asset('assets/scan.json',
                            width: MediaQuery.of(context).size.width * 0.4),
                        Text(
                          "Scan It!",
                          style: GoogleFonts.poppins(
                              textStyle: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      MediaQuery.of(context).textScaleFactor *
                                          30,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Text(
                          "And instantly Know Your Plant",
                          style: GoogleFonts.poppins(
                              textStyle: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      MediaQuery.of(context).textScaleFactor *
                                          12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 30.0, right: 30.0, top: 20.0, bottom: 20.0),
                  child: Divider(
                    thickness: 0.5,
                    color: Colors.grey,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    "Our Services",
                    style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                            color: Colors.white,
                            fontSize:
                                MediaQuery.of(context).textScaleFactor * 15,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                OurServices(),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.05,
                ),
                Center(
                  child: Text(
                    'Version 2.0',
                    style: GoogleFonts.caveat(
                        textStyle: TextStyle(
                            color: Colors.grey,
                            fontSize:
                                MediaQuery.of(context).textScaleFactor * 20)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget OurServices() {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.14,
        // color: Colors.white,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () => widget.isGuest
                      ? ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Please Sign In first 😊")))
                  // : ScaffoldMessenger.of(context).showSnackBar(
                  //     SnackBar(content: Text("Having Some issue in Community!"))),
                      : Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                Community(isGuest: widget.isGuest),
                          )),
                  child: Stack(alignment: Alignment.bottomLeft, children: [
                    Container(
                        width: MediaQuery.of(context).size.width * 0.6,
                        height: MediaQuery.of(context).size.height * 0.1,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  blurRadius: 5,
                                  spreadRadius: 2)
                            ]),
                        child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 20.0),
                              child: Text(
                                "Community\nSupport",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                    textStyle: TextStyle(
                                        fontSize: MediaQuery.of(context)
                                                .textScaleFactor *
                                            15,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ))),
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0, bottom: 10.0),
                      child: Image.asset('assets/images/community.png',
                          height: MediaQuery.of(context).size.height),
                    )
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () =>
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                      "Coming Soon 🤩",
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Color(0xff426D51),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  )),
                  child: Stack(alignment: Alignment.bottomLeft, children: [
                    Container(
                        width: MediaQuery.of(context).size.width * 0.6,
                        height: MediaQuery.of(context).size.height * 0.1,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  blurRadius: 5,
                                  spreadRadius: 2)
                            ]),
                        child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 20.0),
                              child: Text(
                                "Chat with Expert\n(Coming soon)",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                    textStyle: TextStyle(
                                        fontSize: MediaQuery.of(context)
                                                .textScaleFactor *
                                            13,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ))),
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0, bottom: 10.0),
                      child: Image.asset('assets/images/expert.png',
                          height: MediaQuery.of(context).size.height),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Obx(() {
      return Container(
          width: MediaQuery.of(context).size.width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: controller
                .getCategoriesForSelectedSupplier()
                .map((_Category) => _buildCategoryButton(_Category))
                .toList(),
          ));
    });
  }

  Widget _buildCategoryButton(String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          TextButton(
            style: ButtonStyle(
              surfaceTintColor: WidgetStateColor.transparent,
              shadowColor: WidgetStateColor.transparent,
              backgroundColor: WidgetStateColor.transparent,
              overlayColor: WidgetStateColor.transparent,
            ),
            onPressed: () {
              controller.selectCategory(category);
              setState(() {
                Category = category;
              });
            },
            child: Row(
              children: [
                Icon(
                  category == 'Explore Plants'
                      ? FontAwesome.leaf
                      : Icons.camera_alt_outlined,
                  size: MediaQuery.of(context).size.width * 0.05,
                  color: controller.selectedScan.value == category
                      ? Colors.black
                      : Colors.grey,
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                Text(
                  category,
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontSize: MediaQuery.of(context).textScaleFactor * 12,
                      fontWeight: FontWeight.w600,
                      color: controller.selectedScan.value == category
                          ? Colors.black
                          : Colors.grey,
                    ),
                  ),
                )
              ],
            ),
          ),
          Container(
            height: 2,
            width: category.length * 8.0 +
                MediaQuery.of(context).textScaleFactor *
                    14, // Adjust width based on text length
            color: controller.selectedScan.value == category
                ? Color(0xff426D51)
                : Colors.transparent,
          ),
        ],
      ),
    );
  }
}
