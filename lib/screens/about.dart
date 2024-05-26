import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("About Aayu", style: GoogleFonts.ptSerif(
          textStyle: TextStyle(
            color: Colors.teal,
            fontWeight: FontWeight.w600,
          ),
        )),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Text(
                '"Aayu" is a revolutionary app for identifying medicinal plants and raw materials, addressing the challenge of misidentification and adulteration in Ayurvedic pharmaceutics. Leveraging advanced Image Processing and Machine Learning, "Aayu" ensures the genuineness of resources, offering reliability and transparency throughout the supply chain.',
                style: GoogleFonts.ptSerif(
                  textStyle: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 30),
              Text(
                "What Aayu can Identify?",
                style: GoogleFonts.ptSerif(
                  textStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                    color: Colors.teal,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Aayu, in its initial release version 1.0, has the capability to identify and classify the following 10 classes of medicinal plants: Aloe vera, Amruthabali, Arali, Castor, Mango, Mint, Neem, Sandalwood, and Turmeric.\nAs we continue to train our model with more classes, future updates of Aayu will expand its ability to identify additional medicinal plants and raw materials.',
                style: GoogleFonts.ptSerif(
                  textStyle: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 30),
              Text(
                "What's the Unique Feature?",
                style: GoogleFonts.ptSerif(
                  textStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                    color: Colors.teal,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'The unique feature of Aayu is its community support functionality. With this feature, users can explore various medicinal plants and newly identified plants uploaded by other users. If you find a post helpful, you have the option to give it a like. Additionally, if you have any questions or suggestions regarding a particular post, you can leave a comment for the user who uploaded it. This interactive community platform not only allows users to share their knowledge but also contributes to the enhancement of Aayu\'s identification capabilities by encouraging user contributions.',
                style: GoogleFonts.ptSerif(
                  textStyle: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 30),
              Text(
                "Contributors",
                style: GoogleFonts.ptSerif(
                  textStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                    color: Colors.teal,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Column(
                children: [
                  _buildContributorTile(
                      context, 'assets/yash-min.jpg', 'Yash Soni'),
                  _buildContributorTile(
                      context, 'assets/pooja-min.jpg', 'Pooja Baghel'),
                  _buildContributorTile(
                      context, 'assets/krishna-min.JPG', 'Krishna Jhala'),
                  _buildContributorTile(
                      context, 'assets/noshaba-min.JPG', 'Noshaba Khan'),
                  _buildContributorTile(
                      context, 'assets/ritesh-min.JPG', 'Ritesh Bobade'),
                ],
              ),
              SizedBox(height: 50),
              Center(
                child: Text(
                  "Version 1.0",
                  style: GoogleFonts.ptSerif(
                    textStyle: TextStyle(
                      color: Colors.black.withOpacity(0.4),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContributorTile(BuildContext context, String imagePath, String name) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: AssetImage(imagePath),
      ),
      title: Text(name, style: GoogleFonts.ptSerif(
        textStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      )),
      onTap: () {
        _showContributorDialog(context, imagePath, name);
      },
    );
  }

  void _showContributorDialog(BuildContext context, String imagePath, String name) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundImage: AssetImage(imagePath),
                radius: MediaQuery.of(context).size.width*0.3,
              ),
              SizedBox(height: 20),
              Text(name, style: GoogleFonts.ptSerif(
                textStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              )),
              SizedBox(height: 20),

            ],
          ),
        );
      },
    );
  }
}
