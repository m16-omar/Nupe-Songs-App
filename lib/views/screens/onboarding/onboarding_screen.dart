import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/settings_controller.dart';
import '../auth/auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _vinylController;

  // Brand Colors
  static const Color nupeBlue = Color(0xFF001199);
  static const Color nupeGreen = Color(0xFF389F38);
  static const Color nupeRed = Color(0xFFE52A1A);

  @override
  void initState() {
    super.initState();
    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _vinylController.dispose();
    super.dispose();
  }

  Color _getActiveColor(int index) {
    switch (index) {
      case 0:
        return nupeBlue;
      case 1:
        return nupeGreen;
      case 2:
      default:
        return nupeRed;
    }
  }

  void _finishOnboarding(BuildContext context) {
    context.read<SettingsController>().completeOnboarding();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AuthScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _getActiveColor(_currentPage);

    return Scaffold(
      backgroundColor: const Color(0xFF03040B),
      body: Stack(
        children: [
          // Dynamic Background Ambient Glow matching the active page
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            top: -100,
            left: _currentPage == 0
                ? -50
                : _currentPage == 1
                    ? 50
                    : 150,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.15),
                    blurRadius: 130,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          // Slides PageView
          PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: [
              // Slide 1
              _buildSlide(
                context: context,
                title: "Nupe Heritage & Culture",
                description:
                    "Discover and listen to traditional Nupe music and contemporary rhythms in premium audio quality.",
                illustration: _buildVinylIllustration(),
              ),
              // Slide 2
              _buildSlide(
                context: context,
                title: "Custom Music Library",
                description:
                    "Create playlists, favorite songs, and manage your local offline audio tracks with a tap.",
                illustration: _buildLibraryIllustration(),
              ),
              // Slide 3
              _buildSlide(
                context: context,
                title: "Advanced Playback",
                description:
                    "Equipped with sleep timers, equalizer modes, and customizable dark themes for the ultimate listening session.",
                illustration: _buildPlaybackIllustration(),
              ),
            ],
          ),

          // Slide indicators & navigation bottom bar
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: Column(
              children: [
                // Indicators Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) => _buildIndicator(index)),
                ),
                const SizedBox(height: 40),

                // Navigation Controls
                _currentPage == 2
                    ? SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: activeColor,
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shadowColor: activeColor.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => _finishOnboarding(context),
                          child: const Text(
                            "Get Started",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => _finishOnboarding(context),
                            child: Text(
                              "SKIP",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          FloatingActionButton.extended(
                            backgroundColor: activeColor,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            },
                            label: const Text(
                              "NEXT",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            icon: const Icon(Icons.arrow_forward),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide({
    required BuildContext context,
    required String title,
    required String description,
    required Widget illustration,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Visual Illustration
          SizedBox(
            height: 240,
            child: Center(child: illustration),
          ),
          const SizedBox(height: 50),
          // Slide Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          // Slide Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 100), // Spacing for bottom controls
        ],
      ),
    );
  }

  // Active Indicator Dot
  Widget _buildIndicator(int index) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? _getActiveColor(_currentPage) : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  // 1. Rotating Vinyl Disc Widget for Slide 1
  Widget _buildVinylIllustration() {
    return RotationTransition(
      turns: _vinylController,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Black Vinyl Record
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF111116),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: nupeBlue.withValues(alpha: 0.3),
                  blurRadius: 35,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          // Concentric Grooves
          ...List.generate(3, (index) {
            final size = 180.0 - (index + 1) * 30.0;
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
              ),
            );
          }),
          // Tricolor Vinyl Label Center
          Container(
            width: 55,
            height: 55,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [nupeBlue, nupeGreen, nupeRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Center Spindle Hole
          Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF03040B),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Mock Library/Music cards stacked for Slide 2
  Widget _buildLibraryIllustration() {
    return SizedBox(
      width: 200,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Card
          Transform.translate(
            offset: const Offset(-15, -15),
            child: Transform.rotate(
              angle: -0.1,
              child: _buildMockPlaylistCard("Traditional Rhythms", Colors.grey[900]!, nupeBlue),
            ),
          ),
          // Foreground Card
          Transform.translate(
            offset: const Offset(15, 10),
            child: Transform.rotate(
              angle: 0.08,
              child: _buildMockPlaylistCard("Nupe Favorites", const Color(0xFF1E2230), nupeGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockPlaylistCard(String name, Color cardBg, Color accent) {
    return Container(
      width: 140,
      height: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.playlist_play_rounded, size: 20, color: accent),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "24 Audio Tracks",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Audio Equalizer visualization for Slide 3
  Widget _buildPlaybackIllustration() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF111116),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
        boxShadow: [
          BoxShadow(
            color: nupeRed.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildEqualizerBar(50, 0.4, nupeBlue),
            const SizedBox(width: 8),
            _buildEqualizerBar(90, 0.8, nupeGreen),
            const SizedBox(width: 8),
            _buildEqualizerBar(70, 0.6, nupeRed),
            const SizedBox(width: 8),
            _buildEqualizerBar(100, 0.9, Colors.white),
            const SizedBox(width: 8),
            _buildEqualizerBar(60, 0.5, nupeGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildEqualizerBar(double height, double scaleFactor, Color color) {
    return Container(
      width: 8,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
