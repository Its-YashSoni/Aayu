import 'dart:io';

import 'package:ayu/screens/homepage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';

class ClassificationScreen extends StatefulWidget {
  final List<dynamic> predictions;
  final File image;
  final bool isGuest;
  ClassificationScreen({required this.predictions, required this.image , required this.isGuest , Key? key}) : super(key: key);

  @override
  State<ClassificationScreen> createState() => _ClassificationScreenState();
}

class _ClassificationScreenState extends State<ClassificationScreen> {
  Map<String, dynamic>? _plantDetails;


  @override
  void initState() {
    super.initState();
    fetchPlantDetails();
  }


  Future<void> fetchPlantDetails() async {
    String plantName = widget.predictions[0]['label'];
    try {
      DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await FirebaseFirestore.instance
              .collection('plantsinfo')
              .doc(plantName)
              .get();

      if (docSnapshot.exists) {
        setState(() {
          _plantDetails = docSnapshot.data();
        });
      } else {
        print('No plant details found for $plantName');
      }
    } catch (e) {
      print('Error fetching plant details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        children: [

          Stack(
            children:[
              Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height*0.4,
              decoration: BoxDecoration(
                image: DecorationImage(image: FileImage(widget.image), fit: BoxFit.fill),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(30),
                  bottomLeft: Radius.circular(30)
                )
              ),
            ),

              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height*0.4,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black, Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter
                    ),
                    borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(30),
                        bottomLeft: Radius.circular(30)
                    )
                ),
              ),

              SafeArea(child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: ()=> Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage(isGuest: false),)),
                      child: Icon(Icons.arrow_back_outlined, color: Colors.white,),
                    ),
                    InkWell(
                      onTap: () => _onActionSheetPress(context),
                      child: Icon(Icons.translate, color: Colors.white,),
                    ),
                  ],
                ),
              ), )
          ]),

          SizedBox(height: MediaQuery.of(context).size.height*0.02,),
          
          Expanded(
            child: Container(
              child: SingleChildScrollView(
                child: Column(

                  children: [
                    Text(
                      '${widget.predictions[0]['label'].toString().toUpperCase() ?? ""}',
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                          fontSize: MediaQuery.of(context).textScaleFactor *30 ,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text("${_plantDetails?['scientific_name']??""}", style: GoogleFonts.poppins(
                      fontSize: MediaQuery.of(context).textScaleFactor * 15
                    ),),
                
                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),

                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                            "Plant Description",
                              style: GoogleFonts.poppins(
                                textStyle: TextStyle(
                                  color: Colors.black,
                                  fontSize: MediaQuery.of(context).textScaleFactor *20,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                            _plantDetails != null
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        textAlign: TextAlign.justify,
                                        '${_plantDetails?['plantdescription']??""}',
                                        style: GoogleFonts.poppins(
                                          textStyle: TextStyle(
                                            color: Colors.black,
                                            fontSize: MediaQuery.of(context).textScaleFactor * 13,
                                            fontWeight: FontWeight.w300
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Loading plant details...',
                                    style: GoogleFonts.ptSerif(
                                      textStyle: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.05),
                            Text(
                              "Health Benefits",
                              style: GoogleFonts.poppins(
                                textStyle: TextStyle(
                                  color: Colors.black,
                                  fontSize: MediaQuery.of(context).textScaleFactor *20,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                            _plantDetails != null &&
                                    _plantDetails?['healthbenifits'] != null
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: List.generate(
                                      _plantDetails?['healthbenifits'].length,
                                      (index) => Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '\u2022 ${_plantDetails?['healthbenifits'][index]??""}',
                                            textAlign: TextAlign.justify,
                                            style: GoogleFonts.poppins(
                                              textStyle: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: MediaQuery.of(context).textScaleFactor * 13,
                                                  fontWeight: FontWeight.w300
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: MediaQuery.of(context).size.height*0.02),
                                        ],
                                      ),
                                    ),
                                  )
                                : Text(
                                        'Loading Health Benefits...',
                                    style: GoogleFonts.ptSerif(
                                      textStyle: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),

                            SizedBox(
                                height: MediaQuery.of(context).size.height * 0.05),

                            Text(
                              "Note",
                              style: GoogleFonts.poppins(
                                textStyle: TextStyle(
                                  color: Colors.black,
                                  fontSize: MediaQuery.of(context).textScaleFactor *20,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                            Text(
                              "According to our model we are ${(widget.predictions[0]['confidence'] * 100).toStringAsFixed(2)} % Confident the Predicted image is ${widget.predictions[0]['label'].toString()}",
                              textAlign: TextAlign.justify,
                              style: GoogleFonts.poppins(
                                textStyle: TextStyle(
                                    color: Colors.black,
                                    fontSize: MediaQuery.of(context).textScaleFactor * 13,
                                    fontWeight: FontWeight.w300
                                ),
                              ),
                            ),

                            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onActionSheetPress(BuildContext context) {
    showCupertinoModalPopup<String>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text('Select Language'),
        actions: <Widget>[
          CupertinoActionSheetAction(
            child: Text('English'),
            onPressed: () {
              setState(() {

              });
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: Text('Hindi'),
            onPressed: () {
              setState(() {

              });
              Navigator.pop(context);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text('Cancel'),
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
        ),
      ),
    ).then((String? value) {});
  }

}
