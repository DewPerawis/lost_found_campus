
# Lost & Found @Campus Application  
A Flutter + Firebase mobile application for reporting, browsing, and managing lost and found items on campus.

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-Live-orange?logo=firebase&logoColor=white" />
  <img src="https://img.shields.io/badge/Platform-Android-green" />
  <img src="https://img.shields.io/badge/Status-Completed-success" />
  <img src="https://img.shields.io/badge/License-Academic-lightgrey" />
</p>

---

## 🎥 Presentation Video & Demo Video 
<p> <a href="https://youtu.be/9TeAmi0ed8E" target="_blank"> <img src="https://img.shields.io/badge/Watch%20Presentation%20Video%20&%20Demo%20Video-FF0000?logo=youtube&logoColor=white&style=for-the-badge" /> </a> </p>

---

## 🖥 Presentation File
<p> <a href="presentation/Gr15_ITCS259_Final_Presentation.pdf"> <img src="https://img.shields.io/badge/Download%20Presentation-PDF-blue?style=for-the-badge&logo=adobeacrobatreader" /> </a> </p>

---

## 📄 Project Report
<p> <a href="report/Gr15_ITCS259_Final_Report.pdf"> <img src="https://img.shields.io/badge/Download%20Report-PDF-blue?style=for-the-badge&logo=adobeacrobatreader" />  </a> </p>

---

## 📌 Overview

This application allows users to:
- Report **lost or found** items  
- Upload and view item images  
- Chat with users to arrange item returns  
- Manage their own posts and profile settings  

This project was developed for the **ITCS259 – Mobile Application Development** course.

---

## 🚀 Technologies Used

- **Flutter & Dart**
- **Firebase Authentication**
- **Cloud Firestore (NoSQL)**
- **Firebase Storage**
- **Material Design UI**

---

## 📂 Project Structure

```

lib/
├── models/
│    ├── item.dart
│    └── mock_data.dart
│
├── screens/
│    ├── add_item_page.dart
│    ├── chat_list_page.dart
│    ├── chat_page.dart
│    ├── home_menu_page.dart
│    ├── item_detail_page.dart
│    ├── login_page.dart
│    ├── lost_list_page.dart
│    ├── my_post_page.dart
│    ├── other_profile_page.dart
│    └── profile_page.dart
│
├── services/
│    └── chat_service.dart
│
├── widgets/
│    ├── app_button.dart
│    ├── app_input.dart
│    ├── bottom_home_bar.dart
│    ├── item_tile.dart
│    └── firebase_options.dart
│
├── main.dart
└── theme.dart

````

---

## 🛠 Prerequisites

- Flutter SDK installed  
- Android Studio or VS Code  
- Firebase account  
- Emulator or physical device  

---

## 📥 Installation & Setup

### 1️⃣ Clone the Repository

```bash
git clone <repository-link>
cd lost_found_campus
````

### 2️⃣ Install Flutter Dependencies

```bash
flutter pub get
```

### 3️⃣ Firebase Setup

Create a Firebase project and enable:

* **Email/Password Authentication**
* **Cloud Firestore**
* **Firebase Storage**

Add Google config files:

* `google-services.json` → `android/app/`
* (iOS) `GoogleService-Info.plist` → Xcode Runner target

### 4️⃣ Run the Application

```bash
flutter run
```

---

## ⚠️ IMPORTANT: 🔑 Key Notice

If you clone this repository and the app does not run correctly,  
please generate **your own Google Cloud / Firebase API keys** and update the config files.

> For security reasons, the original API keys used in my development
> have been rotated and should no longer be used.

Steps (brief):
1. Create your own Firebase / Google Cloud project.
2. Enable the required APIs and generate new API keys.
3. Replace the API key(s) in `lib/firebase_options.dart` (and any other config files, if needed).

----

## 📱 Key Features

### 🔐 Authentication

* Register / Login
* Email verification & password reset
* Error validation

### 📦 Lost & Found Management

* Create lost/found posts
* Upload item images
* Edit or delete posts
* Search and filter items

### 💬 Real-time Chat

* Send/receive messages using Firestore
* View chat list and history
* Contact item owner directly

### 👤 Profile System

* Edit profile info
* Change password
* Delete account
* Delete all posts

---

## 🗄 Database / SQL Files

This project **does not use SQL**.

Instead, it uses:

* **Firebase Authentication**
* **Cloud Firestore (NoSQL)**
* **Firebase Storage**

No `.sql` file is needed. This satisfies the course requirement by clarification.

---

## 📁 Datasets / Assets

The application does not include any datasets or static assets. All data such as user information, lost/found items, and chat messages 
is stored directly in Firebase (Authentication, Firestore, and Storage). No local assets are required for the functionality of the application.

---

## ⚠ Known Limitations

* Requires internet connection
* Firestore rules may need strengthening for production
* FCM push notifications optional/not fully configured

---

## 👨‍💻 Contributors

| Name                      | Student ID | Responsibilities                                           |
| ------------------------- | ---------- | ---------------------------------------------------------- |
| **Perawis Buranasing**    | 6688012    | Core logic, code implementation, API, navigation           |
| **Phana Mahachairachun**  | 6688061    | UX/UI design, report writing, presentation                 |
| **Pathompong Prasitphol** | 6688088    | Chat system, Firestore data structure, profile integration |

---

## 📄 License

This project is for **academic and educational purposes only**.

---
