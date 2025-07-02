#include <WiFi.h>
#include <Wire.h>
#include <Firebase_ESP_Client.h>
#include "I2CKeyPad.h"

// Wi-Fi credentials
#define WIFI_SSID "YOUR_SSID"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"

// Firebase credentials
#define API_KEY "YOUR_FIREBASE_API"
#define PROJECT_ID "FIREBASE_ID"
#define USER_EMAIL "YOUR_EMAI"
#define USER_PASSWORD "YOUR_PASSWORD"

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

const uint8_t KEYPAD_ADDRESS = 0x3D;
I2CKeyPad keyPad(KEYPAD_ADDRESS);
char keys[] = "147*2580369#ABCDNF";

int key1Count = 0;
unsigned long firstKeyPressTime = 0;
bool timerStarted = false;
const unsigned long waitWindow = 5000; // 5 seconds

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

  config.api_key = API_KEY;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop() {
  uint8_t idx = keyPad.getKey();
  char key = keys[idx];

  if (key == '1') {
    key1Count++;
    Serial.printf("Key '1' pressed %d times\n", key1Count);

    if (!timerStarted) {
      firstKeyPressTime = millis();
      timerStarted = true;
    }

    delay(100);  // Debounce
  }

  if (timerStarted && (millis() - firstKeyPressTime >= waitWindow)) {
    if (key1Count == 2 || key1Count == 3) {
      String username = "Akshatha";
      String documentPath = "keypad/" + username;

      FirebaseJson content;
      content.set("fields/count/integerValue", String(key1Count));

      if (Firebase.Firestore.patchDocument(&fbdo, PROJECT_ID, "", documentPath.c_str(), content.raw(), "count")) {
        Serial.printf("Count %d uploaded to Firestore.\n", key1Count);
      } else {
        Serial.println("Firestore update failed: " + fbdo.errorReason());
      }
    } else {
      Serial.println("Time expired but count not 2 or 3. Skipping update.");
    }

    // Reset timer and count for next round
    key1Count = 0;
    timerStarted = false;
  }
}
