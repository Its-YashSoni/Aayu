import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'plantinfo.dart';
import 'allplants.dart';

class Home extends StatefulWidget {
  final bool isGuest;

  Home({required this.isGuest, Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final user = FirebaseAuth.instance.currentUser;
  bool isDay = true;
  String temperature = '';
  String weatherType = '';
  String location = 'Bhopal';
  String searchQuery = '';
  List<Map<String, dynamic>> plantDataList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWeatherData();
    determineTimeOfDay();
    fetchPlantData();
  }

  void determineTimeOfDay() {
    DateTime now = DateTime.now();
    int hour = now.hour;

    // Assuming day time is between 6:00 AM and 6:00 PM
    setState(() {
      isDay = (hour >= 6 && hour < 18);
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
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('plantsinfo').get();
      setState(() {
        plantDataList = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
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
      return plantDataList.take(4).toList();
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
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.fill,
          opacity: 0.2,
          image: NetworkImage(
            'https://i.pinimg.com/236x/27/ea/19/27ea19fbd4e3de3d15e4bb06ce6e9fc4.jpg',
          ),
        ),
      ),
      child: Column(
        children: [
          // Header section
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.fill,
                image: isDay
                    ? AssetImage('assets/day.gif')
                    : AssetImage('assets/night.gif'),
              ),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(50),
                bottomLeft: Radius.circular(50),
              ),
            ),
            child: Column(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Scaffold.of(context).openDrawer(),
                          child: CircleAvatar(
                            child: Icon(
                              Icons.menu,
                              size: MediaQuery.of(context).size.width * 0.08,
                            ),
                            backgroundColor:
                            isDay ? Colors.green : Colors.white,
                            foregroundColor:
                            isDay ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          "Hello, ${widget.isGuest ? "Guest" : (user?.displayName ?? "")}",
                          style: GoogleFonts.ptSerif(
                            textStyle: TextStyle(
                              fontSize: 20,
                              color: isDay ? Colors.black : Colors.white,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.04,
                ),
                Text(
                  "${location}",
                  style: GoogleFonts.ptSerif(
                    textStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  "${temperature}",
                  style: GoogleFonts.ptSerif(
                    textStyle: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: MediaQuery.of(context).size.height * 0.03,
                  decoration: BoxDecoration(
                    color: isDay ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      "${weatherType}",
                      style: GoogleFonts.ptSerif(
                        textStyle: TextStyle(
                          color: isDay ? Colors.white : Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 20.0),
            child: Container(
              width: MediaQuery.of(context).size.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 3,
                          spreadRadius: 1,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: MediaQuery.of(context).size.width * 0.07,
                      child: Icon(Icons.search),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Explore section
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Explore",
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => ViewAll()));
                  },
                  child: Text(
                    "View all",
                    style: GoogleFonts.poppins(
                      textStyle: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Plant containers
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.3,
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: getFilteredPlantInfo().length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  Map<String, dynamic> plant = getFilteredPlantInfo()[index];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlantInfoPage(
                              plantName: plant['plantname'].toString(),
                              plantData: plant,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: MediaQuery.of(context).size.height * 0.01,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 3,
                              spreadRadius: 1,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(25),
                                topRight: Radius.circular(25),
                              ),
                              child: Image.network(
                                plant['plantimg'].toString(),
                                height: MediaQuery.of(context).size.height * 0.2,
                                width: MediaQuery.of(context).size.width * 0.5,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              plant['plantname'].toString(),
                              style: GoogleFonts.poppins(
                                textStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
