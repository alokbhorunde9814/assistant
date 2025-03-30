import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Lazy initialization of GoogleSignIn
  GoogleSignIn? _googleSignIn;

  // Get GoogleSignIn instance only when needed (Android/iOS only)
  GoogleSignIn get googleSignIn {
    if (_googleSignIn == null && !kIsWeb) {
      _googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
        ],
      );
    }
    return _googleSignIn!;
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Skip Google Sign-In for web
      if (kIsWeb) {
        throw UnsupportedError('Google Sign-In is currently disabled for web in this app');
      }
      
      // For mobile platforms, use GoogleSignIn
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      // If sign in process was aborted
      if (googleUser == null) {
        return null;
      }

      // Obtain auth details from the Google Sign-In
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create new credential for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow; // Let the UI handle the specific error
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Error signing in with email and password: $e');
      rethrow; // Let the UI handle the specific error
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Error registering with email and password: $e');
      rethrow; // Let the UI handle the specific error
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (!kIsWeb && _googleSignIn != null) {
        await _googleSignIn!.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
} 