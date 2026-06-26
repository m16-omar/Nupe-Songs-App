import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/auth_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSent = false;

  // Brand Colors
  static const Color nupeBlue = Color(0xFF001199);
  static const Color nupeGreen = Color(0xFF389F38);
  static const Color nupeRed = Color(0xFFE52A1A);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = context.read<AuthController>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final (success, errorMessage) = await authController.sendPasswordResetEmail(_emailController.text);

    if (success) {
      setState(() {
        _isSent = true;
      });
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(errorMessage ?? "Failed to send reset link. Verify email."),
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

          // Safe content area
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
                    Text(
                      "Reset Password",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Reset Form Card
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
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: _isSent ? _buildSuccessState(textColor, subtitleColor) : _buildFormState(authController, subtitleColor, textColor, isDark),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Bottom navigation link
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        "Back to Login",
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

  Widget _buildFormState(AuthController authController, Color subtitleColor, Color textColor, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Enter the email address associated with your account, and we'll send you a link to reset your password.",
            style: TextStyle(
              fontSize: 13,
              color: subtitleColor,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _emailController,
            label: "Email Address",
            hint: "Enter your registered email",
            icon: Icons.email_outlined,
            isDark: isDark,
            textColor: textColor,
            subtitleColor: subtitleColor,
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return "Please enter your email";
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                return "Please enter a valid email";
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
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
                  : const Text(
                      "Send Recovery Link",
                      style: TextStyle(
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
    );
  }

  Widget _buildSuccessState(Color textColor, Color subtitleColor) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: nupeGreen.withValues(alpha: 0.15),
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: nupeGreen,
            size: 36,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Check Your Email",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "We have sent a password reset link to ${_emailController.text}. Please check your inbox and spam folder.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: subtitleColor,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: nupeGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              "Back to Login",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: nupeGreen,
              ),
            ),
          ),
        ),
      ],
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
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: subtitleColor.withValues(alpha: 0.6), fontSize: 13),
            prefixIcon: Icon(icon, color: subtitleColor.withValues(alpha: 0.7), size: 18),
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
