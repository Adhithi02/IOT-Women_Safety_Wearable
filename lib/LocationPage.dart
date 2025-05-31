import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class LocationPage extends StatefulWidget {
  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  String userId = "user123";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  void _startLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location service is disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      print("Location permission denied.");
      return;
    }

    // Send location every 10 seconds:
     _timer = Timer.periodic(Duration(seconds: 10), (timer) async {
       Position position = await Geolocator.getCurrentPosition(
         desiredAccuracy: LocationAccuracy.high,
       );
       _uploadLocation(position);
     });
  }
   @override
   void dispose() {
     _timer?.cancel();  // Cancel the timer when the widget is disposed
     super.dispose();
   }
  void _uploadLocation(Position pos) async {
  try {
    await FirebaseFirestore.instance.collection('locations').add({
      'userId': userId,
      'lat': pos.latitude,
      'lng': pos.longitude,
      'timestamp': FieldValue.serverTimestamp(),
    });
    print("Location sent: ${pos.latitude}, ${pos.longitude}");
  } catch (e) {
    print("Failed to send location: $e");
  }
}


  // ✅ MOVE _sendEmail OUT HERE:
void _sendEmail() async {
  final serviceId = 'service_7k5bytf';
  final templateId = 'template_o7fwyms';
  final userId = '8W9rxvGq3yTArdSfr';

  final now = DateTime.now().toLocal().toString(); // or use formatted time

  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

  final response = await http.post(
    url,
    headers: {
      'origin': 'http://localhost',
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': userId,
      'template_params': {
        'name': 'Ackshaya',
        'time': now,
        'message': 'Location tracking has started. Coordinates are being stored in Firebase.',
        'to_email': 'aishwaryavs.cs23@rvce.edu.in' // recipient
      },
    }),
  );

  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Email sent")),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Email failed: ${response.body}")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Location Uploader")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Sending location updates..."),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendEmail, // ✅ Now this will work!
              child: const Text("Send Email"),
            ),
          ],
        ),
      ),
    );
  }
}
