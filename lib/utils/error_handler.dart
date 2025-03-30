import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ErrorHandler {
  /// Translates Firebase Auth errors into user-friendly messages
  static String getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'weak-password':
          return 'The password is too weak. Use at least 6 characters.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled.';
        case 'invalid-credential':
          return 'The credentials are invalid or have expired.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with the same email but different sign-in credentials.';
        case 'invalid-verification-code':
          return 'The verification code is invalid.';
        case 'invalid-verification-id':
          return 'The verification ID is invalid.';
        case 'captcha-check-failed':
          return 'The reCAPTCHA verification failed.';
        case 'app-not-authorized':
          return 'The app is not authorized to use Firebase Authentication.';
        case 'network-request-failed':
          return 'A network error occurred. Check your connection.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        default:
          return error.message ?? 'An unknown authentication error occurred.';
      }
    } else {
      return error?.toString() ?? 'An unknown error occurred.';
    }
  }

  /// Translates Firestore errors into user-friendly messages
  static String getFirestoreErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You don\'t have permission to access this resource.';
        case 'not-found':
          return 'The requested document was not found.';
        case 'already-exists':
          return 'A document with the same ID already exists.';
        case 'failed-precondition':
          return 'The operation failed because a condition was not met.';
        case 'aborted':
          return 'The operation was aborted.';
        case 'out-of-range':
          return 'The operation was attempted past the valid range.';
        case 'unavailable':
          return 'The service is currently unavailable. Check your connection.';
        case 'data-loss':
          return 'Unrecoverable data loss or corruption.';
        case 'unauthenticated':
          return 'You need to be logged in to perform this action.';
        case 'resource-exhausted':
          return 'Resource limits exceeded. Try again later.';
        case 'cancelled':
          return 'The operation was cancelled.';
        case 'unknown':
        default:
          return error.message ?? 'An unknown database error occurred.';
      }
    } else if (error is Exception) {
      if (error.toString().contains('Class not found with this code')) {
        return 'Class not found with this code. Please check and try again.';
      } else if (error.toString().contains('already a member')) {
        return 'You are already a member of this class.';
      } else if (error.toString().contains('User not logged in')) {
        return 'You need to be logged in to perform this action.';
      }
      return error.toString();
    } else {
      return error?.toString() ?? 'An unknown error occurred.';
    }
  }

  /// Get a friendly error message for any type of error
  static String getFriendlyErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return getAuthErrorMessage(error);
    } else if (error is FirebaseException) {
      return getFirestoreErrorMessage(error);
    } else {
      return error?.toString() ?? 'An unknown error occurred.';
    }
  }
} 