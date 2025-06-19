# 🛡️ IOT Women Safety Wearable

A comprehensive IoT-based women safety solution combining a Flutter mobile application with wearable technology to provide real-time safety monitoring, emergency alerts, and location tracking.

---

## 📱 Overview

This project consists of a Flutter mobile application that interfaces with IoT wearable devices to create a comprehensive safety ecosystem for women. The system provides emergency assistance, real-time location sharing, and proactive safety features through seamless integration between hardware and software components.

---

## ✨ Features

### 🚨 Emergency Features

* **SOS Alert System**: One-touch emergency button activation
* **Real-time Location Sharing**: GPS tracking with emergency contacts

### 📍 Location & Tracking

* **Live Location Tracking**: Real-time GPS monitoring
* **Location History**: Track movement patterns and safe routes
* **Nearby Help Finder**: Locate police stations, hospitals, and safe places

### 👥 Contact Management

* **Emergency Contacts**: Quick access to trusted contacts
* **Auto-notification System**: Automatic alerts to emergency contacts
* **Family Dashboard**: Real-time status for family members
* **Community Network**: Connect with nearby safety network

### 📊 Additional Features(future scope)

* **Safety Tips & Resources**: Educational content and safety guidelines
* **Incident Reporting**: Anonymous reporting system
* **Safe Route Planning**: AI-powered route recommendations
* **Battery Monitoring**: Low battery alerts for wearable device

---

## 🏗️ Architecture

```
📄 Mobile App (Flutter)
├─ User Interface
├─ Emergency Management
├─ Location Services
└─ Device Communication
🛠️ IoT Wearable Device
├─ Communication Module (Bluetooth/WiFi)
├─ Emergency Button
└─ Battery Management
📆 Backend Services
├─ Real-time Database
├─ Notification System
└─ Location Processing
🚑 Emergency Response System
├─ Contact Notification
├─ Authority Alerts
└─ Location Broadcasting
```

---

## 🛠️ Technologies Used

### Mobile Application

* **Framework**: Flutter
* **Language**: Dart
* **State Management**: Provider/Bloc
* **Database**: Firebase
* **Communication**: HTTP/WebSocket

### IoT Hardware

* **Microcontroller**: ESP32/Arduino
* **Communication**: Bluetooth, WiFi

### Backend

* **Database**: Firebase
* **Real-time Communication**: WebSocket
* **Cloud Services**: Firebase Cloud Functions
* **Notifications**: FCM (Firebase Cloud Messaging)

---

## 📋 Prerequisites

### For Mobile App Development

* Flutter SDK (>=3.0.0)
* Dart SDK (>=2.17.0)
* Android Studio / VS Code
* Android SDK (API level 21+)
* iOS Development tools (for iOS deployment)

### For Hardware Development

* Arduino IDE or PlatformIO
* ESP32 Development Board
* Required sensors and components
* Basic electronics knowledge

---

## 🚀 Installation & Setup

### Mobile Application Setup

```bash
# Clone the repository
git clone https://github.com/ackshayakeerthig/IOT-Women_Safety_Wearable.git
cd IOT-Women_Safety_Wearable

# Install dependencies
flutter pub get
```

**Firebase Setup**

* Create Firebase project
* Add Android/iOS apps
* Add `google-services.json` & `GoogleService-Info.plist`
* Enable Firestore, Auth, and FCM

```bash
flutter run
```

### Hardware Setup

1. Assemble components: ESP32 + GPS(optional)+ emergency button + battery
2. Use Arduino IDE to flash firmware
3. Install necessary libraries (WiFi, Bluetooth, GPS, etc.)
4. Pair the device with the mobile app via Bluetooth

---

## 📱 Usage

### Initial Setup

* Register and verify account
* Add profile and emergency contacts
* Pair wearable device
* Grant required permissions

### Emergency Situations

* Press SOS button or use voice command
* Alerts sent with live location & audio
* System handles fall or panic detection automatically

---

## 🔧 Configuration

* Set up emergency contacts and priority
* Configure geofencing safe zones
* Tune device sensitivity and alert modes

---

## 🤝 Contributing

1. Fork the repo
2. Create a branch (`git checkout -b feature/X`)
3. Commit your changes (`git commit -m "feat: Add X"`)
4. Push and open a Pull Request

---

## 🧪 Testing

```bash
flutter test           # Unit tests
flutter test --coverage
flutter drive          # Integration tests
```

For hardware:

* Check sensor values
* Validate alerts
* Test battery usage

---

## 🚀 Deployment

```bash
flutter build appbundle  # Android
flutter build ios --release  # iOS
```

For hardware:

* Create PCB, custom enclosure, and begin small-scale production

---

## 🛡️ Privacy & Security

* End-to-end encrypted communications
* Local storage when possible
* Compliant with GDPR and other regulations

---

## 📈 Future Enhancements

* [ ] AI-powered threat detection
* [ ] Smart city integrations
* [ ] Waterproof wearables
* [ ] Multi-language support
* [ ] Analytics dashboard

---

## 🛐 Support & Emergency

**Technical Help**: Open a GitHub issue
**In Danger?**: Contact local authorities

️ *This app is an assistive tool and not a replacement for emergency services.*

---

## 🙏 Acknowledgments

* Open-source community
* Women’s safety advocacy organizations
* Contributors and emergency response teams

---

**⭐ If this helped, please star the repo and share!**

*Built with ❤️ for women’s empowerment and safety.*
