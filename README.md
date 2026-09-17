🛡️ SafeBand

💚 Smart Wearable for Safety and Health Monitoring

SafeBand is an IoT-based smart wearable system that monitors movement and health-related information, detects possible falls using Machine Learning, and helps family members monitor the wearer through a Flutter mobile application.

📌 Project Overview

SafeBand is designed as a wearable safety system using an ESP32 as the main controller. The device collects data from the MPU6050 accelerometer and gyroscope, an analog Pulse Sensor, and a BMP280/BME280 sensor. The ESP32 processes the sensor data locally and uses a Random Forest Machine Learning model for fall detection.

When a possible fall is detected, the system performs additional confirmation using impact, wrist rotation, post-impact stillness, and barometric information. If the fall is confirmed, the ESP32 changes the system to an emergency state and uploads the relevant information to Firebase Realtime Database through Wi-Fi. The Flutter mobile application provides the family member with the wearable's information and emergency status.

🎯 Objectives

🛡️ Provide a smart wearable safety solution.

🧠 Detect falls using Machine Learning.

📐 Monitor movement using an accelerometer and gyroscope.

❤️ Monitor heart rate using a Pulse Sensor.

🌡️ Monitor temperature and pressure.

☁️ Store wearable data in Firebase.

📱 Provide a mobile monitoring application.

🔵 Configure the wearable using Bluetooth Low Energy.

🚨 Provide an emergency status after a confirmed fall.

⭐ Key Features

Feature

Description

🧠 ML Fall Detection

Random Forest model classifies motion data

📐 Motion Monitoring

MPU6050 monitors acceleration and rotation

❤️ Heart-Rate Monitoring

Analog Pulse Sensor monitors heart-rate activity

🌡️ Environmental Monitoring

BMP280/BME280 provides temperature and pressure data

🚨 Fall Confirmation

Uses multiple signals to confirm a possible fall

📶 Wi-Fi Communication

ESP32 communicates with Firebase

☁️ Firebase Database

Stores wearable and emergency information

📱 Flutter App

Provides family-side monitoring

🔵 BLE Provisioning

Used for initial device configuration

🏗️ System Architecture

                         👤 WEARER
                            │
                            ▼
                   ┌─────────────────┐
                   │  ⌚ SafeBand     │
                   │     Sensors     │
                   └────────┬────────┘
                            │
             ┌──────────────┼──────────────┐
             │              │              │
             ▼              ▼              ▼
        📐 MPU6050      ❤️ Pulse      🌡️ BMP/BME280
        Motion Sensor    Sensor        Environment
             │              │              │
             └──────────────┼──────────────┘
                            ▼
                   ┌─────────────────┐
                   │     🧠 ESP32    │
                   │                 │
                   │ Sensor Reading  │
                   │ Feature Extract │
                   │ Random Forest   │
                   │ Fall Confirm.   │
                   └────────┬────────┘
                            │
                         📶 Wi-Fi
                            │
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

📡 Sensors collect data
          ↓
🧠 ESP32 receives sensor readings
          ↓
📊 Motion data is processed
          ↓
🔢 22 motion features are extracted
          ↓
🤖 Random Forest predicts possible fall
          ↓
🔍 Additional confirmation is performed
          ↓
🚨 Fall confirmed
          ↓
📶 Data uploaded through Wi-Fi
          ↓
☁️ Firebase stores the information
          ↓
📱 Flutter application displays the status
          ↓
👨‍👩‍👧 Family member monitors the wearer

🧠 Machine Learning – Fall Detection

The MPU6050 continuously provides acceleration and gyroscope readings. The ESP32 maintains a motion window and extracts 22 features from the acceleration data.

📊 Features

The feature vector contains:

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

The trained model is deployed to the ESP32 as:

fall_model.h

🚨 Fall Detection Process

Sustained Free-Fall
        +
      Impact
        ↓
Motion Window Captured
        ↓
22 Features Extracted
        ↓
Random Forest Prediction
        ↓
Additional Evidence
   ┌────┼─────────┐
   │    │         │
Rotation Stillness Barometric
   │    │         │
   └────┼─────────┘
        ↓
  🚨 Confirmed Fall

The additional confirmation stage helps reduce false alarms by considering more than one indication of a fall.

🔧 Hardware Components

🔩 Component

🎯 Purpose

ESP32

Main controller and communication

MPU6050

Accelerometer + gyroscope for movement/fall detection

Analog Pulse Sensor

Heart-rate monitoring

BMP280/BME280

Temperature and pressure/environmental monitoring

Battery / Power Supply

Provides portable power

💻 Technology Stack

🔌 Embedded System

ESP32

C/C++

Arduino Framework

PlatformIO

I²C

GPIO

🤖 Machine Learning

Random Forest

Python

Scikit-learn

Embedded model: fall_model.h

📱 Mobile Application

Flutter

Dart

☁️ Cloud

Firebase Realtime Database

Firebase Authentication

📡 Communication

Wi-Fi

Bluetooth Low Energy (BLE)

📡 Communication

📶 Wi-Fi

Wi-Fi is used to send processed sensor information and emergency status from the ESP32 to Firebase.

🧠 ESP32
   │
   │ Wi-Fi
   ▼
☁️ Firebase Realtime Database

🔵 Bluetooth Low Energy

BLE is used mainly for initial configuration of the wearable.

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
📶 Connect to Wi-Fi

☁️ Firebase Integration

Firebase Realtime Database acts as the cloud data layer for SafeBand.

The ESP32 authenticates with Firebase and uploads information associated with the configured Band ID.

📊 Data Stored

❤️ heartRate
🫁 spo2
🚨 fallDetected
👣 steps
📌 status
🌡️ temperature
💨 pressure
💧 humidity
📉 baroDropM
🔍 baroConfirm
🔧 sensor status
⏱️ lastUpdated

⚠️ Note: In the current firmware, the SpO₂ value is a simulated placeholder because the current hardware uses an analog Pulse Sensor rather than a dedicated red/IR SpO₂ sensor.

📱 Flutter Mobile Application

The Flutter application is the family-side interface of SafeBand.

It is designed to provide:

👤 User and family information

❤️ Health-related readings

📊 Wearable status

🚨 Fall/emergency status

🔄 Updated information from Firebase

👨‍👩‍👧 Family monitoring

The fall-detection computation is performed on the ESP32, while the Flutter application is used for monitoring and displaying the information.

🔵 BLE Provisioning

During the initial setup, configuration information can be provided to the ESP32 through BLE.

📦 Provisioning Format

SSID | Wi-Fi Password | Firebase Email | Firebase Password | Band ID

The ESP32 stores the configuration in non-volatile storage and uses it to connect to Wi-Fi and Firebase.

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

1️⃣ ESP32 Firmware

Open the firmware project using PlatformIO or Arduino IDE.

2️⃣ Connect the Sensors

Connect the MPU6050, Pulse Sensor, and BMP280/BME280 according to the pin configuration.

3️⃣ Configure Firebase

Create the Firebase project and Realtime Database, then add the required Firebase configuration to:

firebase_config.h

4️⃣ Add the ML Model

Place the generated model file in the firmware include directory:

fall_model.h

5️⃣ Upload Firmware

Connect the ESP32, select the correct board and COM port, build the project, and upload the firmware.

6️⃣ Configure Through BLE

Provide:

📶 Wi-Fi credentials
☁️ Firebase credentials
🆔 Band ID

7️⃣ Run Flutter App

Open the Flutter project, install dependencies, and run the application on an Android device or emulator.

🧪 Testing & Diagnostics

The firmware provides serial commands for development and testing.

Command

Function

f

🚨 Trigger a fake fall

b

🔵 Release BLE

h

💾 Show heap information

s

🔧 Show sensor status

i

🔄 Re-initialize sensors

w

📶 Show saved Wi-Fi

c

🔄 Clear boot count and restart

r

🗑️ Factory reset

🚨 Emergency Flow

⌚ Abnormal Motion
       ↓
📐 MPU6050 Processing
       ↓
🤖 ML Prediction
       ↓
🔍 Fall Confirmation
       ↓
   ┌───┴───┐
   │       │
  ❌ No   🚨 Yes
   │       │
   ▼       ▼
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

🧠 Machine Learning predictions may contain errors.

📐 Sensor readings can be affected by sensor placement and environmental conditions.

🫁 The current SpO₂ value is a simulated placeholder.

🏥 SafeBand is an academic/prototype system and is not a replacement for professional medical or emergency services.

🚀 Future Enhancements

📍 GPS-based location tracking

📡 GSM/LTE connectivity

❤️ Dedicated optical heart-rate and SpO₂ sensor

🔔 Push notifications

💾 Offline data storage and synchronization

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

SafeBand follows this pipeline to collect sensor information, process it locally, detect possible falls, confirm the event, communicate the status to the cloud, and provide the information to the family member.

💚 SafeBand

<div align="center">

“Wear it for the ones who care.”

⌚ Sensors → 🧠 ESP32 → 🤖 ML → 📶 Wi-Fi → ☁️ Firebase → 📱 Flutter → 👨‍👩‍👧 Family

🛡️ Safety Today. A Better Tomorrow.

Version 1.0

</div>
