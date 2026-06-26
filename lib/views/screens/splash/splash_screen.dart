import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/settings_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../auth/auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _introController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  String _loadingText = "Loading Nupe Songs...";

  // Brand Colors from screenshot
  static const Color nupeBlue = Color(0xFF001199);
  static const Color nupeGreen = Color(0xFF389F38);
  static const Color nupeRed = Color(0xFFE52A1A);

  @override
  void initState() {
    super.initState();

    // Intro scale/fade animation
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeIn,
      ),
    );

    // Continuous pulse animation for outer logo ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Continuous rotation for inner orbits
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _introController.forward().then((_) {
      _pulseController.repeat(reverse: true);
    });

    _rotationController.repeat();

    // Start background loading tasks simulation
    _runLoadingTasks();
  }

  Future<void> _runLoadingTasks() async {
    if (mounted) {
      setState(() {
        _loadingText = "Restoring user session...";
      });
    }
    
    // Attempt auto-login using persisted credentials
    try {
      final authController = context.read<AuthController>();
      await authController.tryAutoLogin();
    } catch (e) {
      // Gracefully capture session recovery failures
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _loadingText = "Setting up sound database...";
      });
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _loadingText = "Scanning Nupe music archive...";
      });
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() {
        _loadingText = "Done!";
      });
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    final settingsController = context.read<SettingsController>();
    final authController = context.read<AuthController>();
    
    final Widget destination;
    if (settingsController.isFirstLaunch) {
      destination = const OnboardingScreen();
    } else if (authController.isAuthenticated || authController.isGuest) {
      destination = const HomeScreen();
    } else {
      destination = const AuthScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  void dispose() {
    _introController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF03040B), // Extremely dark blue-black
              Color(0xFF090A15), // Deep midnight blue
              Color(0xFF020306), // Pure pitch black
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Ambient Orbs based on Brand Colors
            // Blue Orb (top-left)
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: nupeBlue.withValues(alpha: 0.22),
                      blurRadius: 120,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
            // Green Orb (middle-right)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.35,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: nupeGreen.withValues(alpha: 0.12),
                      blurRadius: 120,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
            ),
            // Red Orb (bottom-left)
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: nupeRed.withValues(alpha: 0.15),
                      blurRadius: 120,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
            ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo Assembly
                  AnimatedBuilder(
                    animation: ListNotifier([_introController, _pulseController]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: SizedBox(
                      width: 170,
                      height: 170,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer Pulsing Red Ring
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: nupeRed.withValues(alpha: 0.4),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Middle Counter-Clockwise Rotating Green Ring (Arc)
                          RotationTransition(
                            turns: Tween<double>(begin: 1.0, end: 0.0).animate(_rotationController),
                            child: const SizedBox(
                              width: 125,
                              height: 125,
                              child: CircularProgressIndicator(
                                value: 0.70,
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(nupeGreen),
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          ),

                          // Inner Clockwise Rotating Blue Ring (Arc)
                          RotationTransition(
                            turns: _rotationController,
                            child: const SizedBox(
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator(
                                value: 0.60,
                                strokeWidth: 3.5,
                                valueColor: AlwaysStoppedAnimation<Color>(nupeBlue),
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          ),

                          // Core Glowing Emblem (White Circle + Icon)
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  blurRadius: 25,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.music_note_rounded,
                              size: 42,
                              color: Color(0xFF0F0C1B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Brand Text with Tricolor Gradient (Blue -> Green -> Red)
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        colors: [
                          nupeBlue,
                          nupeGreen,
                          nupeRed,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    child: const Text(
                      'NUPE SONGS',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        color: Colors.white, // Required for shader mask to work
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Slogan
                  Text(
                    'Tradition Meets Rhythm',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.45),
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom loading indicators
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Sleek Custom Linear Progress Bar matching the tricolor theme
                  Container(
                    width: 120,
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [nupeBlue, nupeGreen, nupeRed],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _loadingText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple Helper to listen to multiple AnimationControllers
class ListNotifier extends ChangeNotifier implements Listenable {
  final List<Listenable> listenables;

  ListNotifier(this.listenables) {
    for (final listenable in listenables) {
      listenable.addListener(notifyListeners);
    }
  }

  @override
  void dispose() {
    for (final listenable in listenables) {
      listenable.removeListener(notifyListeners);
    }
    super.dispose();
  }
}
