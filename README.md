# 🛡️ SafeBand

## 💚 Smart Wearable for Safety and Health Monitoring

> An IoT-based wearable safety system that monitors movement and health-related information, detects possible falls using Machine Learning, and provides monitoring through a Flutter mobile application.

---

## 📖 About SafeBand

**SafeBand** is an IoT-based smart wearable system developed using **ESP32, MPU6050, Pulse Sensor, BMP280/BME280, Machine Learning, Firebase, BLE, and Flutter**.

The ESP32 acts as the main controller of the wearable. It collects movement data from the **MPU6050 accelerometer and gyroscope**, heart-rate information from the **analog Pulse Sensor**, and environmental information from the **BMP280/BME280 sensor**.

For fall detection, the ESP32 processes the motion data, extracts **22 features**, and uses a **Random Forest Machine Learning model** to identify possible falls. Additional conditions such as **impact, wrist rotation, post-impact stillness, and barometric change** are also considered before confirming a fall.

After a fall is confirmed, the ESP32 enters an emergency state and uploads the relevant information to **Firebase Realtime Database** through Wi-Fi. The **Flutter mobile application** is used by the family member to monitor the wearable information and emergency status.

---

## 🎯 Objectives

- 🛡️ Develop a smart wearable safety system.
- 🧠 Detect falls using Machine Learning.
- 📐 Monitor movement using the MPU6050.
- ❤️ Monitor heart rate using a Pulse Sensor.
- 🌡️ Monitor temperature and pressure.
- ☁️ Store wearable information using Firebase.
- 📱 Provide a Flutter mobile monitoring application.
- 🔵 Configure the wearable using Bluetooth Low Energy.
- 🚨 Provide an emergency status after a confirmed fall.

---

## ⭐ Key Features

| Feature | Description |
|---|---|
| 🧠 Machine Learning | Random Forest based fall classification |
| 📐 Motion Monitoring | MPU6050 accelerometer and gyroscope |
| ❤️ Heart Rate | Analog Pulse Sensor |
| 🌡️ Environment | BMP280/BME280 temperature and pressure |
| 🚨 Fall Confirmation | Multiple motion and environmental checks |
| 📶 Wi-Fi | ESP32 to Firebase communication |
| ☁️ Firebase | Realtime wearable data storage |
| 📱 Flutter | Family monitoring application |
| 🔵 BLE | Initial device provisioning |

---

## 🏗️ System Architecture

```text
                    👤 WEARER
                       |
                       v
                +--------------+
                |  ⌚ SafeBand  |
                |    Sensors   |
                +------+-------+
                       |
          +------------+------------+
          |            |            |
          v            v            v
      📐 MPU6050   ❤️ Pulse    🌡️ BMP/BME280
       Motion       Sensor       Environment
          |            |            |
          +------------+------------+
                       |
                       v
                +--------------+
                |    🧠 ESP32   |
                |              |
                | Data Process |
                | Feature Ext.|
                | Random Forest|
                | Fall Confirm.|
                +------+-------+
                       |
                       | 📶 Wi-Fi
                       v
                +--------------+
                | ☁️ Firebase  |
                | Realtime DB  |
                +------+-------+
                       |
                       v
                +--------------+
                | 📱 Flutter   |
                |     App      |
                +------+-------+
                       |
                       v
                 👨‍👩‍👧 FAMILY
🔄 Working Flow
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
🧠 Machine Learning – Fall Detection

The MPU6050 continuously provides acceleration and gyroscope readings. The ESP32 processes the motion information and maintains a motion window for analysis.

The system extracts 22 features from the motion data.

📊 Features Used
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
Motion Window Captured
        ↓
22 Features Extracted
        ↓
Random Forest Prediction
        ↓
Additional Confirmation
        ↓
+-----------------------------+
| Rotation | Stillness | Baro |
+-----------------------------+
        ↓
🚨 CONFIRMED FALL

The additional confirmation stage helps reduce false fall detections.

🔧 Hardware Components
Component	Purpose
🧠 ESP32	Main controller and processing unit
📐 MPU6050	Accelerometer and gyroscope
❤️ Analog Pulse Sensor	Heart-rate monitoring
🌡️ BMP280/BME280	Temperature and pressure monitoring
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
Embedded model: fall_model.h
📱 Mobile Application
Flutter
Dart
☁️ Backend
Firebase Authentication
Firebase Realtime Database
📡 Communication
Wi-Fi
Bluetooth Low Energy (BLE)
📡 Communication
📶 Wi-Fi

Wi-Fi is used by the ESP32 to communicate with Firebase and upload the wearable's information.

🧠 ESP32
   |
   | Wi-Fi
   v
☁️ Firebase Realtime Database
🔵 Bluetooth Low Energy

BLE is mainly used during the initial configuration of the wearable.

📱 Mobile
   |
   | BLE
   v
🧠 ESP32
   |
   v
💾 Save Configuration
   |
   v
📶 Wi-Fi
☁️ Firebase Integration

Firebase Realtime Database acts as the cloud data layer for SafeBand.

The ESP32 authenticates with Firebase and uploads information associated with the configured Band ID.

📊 Data Stored
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

⚠️ Note: In the current firmware, the SpO₂ value is a simulated placeholder because the current hardware uses an analog Pulse Sensor rather than a dedicated red/IR SpO₂ sensor.

📱 Flutter Application

The Flutter application provides the family-side monitoring interface.

The application is used to display:

👤 User and family information
❤️ Health-related readings
📊 Wearable information
🚨 Fall and emergency status
🔄 Updated information from Firebase

The fall-detection computation is performed on the ESP32, while the Flutter application is used for monitoring and displaying the information.

🔵 BLE Provisioning

During initial setup, configuration information can be provided to the ESP32 through Bluetooth Low Energy.

📦 Provisioning Format
SSID | Wi-Fi Password | Firebase Email | Firebase Password | Band ID

The ESP32 stores the configuration and uses it to connect to Wi-Fi and Firebase.

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
├── firmware/
│   ├── src/
│   │   └── main.cpp
│   │
│   ├── include/
│   │   ├── fall_model.h
│   │   └── firebase_config.h
│   │
│   └── platformio.ini
│
├── flutter_app/
│   ├── lib/
│   │   ├── screens/
│   │   ├── services/
│   │   ├── widgets/
│   │   └── main.dart
│   │
│   └── pubspec.yaml
│
└── README.md
⚙️ Installation & Setup
1️⃣ ESP32 Firmware

Open the firmware project using PlatformIO or Arduino IDE.

2️⃣ Connect Sensors

Connect the MPU6050, Pulse Sensor, and BMP280/BME280 according to the pin configuration.

3️⃣ Configure Firebase

Create and configure the Firebase project and Realtime Database.

Add the required Firebase configuration to:

firebase_config.h

4️⃣ Add Machine Learning Model

Place the trained model file:

fall_model.h

inside the firmware include directory.

5️⃣ Upload Firmware

Connect the ESP32, select the correct board and COM port, build the project, and upload the firmware.

6️⃣ Configure Through BLE

Provide:

📶 Wi-Fi credentials
☁️ Firebase credentials
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
⌚ Abnormal Motion
       ↓
📐 MPU6050 Processing
       ↓
🤖 ML Prediction
       ↓
🔍 Fall Confirmation
       ↓
   ┌───┴────┐
   │        │
  ❌ No    🚨 Yes
   │        │
   ↓        ↓
Continue  Emergency
Monitoring  State
              ↓
           📶 Wi-Fi
              ↓
         ☁️ Firebase
              ↓
         📱 Flutter
              ↓
       👨‍👩‍👧 Family
⚠️ Limitations
📶 Cloud synchronization currently depends on Wi-Fi connectivity.
🧠 Machine Learning predictions can contain errors.
📐 Sensor readings can be affected by sensor placement and environmental conditions.
🫁 The current SpO₂ value is a simulated placeholder.
🏥 SafeBand is a prototype/academic project and is not a replacement for professional medical or emergency services.
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

SafeBand follows this pipeline to sense the wearer's information, process it locally, detect a possible fall, confirm the event, communicate the status to the cloud, and provide the information through the mobile application.

📜 Project Status

SafeBand — Version 1.0

🎓 Academic / Prototype Project

Technologies

IoT + Embedded Systems + Machine Learning + Firebase + Flutter

<div align="center">
🛡️ SafeBand
💚 Wear it for the ones who care.

⌚ Sensors → 🧠 ESP32 → 🤖 ML → 📶 Wi-Fi → ☁️ Firebase → 📱 Flutter

Version 1.0

</div> ```
✅ How to paste it into GitHub
Open your GitHub repository.
Open README.md.
Click ✏️ Edit.
Delete everything currently inside it.
Copy only the content inside my code block above.
Paste it into GitHub.
Click Preview first.
Check that the headings, tables, diagrams and emojis are rendered correctly.
Then click Commit changes.

Do not paste the triple backticks surrounding the entire README — those are only there so I can show you the Markdown without GitHub rendering it inside this chat.

provide once complete

Absolutely. Here is the complete SafeBand README in one place, specifically formatted so you can copy everything inside the code block and paste it directly into GitHub's README.md editor.

Important: Copy from # 🛡️ SafeBand until the final </div>. Do not copy the outer triple backticks.

# 🛡️ SafeBand

## 💚 Smart Wearable for Safety and Health Monitoring

> **SafeBand** is an IoT-based smart wearable safety system that monitors movement and health-related information, detects possible falls using Machine Learning, and allows family members to monitor the wearer through a Flutter mobile application.

---

## 📖 About the Project

**SafeBand** is an IoT-based wearable safety system developed using an **ESP32**, **MPU6050**, **Analog Pulse Sensor**, **BMP280/BME280**, **Random Forest Machine Learning**, **Wi-Fi**, **Firebase**, **Bluetooth Low Energy (BLE)**, and **Flutter**.

The **ESP32** acts as the main controller of the wearable. It continuously collects movement data from the **MPU6050 accelerometer and gyroscope**, heart-rate information from the **Analog Pulse Sensor**, and environmental information from the **BMP280/BME280 sensor**.

For fall detection, the ESP32 processes the motion data, extracts **22 motion features**, and uses a **Random Forest Machine Learning model** to classify possible falls. The system also performs additional confirmation using **free-fall, impact, wrist rotation, post-impact stillness, and barometric change** to reduce false detections.

When a fall is confirmed, the ESP32 changes the wearable to an **Emergency State** and uploads the relevant information to **Firebase Realtime Database** through Wi-Fi. The **Flutter mobile application** provides the family-side interface for monitoring the wearable information and emergency status.

---

## 🎯 Objectives

- 🛡️ Develop a smart wearable safety system.
- 🧠 Detect falls using Machine Learning.
- 📐 Monitor movement using an accelerometer and gyroscope.
- ❤️ Monitor heart rate using an Analog Pulse Sensor.
- 🌡️ Monitor temperature and pressure.
- ☁️ Store wearable information in Firebase.
- 📱 Provide a Flutter-based monitoring application.
- 🔵 Configure the wearable using Bluetooth Low Energy.
- 🚨 Provide an emergency status after a confirmed fall.

---

## ⭐ Key Features

| Feature | Description |
|---|---|
| 🧠 **Machine Learning Fall Detection** | Random Forest model for motion classification |
| 📐 **Motion Monitoring** | MPU6050 accelerometer and gyroscope |
| ❤️ **Heart-Rate Monitoring** | Analog Pulse Sensor |
| 🌡️ **Environmental Monitoring** | BMP280/BME280 temperature and pressure |
| 🚨 **Fall Confirmation** | Multiple motion and environmental checks |
| 📶 **Wi-Fi Communication** | ESP32 to Firebase communication |
| ☁️ **Firebase Database** | Stores wearable and emergency information |
| 📱 **Flutter Application** | Family-side monitoring interface |
| 🔵 **BLE Provisioning** | Initial wearable configuration |

---

## 🏗️ System Architecture

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
                  │ Sensor Reading   │
                  │ Feature Extract. │
                  │ Random Forest    │
                  │ Fall Confirmation│
                  └────────┬─────────┘
                           │
                        📶 Wi-Fi
                           │
                           ▼
                  ┌──────────────────┐
                  │ ☁️ Firebase      │
                  │ Realtime Database│
                  └────────┬─────────┘
                           │
                           ▼
                  ┌──────────────────┐
                  │  📱 Flutter App  │
                  │                  │
                  │ Health Data      │
                  │ Fall Status      │
                  │ Family Monitoring│
                  └────────┬─────────┘
                           │
                           ▼
                    👨‍👩‍👧 FAMILY
🔄 Working Principle
📡 Sensor Data
      │
      ▼
🧠 ESP32 Processing
      │
      ▼
📊 Feature Extraction
      │
      ▼
🤖 Random Forest Prediction
      │
      ▼
🔍 Fall Confirmation
      │
      ▼
🚨 Emergency State
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
👨‍👩‍👧 Family Monitoring
🧠 Machine Learning - Fall Detection

The MPU6050 continuously provides acceleration and gyroscope readings. The ESP32 processes the motion information using a rolling window and extracts 22 features for classification.

📊 Features Used

The feature vector contains:

📈 Mean
📉 Standard Deviation
🔽 Minimum
🔼 Maximum
↔️ Range
📊 25th Percentile
📊 75th Percentile
📐 Skewness
📐 Kurtosis
√ RMS
📐 X-axis statistics
📐 Y-axis statistics
📐 Z-axis statistics

The trained Random Forest model is deployed to the ESP32 as:

fall_model.h
🚨 Fall Detection Process
        Sustained Free-Fall
                │
                ▼
              Impact
                │
                ▼
       Motion Window Captured
                │
                ▼
        22 Features Extracted
                │
                ▼
      Random Forest Prediction
                │
                ▼
       Additional Confirmation
                │
        ┌───────┼────────┐
        ▼       ▼        ▼
    🔄 Rotation 🧍 Still  📉 Barometric
                │
                ▼
         🚨 CONFIRMED FALL

The additional confirmation stage is used to reduce false fall detections by considering multiple signals instead of relying on a single sensor condition.

🔧 Hardware Components
Component	Purpose
🧠 ESP32	Main controller, processing and communication
📐 MPU6050	Accelerometer and gyroscope for movement and fall detection
❤️ Analog Pulse Sensor	Heart-rate monitoring
🌡️ BMP280/BME280	Temperature and pressure/environmental monitoring
🔋 Battery / Power Supply	Portable power for the wearable
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
☁️ Backend and Database
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

⚠️ Current Firmware Note: The current firmware contains an SpO₂ field, but the value is a simulated placeholder because the current hardware uses an Analog Pulse Sensor rather than a dedicated red/IR SpO₂ sensor.

📱 Flutter Mobile Application

The Flutter application provides the family-side monitoring interface for SafeBand.

The application is designed to display:

👤 User and family information
❤️ Health-related readings
📊 Wearable information
🚨 Fall and emergency status
🔄 Updated information from Firebase

The fall-detection computation is performed on the ESP32, while the Flutter application is used for monitoring and displaying the information.

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
⚙️ Installation and Setup
1️⃣ ESP32 Firmware

Open the firmware project using PlatformIO or Arduino IDE.

2️⃣ Connect the Sensors

Connect the MPU6050, Analog Pulse Sensor, and BMP280/BME280 according to the pin configuration.

3️⃣ Configure Firebase

Create and configure the Firebase project and Realtime Database.

Add the required Firebase configuration to:

firebase_config.h
4️⃣ Add the Machine Learning Model

Place the trained model file:

fall_model.h

inside the firmware include directory.

5️⃣ Upload the Firmware

Connect the ESP32, select the correct board and COM port, build the project, and upload the firmware.

6️⃣ Configure the Wearable

Use BLE provisioning to provide:

📶 Wi-Fi Credentials
☁️ Firebase Credentials
🆔 Band ID
7️⃣ Run the Flutter Application

Open the Flutter project, install the required dependencies, and run the application on an Android device or emulator.

🧪 Testing and Diagnostics

The ESP32 firmware provides serial commands for testing and diagnostics.

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
⌚ Abnormal Motion
       │
       ▼
📐 MPU6050 Processing
       │
       ▼
🤖 ML Prediction
       │
       ▼
🔍 Fall Confirmation
       │
       ▼
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
🔄 Complete Data Flow
📐 MPU6050
    │
    ├──────────────┐
    │              │
    ▼              ▼
Motion Data     Gyroscope Data
    │              │
    └──────┬───────┘
           ▼
     🧠 ESP32
           │
           ├── 📊 Feature Extraction
           │
           ├── 🤖 Random Forest
           │
           ├── 🚨 Fall Confirmation
           │
           └── ❤️ Health Monitoring
           │
           ▼
       📶 Wi-Fi
           │
           ▼
  ☁️ Firebase Realtime Database
           │
           ▼
     📱 Flutter App
           │
           ▼
    👨‍👩‍👧 Family Member
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

The wearable senses the user's movement and health-related information, processes it locally, detects possible falls, confirms the event using multiple signals, communicates the status to the cloud, and provides the information through the mobile application.

⚠️ Limitations
📶 Cloud synchronization currently depends on Wi-Fi connectivity.
🧠 Machine Learning predictions can contain errors.
📐 Sensor readings can be affected by sensor placement and environmental conditions.
🫁 The current SpO₂ value is a simulated placeholder.
🏥 SafeBand is a prototype/academic project and should not be considered a medical device or a replacement for professional medical or emergency services.
🚀 Future Enhancements
📍 GPS-based location tracking
📡 GSM/LTE communication
❤️ Dedicated optical heart-rate and SpO₂ sensor
🔔 Push notification integration
💾 Offline data buffering and synchronization
🧠 Larger and more diverse fall-detection dataset
📊 Improved Machine Learning model evaluation
🔋 Battery-level monitoring
⚡ Power optimization
📈 Detailed health and activity analytics
🆘 Additional emergency response features
📊 Project Workflow Summary
        ┌─────────────────────┐
        │ ⌚ WEARABLE SENSORS  │
        └──────────┬──────────┘
                   │
                   ▼
        ┌─────────────────────┐
        │ 🧠 ESP32 PROCESSING │
        └──────────┬──────────┘
                   │
                   ▼
        ┌─────────────────────┐
        │ 🤖 ML FALL DETECTION│
        └──────────┬──────────┘
                   │
                   ▼
        ┌─────────────────────┐
        │ 🚨 FALL CONFIRMATION│
        └──────────┬──────────┘
                   │
                   ▼
        ┌─────────────────────┐
        │ 📶 WI-FI            │
        └──────────┬──────────┘
                   │
                   ▼
        ┌─────────────────────┐
        │ ☁️ FIREBASE         │
        └──────────┬──────────┘
                   │
                   ▼
        ┌─────────────────────┐
        │ 📱 FLUTTER APP      │
        └──────────┬──────────┘
                   │
                   ▼
        ┌─────────────────────┐
        │ 👨‍👩‍👧 FAMILY         │
        └─────────────────────┘
🧪 Current Project Status
Version 1.0

SafeBand is developed as an academic/prototype project combining:

IoT + Embedded Systems + Machine Learning + Cloud Database + Mobile Application

🔩 Current Hardware

ESP32 + MPU6050 + Analog Pulse Sensor + BMP280/BME280

💻 Current Software

C/C++ + Arduino + Random Forest + Firebase + Flutter

📡 Current Communication

Wi-Fi + Bluetooth Low Energy

🔮 Future Vision

SafeBand can be further developed into a complete wearable safety platform with:

Real-time location + Cellular communication + Dedicated health sensors + Push notifications + Offline synchronization + Advanced Machine Learning

<div align="center">
🛡️ SafeBand
💚 Wear it for the ones who care.

⌚ Sensors → 🧠 ESP32 → 🤖 ML → 📶 Wi-Fi → ☁️ Firebase → 📱 Flutter → 👨‍👩‍👧 Family

🛡️ Safety Today. A Better Tomorrow.

Version 1.0

</div> ```
