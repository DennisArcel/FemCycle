import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme_provider.dart';
import '../services/api_service.dart';
import '../services/tutorial_storage_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';
import '../services/notification_service.dart';
import '../widgets/glass.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  // NEW: "Remember me" checkbox state. Starts ticked so people stay logged
  // in by default; set to false if you want it to be opt-in instead.
  bool _rememberMe = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Basic validation
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.login(email: email, password: password);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // NEW: remember the user's choice so SplashScreen knows whether to
      // skip login next time the app is opened.
      await ApiService.setRememberMe(_rememberMe);

      // Remember which account just logged in so tutorial flags are
      // stored per account.
      final user = result['data']?['user'];
      await TutorialStorageService.setUser(user is Map ? user['id'] : null);

      // Request notification permission + register this device with the backend
      await NotificationService.initialize();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Login failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Glass.pageBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBackground()),
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 12),

                            // App Name
                            Text(
                              'FemCycle',
                              style: Glass.heading(size: 30),
                            ),
                            const SizedBox(height: 18),

                            // Logo
                            Glass.frostedCircle(
                              size: 90,
                              child: Image.asset(
                                'assets/icon/logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.female,
                                    color: Glass.pink,
                                    size: 40,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Tab: Register / Log in
                            _AuthTabBar(
                              selectedIndex: 1, // Log in is selected
                              onTabChanged: (index) {
                                if (index == 0) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 20),

                            // Glass form card
                            Glass.card(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Error banner
                                  if (_errorMessage != null) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Glass.pink.withOpacity(0.16),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                            color: Glass.pink.withOpacity(0.35)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline,
                                              color: Glass.pinkDeep, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: Glass.body(
                                                  size: 12, color: Glass.pinkDeep),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // Email Field
                                  _buildLabel('Email'),
                                  const SizedBox(height: 6),
                                  _buildTextField(
                                    controller: _emailController,
                                    hint: 'stacey@gmail.com',
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 16),

                                  // Password Field
                                  _buildLabel('Password'),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: Glass.body(size: 15),
                                    decoration: Glass.fieldDecoration(
                                      hint: '••••••••',
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: Glass.textMuted,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() => _obscurePassword = !_obscurePassword);
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // NEW: Remember me (left) + Forgot password (right)
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          activeColor: Glass.blueDeep,
                                          side: BorderSide(color: Glass.textMuted),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          onChanged: (v) =>
                                              setState(() => _rememberMe = v ?? false),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () =>
                                            setState(() => _rememberMe = !_rememberMe),
                                        child: Text(
                                          'Remember me',
                                          style: Glass.body(size: 13),
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => const ForgotPasswordScreen()),
                                          );
                                        },
                                        child: Text(
                                          'Forgot password?',
                                          style: Glass.body(
                                            size: 13,
                                            color: Glass.blueDeep,
                                            weight: FontWeight.w700,
                                          ).copyWith(decoration: TextDecoration.underline),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Log In Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleLogin,
                                      style: Glass.primaryButtonStyle(),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : Text(
                                              'Log In',
                                              style: Glass.heading(
                                                size: 17,
                                                weight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: Glass.body(size: 14, weight: FontWeight.w700),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: Glass.body(size: 15),
      decoration: Glass.fieldDecoration(hint: hint),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _AuthTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const _AuthTabBar({
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Glass.card(
      radius: 16,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            _tab('Register', 0),
            _tab('Log in', 1),
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, int index) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [Glass.blueDeep, Glass.purpleDeep],
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Glass.body(
              size: 15,
              weight: FontWeight.w700,
              color: isSelected ? Colors.white : Glass.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}