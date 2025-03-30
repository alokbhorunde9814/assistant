# Firestore Setup for Class Management

This guide explains how to set up and configure Firestore for the class management functionality in the AI Teacher Assistant app.

## 1. Enable Firestore in Firebase Console

1. Go to the [Firebase Console](https://console.firebase.google.com/) and select your project.
2. In the left sidebar, click on "Firestore Database".
3. Click "Create database" if you haven't already set up Firestore.
4. Choose "Start in production mode" and select a location closest to your users.
5. Click "Enable" to create the Firestore database.

## 2. Deploy Firestore Security Rules

1. In the Firebase Console, go to the "Firestore Database" section.
2. Click on the "Rules" tab.
3. Copy and paste the contents of the `firestore.rules` file from this project.
4. Click "Publish" to deploy the security rules.

Alternatively, you can deploy the rules using the Firebase CLI:

```bash
firebase deploy --only firestore:rules
```

## 3. Data Model

The app uses the following collections and documents in Firestore:

### Classes Collection

Each document in the `classes` collection represents a class and has the following fields:

- `id`: The unique identifier for the class (string)
- `name`: The name of the class (string)
- `code`: A unique code used to join the class (string)
- `description`: Description of the class (string)
- `ownerId`: The user ID of the teacher who created the class (string)
- `ownerName`: The display name of the teacher (string)
- `subject`: The subject of the class (string)
- `studentIds`: Array of user IDs for students who joined the class (array of strings)
- `createdAt`: Timestamp when the class was created (timestamp)
- `hasAutomatedGrading`: Whether automated grading is enabled (boolean)
- `hasAiFeedback`: Whether AI feedback is enabled (boolean)

### Users Collection (Future Enhancement)

This collection is prepared for future enhancements. Each document would represent a user with the following fields:

- `uid`: The Firebase Auth user ID (string)
- `displayName`: The user's display name (string)
- `email`: The user's email address (string)
- `role`: The user's role, e.g., "teacher" or "student" (string)
- `createdAt`: Timestamp when the user account was created (timestamp)

## 4. Testing Firestore Integration

To test if your Firestore integration is working correctly:

1. Run the app and sign in with a valid Firebase account.
2. Create a new class through the app.
3. Check the Firebase Console to verify the class was created in the `classes` collection.
4. Try joining the class from another account using the class code.
5. Verify that the student ID was added to the `studentIds` array in the class document.

## 5. Firestore Indexes (If Needed)

For most queries in this app, you won't need to create custom indexes. However, if you see an error about missing indexes when running complex queries, follow the link provided in the error message to create the required index.

## 6. Security Considerations

The security rules in `firestore.rules` are designed to:

- Allow users to read and write only their own user documents.
- Allow users to read classes they own or are members of.
- Allow only class owners to update or delete classes.
- Allow students to update a class document only when removing themselves from the class.

Ensure that these security rules are properly deployed to protect your data.

## 7. Troubleshooting

If you encounter issues with Firestore access:

1. Check that you're properly authenticated in Firebase Auth.
2. Verify that your security rules are correctly deployed.
3. Check the Firebase console logs for any error messages.
4. Ensure your app has the correct Firebase configuration in `firebase_options.dart`. 