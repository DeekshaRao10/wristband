🛡️ SafeBand

Smart Wearable for Safety and Health Monitoring

A smart wearable system for movement monitoring, Machine Learning
based fall detection, basic health monitoring, and family-side
monitoring through a Flutter application.

📖 About the Project

SafeBand is an IoT-based wearable safety system built using an
ESP32, MPU6050, analog Pulse Sensor, BMP280/BME280,
Random Forest Machine Learning, Wi-Fi, Firebase Realtime
Database, Bluetooth Low Energy (BLE), and Flutter.

The ESP32 continuously collects sensor data and processes the
information locally. The MPU6050 is used to monitor acceleration and
gyroscope data for fall detection. A Random Forest model is used to
classify motion data, while additional conditions such as impact,
rotation, stillness, and barometric change are used to confirm a
possible fall. Confirmed fall information is uploaded to Firebase
through Wi-Fi and can be monitored through the Flutter application.

🎯 Objectives

🛡️ Develop a smart wearable safety system.

🧠 Detect falls using Machine Learning.

📐 Monitor movement using the MPU6050.

❤️ Monitor heart rate using an analog Pulse Sensor.

🌡️ Monitor temperature and pressure using BMP280/BME280.

☁️ Store wearable information in Firebase.

📱 Provide a Flutter-based monitoring application.

🔵 Provide BLE-based device provisioning.

🚨 Provide an emergency status after a confirmed fall.

⭐ Key Features

Feature                             Description

🧠 Machine Learning Fall          Random Forest model for motion
Detection                         classification

📐 Motion Monitoring            MPU6050 accelerometer and gyroscope

❤️ Heart-Rate Monitoring        Analog Pulse Sensor

🌡️ Environmental Monitoring     BMP280/BME280 temperature and
pressure data

🚨 Fall Confirmation            Multiple motion and barometric
checks

📶 Wi-Fi Communication          ESP32 to Firebase communication

☁️ Firebase Database            Stores wearable and emergency
information

📱 Flutter Application          Family-side monitoring interface

🔵 BLE Provisioning             Initial device configuration

🏗️ System Architecture

                    👤 WEARER
                       │
                       ▼
              ┌──────────────────┐
              │  ⌚ SAFEBAND      │
              │     SENSORS      │
              └────────┬─────────┘
                       │
          ┌────────────┼────────────┐
          │            │            │
          ▼            ▼            ▼
      📐 MPU6050    ❤️ Pulse    🌡️ BMP/BME280
      Motion        Sensor      Environment
          │            │            │
          └────────────┼────────────┘
                       ▼
              ┌──────────────────┐
              │     🧠 ESP32     │
              │                  │
              │ Sensor Processing│
              │ Feature Extraction│
              │ Random Forest    │
              │ Fall Confirmation│
              └────────┬─────────┘
                       │
                       │ 📶 Wi-Fi
                       ▼
              ┌──────────────────┐
              │ ☁️ Firebase RTDB │
              └────────┬─────────┘
                       │
                       ▼
              ┌──────────────────┐
              │  📱 Flutter App  │
              │                  │
              │ Health Data      │
              │ Fall Status      │
              └────────┬─────────┘
                       │
                       ▼
                 👨‍👩‍👧 FAMILY

🔄 Working Principle

📡 Sensor Data
      ↓
🧠 ESP32 Processing
      ↓
📊 Feature Extraction
      ↓
🤖 Random Forest Prediction
      ↓
🔍 Fall Confirmation
      ↓
🚨 Emergency State
      ↓
📶 Wi-Fi
      ↓
☁️ Firebase Realtime Database
      ↓
📱 Flutter Application
      ↓
👨‍👩‍👧 Family Monitoring

🧠 Machine Learning -- Fall Detection

The MPU6050 provides acceleration and gyroscope readings. The ESP32
processes the motion information using a rolling window and calculates
22 features.

📊 Motion Features

The feature vector contains:

Mean

Standard deviation

Minimum

Maximum

Range

25th percentile

75th percentile

Skewness

Kurtosis

RMS

X-axis statistics

Y-axis statistics

Z-axis statistics

The trained Random Forest model is deployed to the ESP32 as:

fall_model.h

🚨 Fall Detection Process

Sustained Free-Fall
        +
      Impact
        ↓
 Motion Window
        ↓
22 Feature Extraction
        ↓
Random Forest Prediction
        ↓
Additional Confirmation
        ↓
┌─────────┬──────────┬─────────────┐
│ Rotation│ Stillness│ Barometric  │
└─────────┴──────────┴─────────────┘
        ↓
🚨 CONFIRMED FALL

The additional confirmation stage is used to reduce false fall
detections.

🔧 Hardware Components

Component                           Purpose

🧠 ESP32                        Main controller and processing unit

📐 MPU6050                      Accelerometer and gyroscope

❤️ Analog Pulse Sensor          Heart-rate monitoring

🌡️ BMP280/BME280                Temperature and
pressure/environmental monitoring

🔋 Battery / Power Supply       Portable power

💻 Technology Stack

🔌 Embedded System

ESP32

C/C++

Arduino Framework

PlatformIO / Arduino IDE

I²C

GPIO

🤖 Machine Learning

Python

Scikit-learn

Random Forest

Embedded model: fall_model.h

📱 Mobile Application

Flutter

Dart

☁️ Backend & Database

Firebase Authentication

Firebase Realtime Database

📡 Communication

Wi-Fi

Bluetooth Low Energy (BLE)

📡 Communication

📶 Wi-Fi

Wi-Fi is used to send processed sensor information and emergency status
from the ESP32 to Firebase.

🧠 ESP32
   │
   │ Wi-Fi
   ▼
☁️ Firebase Realtime Database

🔵 Bluetooth Low Energy

BLE is mainly used for initial device provisioning.

📱 Mobile
   │
   │ BLE
   ▼
🧠 ESP32
   │
   ▼
💾 Save Configuration
   │
   ▼
📶 Wi-Fi

☁️ Firebase Integration

Firebase Realtime Database acts as the cloud data layer of SafeBand.

The ESP32 authenticates with Firebase and uploads information associated
with the configured Band ID.

📊 Data

❤️ Heart Rate
🫁 SpO₂ Field
🚨 Fall Detected
👣 Steps
📌 Status
🌡️ Temperature
💨 Pressure
💧 Humidity
📉 Barometric Fall Information
🔧 Sensor Status
⏱️ Last Updated

⚠️ Current Firmware Note: The current firmware contains an SpO₂
field, but it is a simulated placeholder because the current hardware
uses an analog Pulse Sensor rather than a dedicated red/IR SpO₂
sensor.

📱 Flutter Application

The Flutter application provides the family-side monitoring interface.

It can display:

👤 User/family information

❤️ Health-related readings

📊 Wearable information

🚨 Fall/emergency status

🔄 Updated information from Firebase

The fall-detection computation is performed on the ESP32. The
Flutter application is used for monitoring and displaying the
information.

🔵 BLE Provisioning

During initial setup, the ESP32 can receive configuration information
through BLE.

📦 Provisioning Format

SSID | Wi-Fi Password | Firebase Email | Firebase Password | Band ID

The ESP32 stores the configuration in non-volatile storage and uses it
to connect to Wi-Fi and Firebase.

📌 Pin Configuration

📐 MPU6050

SDA → GPIO 21
SCL → GPIO 22

❤️ Pulse Sensor

Signal → GPIO 34

🌡️ BMP280/BME280

SDA → GPIO 4
SCL → GPIO 13

📂 Project Structure

SafeBand/
│
├── 📁 firmware/
│   ├── 📁 src/
│   │   └── 📄 main.cpp
│   │
│   ├── 📁 include/
│   │   ├── 📄 fall_model.h
│   │   └── 📄 firebase_config.h
│   │
│   └── 📄 platformio.ini
│
├── 📁 flutter_app/
│   ├── 📁 lib/
│   │   ├── 📁 screens/
│   │   ├── 📁 services/
│   │   ├── 📁 widgets/
│   │   └── 📄 main.dart
│   │
│   └── 📄 pubspec.yaml
│
└── 📄 README.md

⚙️ Installation & Setup

1️⃣ Set Up ESP32

Open the firmware project using PlatformIO or Arduino IDE.

2️⃣ Connect Sensors

Connect the MPU6050, Pulse Sensor, and BMP280/BME280 according to the
pin configuration.

3️⃣ Configure Firebase

Create/configure the Firebase project and Realtime Database, then add
the required Firebase configuration.

4️⃣ Add Machine Learning Model

Place:

fall_model.h

inside the firmware include directory.

5️⃣ Upload Firmware

Connect the ESP32, select the correct board and COM port, build the
project, and upload the firmware.

6️⃣ Configure the Wearable

Use BLE provisioning to provide:

📶 Wi-Fi credentials
☁️ Firebase credentials
🆔 Band ID

7️⃣ Run Flutter Application

Open the Flutter project, install the required dependencies, and run the
application on an Android device or emulator.

🧪 Testing & Diagnostics

The firmware provides serial commands for testing and diagnostics.

Command   Function

f       🚨 Trigger a fake fall
b       🔵 Release BLE
h       💾 Show heap information
s       🔧 Show sensor status
i       🔄 Re-initialize sensors
w       📶 Show saved Wi-Fi
c       🔄 Clear boot count and restart
r       🗑️ Factory reset

🚨 Emergency Flow

⌚ Abnormal Motion
       ↓
📐 MPU6050 Processing
       ↓
🤖 ML Prediction
       ↓
🔍 Additional Confirmation
       ↓
   ┌───┴────┐
   │        │
  ❌ No    🚨 Yes
   │        │
   ▼        ▼
Continue  Emergency
Monitoring  State
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
        👨‍👩‍👧 Family

⚠️ Limitations

📶 Cloud synchronization currently depends on Wi-Fi connectivity.

🧠 Machine Learning predictions can contain errors.

📐 Sensor readings can be affected by sensor placement and
environmental conditions.

🫁 The current SpO₂ value is a simulated placeholder.

🏥 SafeBand is a prototype/academic project and is not a replacement
for professional medical or emergency services.

🚀 Future Enhancements

📍 GPS-based location tracking

📡 GSM/LTE communication

❤️ Dedicated optical heart-rate and SpO₂ sensor

🔔 Push notifications

💾 Offline data buffering and synchronization

🧠 Larger and more diverse fall-detection dataset

📊 Improved ML model evaluation

🔋 Battery-level monitoring

⚡ Power optimization

📈 Detailed health and activity analytics

🆘 Additional emergency response features

🛡️ Safety Concept

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

SafeBand follows this pipeline to sense the wearer's information,
process it locally, detect a possible fall, confirm the event,
communicate the status to the cloud, and provide the information through
the mobile application.

📜 Project Status

SafeBand --- Version 1.0

🎓 Developed as an academic/prototype project combining:

IoT + Embedded Systems + Machine Learning + Cloud Database + Mobile
Application

::: {align="center"}

🛡️ SafeBand

💚 Wear it for the ones who care.

⌚ Sensors → 🧠 ESP32 → 🤖 ML → 📶 Wi-Fi → ☁️ Firebase → 📱 Flutter

Version 1.0
:::
