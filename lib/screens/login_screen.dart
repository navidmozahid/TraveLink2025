import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'business_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Logo Section
              _buildLogoSection(),
              const SizedBox(height: 40),

              // Login Form
              _buildLoginForm(),
              const SizedBox(height: 8), // Reduced space

              // Forgot Password - MOVED HERE
              _buildForgotPassword(),
              const SizedBox(height: 24),

              // Traveler Login Button
              _buildLoginButton(),
              const SizedBox(height: 16),

              // Traveler Signup
              _buildSignupButton(),
              const SizedBox(height: 32),

              // Divider
              _buildDivider(),
              const SizedBox(height: 24),

              // Business Section
              _buildBusinessSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return const Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Color(0xFF023e8a),
          child: Icon(
            Icons.travel_explore,
            size: 50,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16),
        Text(
          "TraveLink",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF023e8a),
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Your Travel Companion",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        // Email Field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: "Email Address",
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF023e8a)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF023e8a),
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Password Field
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: "Password",
            prefixIcon: const Icon(Icons.lock_outlined, color: Color(0xFF023e8a)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: const Color(0xFF023e8a),
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF023e8a),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _loading ? null : _showForgotPasswordDialog,
        child: const Text(
          "Forgot Password?",
          style: TextStyle(
            color: Color(0xFF023e8a),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF023e8a),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        onPressed: _loading ? null : _handleTravelerLogin,
        child: _loading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Text(
          "Traveler Login",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSignupButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF023e8a),
          side: const BorderSide(
            color: Color(0xFF023e8a),
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _loading
            ? null
            : () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SignupScreen()),
          );
        },
        child: const Text(
          "Create Traveler Account",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey[400],
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "For Business",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey[400],
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessSection() {
    return Column(
      children: [
        const Text(
          "Agency Partners",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF023e8a),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Manage your travel agency business",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF023e8a),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            onPressed: _loading
                ? null
                : () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BusinessLoginScreen()),
              );
            },
            icon: const Icon(Icons.business_center),
            label: const Text(
              "Business Portal",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 🔹 Forgot Password Dialog
  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Reset Password",
          style: TextStyle(
            color: Color(0xFF023e8a),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter your email address and we'll send you a password reset link:",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: TextEditingController(text: _emailController.text),
              decoration: InputDecoration(
                labelText: "Email Address",
                prefixIcon: const Icon(Icons.email, color: Color(0xFF023e8a)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF023e8a)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF023e8a),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final emailController = TextEditingController(text: _emailController.text);
              final email = emailController.text.trim();

              if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                _showToast("Please enter a valid email address", isError: true);
                return;
              }

              Navigator.pop(context);
              await _handleForgotPassword(email);
            },
            child: const Text("Send Reset Link"),
          ),
        ],
      ),
    );
  }

  // 🔹 Forgot Password Logic
  Future<void> _handleForgotPassword(String email) async {
    setState(() => _loading = true);

    try {
      await _supabaseService.resetPassword(email);
      _showToast("✅ Password reset email sent! Check your inbox and follow the instructions.", isSuccess: true);
    } catch (e) {
      String message = "Failed to send reset link. Please try again.";
      if (e.toString().contains("user not found")) {
        message = "No account found with this email address.";
      } else if (e.toString().contains("rate limit")) {
        message = "Too many attempts. Please try again later.";
      }
      _showToast("❌ $message", isError: true);
    }

    setState(() => _loading = false);
  }

  // 🔹 Traveler Login Logic
  Future<void> _handleTravelerLogin() async {
    // Basic validation
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showToast("Please fill in all fields", isError: true);
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      _showToast("Please enter a valid email address", isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await _supabaseService.loginTraveler(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = response.user;

      if (user != null) {
        if (user.emailConfirmedAt == null) {
          // Email not verified
          _showToast("Please verify your email before logging in.", isError: true);
        } else {
          // ✅ Verified → go to HomeScreen
          _showToast("✅ Login successful!", isSuccess: true);
          await Future.delayed(const Duration(seconds: 1));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      String message = "Login failed. Please try again.";
      if (e.toString().contains("Invalid login credentials")) {
        message = "Invalid email or password.";
      } else if (e.toString().contains("Email not confirmed")) {
        message = "Please verify your email before logging in.";
      }
      _showToast("❌ $message", isError: true);
    }

    setState(() => _loading = false);
  }

  void _showToast(String message, {bool isError = false, bool isSuccess = false}) {
    Color backgroundColor = const Color(0xFF023e8a);
    if (isError) backgroundColor = Colors.red;
    if (isSuccess) backgroundColor = Colors.green;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}