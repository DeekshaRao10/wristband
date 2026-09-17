<div align="center">

🛡️ SafeBand

Smart Wearable for Safety and Health Monitoring

An IoT-based wearable system that monitors movement and health-related information, detects possible falls using Machine Learning, and synchronizes the wearable status with a Flutter mobile application through Firebase.

<br>






Sensors → ESP32 → ML Fall Detection → Wi-Fi → Firebase → Flutter App

</div>

📖 About SafeBand

SafeBand is a smart wearable safety system built using an ESP32, motion sensors, a Pulse Sensor, an environmental sensor, Machine Learning, Firebase Realtime Database, and a Flutter mobile application.

The wearable continuously collects sensor readings and processes them on the ESP32. The MPU6050 accelerometer and gyroscope are used for movement analysis and fall detection. A Random Forest Machine Learning model is deployed on the ESP32 to classify motion data. The system also performs additional fall-confirmation checks using impact, wrist rotation, post-impact stillness, and barometric information.

When a fall is confirmed, the ESP32 changes the wearable to an emergency state and uploads the relevant information to Firebase through Wi-Fi. The Flutter application provides the family-side interface for viewing the wearable information and emergency status.


🎯 Project Objectives

🛡️ Provide a wearable safety-monitoring solution.

🧠 Detect possible falls using Machine Learning.

📐 Monitor movement using an accelerometer and gyroscope.

❤️ Monitor heart rate using a Pulse Sensor.

🌡️ Monitor environmental information such as temperature and pressure.

☁️ Store wearable information in Firebase Realtime Database.

📱 Provide a Flutter-based family monitoring application.

🔵 Simplify initial device configuration using Bluetooth Low Energy.

🚨 Provide an emergency state when a fall is confirmed.

⭐ Key Features

🧠 Machine Learning Fall Detection

SafeBand uses a Random Forest classifier deployed on the ESP32. Motion data is converted into a feature vector before classification.

📐 Motion Monitoring

The MPU6050 provides accelerometer and gyroscope readings used to analyze movement and possible falls.

❤️ Heart-Rate Monitoring

The current firmware uses an analog Pulse Sensor connected to the ESP32 for heart-rate monitoring.

🌡️ Environmental Monitoring

The BMP280/BME280 sensor is used for pressure and temperature measurements and humidity where supported.

🚨 Multi-Stage Fall Confirmation

A fall is not confirmed from a single sensor reading. The system combines motion-gate detection, Machine Learning classification, and additional evidence such as impact, rotation, stillness, and barometric change.

☁️ Firebase Synchronization

The ESP32 authenticates with Firebase and uploads wearable information to the Firebase Realtime Database using Wi-Fi.

📱 Flutter Mobile Application

The Flutter application provides the family-side interface for viewing the wearable's information and emergency state.

🔵 BLE Provisioning

Bluetooth Low Energy is used during initial configuration to provide Wi-Fi credentials, Firebase information, and the Band ID.


🏗️ System Architecture

                    👤 WEARER
                       │
                       ▼
              ┌─────────────────┐
              │  ⌚ SafeBand     │
              │    Sensors      │
              └────────┬────────┘
                       │
          ┌────────────┼────────────┐
          │            │            │
          ▼            ▼            ▼
      📐 MPU6050   ❤️ Pulse     🌡️ BMP/BME280
      Motion       Sensor       Environment
          │            │            │
          └────────────┼────────────┘
                       ▼
              ┌─────────────────┐
              │    🧠 ESP32     │
              │                 │
              │ Sensor Reading  │
              │ Feature Extract │
              │ Random Forest   │
              │ Fall Confirm.   │
              └────────┬────────┘
                       │
                       │ 📶 Wi-Fi
                       ▼
              ┌─────────────────┐
              │ ☁️ Firebase     │
              │ Realtime DB     │
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │ 📱 Flutter App  │
              │                 │
              │ Health Data     │
              │ Fall Status     │
              │ Family View     │
              └────────┬────────┘
                       │
                       ▼
                  👨‍👩‍👧 FAMILY


🔄 How SafeBand Works

📡 1. Sensors collect data
          ↓
🧠 2. ESP32 receives and processes the readings
          ↓
📊 3. Motion features are extracted
          ↓
🤖 4. Random Forest checks for a possible fall
          ↓
🔍 5. Additional fall-confirmation conditions are checked
          ↓
🚨 6. Confirmed fall changes the system to emergency state
          ↓
📶 7. ESP32 uploads the status through Wi-Fi
          ↓
☁️ 8. Firebase Realtime Database stores the information
          ↓
📱 9. Flutter application reads the wearable information
          ↓
👨‍👩‍👧 10. Family member can monitor the wearer

🧠 Machine Learning – Fall Detection

The MPU6050 continuously provides acceleration and gyroscope readings. The ESP32 maintains a motion window and extracts 22 features from the acceleration data.


📊 Features Used

The feature vector includes:

📈 Mean

📉 Standard deviation

🔽 Minimum

🔼 Maximum

↔️ Range

📊 25th percentile

📊 75th percentile

📐 Skewness

📐 Kurtosis

√ RMS

📐 X-axis statistics

📐 Y-axis statistics

📐 Z-axis statistics

The extracted features are passed to the deployed Random Forest model:

fall_model.h

🚨 Fall Detection Logic

Sustained Free-Fall
        +
      Impact
        ↓
   Capture Motion
        ↓
  22 Feature Extraction
        ↓
 Random Forest Prediction
        ↓
Additional Confirmation
 ┌──────┼────────┐
 │      │        │
Rotation Stillness Barometric
 │      │        │
 └──────┼────────┘
        ↓
  🚨 Confirmed Fall

This multi-stage process is designed to reduce false alarms compared with relying on a single threshold or sensor reading.


🔧 Hardware Components

🔩 Component

🎯 Purpose

🧠 ESP32

Main controller, sensor processing and communication

📐 MPU6050

Accelerometer + gyroscope for movement and fall detection

❤️ Analog Pulse Sensor

Heart-rate monitoring

🌡️ BMP280/BME280

Temperature, pressure and environmental measurements

🔋 Battery / Power Supply

Portable power for the wearable


💻 Technology Stack

Category

Technology

🧠 Microcontroller

ESP32

💻 Firmware

C/C++ with Arduino Framework

🛠️ Development

PlatformIO / Arduino IDE

📐 Motion Sensor

MPU6050

❤️ Heart Sensor

Analog Pulse Sensor

🌡️ Environmental Sensor

BMP280/BME280

🤖 Machine Learning

Random Forest

📱 Mobile App

Flutter / Dart

☁️ Database

Firebase Realtime Database

📶 Wireless

Wi-Fi

🔵 Provisioning

Bluetooth Low Energy (BLE)

🔌 Sensor Interface

I²C / GPIO

📡 Communication

📶 Wi-Fi

Wi-Fi is used by the ESP32 to connect to the configured network and communicate with Firebase.

ESP32 → Wi-Fi → Firebase Realtime Database

🔵 Bluetooth Low Energy

BLE is used mainly during the initial configuration of the wearable.

Flutter / Mobile
       │
       │ 🔵 BLE
       ▼
     ESP32
       │
       ▼
Save Configuration
       │
       ▼
   📶 Wi-Fi

☁️ Firebase Realtime Database

Firebase acts as the cloud data layer for SafeBand.

The ESP32 authenticates with Firebase and uploads information associated with the configured Band ID.

📊 Typical Information

❤️ Heart Rate
🫁 SpO₂ field
🚨 Fall Detected
👣 Steps
📌 Status
🌡️ Temperature
💨 Pressure
💧 Humidity
📉 Barometric Fall Information
🔧 Sensor Status
⏱️ Last Updated

⚠️ Current Firmware Note: The current firmware contains an SpO₂ field, but the value is a simulated placeholder because the current hardware uses an analog Pulse Sensor rather than a dedicated red/IR SpO₂ sensor.

📱 Flutter Mobile Application

The Flutter application provides the mobile interface for the family member.

The application is intended to provide:

👤 User/family information

📊 Wearable data

❤️ Health-related readings

🚨 Fall/emergency status

🔄 Updated information from Firebase

👨‍👩‍👧 Family-side monitoring

The fall-detection processing itself is performed on the ESP32, while the Flutter application is used for monitoring and presentation.

🔵 BLE Provisioning

During initial setup, the wearable can receive configuration information through BLE.

📦 Provisioning Format

SSID | Wi-Fi Password | Firebase Email | Firebase Password | Band ID

The ESP32 stores the configuration using non-volatile storage and uses it to connect to Wi-Fi and Firebase.

📌 Pin Configuration

📐 MPU6050

SDA → GPIO 21
SCL → GPIO 22

❤️ Pulse Sensor

Signal → GPIO 34

🌡️ BMP280/BME280

SDA → GPIO 4
SCL → GPIO 13

💡 Note: Use the appropriate voltage for the sensor modules and connect all required grounds correctly.


📂 Project Structure

SafeBand/
│
├── 📁 firmware/
│   ├── 📁 src/
│   │   └── main.cpp
│   │
│   ├── 📁 include/
│   │   ├── fall_model.h
│   │   └── firebase_config.h
│   │
│   └── platformio.ini
│
├── 📁 flutter_app/
│   ├── 📁 lib/
│   │   ├── 📁 screens/
│   │   ├── 📁 services/
│   │   ├── 📁 widgets/
│   │   └── main.dart
│   │
│   └── pubspec.yaml
│
└── 📄 README.md


⚙️ Setup & Installation

1️⃣ ESP32 Firmware

Open the firmware project using PlatformIO or the appropriate Arduino development environment.

2️⃣ Configure Firebase

Set up the Firebase project and Realtime Database and provide the required Firebase configuration used by the firmware.

3️⃣ Add the ML Model

Place the generated Random Forest model header in the firmware:

fall_model.h

4️⃣ Connect the Sensors

Connect the sensors according to the pin configuration shown above.

5️⃣ Upload the Firmware

Connect the ESP32, select the correct board/serial port, build the project, and upload the firmware.

6️⃣ Configure the Wearable

Use BLE provisioning to provide:

📶 Wi-Fi credentials
☁️ Firebase credentials
🆔 Band ID

7️⃣ Run the Flutter Application

Install the Flutter dependencies and run the application on an Android device or emulator.

🚨 Emergency Flow

⌚ Abnormal motion detected
            ↓
📐 MPU6050 data processed
            ↓
🤖 ML model predicts possible fall
            ↓
🔍 Additional evidence checked
            ↓
       ┌────┴────┐
       │         │
     ❌ No      🚨 Yes
       │         │
       ▼         ▼
 Continue     Emergency
 Monitoring     State
                  │
                  ▼
               📶 Wi-Fi
                  │
                  ▼
             ☁️ Firebase
                  │
                  ▼
             📱 Flutter
                  │
                  ▼
          👨‍👩‍👧 Family Member

🔄 Data Flow

📐 MPU6050
    │
❤️ Pulse Sensor
    │
🌡️ BMP/BME280
    │
    ▼
🧠 ESP32
    │
    ├── 📊 Data Processing
    ├── 🧠 Feature Extraction
    ├── 🤖 Random Forest
    ├── 🚨 Fall Confirmation
    └── ❤️ Health Monitoring
    │
    ▼
📶 Wi-Fi
    │
    ▼
☁️ Firebase Realtime Database
    │
    ▼
📱 Flutter Application
    │
    ▼
👨‍👩‍👧 Family Member

🧪 Testing

The ESP32 firmware provides serial diagnostics for checking the system during development.

Useful serial commands include:

f → Fake fall
b → Release BLE
h → Show heap information
s → Sensor status
i → Re-initialize sensors
w → Show saved Wi-Fi
c → Clear boot count and restart
r → Factory reset

The firmware also reports sensor and Wi-Fi status during operation, which helps verify the wearable before testing fall-detection behavior.

⚠️ Limitations

📶 Cloud synchronization requires Wi-Fi connectivity.

🧠 Machine Learning predictions can contain errors.

📐 Sensor readings can be affected by movement, placement, and environmental conditions.

🫁 The current SpO₂ value is a simulated placeholder.

🏥 SafeBand is a prototype/academic project and should not be treated as a medical device or a replacement for professional medical or emergency services.

🚀 Future Enhancements

📍 GPS-based location tracking

📡 GSM/LTE connectivity for operation without Wi-Fi

❤️ Dedicated optical heart-rate and SpO₂ sensor

🔔 Push notification integration

💾 Offline data buffering and synchronization

🧠 Larger and more diverse fall-detection dataset

📊 Improved ML model evaluation

🔋 Battery-level monitoring

⚡ Power optimization

📈 Detailed activity and health analytics

🆘 Additional emergency response options

🛡️ Safety Concept

SafeBand follows a simple safety pipeline:

👁️ SENSE
   ↓
🧠 PROCESS
   ↓
🤖 DETECT
   ↓
🔍 CONFIRM
   ↓
📡 COMMUNICATE
   ↓
🛡️ PROTECT

The wearable senses the user's movement and health-related information, processes it locally, detects possible falls, confirms the event using multiple signals, communicates the status through Firebase, and provides the information to the family through the mobile application.

📌 Important Note

SafeBand is currently developed as an academic/prototype system for IoT, Machine Learning, embedded systems, and mobile application development.

The current firmware uses:

MPU6050 + Analog Pulse Sensor + BMP280/BME280 + ESP32 + Random Forest + Wi-Fi + Firebase + Flutter

💚 SafeBand

<div align="center">

“Wear it for the ones who care.”

⌚ Sensors → 🧠 ESP32 → 🤖 ML Fall Detection → 📶 Wi-Fi → ☁️ Firebase → 📱 Flutter App → 👨‍👩‍👧 Family

🛡️ Safety Today. A Better Tomorrow.

Version 1.0

</div>
