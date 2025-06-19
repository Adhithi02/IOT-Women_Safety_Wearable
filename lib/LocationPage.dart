import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:trial/secret.dart'; // replace with your actual secret.dart

class LocationPage extends StatefulWidget {
  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  String userId = "";
  String? username;
  String? emergencyEmail;

  Timer? _timer;
  StreamSubscription<DocumentSnapshot>? _keypadSubscription;

  List<String> _logMessages = [];
  bool _locationServiceEnabled = false;
  bool _locationPermissionGranted = false;
  bool _listeningToKeypad = false;
  bool _emailSendingInProgress = false;

  @override
  void initState() {
    super.initState();
    _setupUser();
  }

  Future<void> _setupUser() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _addLog("No user logged in.");
      return;
    }

    userId = user.uid;
    _addLog("Authenticated UID: $userId");

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          username = data?['username'] ?? "Unknown";
          emergencyEmail = data?['emergencyEmail'] ?? "emergency@example.com";
        });
        _addLog("Fetched user data: username = $username, emergencyEmail = $emergencyEmail");

        _initLocation();
        _listenToKeypadCollection();
      } else {
        _addLog("User document not found.");
      }
    } catch (e) {
      _addLog("Error fetching user data: $e");
    }
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
      await FirebaseFirestore.instance.collection('locations').
      doc(username)
      .collection('logs')
      .add({
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
  _addLog("Listening to 'keypad/{username}/count'...");

  if (username == null) {
    _addLog("Username is null; can't listen to count.");
    return;
  }

  final docRef = FirebaseFirestore.instance.collection('keypad').doc(username).collection('meta').doc('count');

  _keypadSubscription = docRef.snapshots().listen(
    (docSnapshot) async {
      if (!_listeningToKeypad) {
        setState(() {
          _listeningToKeypad = true;
        });
      }

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data.containsKey('count')) {
          int count = data['count'];
          _addLog("🧮 Count value: $count");

          if (count == 3) {
            _addLog("🚨 Count is 3! Triggering emergency email...");
            await _sendEmail();

            // Reset count to 0 after email
            try {
              await docRef.update({'count': 0});
              _addLog("✅ Count reset to 0 after email.");
            } catch (e) {
              _addLog("❌ Failed to reset count: $e");
            }
          }
        }
      } else {
        _addLog("⚠️ Document does not exist at 'keypad/$username/meta/count'");
      }
    },
    onError: (error) {
      _addLog("❌ Error listening to count document: $error");
      setState(() {
        _listeningToKeypad = false;
      });
    },
  );
}

  
  Future<void> _sendEmail() async {
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
            'name': username ?? 'User',
            'time': now,
            'message': 'Location tracking has started. Coordinates are being stored in Firebase.',
            'to_email': emergencyEmail ?? toEmail, // Fallback to static if not found
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
