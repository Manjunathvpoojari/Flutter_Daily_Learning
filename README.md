# Flutter Login App – Feature Evolution (Phase 1, Phase 2, and Phase 3 Learning)

This Login App is developed as part of my mentor-guided Flutter internship learning.  
The application has been continuously enhanced with new features as concepts were introduced during daily sessions.

---
## **Phase 1**
---

## 🚀 Core Features

- Username & Password Input
- Password Visibility Toggle (Obscure Text)
- Form Validation using `GlobalKey`
- TextFormField Validators
- Navigation using `Navigator.push()` and `Navigator.pop()`
- Home Page after Successful Login

---

## 🧠 UI & UX Enhancements

- AlertDialog for Login Feedback
- SnackBar Notifications
- BottomSheet Implementation
- Toast Message Design
- Fade, Scale & Slide Animations
- Lottie Animation Integration (Splash & Login Screen)
- Improved UI Styling & Layout Alignment

---

## 📱 Navigation & Multi-Screen Implementation

- Login Page → Home Page Navigation
- Button-based Screen Routing
- Navigation Flow Control
- Dynamic Feature Integration inside Home Page

---

## 📂 List & Grid Implementations

- ListView (Static & Dynamic)
- GridView Photo Gallery Layout
- Stack Widget for Overlay UI
- Scroll Physics Implementation

---

## 🔄 State Management

- Stateful vs Stateless Widget Implementation
- setState() Usage
- Inherited Widgets
- Provider Setup & Implementation
- Shared State Updates Across Screens

---
## **Phase 2**
---

## 🌐 Networking & API Integration

- REST API Integration using `http` package
- GET Request Handling
- JSON Parsing
- Parsing List of Objects
- Future, Async & Await Implementation
- FutureBuilder for Displaying API Data
- Random Joke API Integration
- Random User Profile API Integration

---

## 🛠 Project Configuration & Setup

- pubspec.yaml Dependency Management
- Asset Image Configuration
- Lottie Asset Setup
- Emulator Testing (Android Studio)
- VS Code Development Workflow
- GitHub Version Control Integration

---

## 🧪 Assessments & Practice Integration

- Splash Screen Implementation
- Continuous Feature Enhancement Based on Mentor Guidance
- Weekend Assignment Integration into Login App ex- video intro to this

---
## **Phase 3**
---

## 🔥 Firebase Integration (Initial Setup – Google Sign-In)

- Created a Firebase project using Firebase Console.
- Registered the Android application with the correct package name.
- Downloaded and added `google-services.json` inside the `android/app/` directory.
- Updated project-level and app-level `build.gradle.kts` files with required Firebase plugins.
- Added necessary dependencies in `pubspec.yaml`:
  - `firebase_core`
  - `firebase_auth`
  - `google_sign_in`
- Executed `flutter pub get` to install dependencies.
- Initialized Firebase in `main.dart` using:
  - `WidgetsFlutterBinding.ensureInitialized()`
  - `Firebase.initializeApp()`
- Implemented Google Sign-In authentication flow.
- Successfully connected Google credentials with Firebase Authentication for secure login.

---

## 🔥Continue with Firebase

- Integrated **Firebase Authentication** and **Cloud Firestore** with the Flutter application.
- Implemented user authentication using **Email and Password** through Firebase Auth.
- Developed a **User Registration feature** that allows new users to create an account within the application.
- Stored user information such as **username and email** in **Firebase Cloud Firestore**.
- Enabled users to **log in securely using their registered email and password**, with authentication handled by Firebase.
- Ensured seamless interaction between the Flutter frontend and Firebase backend for user data management.

---

## 🧑🏻‍🎓 CRUD Operations on Student List

- Implemented **CRUD operations using Firebase** on the Student List page.
- The Firebase database was successfully connected to store and manage student records.
- The page was designed with a **modern interface**, including proper alignment, icons, and a clean layout.
- An **Add Student** section was integrated, allowing users to add new student details easily.
- The added students are displayed in a **dynamic list view**.
- Users can **edit existing student details** or **delete records safely** using appropriate action icons.
- Users can even **Search for the student** and is guided through proper actions.
- Users can even **Filter out the Students** based on the Grades sections.
- Overall, the implementation ensures **efficient data management and a user-friendly interface**.

---
## 📌 Project Status

This Login App is a continuously evolving learning project.  
New features are regularly integrated as new Flutter concepts are learned.
