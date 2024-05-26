import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';

class ClassificationScreen extends StatefulWidget {
  final List<dynamic> predictions;

  ClassificationScreen({required this.predictions, Key? key}) : super(key: key);

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
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: () => _onActionSheetPress(context),
              child: Icon(Icons.translate),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.predictions[0]['label']}',
                      style: GoogleFonts.ptSerif(
                        textStyle: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text("Scientific Name"),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    Text(
                      "${"Confidence Score:"}\t\t${(widget.predictions[0]['confidence'] * 100).toStringAsFixed(2)} %",
                      style: GoogleFonts.ptSerif(
                        textStyle: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    )
                  ],
                ),
                CircleAvatar(
                  radius: MediaQuery.of(context).size.width * 0.12,
                  backgroundImage: _plantDetails != null
                      ? NetworkImage('${_plantDetails!['plantimg']}')
                      : null,
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            Expanded(
              child: Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(35),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                        "Plant Description",
                          style: GoogleFonts.ptSerif(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        _plantDetails != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    textAlign: TextAlign.justify,
                                    '${_plantDetails!['plantdescription']}',
                                    style: GoogleFonts.ptSerif(
                                      textStyle: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
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
                          style: GoogleFonts.ptSerif(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        _plantDetails != null &&
                                _plantDetails!['healthbenifits'] != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List.generate(
                                  _plantDetails!['healthbenifits'].length,
                                  (index) => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '\u2022 ${_plantDetails!['healthbenifits'][index]}',
                                        textAlign: TextAlign.justify,
                                        style: GoogleFonts.ptSerif(
                                          textStyle: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 5),
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
