import 'package:ayu/screens/delete_account.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _cameraEnabled = false;
  bool _locationEnabled = false;
  bool _storageEnabled = false;
  bool _darkTheme = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkPermissions();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkTheme = prefs.getBool('darkTheme') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('darkTheme', _darkTheme);
    prefs.setBool('cameraEnabled', _cameraEnabled);
    prefs.setBool('locationEnabled', _locationEnabled);
    prefs.setBool('storageEnabled', _storageEnabled);
  }

  Future<void> _checkPermissions() async {
    bool cameraStatus = await Permission.camera.isGranted;
    bool locationStatus = await Permission.location.isGranted;
    bool storageStatus = await Permission.photos.isGranted || await Permission.storage.isGranted;

    setState(() {
      _cameraEnabled = cameraStatus;
      _locationEnabled = locationStatus;
      _storageEnabled = storageStatus;
    });
  }

  Future<void> _togglePermission(Permission permission, bool enabled) async {
    if (enabled) {
      await permission.request();
    } else {
      // Notify user to manually revoke permission from app settings
      await _openAppSettings();
    }
    _checkPermissions(); // Re-check permissions after request
  }

  Future<void> _openAppSettings() async {
    await openAppSettings(); // Opens app settings for user to manually change permissions
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      brightness: _darkTheme ? Brightness.dark : Brightness.light,
    );

    return MaterialApp(
      theme: theme,
      home: Scaffold(
        appBar: AppBar(
          leading: InkWell(
            onTap: ()=> Navigator.of(context).pop(),
              child: Icon(Icons.arrow_back, color: Colors.white,)),
          title: Text('Settings', style: TextStyle(color: Colors.white),),
          backgroundColor: Color(0xff426D51),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: Text('Enable Camera'),
                value: _cameraEnabled,
                activeColor: Color(0xff426D51),
                onChanged: (value) {
                  setState(() {
                    _cameraEnabled = value;
                    _togglePermission(Permission.camera, value);
                    _saveSettings();
                  });
                },
              ),
              SwitchListTile(
                title: Text('Enable Location'),
                value: _locationEnabled,
                activeColor: Color(0xff426D51),
                onChanged: (value) {
                  setState(() {
                    _locationEnabled = value;
                    _togglePermission(Permission.location, value);
                    _saveSettings();
                  });
                },
              ),
              SwitchListTile(
                title: Text('Enable Storage'),
                value: _storageEnabled,
                activeColor: Color(0xff426D51),
                onChanged: (value) {
                  setState(() {
                    _storageEnabled = value;
                    _togglePermission(Permission.photos, value);
                    _saveSettings();
                  });
                },
              ),

              SizedBox(height: MediaQuery.of(context).size.height*0.02,),
              Align(
                alignment: Alignment.center,
                  child: TextButton(onPressed: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => DeleteAccountPage(),));
                  }, child: Text("Delete Account",style: GoogleFonts.poppins(
                    fontSize: MediaQuery.of(context).textScaleFactor *15, fontWeight: FontWeight.w600,
                    color: Colors.red
                  ),)))
              // SwitchListTile(
              //   title: Text('Dark Theme'),
              //   value: _darkTheme,
              //   onChanged: (value) {
              //     setState(() {
              //       _darkTheme = value;
              //       _saveSettings();
              //     });
              //   },
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
