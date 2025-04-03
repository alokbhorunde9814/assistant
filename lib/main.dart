import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/search_screen.dart';
import 'auth_wrapper.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';
import 'firebase_options.dart';
import 'widgets/vertex_ai_chat.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.web,
      );
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    print('Firebase initialized successfully');
  } catch (e, stackTrace) {
    print('Failed to initialize Firebase: $e');
    print('Stack trace: $stackTrace');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        AppConstants.homeRoute: (context) {
          print('Navigating to HomeScreen route');
          return const HomeScreen();
        },
        AppConstants.splashRoute: (context) => const SplashScreen(),
        AppConstants.loginRoute: (context) => const LoginScreen(),
        AppConstants.profileRoute: (context) => const ProfileScreen(),
        AppConstants.editProfileRoute: (context) => const EditProfileScreen(),
        AppConstants.searchRoute: (context) {
          print('Navigating to SearchScreen route');
          return const SearchScreen();
        },
        '/auth': (context) {
          print('Navigating to AuthWrapper route');
          return const AuthWrapper();
        },
        '/vertex-ai-chat': (context) => const VertexAIChat(),
      },
      // Observe and log navigation events for debugging
      navigatorObservers: [
        NavigationObserver(),
      ],
    );
  }
}

// A custom observer to log navigation events
class NavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('Navigation: Pushed ${route.settings.name ?? route.toString()}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    print('Navigation: Replaced ${oldRoute?.settings.name ?? oldRoute.toString()} with ${newRoute?.settings.name ?? newRoute.toString()}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('Navigation: Popped ${route.settings.name ?? route.toString()}');
  }
}
