import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/auth_controller.dart';
import '../home/home_screen.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _obscurePassword = true;

  // Brand Colors
  static const Color nupeBlue = Color(0xFF001199);
  static const Color nupeGreen = Color(0xFF389F38);
  static const Color nupeRed = Color(0xFFE52A1A);

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = context.read<AuthController>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = Navigator.of(context);

    bool success = false;
    String? errorMessage;
    if (_isLogin) {
      final result = await authController.login(
        _emailController.text,
        _passwordController.text,
      );
      success = result.$1;
      errorMessage = result.$2;
    } else {
      final result = await authController.signup(
        _firstNameController.text,
        _lastNameController.text,
        _emailController.text,
        _passwordController.text,
      );
      success = result.$1;
      errorMessage = result.$2;
    }

    if (success) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                _isLogin ? "Welcome back to Nupe Songs!" : "Account created successfully!",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: nupeGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      router.pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(errorMessage ?? "Authentication failed. Please verify credentials."),
              ),
            ],
          ),
          backgroundColor: nupeRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _handleGuestAccess() {
    context.read<AuthController>().continueAsGuest();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final textColor = isDark ? Colors.white : const Color(0xFF0C1026);
    final subtitleColor = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B728E);
    final backgroundColor = isDark ? const Color(0xFF03040B) : const Color(0xFFF6F8FD);
    final cardColor = isDark ? const Color(0xFF141416) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: nupeBlue.withValues(alpha: isDark ? 0.18 : 0.08),
                    blurRadius: 130,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: nupeRed.withValues(alpha: isDark ? 0.12 : 0.05),
                    blurRadius: 120,
                    spreadRadius: 35,
                  ),
                ],
              ),
            ),
          ),

          // Core layout
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Logo Emblem
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                        border: Border.all(
                          color: nupeGreen.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_logo.jpeg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // App Name
                    Text(
                      "Nupe Songs",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLogin ? "Login to sync your playlists and favorites" : "Create an account to start your musical journey",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Auth Form Card with Glassmorphic Border
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: cardColor.withValues(alpha: isDark ? 0.65 : 0.9),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: borderColor),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Custom tab switcher for Login/Signup
                                Container(
                                  width: double.infinity,
                                  height: 46,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() => _isLogin = true),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 250),
                                            curve: Curves.easeInOut,
                                            decoration: BoxDecoration(
                                              color: _isLogin
                                                  ? (isDark ? const Color(0xFF1E1E22) : Colors.white)
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(10),
                                              boxShadow: _isLogin
                                                  ? [
                                                      BoxShadow(
                                                        color: Colors.black.withValues(alpha: 0.05),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 2),
                                                      )
                                                    ]
                                                  : null,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              "Login",
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: _isLogin ? textColor : subtitleColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() => _isLogin = false),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 250),
                                            curve: Curves.easeInOut,
                                            decoration: BoxDecoration(
                                              color: !_isLogin
                                                  ? (isDark ? const Color(0xFF1E1E22) : Colors.white)
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(10),
                                              boxShadow: !_isLogin
                                                  ? [
                                                      BoxShadow(
                                                        color: Colors.black.withValues(alpha: 0.05),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 2),
                                                      )
                                                    ]
                                                  : null,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              "Register",
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: !_isLogin ? textColor : subtitleColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Animated Form fields based on selection
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  child: Column(
                                    children: [
                                      if (!_isLogin) ...[
                                        // Surname row
                                        _buildTextField(
                                          controller: _lastNameController,
                                          label: "Surname",
                                          hint: "Enter your surname",
                                          icon: Icons.badge_outlined,
                                          isDark: isDark,
                                          textColor: textColor,
                                          subtitleColor: subtitleColor,
                                          validator: (val) {
                                            if (val == null || val.trim().isEmpty) {
                                              return "Please enter your surname";
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        // First Name row
                                        _buildTextField(
                                          controller: _firstNameController,
                                          label: "First Name",
                                          hint: "Enter your first name",
                                          icon: Icons.person_outline_rounded,
                                          isDark: isDark,
                                          textColor: textColor,
                                          subtitleColor: subtitleColor,
                                          validator: (val) {
                                            if (val == null || val.trim().isEmpty) {
                                              return "Please enter your first name";
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                      _buildTextField(
                                        controller: _emailController,
                                        label: "Email Address",
                                        hint: "Enter your email",
                                        icon: Icons.email_outlined,
                                        isDark: isDark,
                                        textColor: textColor,
                                        subtitleColor: subtitleColor,
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) {
                                            return "Please enter your email";
                                          }
                                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                                            return "Please enter a valid email";
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _passwordController,
                                        label: "Password",
                                        hint: "Minimum 6 characters",
                                        icon: Icons.lock_outline_rounded,
                                        isDark: isDark,
                                        textColor: textColor,
                                        subtitleColor: subtitleColor,
                                        obscureText: _obscurePassword,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                            color: subtitleColor,
                                            size: 18,
                                          ),
                                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                        ),
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) return "Please enter your password";
                                          if (val.length < 6) return "Password must be at least 6 characters";
                                          return null;
                                        },
                                      ),
                                      if (_isLogin) ...[
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                PageRouteBuilder(
                                                  pageBuilder: (context, animation, secondaryAnimation) => const ForgotPasswordScreen(),
                                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                    return FadeTransition(opacity: animation, child: child);
                                                  },
                                                  transitionDuration: const Duration(milliseconds: 400),
                                                ),
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: Text(
                                              "Forgot Password?",
                                              style: TextStyle(
                                                color: subtitleColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Submit Button with Tricolor Brand Gradient
                                Container(
                                  width: double.infinity,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: const LinearGradient(
                                      colors: [nupeBlue, nupeGreen, nupeRed],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: nupeBlue.withValues(alpha: 0.3),
                                        blurRadius: 15,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: authController.isLoading ? null : _submit,
                                    child: authController.isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            _isLogin ? "Login" : "Register Account",
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Guest Bypass option
                    TextButton(
                      onPressed: _handleGuestAccess,
                      child: Text(
                        "Continue as Guest",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: subtitleColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final fillColor = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02);
    final focusBorderColor = isDark ? Colors.white24 : Colors.black26;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: subtitleColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: subtitleColor.withValues(alpha: 0.6), fontSize: 13),
            prefixIcon: Icon(icon, color: subtitleColor.withValues(alpha: 0.7), size: 18),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: focusBorderColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: nupeRed.withValues(alpha: 0.5)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: nupeRed, width: 1.5),
            ),
            errorStyle: const TextStyle(fontSize: 11, color: nupeRed),
          ),
        ),
      ],
    );
  }
}
