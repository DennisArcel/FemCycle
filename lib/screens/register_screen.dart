import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  DateTime? _selectedBirthday;
  bool _agreedToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF84B2E9),
              onPrimary: Colors.white,
              onSurface: Color(0xFF333333),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedBirthday = picked);
    }
  }

  Future<void> _handleRegister() async {
    final firstName = _firstNameController.text.trim();
    final middleName = _middleNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validation
    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all required fields.');
      return;
    }
    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters.');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }
    if (!_agreedToTerms) {
      setState(() => _errorMessage = 'Please agree to the Terms and Privacy Policy.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.register(
      firstName: firstName,
      middleName: middleName.isEmpty ? null : middleName,
      lastName: lastName,
      email: email,
      password: password,
      passwordConfirmation: confirmPassword,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Registration failed. Please try again.';
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
                selectedIndex: 0,
                onTabChanged: (index) {
                  if (index == 1) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
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

              // First Name
              _buildLabel('First Name'),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _firstNameController,
                hint: 'First Name',
              ),
              const SizedBox(height: 16),

              // Middle Name
              _buildLabel('Middle Name'),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _middleNameController,
                hint: 'Middle Name',
              ),
              const SizedBox(height: 16),

              // Last Name
              _buildLabel('Last Name'),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _lastNameController,
                hint: 'Last Name',
              ),
              const SizedBox(height: 16),

              // Birthday
              _buildLabel('Birthday'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickBirthday,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedBirthday != null
                              ? '${_selectedBirthday!.month.toString().padLeft(2, '0')}/'
                                '${_selectedBirthday!.day.toString().padLeft(2, '0')}/'
                                '${_selectedBirthday!.year}'
                              : 'MM/DD/YYYY',
                          style: TextStyle(
                            fontFamily: 'Archivo',
                            fontSize: 15,
                            color: _selectedBirthday != null
                                ? const Color(0xFF2B2638)
                                : const Color(0xFFAAAAAA),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: Color(0xFF84B2E9),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Email
              _buildLabel('Email Address'),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _emailController,
                hint: 'Email Address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password
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
                  hintText: 'Password',
                  hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
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
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password
              _buildLabel('Confirm Password'),
              const SizedBox(height: 6),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                style: const TextStyle(
                  fontFamily: 'Archivo',
                  fontSize: 15,
                  color: Color(0xFF2B2638),
                ),
                decoration: InputDecoration(
                  hintText: 'Confirm Password',
                  hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
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
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: context.textHint,
                      size: 20,
                    ),
                    onPressed: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Terms checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _agreedToTerms,
                      onChanged: (val) =>
                          setState(() => _agreedToTerms = val ?? false),
                      activeColor: const Color(0xFF84B2E9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(color: Color(0xFF84B2E9)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Mallanna',
                        fontSize: 13,
                        color: Color(0xFF555555),
                      ),
                      children: [
                        TextSpan(text: 'I agree '),
                        TextSpan(
                          text: 'Terms',
                          style: TextStyle(
                            color: Color(0xFF84B2E9),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: Color(0xFF84B2E9),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Registration Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
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
                          'Sign Up',
                          style: TextStyle(
                            fontFamily: 'Mallanna',
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Already have account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(
                      fontFamily: 'Mallanna',
                      fontSize: 13,
                      color: Color(0xFF555555),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Login',
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

// ─── Shared Tab Bar ────────────────────────────────────────────────────────────

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