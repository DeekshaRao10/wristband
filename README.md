<div align="center">

# 🛡️ SafeBand

### **Smart Wearable for Safety and Health Monitoring**

**An IoT-based wearable system for fall detection, health monitoring, and family safety**

<br>

🧠 **Machine Learning** &nbsp; • &nbsp;
📡 **IoT** &nbsp; • &nbsp;
📱 **Flutter** &nbsp; • &nbsp;
☁️ **Firebase**

<br><br>

**⌚ Sensors → 🧠 ESP32 → 🤖 ML → 📶 Wi-Fi → ☁️ Firebase → 📱 Flutter**

</div>

---

## 📖 About SafeBand

**SafeBand** is a smart wearable safety system developed using **ESP32, MPU6050, Analog Pulse Sensor, BMP280/BME280, Machine Learning, Firebase, Bluetooth Low Energy (BLE), and Flutter**.

The **ESP32** acts as the main controller of the wearable. It continuously collects movement data from the **MPU6050 accelerometer and gyroscope**, heart-rate information from the **Analog Pulse Sensor**, and environmental information from the **BMP280/BME280 sensor**.

For fall detection, the ESP32 processes the motion data, extracts **22 motion features**, and uses a **Random Forest Machine Learning model** to classify possible falls. The system also performs additional confirmation using **free-fall, impact, wrist rotation, post-impact stillness, and barometric change** to reduce false detections.

When a fall is confirmed, the ESP32 changes the wearable to an **Emergency State** and uploads the relevant information to **Firebase Realtime Database** through Wi-Fi. The **Flutter mobile application** provides the family-side interface for monitoring the wearable information and emergency status.

---

## 🎯 Objectives

| | Objective |
|---|---|
| 🛡️ | Develop a smart wearable safety system |
| 🧠 | Detect falls using Machine Learning |
| 📐 | Monitor movement using an accelerometer and gyroscope |
| ❤️ | Monitor heart rate using an Analog Pulse Sensor |
| 🌡️ | Monitor temperature and pressure |
| ☁️ | Store wearable information using Firebase |
| 📱 | Provide a Flutter-based monitoring application |
| 🔵 | Configure the wearable using Bluetooth Low Energy |
| 🚨 | Provide an emergency status after a confirmed fall |

---

## ⭐ Key Features

### 🧠 Machine Learning Fall Detection

Uses a **Random Forest classifier** deployed on the ESP32 to classify motion data.

### 📐 Motion Monitoring

The **MPU6050 accelerometer and gyroscope** continuously monitor the wearer's movement.

### ❤️ Heart-Rate Monitoring

An **Analog Pulse Sensor** is used for heart-rate monitoring.

### 🌡️ Environmental Monitoring

The **BMP280/BME280** provides temperature and pressure information and humidity where supported.

### 🚨 Multi-Stage Fall Confirmation

The system combines multiple signals such as:

**Free-Fall + Impact + ML Prediction + Rotation + Stillness + Barometric Change**

to confirm a possible fall.

### 📶 Wi-Fi Communication

The ESP32 communicates with Firebase through Wi-Fi.

### ☁️ Firebase Integration

Firebase Realtime Database stores the wearable's health and emergency information.

### 📱 Flutter Application

The Flutter application provides the family-side monitoring interface.

### 🔵 BLE Provisioning

Bluetooth Low Energy is used for initial wearable configuration.

---

# 🏗️ System Architecture

```text
                         👤 WEARER
                            │
                            ▼
                  ┌──────────────────┐
                  │   ⌚ SAFEBAND     │
                  │     SENSORS      │
                  └────────┬─────────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
              ▼            ▼            ▼
         📐 MPU6050     ❤️ Pulse    🌡️ BMP/BME280
          Motion        Sensor       Environment
              │            │            │
              └────────────┼────────────┘
                           │
                           ▼
                  ┌──────────────────┐
                  │      🧠 ESP32    │
                  │                  │
                  │ Sensor Processing│
                  │ Feature Extraction│
                  │ Random Forest    │
                  │ Fall Confirmation│
                  └────────┬─────────┘
                           │
                        📶 Wi-Fi
                           │
                           ▼
                  ┌──────────────────┐
                  │ ☁️ FIREBASE      │
                  │ REALTIME DATABASE│
                  └────────┬─────────┘
                           │
                           ▼
                  ┌──────────────────┐
                  │  📱 FLUTTER APP  │
                  │                  │
                  │ Health Data      │
                  │ Fall Status      │
                  │ Family Monitoring│
                  └────────┬─────────┘
                           │
                           ▼
                    👨‍👩‍👧 FAMILY
🔄 Working Principle
<div align="center">
1️⃣ Sense

📐 MPU6050   •   ❤️ Pulse Sensor   •   🌡️ BMP/BME280

⬇️

2️⃣ Process

🧠 ESP32 collects and processes sensor information

⬇️

3️⃣ Detect

🤖 Random Forest Machine Learning model

⬇️

4️⃣ Confirm

🔍 Impact   •   Rotation   •   Stillness   •   Barometric Change

⬇️

5️⃣ Communicate

📶 Wi-Fi → ☁️ Firebase

⬇️

6️⃣ Monitor

📱 Flutter Application → 👨‍👩‍👧 Family

</div>
🧠 Machine Learning — Fall Detection

The MPU6050 continuously provides acceleration and gyroscope readings. The ESP32 processes the motion information using a rolling window and extracts 22 features for classification.

📊 Features Used
Category	Features
📈 Statistical	Mean, Standard Deviation
🔽 Range	Minimum, Maximum, Range
📊 Percentile	25th Percentile, 75th Percentile
📐 Distribution	Skewness, Kurtosis
√ Signal	RMS
📐 Axis Data	X-axis, Y-axis, Z-axis statistics

The trained Random Forest model is deployed to the ESP32 as:

fall_model.h
🚨 Fall Detection Process
        📉 Sustained Free-Fall
                 │
                 ▼
             🔴 Impact
                 │
                 ▼
       📊 Motion Window Captured
                 │
                 ▼
        🔢 22 Features Extracted
                 │
                 ▼
       🤖 Random Forest Prediction
                 │
                 ▼
       🔍 Additional Confirmation
                 │
        ┌────────┼────────┐
        │        │        │
        ▼        ▼        ▼
    🔄 Rotation 🧍 Still  📉 Barometric
        │        │        │
        └────────┼────────┘
                 │
                 ▼
          🚨 CONFIRMED FALL

The additional confirmation stage is used to reduce false fall detections by considering multiple signals instead of relying on a single threshold.

🔧 Hardware Components
🔩 Component	🎯 Purpose
🧠 ESP32	Main controller, processing and communication
📐 MPU6050	Accelerometer and gyroscope for motion and fall detection
❤️ Analog Pulse Sensor	Heart-rate monitoring
🌡️ BMP280/BME280	Temperature and pressure/environmental monitoring
🔋 Battery	Portable power supply
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
Embedded Model — fall_model.h

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

Wi-Fi is used by the ESP32 to communicate with Firebase and upload the wearable's information.

🧠 ESP32
     │
     │ 📶 Wi-Fi
     ▼
☁️ Firebase Realtime Database
🔵 Bluetooth Low Energy

BLE is mainly used during the initial configuration of the wearable.

📱 Mobile Application
          │
          │ 🔵 BLE
          ▼
       🧠 ESP32
          │
          ▼
   💾 Save Configuration
          │
          ▼
        📶 Wi-Fi
☁️ Firebase Integration

Firebase Realtime Database acts as the cloud data layer for SafeBand.

The ESP32 authenticates with Firebase and uploads information associated with the configured Band ID.

📊 Data Stored
Data	Purpose
❤️ Heart Rate	Heart-rate information
🫁 SpO₂	SpO₂ field
🚨 Fall Detected	Fall detection status
👣 Steps	Step count
📌 Status	Normal / Emergency status
🌡️ Temperature	Temperature reading
💨 Pressure	Pressure reading
💧 Humidity	Humidity reading
📉 Barometric Information	Additional fall evidence
🔧 Sensor Status	Sensor availability
⏱️ Last Updated	Latest update timestamp

⚠️ Current Firmware Note: The current firmware contains an SpO₂ field, but the value is a simulated placeholder because the current hardware uses an Analog Pulse Sensor rather than a dedicated red/IR SpO₂ sensor.

📱 Flutter Mobile Application

The Flutter application provides the family-side monitoring interface.

The application can display:
👤 User and family information
❤️ Health-related readings
📊 Wearable information
🚨 Fall and emergency status
🔄 Updated information from Firebase

The ESP32 performs the fall-detection computation, while the Flutter application is used for monitoring and displaying the information.

🔵 BLE Provisioning

During initial setup, configuration information can be provided to the ESP32 through Bluetooth Low Energy.

📦 Provisioning Format
SSID | Wi-Fi Password | Firebase Email | Firebase Password | Band ID

The ESP32 stores the configuration in non-volatile storage and uses it to connect to Wi-Fi and Firebase.

📌 Pin Configuration
📐 MPU6050
SDA → GPIO 21
SCL → GPIO 22
❤️ Analog Pulse Sensor
Signal → GPIO 34
🌡️ BMP280/BME280
SDA → GPIO 4
SCL → GPIO 13
📂 Project Structure
SafeBand/
│
├── 📁 firmware/
│   │
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
│   │
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
1️⃣ ESP32 Firmware

Open the firmware project using PlatformIO or Arduino IDE.

2️⃣ Connect Sensors

Connect the:

📐 MPU6050
❤️ Analog Pulse Sensor
🌡️ BMP280/BME280

according to the pin configuration.

3️⃣ Configure Firebase

Create and configure the Firebase project and Realtime Database.

Add the required Firebase configuration to:

firebase_config.h
4️⃣ Add Machine Learning Model

Place:

fall_model.h

inside the firmware include directory.

5️⃣ Upload Firmware

Connect the ESP32, select the correct board and COM port, build the project, and upload the firmware.

6️⃣ Configure the Wearable

Use BLE provisioning to provide:

📶 Wi-Fi Credentials
☁️ Firebase Credentials
🆔 Band ID
7️⃣ Run Flutter Application

Open the Flutter project, install the required dependencies, and run the application on an Android device or emulator.

🧪 Testing & Diagnostics

The firmware provides serial commands for testing and diagnostics.

Command	Function
f	🚨 Trigger a fake fall
b	🔵 Release BLE
h	💾 Show heap information
s	🔧 Show sensor status
i	🔄 Re-initialize sensors
w	📶 Show saved Wi-Fi
c	🔄 Clear boot count and restart
r	🗑️ Factory reset
🚨 Emergency Flow
             ⌚ ABNORMAL MOTION
                     │
                     ▼
             📐 MPU6050 DATA
                     │
                     ▼
             🤖 ML PREDICTION
                     │
                     ▼
          🔍 FALL CONFIRMATION
                     │
             ┌───────┴───────┐
             │               │
             ▼               ▼
          ❌ NO             🚨 YES
             │               │
             ▼               ▼
       Continue          Emergency
       Monitoring          State
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
🔄 Complete Data Flow
        📐 MPU6050
             │
             ├──────────────┐
             │              │
             ▼              ▼
       Acceleration      Gyroscope
             │              │
             └──────┬───────┘
                    │
                    ▼
               🧠 ESP32
                    │
          ┌─────────┼─────────┐
          │         │         │
          ▼         ▼         ▼
       📊 Data    🤖 ML     ❤️ Health
      Processing  Detection  Monitoring
          │         │         │
          └─────────┼─────────┘
                    │
                    ▼
             🚨 Fall Status
                    │
                    ▼
                📶 Wi-Fi
                    │
                    ▼
          ☁️ Firebase RTDB
                    │
                    ▼
             📱 Flutter App
                    │
                    ▼
             👨‍👩‍👧 Family
🛡️ Safety Concept

SafeBand follows a simple six-stage safety pipeline:

<div align="center">
👁️ SENSE

Collect information from wearable sensors.

⬇️

🧠 PROCESS

Process sensor information using the ESP32.

⬇️

🤖 DETECT

Use Machine Learning to identify a possible fall.

⬇️

🔍 CONFIRM

Check additional motion and environmental evidence.

⬇️

📡 COMMUNICATE

Send the confirmed status to Firebase.

⬇️

🛡️ PROTECT

Provide the information through the Flutter application.

</div>
⚠️ Limitations
📶 Cloud synchronization currently depends on Wi-Fi connectivity.
🧠 Machine Learning predictions can contain errors.
📐 Sensor readings can be affected by sensor placement and environmental conditions.
🫁 The current SpO₂ value is a simulated placeholder.
🏥 SafeBand is a prototype/academic project and should not be considered a medical device or a replacement for professional medical or emergency services.
🚀 Future Enhancements
Enhancement	Description
📍 GPS	Add location tracking
📡 GSM/LTE	Enable communication without Wi-Fi
❤️ Dedicated SpO₂ Sensor	Add actual optical SpO₂ measurement
🔔 Push Notifications	Notify family members about emergencies
💾 Offline Storage	Store data when network is unavailable
🧠 Improved ML Model	Train with larger and more diverse datasets
🔋 Battery Monitoring	Monitor wearable battery level
⚡ Power Optimization	Improve battery life
📈 Health Analytics	Add detailed health and activity analysis
🆘 Emergency Features	Add additional emergency response options
📊 Project Workflow
┌───────────────────────────────┐
│       ⌚ WEARABLE SENSORS     │
│                               │
│  📐 MPU6050                   │
│  ❤️ Pulse Sensor              │
│  🌡️ BMP280/BME280             │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│          🧠 ESP32             │
│                               │
│  Sensor Processing            │
│  Feature Extraction           │
│  Random Forest                │
│  Fall Confirmation            │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│          📶 WI-FI             │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│       ☁️ FIREBASE RTDB        │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│        📱 FLUTTER APP         │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│       👨‍👩‍👧 FAMILY MEMBER      │
└───────────────────────────────┘
🧪 Project Status
🟢 Version 1.0 — Prototype

SafeBand combines:

Category	Technologies
🔌 IoT	ESP32
📐 Sensors	MPU6050, Pulse Sensor, BMP280/BME280
🤖 ML	Random Forest
📡 Communication	Wi-Fi, BLE
☁️ Cloud	Firebase
📱 Mobile	Flutter
💚 SafeBand
<div align="center">
🛡️ SafeBand
“Wear it for the ones who care.”
<br>

⌚ Sensors

⬇️

🧠 ESP32

⬇️

🤖 Machine Learning

⬇️

📶 Wi-Fi

⬇️

☁️ Firebase

⬇️

📱 Flutter

⬇️

👨‍👩‍👧 Family

<br>
🛡️ Safety Today. A Better Tomorrow.
<br>

Version 1.0

</div> ```
