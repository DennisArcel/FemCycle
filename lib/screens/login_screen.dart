import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';
import '../services/api_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
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
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // App Name
              const Text(
                'FemCycle',
                style: TextStyle(
                  fontFamily: 'Magra',
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B2638),
                ),
              ),
              const SizedBox(height: 16),

              // Logo
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF84B2E9), width: 2.5),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFE4E8FE),
                        child: const Icon(
                          Icons.female,
                          color: Color(0xFFE96A8F),
                          size: 40,
                        ),
                      );
                    },
                  ),
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
              const SizedBox(height: 28),

              // Error banner
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE96A8F).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFE96A8F), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontFamily: 'Mallanna',
                            fontSize: 12,
                            color: Color(0xFFE96A8F),
                          ),
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
                style: const TextStyle(
                  fontFamily: 'Archivo',
                  fontSize: 15,
                  color: Color(0xFF2B2638),
                ),
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: const TextStyle(
                    color: Color(0xFFAAAAAA),
                    letterSpacing: 3,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: context.textHint,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Remember me + Forgot password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (val) =>
                              setState(() => _rememberMe = val ?? false),
                          activeColor: const Color(0xFF84B2E9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: const BorderSide(color: Color(0xFF84B2E9)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Remember me',
                        style: TextStyle(
                          fontFamily: 'Mallanna',
                          fontSize: 13,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen()),
                      );
                    },
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontFamily: 'Mallanna',
                        fontSize: 13,
                        color: Color(0xFF84B2E9),
                        decoration: TextDecoration.underline,
                      ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF84B2E9),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF84B2E9).withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Log In',
                          style: TextStyle(
                            fontFamily: 'Mallanna',
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Mallanna',
          fontSize: 14,
          color: Color(0xFF333333),
          fontWeight: FontWeight.w600,
        ),
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
      style: const TextStyle(
        fontFamily: 'Archivo',
        fontSize: 15,
        color: Color(0xFF2B2638),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
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
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _tab('Register', 0),
          _tab('Log in', 1),
        ],
      ),
    );
  }

  Widget _tab(String label, int index) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF84B2E9) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Mallanna',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF888888),
            ),
          ),
        ),
      ),
    );
  }
}