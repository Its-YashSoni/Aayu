import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class PlantInfoPage extends StatelessWidget {
  final String plantName;
  final Map<String, dynamic> plantData;

  PlantInfoPage({
    required this.plantName,
    required this.plantData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: PlantInfoItem(plantData: plantData),
    );
  }
}


class PlantInfoItem extends StatelessWidget {
  final Map<String, dynamic> plantData;

  const PlantInfoItem({required this.plantData, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Stack(alignment: Alignment.bottomCenter, children: [
                Container(
                  width: MediaQuery.of(context).size.width*0.5,
                  height: MediaQuery.of(context).size.height*0.03,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.elliptical(90, 20),
                          bottomLeft: Radius.elliptical(30, 20),
                          topRight: Radius.elliptical(100, 20),
                          bottomRight: Radius.elliptical(30, 20)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 10,
                            blurRadius: 30)
                      ]),
                ),
                Hero(
                  tag: 'plant-${plantData['plantname']}',
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.3,
                    decoration: BoxDecoration(
                      // color: Colors.black,
                        image: DecorationImage(
                            image: NetworkImage(plantData['plantimg']),
                            fit: BoxFit.fitHeight)),
                  ),
                ),
              ]),
              SizedBox(height: MediaQuery.of(context).size.height*0.03,),
              Center(
                child: Text(
                  plantData['plantname'],
                  style: GoogleFonts.poppins(
                      textStyle: TextStyle(
                        fontSize: MediaQuery.of(context).textScaleFactor * 30,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ),
              Center(
                child: Text(
                  'Scientific Name: ' + plantData['scientific_name'],
                  style: GoogleFonts.poppins(
                      textStyle: TextStyle(
                        fontSize: MediaQuery.of(context).textScaleFactor * 11,
                        fontWeight: FontWeight.w400,
                      )),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height*0.04,),


              Text(
                'Description',
                style: GoogleFonts.poppins(
                    fontSize: MediaQuery.of(context).textScaleFactor * 20,
                    fontWeight: FontWeight.w600),
              ),
              SizedBox(height: MediaQuery.of(context).size.height*0.02,),
              Text(
                plantData['plantdescription'],
                textAlign: TextAlign.justify,
                style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontSize: MediaQuery.of(context).textScaleFactor * 11,
                      fontWeight: FontWeight.w400,
                    )),
              ),
              SizedBox(height: MediaQuery.of(context).size.height*0.03,),
              Text(
                'Benifits',
                style: GoogleFonts.poppins(
                    fontSize: MediaQuery.of(context).textScaleFactor * 20,
                    fontWeight: FontWeight.w600),
              ),
              SizedBox(height: MediaQuery.of(context).size.height*0.02,),
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    (plantData['healthbenifits'] as List<dynamic>).length,
                    (index) {
                      return Text(
                        '${index+1}. ${(plantData['healthbenifits'] as List<dynamic>)[index]}\n',
                        textAlign: TextAlign.justify,
                        style: GoogleFonts.poppins(
                          fontSize: MediaQuery.of(context).textScaleFactor * 11
                        ),
                      );
                    },
                  )),

              SizedBox(height: MediaQuery.of(context).size.height*0.1,)
            ],
          ),
        ),
      ),
    );
  }
}
