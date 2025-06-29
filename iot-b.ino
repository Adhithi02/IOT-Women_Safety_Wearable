#include <WiFi.h>
#include <Wire.h>
#include <Firebase_ESP_Client.h>
#include "I2CKeyPad.h"

// Wi-Fi credentials
#define WIFI_SSID "OPPO F17 Pro"
#define WIFI_PASSWORD "adhithi@265"

// Firebase credentials
#define API_KEY "AIzaSyDs8E9NE3kPedZ-0XKv0vceXSOQTQGOy88"
#define PROJECT_ID "iot-akg"  // no .firebaseio.com

#define USER_EMAIL "abc@gmail.com"
#define USER_PASSWORD "abc123"   // Firebase Auth password

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

const uint8_t KEYPAD_ADDRESS = 0x3D;
I2CKeyPad keyPad(KEYPAD_ADDRESS);
char keys[] = "147*2580369#ABCDNF";

int key1Count = 0;
unsigned long lastResetTime = 0;  // To track 1-minute interval
const unsigned long resetInterval = 60000; // 1 minute in milliseconds

void setup() {
  Serial.begin(115200);
  Wire.begin();

  if (!keyPad.begin()) {
    Serial.println("ERROR: Keypad not detected.");
    while (1);
  }

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(300);
    Serial.print(".");
  }
  Serial.println("\nConnected to WiFi");

  // Set API key and credentials
  config.api_key = API_KEY;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  lastResetTime = millis(); // Start the timer
}

void loop() {
  uint8_t idx = keyPad.getKey();
  char key = keys[idx];

  if (key == '1') {
    key1Count++;
    Serial.printf("Key '1' pressed %d times\n", key1Count);

    String documentPath = "keypad/key1";

    FirebaseJson content;
    content.set("fields/count/integerValue", String(key1Count));

    if (Firebase.Firestore.patchDocument(&fbdo, PROJECT_ID, "", documentPath.c_str(), content.raw(), "count")) {
      Serial.println("Successfully updated Firestore.");
    } else {
      Serial.println("Firestore update failed: " + fbdo.errorReason());
    }

    delay(100); // Debounce
  }

  // Check if one minute has passed
  if (millis() - lastResetTime >= resetInterval) {
    key1Count = 0;
    lastResetTime = millis();

    // Update Firestore with reset count
    String documentPath = "keypad/key1";
    FirebaseJson content;
    content.set("fields/count/integerValue", "0");

    if (Firebase.Firestore.patchDocument(&fbdo, PROJECT_ID, "", documentPath.c_str(), content.raw(), "count")) {
      Serial.println("Count reset to 0 in Firestore.");
    } else {
      Serial.println("Failed to reset count: " + fbdo.errorReason());
    }
  }
}

