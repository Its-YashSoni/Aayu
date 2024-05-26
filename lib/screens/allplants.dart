import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ayu/screens/plantinfo.dart';

class ViewAll extends StatefulWidget {
  const ViewAll({Key? key}) : super(key: key);

  @override
  State<ViewAll> createState() => _ViewAllState();
}

class _ViewAllState extends State<ViewAll> {
  String searchQuery = '';
  List<Map<String, dynamic>> plantDataList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPlantData();
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
      return plantDataList;
    } else {
      return plantDataList.where((plant) {
        String plantName = plant['plantname'].toString().toLowerCase();
        return plantName.contains(searchQuery.toLowerCase());
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: TextField(
          cursorColor: Colors.white,
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search plants...',
            hintStyle: TextStyle(color: Colors.white),
            border: InputBorder.none,
          ),
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black, // Change color as needed
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2 / 2.2,
                ),
                itemCount: getFilteredPlantInfo().length,
                scrollDirection: Axis.vertical,
                itemBuilder: (context, index) {
                  Map<String, dynamic> plant = getFilteredPlantInfo()[index];
                  return Padding(
                    padding: const EdgeInsets.all(5.0),
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
