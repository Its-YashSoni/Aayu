// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// class WeatherService {
//   final String apiKey = '8810a0a1c6e61c7ff6b519d6890c1a1b'; // Replace with your OpenWeatherMap API key
//
//   Future<Map<String, dynamic>> fetchWeather(double latitude, double longitude) async {
//     final response = await http.get(Uri.parse(
//         'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric'));
//
//     if (response.statusCode == 200) {
//       return json.decode(response.body);
//     } else {
//       throw Exception('Failed to load weather data');
//     }
//   }
// }
//
//
//
// class WeatherScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: WeatherDetailsPage(),
//     );
//   }
// }
//
// class WeatherDetailsPage extends StatefulWidget {
//   @override
//   _WeatherDetailsPageState createState() => _WeatherDetailsPageState();
// }
//
// class _WeatherDetailsPageState extends State<WeatherDetailsPage> {
//   final WeatherService _weatherService = WeatherService();
//   bool _loading = true;
//   Map<String, dynamic>? _weatherData;
//   Position? _currentPosition;
//   String _error = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchWeatherData();
//   }
//
//   Future<void> _fetchWeatherData() async {
//     try {
//       Position position = await _determinePosition();
//       final weatherData = await _weatherService.fetchWeather(position.latitude, position.longitude);
//       setState(() {
//         _weatherData = weatherData;
//         _currentPosition = position;
//         _loading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = e.toString();
//         _loading = false;
//       });
//       print('Error: $e');
//     }
//   }
//
//   Future<Position> _determinePosition() async {
//     bool serviceEnabled;
//     LocationPermission permission;
//
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return Future.error('Location services are disabled.');
//     }
//
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         return Future.error('Location permissions are denied');
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       return Future.error('Location permissions are permanently denied, we cannot request permissions.');
//     }
//
//     return await Geolocator.getCurrentPosition();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Weather Details'),
//       ),
//       body: _loading
//           ? Center(child: CircularProgressIndicator())
//           : _error.isNotEmpty
//           ? Center(child: Text('Error: $_error'))
//           : _weatherData != null
//           ? Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Location: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}',
//               style: TextStyle(fontSize: 18),
//             ),
//             SizedBox(height: 20),
//             Text(
//               'Weather: ${_weatherData!['weather'][0]['description']}',
//               style: TextStyle(fontSize: 18),
//             ),
//             SizedBox(height: 20),
//             Text(
//               'Temperature: ${_weatherData!['main']['temp']} °C',
//               style: TextStyle(fontSize: 18),
//             ),
//             SizedBox(height: 20),
//             Text(
//               'Humidity: ${_weatherData!['main']['humidity']} %',
//               style: TextStyle(fontSize: 18),
//             ),
//             SizedBox(height: 20),
//             Text(
//               'Wind Speed: ${_weatherData!['wind']['speed']} m/s',
//               style: TextStyle(fontSize: 18),
//             ),
//           ],
//         ),
//       )
//           : Center(child: Text('Failed to load weather data')),
//     );
//   }
// }
//
