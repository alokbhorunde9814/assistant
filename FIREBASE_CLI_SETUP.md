# Firebase CLI Setup Guide

This guide will help you set up Firebase in your Flutter project using the Firebase CLI, which is easier and more reliable than manual configuration.

## 1. Install the Firebase CLI

First, you need to install the Firebase CLI. You can do this using npm:

```bash
npm install -g firebase-tools
```

## 2. Log in to Firebase

Log in to your Firebase account:

```bash
firebase login
```

This will open a browser window where you can sign in with your Google account that has access to Firebase.

## 3. Install the FlutterFire CLI

The FlutterFire CLI helps configure Firebase for Flutter:

```bash
dart pub global activate flutterfire_cli
```

## 4. Initialize Firebase in Your Project

Navigate to your project directory and run:

```bash
cd firebase_login
flutterfire configure
```

This interactive command will:
1. Prompt you to select a Firebase project (or create a new one)
2. Choose which platforms to configure (Android, iOS, web)
3. Automatically download the necessary configuration files
4. Create a `firebase_options.dart` file with your project's configuration

## 5. Update Your main.dart File

The FlutterFire CLI will generate a `firebase_options.dart` file. Make sure your `main.dart` initializes Firebase with these options:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```

## 6. Enable Authentication Methods

After configuration, go to the Firebase Console:
1. Select your project
2. Go to "Authentication" in the left sidebar
3. Click on "Sign-in method"
4. Enable the authentication methods you want to use (Email/Password, Google, etc.)

## 7. Run Your App

Now you can run your app with Firebase properly configured:

```bash
flutter run
```

## Troubleshooting

- If you get SHA-1 fingerprint errors for Google Sign-In on Android, run:
  ```bash
  cd android && ./gradlew signingReport
  ```
  Then add the SHA-1 fingerprint to your Firebase project in the console.

- If you encounter version compatibility issues, check that your Firebase packages in `pubspec.yaml` are using compatible versions. 