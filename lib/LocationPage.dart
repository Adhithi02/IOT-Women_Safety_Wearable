import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:trial/secret.dart'; // replace with your actual project name


class LocationPage extends StatefulWidget {
  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  String userId = "user123";
  Timer? _timer;
  StreamSubscription<QuerySnapshot>? _keypadSubscription;

  List<String> _logMessages = [];
  bool _locationServiceEnabled = false;
  bool _locationPermissionGranted = false;
  bool _listeningToKeypad = false;
  bool _emailSendingInProgress = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _listenToKeypadCollection();
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toLocal().toIso8601String();
    setState(() {
      _logMessages.insert(0, "[$timestamp] $message");
    });
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() {
      _locationServiceEnabled = serviceEnabled;
    });
    if (!serviceEnabled) {
      _addLog("Location service is disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.requestPermission();
    bool permissionGranted = !(permission == LocationPermission.deniedForever || permission == LocationPermission.denied);
    setState(() {
      _locationPermissionGranted = permissionGranted;
    });

    if (!permissionGranted) {
      _addLog("Location permission denied.");
      return;
    }

    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _addLog("Starting location updates every 10 seconds...");
    _timer = Timer.periodic(Duration(seconds: 10), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        _uploadLocation(position);
      } catch (e) {
        _addLog("Error getting location: $e");
      }
    });
  }

  void _uploadLocation(Position pos) async {
    try {
      await FirebaseFirestore.instance.collection('locations').add({
        'userId': userId,
        'lat': pos.latitude,
        'lng': pos.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _addLog("Location sent: (${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)})");
    } catch (e) {
      _addLog("Failed to send location: $e");
    }
  }

  void _listenToKeypadCollection() {
    _addLog("Listening to 'keypad' collection...");
    _keypadSubscription = FirebaseFirestore.instance.collection('keypad').snapshots().listen(
      (querySnapshot) {
        if (!_listeningToKeypad) {
          setState(() {
            _listeningToKeypad = true;
          });
        }
        for (var docChange in querySnapshot.docChanges) {
          if (docChange.type == DocumentChangeType.added || docChange.type == DocumentChangeType.modified) {
            var data = docChange.doc.data();
            if (data != null && data.containsKey('count')) {
              int count = data['count'];
              _addLog("Keypad document '${docChange.doc.id}' count: $count");
              if (count == 3) {
                _addLog("Count is 3! Triggering email send...");
                _sendEmail();
              }
            }
          }
        }
      },
      onError: (error) {
        _addLog("Error listening to keypad collection: $error");
        setState(() {
          _listeningToKeypad = false;
        });
      },
    );
  }
void _sendEmail() async {
       if (_emailSendingInProgress) {
         _addLog("Email sending already in progress, skipping duplicate.");
         return;
       }
     
       setState(() {
         _emailSendingInProgress = true;
       });
     
       final now = DateTime.now().toLocal().toString();
       final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
     
       try {
         final response = await http.post(
           url,
           headers: {
             'origin': 'http://localhost',
             'Content-Type': 'application/json',
           },
           body: json.encode({
             'service_id': serviceId,
             'template_id': templateId,
             'user_id': userIdEmailJS,
             'template_params': {
               'name': 'Ackshaya',
               'time': now,
               'message': 'Location tracking has started. Coordinates are being stored in Firebase.',
               'to_email': toEmail,
             },
           }),
         );
     
         if (response.statusCode == 200) {
           _addLog("✅ Email sent successfully.");
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("✅ Email sent")),
           );
         } else {
           _addLog("❌ Email failed: ${response.body}");
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("❌ Email failed: ${response.body}")),
           );
         }
       } catch (e) {
         _addLog("❌ Exception sending email: $e");
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("❌ Exception sending email: $e")),
         );
       }
     
       setState(() {
         _emailSendingInProgress = false;
       });
     }
     
  @override
  void dispose() {
    _timer?.cancel();
    _keypadSubscription?.cancel();
    super.dispose();
  }

  Widget _buildStatusBadge(String title, bool status) {
    return Chip(
      label: Text(title),
      avatar: Icon(
        status ? Icons.check_circle : Icons.error,
        color: status ? Colors.green : Colors.red,
      ),
      backgroundColor: status ? Colors.green[50] : Colors.red[50],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Location Uploader & Keypad Listener"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Status badges:
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusBadge("Location Service", _locationServiceEnabled),
                _buildStatusBadge("Permission", _locationPermissionGranted),
                _buildStatusBadge("Listening Firestore", _listeningToKeypad),
                _buildStatusBadge("Email Sending", _emailSendingInProgress),
              ],
            ),
            SizedBox(height: 20),

            // Log area:
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.all(10),
                child: _logMessages.isEmpty
                    ? Center(
                        child: Text(
                          "No logs yet.",
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        itemCount: _logMessages.length,
                        itemBuilder: (context, index) {
                          return Text(
                            _logMessages[index],
                            style: TextStyle(color: Colors.white, fontFamily: 'monospace'),
                          );
                        },
                      ),
              ),
            ),

            SizedBox(height: 20),

            // Manual send email button:
            ElevatedButton.icon(
              onPressed: _sendEmail,
              icon: Icon(Icons.email),
              label: Text("Send Email Now"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
