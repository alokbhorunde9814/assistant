# Firebase Login App

A Flutter application demonstrating Firebase Authentication with Google Sign-In, Email/Password Sign-In, and Firebase integration.

## Configuration Status

✅ Splash Screen with animations  
✅ Firebase Core, Auth, and Firestore  
✅ Email/Password Authentication  
✅ Google Sign-In (needs SHA-1 for Android)  

## Firebase Connection

This app is connected to the Firebase project:
- **Project ID:** myapp-6ed81
- **Web Client ID:** 702431682405-6m7t60ieo7udrbcv69k83dk30uk34r5o.apps.googleusercontent.com

## Setup Instructions

### 1. Add SHA-1 Certificate for Android Google Sign-In

1. Run the following command in the project directory to get your debug SHA-1:

   ```
   cd android && ./gradlew signingReport
   ```

2. Go to the [Firebase Console](https://console.firebase.google.com/)
3. Select your project → Project settings
4. Under "Your apps", select the Android app
5. Click "Add fingerprint" and add your SHA-1
6. Update your `google-services.json` file

### 2. Enable Authentication Methods

1. In the Firebase console, go to "Authentication" in the left sidebar
2. Click on "Sign-in method"
3. Enable the "Email/Password" sign-in method
4. Enable the "Google" sign-in method
5. For Google Sign-In, provide your support email

## Features

- Beautiful gradient splash screen
- Google Sign-In Authentication
- Email/Password Sign-In and Registration
- User profile display
- Email verification
- Secure authentication flow
- Responsive UI with Material 3

## Running the App

```
flutter run
```

## Troubleshooting

- If you encounter build issues, check that your Firebase configuration files match your project
- For Google Sign-In issues, verify that you've added the correct SHA-1 fingerprint to your Firebase project
- Make sure you have a working internet connection when testing authentication
