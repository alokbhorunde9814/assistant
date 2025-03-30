import 'dart:async';
import 'package:flutter/material.dart';
import '../auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _welcomeOpacityAnimation;
  
  bool _showWelcomeText = false;
  bool _beginNavigation = false;

  @override
  void initState() {
    super.initState();
    
    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    
    // Logo fade & scale animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    
    // Slide up animation for welcome text
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );
    
    // Opacity animation for welcome text
    _welcomeOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );

    // Start animation
    _animationController.forward();
    
    // Show welcome text after a delay
    Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _showWelcomeText = true;
        });
      }
    });
    
    // Navigate to AuthWrapper after delay
    Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() {
          _beginNavigation = true;
        });
        _navigateToNextScreen();
      }
    });
  }
  
  void _navigateToNextScreen() {
    print('SplashScreen: Navigating to AuthWrapper');
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // Purple to pink to orange gradient similar to the image
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6A3DE8), // Purple
              Color(0xFFE43DB5), // Pink
              Color(0xFFFF9472), // Orange
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo
                  Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.school_rounded,
                            color: Color(0xFFE43DB5),
                            size: 70,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Welcome text with animation
                  if (_showWelcomeText)
                    Opacity(
                      opacity: _welcomeOpacityAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Column(
                          children: [
                            // Main title
                            const Text(
                              'Welcome to TeachAssist',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 5.0,
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Subtitle
                            const Text(
                              'Your AI-powered learning companion',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4.0,
                                    color: Colors.black26,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 30),
                            
                            // Dots animation for loading
                            if (!_beginNavigation)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildLoadingDot(delay: 0),
                                  const SizedBox(width: 12),
                                  _buildLoadingDot(delay: 0.2),
                                  const SizedBox(width: 12),
                                  _buildLoadingDot(delay: 0.4),
                                ],
                              )
                            else
                              const Text(
                                "Let's get started!",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildLoadingDot({required double delay}) {
    // Create a repeating pulse animation for each dot
    final Animation<double> pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 1.0),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 1.0),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          delay, // Start with delay
          1.0, // End at the end of the controller's duration
          curve: Curves.easeInOut,
        ),
      ),
    );
    
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3 + (pulseAnimation.value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
} 