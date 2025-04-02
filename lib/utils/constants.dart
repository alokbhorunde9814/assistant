class AppConstants {
  // App Information
  static const String appName = 'AI Teacher Assistant';
  static const String appVersion = '1.0.0';
  
  // Routes
  static const String homeRoute = '/home';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String createClassRoute = '/create_class';
  static const String joinClassRoute = '/join_class';
  static const String splashRoute = '/splash';
  static const String profileRoute = '/profile';
  static const String editProfileRoute = '/edit_profile';
  static const String searchRoute = '/search';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'app_theme';
  static const String onboardingKey = 'onboarding_complete';
  
  // API Endpoints
  static const String baseUrl = 'https://api.example.com';
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  
  // Error Messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Network error. Please check your connection.';
  static const String authError = 'Authentication failed. Please check your credentials.';
  
  // Form Validation
  static const String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String passwordMinLength = 'Password must be at least 6 characters';
  static const String emailRequired = 'Email is required';
  static const String passwordRequired = 'Password is required';
  static const String invalidEmail = 'Please enter a valid email address';
  
  // Subject Options
  static const List<String> subjectOptions = [
    'Mathematics',
    'Science',
    'English',
    'History',
    'Geography',
    'Computer Science',
    'Art',
    'Music',
    'Physical Education',
    'Foreign Language',
    'Other',
  ];
  
  // App Features
  static const List<Map<String, String>> features = [
    {
      'title': 'AI-Generated Summaries',
      'description': 'Get concise summaries of class content powered by AI',
      'icon': 'auto_awesome',
    },
    {
      'title': 'Automated Grading',
      'description': 'Save time with automatic grading of assignments',
      'icon': 'grading',
    },
    {
      'title': 'Smart Feedback',
      'description': 'Provide personalized feedback to students using AI',
      'icon': 'comment',
    },
    {
      'title': 'Progress Analytics',
      'description': 'Track student progress with detailed analytics',
      'icon': 'analytics',
    },
  ];
  
  // Placeholder Texts
  static const String loremIpsum = 
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla quam velit, vulputate eu pharetra nec, mattis ac neque.';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 800);
} 