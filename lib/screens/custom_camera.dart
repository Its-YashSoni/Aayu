import 'dart:io';

import 'package:ayu/screens/homepage.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_v2/tflite_v2.dart';

import 'classification.dart';

class CustomCameraScreen extends StatefulWidget {
  late bool isGuest;
  CustomCameraScreen({required this.isGuest, super.key});
  @override
  _CustomCameraScreenState createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> {
  CameraController? controller;
  List<CameraDescription>? cameras;
  bool isCameraInitialized = false;
  String _image = '';
  var _recognitions;
  var v = "";
  bool isloading = false;
  late BuildContext _context;
  bool isFlashon = false;
  bool isFrontCamera = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _flipCamera() async {
    setState(()  {
      isFrontCamera = !isFrontCamera;
    });
    await _initializeCamera();
  }

  Future<void> _toggleFlash() async {
    if (controller != null && controller!.value.flashMode != FlashMode.torch) {
      await controller!.setFlashMode(FlashMode.torch);
      setState(() {
        isFlashon = true;
      });
    } else {
      await controller!.setFlashMode(FlashMode.off);
      setState(() {
        isFlashon = false;
      });
    }
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    controller = CameraController(cameras![isFrontCamera ? 1 :0], ResolutionPreset.high);

    await controller!.initialize();
    setState(() {
      isCameraInitialized = true;
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    setState(() {
      _context = context;
    });
    if (!isCameraInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(

        body: Stack(
        children: <Widget>[
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: 100,
                child: CameraPreview(
                  controller!,
                ),
              ),
            ),
          ),

          isloading ? Center(child: CircularProgressIndicator(),) :  Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width*1.3,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: Colors.black,
                        width: MediaQuery.of(context).size.height,
                        strokeAlign: BorderSide.strokeAlignOutside
                    )
                ),
                child: Lottie.asset('assets/images/camerascan.json'),
              ),
            ),
          ),

          InkWell(
            onTap: ()=> Navigator.of(context).pop(),
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0, top: 20.0),
              child: SafeArea(
                child: Row(
                  children: [
                    Icon(Icons.arrow_back_outlined, color: Colors.white,),
                    SizedBox(width: MediaQuery.of(context).size.width*0.03,),
                    Text("Back", style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).textScaleFactor * 18,
                      fontWeight: FontWeight.bold
                    ),),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 50),
              child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [

                FloatingActionButton(onPressed: _flipCamera,
                backgroundColor: Color(0xff426D51),
                child: Icon(Icons.flip_camera_ios_outlined, color: Colors.white,),),

                SizedBox(
                  width: MediaQuery.of(context).size.width*0.4,
                  child: FloatingActionButton(onPressed: _takePicture,
                  backgroundColor: Color(0xff426D51),
                  child: Text("Click to Capture", style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600
                  ),)),
                ),

                FloatingActionButton(onPressed: _toggleFlash,
                backgroundColor: Color(0xff426D51),
                child: Icon(isFlashon ? Icons.flash_off :Icons.flash_on, color: Colors.white,))

              ],),
            ),
          )

          ],
      ),
    );
  }

  Future<void> _takePicture() async {

    try {
      final image = await controller!.takePicture();
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = join(directory.path, '${DateTime.now()}.png');
      await image.saveTo(imagePath);

      setState(() {
        _image = imagePath;
      });

      await _classifyImage(File(_image));
    } catch (e) {
      print(e);
    }
  }

  Future<void> _classifyImage(File image) async {
    setState(() {
      isloading = true;
    });
    int startTime = DateTime.now().millisecondsSinceEpoch;
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
        int endTime = DateTime.now().millisecondsSinceEpoch;
        print("Inference took ${endTime - startTime}ms");
        setState(() {
          isloading = false;
        });
        if (_recognitions[0]['label'] == 'Unknown') {
          // Show dialog
          showDialog(
            context: _context,
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
          Navigator.of(_context).push(
            MaterialPageRoute(
              builder: (context) => ClassificationScreen(
                predictions: _recognitions,
                isGuest: widget.isGuest,
                image: image,
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        isloading = false;
      });
      print("Error classifying image: $e");
    }
  }
}
