import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // ── Step control: 0 = registration form, 1 = email OTP verification ──────
  int _step = 0;
  final _otpControllers = List.generate(4, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
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
            colorScheme: ColorScheme.light(
              primary: _Glass.blueDeep,
              onPrimary: Colors.white,
              onSurface: _Glass.textDark,
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

  // ── Step 0 -> validate fields, then send the OTP and move to step 1 ──────
  Future<void> _handleContinue() async {
    final firstName = _firstNameController.text.trim();
    final middleName = _middleNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

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

    final result = await ApiService.sendRegisterOtp(email: email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() => _step = 1);
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Could not send verification code. Please try again.';
      });
    }
  }

  // ── Step 1 -> verify the OTP, then actually create the account ───────────
  Future<void> _handleVerifyAndRegister() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 4) {
      setState(() => _errorMessage = 'Please enter the 4-digit code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final verifyResult = await ApiService.verifyOtp(email: email, otp: otp);

    if (!mounted) return;

    if (verifyResult['success'] != true) {
      setState(() {
        _isLoading = false;
        _errorMessage = verifyResult['message'] ?? 'Invalid or expired code.';
      });
      for (final c in _otpControllers) c.clear();
      _otpFocusNodes[0].requestFocus();
      return;
    }

    // Format the picked birthday as YYYY-MM-DD, same convention AccountInfoScreen
    // uses when saving it later — keeps both screens consistent.
    String? birthdayStr;
    if (_selectedBirthday != null) {
      birthdayStr =
          '${_selectedBirthday!.year}-${_selectedBirthday!.month.toString().padLeft(2, '0')}-${_selectedBirthday!.day.toString().padLeft(2, '0')}';
    }

    // OTP confirmed — now actually create the account.
    final result = await ApiService.register(
      firstName: _firstNameController.text.trim(),
      middleName: _middleNameController.text.trim().isEmpty
          ? null
          : _middleNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: email,
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
      birthday: birthdayStr,
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

  Future<void> _handleResendOtp() async {
    setState(() => _isLoading = true);
    final result = await ApiService.sendRegisterOtp(email: _emailController.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSnack('A new code has been sent to your email.', isError: false);
    } else {
      _showSnack(result['message'] ?? 'Could not resend code.', isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: _Glass.body(color: Colors.white)),
      backgroundColor: isError ? _Glass.pinkDeep : const Color(0xFF4CAF7D),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Terms & Conditions scroll-gated modal ─────────────────────────────────
  Future<void> _openTermsSheet() async {
    if (_agreedToTerms) {
      // Already agreed — a direct tap on the checkbox area just unchecks it,
      // no need to re-show the whole sheet again.
      setState(() => _agreedToTerms = false);
      return;
    }

    final agreed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _TermsSheet(),
    );

    if (agreed == true && mounted) {
      setState(() => _agreedToTerms = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Glass.pageBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientBackground()),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _step == 0 ? _buildFormStep() : _buildOtpStep(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
    child: _Glass.card(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_step == 1) {
                setState(() => _step = 0);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
              child: Icon(Icons.chevron_left, color: _Glass.textDark, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Text(_step == 0 ? 'Create Account' : 'Verify Email',
              style: _Glass.heading(size: 18, weight: FontWeight.w600)),
        ],
      ),
    ),
  );
}

  // ── Step 0: registration form ─────────────────────────────────────────────
  Widget _buildFormStep() {
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        Text('FemCycle', style: _Glass.heading(size: 26)),
        const SizedBox(height: 20),

        _Glass.card(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                _errorBanner(_errorMessage!),
                const SizedBox(height: 16),
              ],

              _buildLabel('First Name'),
              const SizedBox(height: 6),
              _buildTextField(controller: _firstNameController, hint: 'First Name'),
              const SizedBox(height: 16),

              _buildLabel('Middle Name (OPTIONAL)'),
              const SizedBox(height: 6),
              _buildTextField(controller: _middleNameController, hint: 'Middle Name (OPTIONAL)'),
              const SizedBox(height: 16),

              _buildLabel('Last Name'),
              const SizedBox(height: 6),
              _buildTextField(controller: _lastNameController, hint: 'Last Name'),
              const SizedBox(height: 16),

              _buildLabel('Birthdate'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickBirthday,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.7)),
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
                          style: _Glass.body(
                            size: 15,
                            color: _selectedBirthday != null ? _Glass.textDark : _Glass.textHint,
                          ),
                        ),
                      ),
                      Icon(Icons.calendar_today_outlined, size: 18, color: _Glass.blueDeep),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel('Email Address'),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _emailController,
                hint: 'Email Address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              _buildLabel('Password'),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: _Glass.body(size: 15),
                decoration: _Glass.fieldDecoration(
                  hint: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: _Glass.textMuted,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel('Confirm Password'),
              const SizedBox(height: 6),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                style: _Glass.body(size: 15),
                decoration: _Glass.fieldDecoration(
                  hint: 'Confirm Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: _Glass.textMuted,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Terms & Conditions — checkbox reflects _agreedToTerms, but is
              // read-only; tapping anywhere in this row opens the scroll-gated
              // sheet instead of toggling directly.
              GestureDetector(
                onTap: _openTermsSheet,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: IgnorePointer(
                        child: Checkbox(
                          value: _agreedToTerms,
                          onChanged: null,
                          activeColor: _Glass.blueDeep,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          side: BorderSide(color: _Glass.blueDeep),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: _Glass.body(size: 13, color: _Glass.textMuted),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms and Privacy Policy',
                              style: TextStyle(
                                color: _Glass.blueDeep,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(text: ' (tap to review)'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleContinue,
                  style: _Glass.primaryButtonStyle(),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text('Continue',
                          style: _Glass.heading(size: 17, weight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ',
                      style: _Glass.body(size: 13, color: _Glass.textMuted)),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: Text(
                      'Login',
                      style: _Glass.body(size: 13, weight: FontWeight.w700, color: _Glass.blueDeep)
                          .copyWith(decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 1: OTP verification ──────────────────────────────────────────────
  Widget _buildOtpStep() {
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _Glass.pink.withOpacity(0.25),
            shape: BoxShape.circle,
            border: Border.all(color: _Glass.pinkDeep, width: 2),
          ),
          child: Icon(Icons.mark_email_read_outlined, color: _Glass.pinkDeep, size: 38),
        ),
        const SizedBox(height: 20),
        Text('Verify your email', style: _Glass.heading(size: 20, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'We sent a 4-digit code to\n${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: _Glass.body(size: 13, color: _Glass.textMuted).copyWith(height: 1.5),
        ),
        const SizedBox(height: 24),

        _Glass.card(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              if (_errorMessage != null) ...[
                _errorBanner(_errorMessage!),
                const SizedBox(height: 16),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  return Container(
                    width: 58,
                    height: 58,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _otpControllers[i].text.isNotEmpty
                            ? _Glass.blueDeep
                            : Colors.white.withOpacity(0.7),
                        width: 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: _otpControllers[i],
                      focusNode: _otpFocusNodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: _Glass.heading(size: 22, weight: FontWeight.w700),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (val) {
                        setState(() {});
                        if (val.isNotEmpty && i < 3) {
                          _otpFocusNodes[i + 1].requestFocus();
                        } else if (val.isEmpty && i > 0) {
                          _otpFocusNodes[i - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 26),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerifyAndRegister,
                  style: _Glass.primaryButtonStyle(),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text('Verify & Create Account',
                          style: _Glass.heading(size: 15, weight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Didn't receive the code? ",
                      style: _Glass.body(size: 13, color: _Glass.textMuted)),
                  GestureDetector(
                    onTap: _isLoading ? null : _handleResendOtp,
                    child: Text(
                      'Resend',
                      style: _Glass.body(size: 13, weight: FontWeight.w700, color: _Glass.blueDeep)
                          .copyWith(decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _Glass.pink.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Glass.pink.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: _Glass.pinkDeep, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: _Glass.body(size: 12, color: _Glass.pinkDeep)),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: _Glass.body(size: 14, weight: FontWeight.w700)),
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
      style: _Glass.body(size: 15),
      decoration: _Glass.fieldDecoration(hint: hint),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TERMS & CONDITIONS — scroll-gated bottom sheet
// Must be scrolled to the bottom before "I Agree" enables. Returns true via
// Navigator.pop if agreed, or null/false if dismissed without agreeing.
// ─────────────────────────────────────────────────────────────────────────────

class _TermsSheet extends StatefulWidget {
  const _TermsSheet();

  @override
  State<_TermsSheet> createState() => _TermsSheetState();
}

class _TermsSheetState extends State<_TermsSheet> {
  final ScrollController _scrollController = ScrollController();
  bool _reachedBottom = false;

  static const String _lastUpdated = 'August 2026';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // In case the content is short enough to not need scrolling at all on a
    // tall device, check once after the first frame too.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final atBottom = pos.maxScrollExtent <= 0 ||
        pos.pixels >= pos.maxScrollExtent - 24;
    if (atBottom && !_reachedBottom) {
      setState(() => _reachedBottom = true);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.97),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _Glass.textHint.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Terms & Conditions',
                        style: _Glass.heading(size: 17, weight: FontWeight.w700)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Icon(Icons.close, color: _Glass.textMuted, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last updated: $_lastUpdated',
                          style: _Glass.body(size: 11, color: _Glass.textHint)),
                      const SizedBox(height: 16),
                      _section('1. Acceptance of Terms',
                          'By creating an account or using FemCycle ("the App"), you agree to be '
                          'bound by these Terms and Conditions. If you do not agree, please do not '
                          'use the App.'),
                      _section('2. Description of Service',
                          'FemCycle helps you log menstrual cycle data, symptoms, mood, and diary '
                          'entries, and provides cycle predictions and cycle-health observations '
                          'based on the information you enter.'),
                      _section('3. Not Medical Advice',
                          'FemCycle is not a medical device and does not provide medical advice, '
                          'diagnosis, or treatment. Any predictions, patterns, or observations shown '
                          'in the App — including cycle-health signals — are informational only and '
                          'are not a diagnosis of any condition, including PCOS. Always consult a '
                          'qualified healthcare provider for medical concerns.'),
                      _section('4. Eligibility',
                          'You must be able to form a legally binding agreement to use this App. If '
                          'you are using the App on behalf of a minor or are a minor yourself, please '
                          'use the App only with the involvement of a parent or guardian, as '
                          'appropriate in your jurisdiction.'),
                      _section('5. Your Account',
                          'You are responsible for maintaining the confidentiality of your login '
                          'credentials and for all activity under your account.'),
                      _section('6. Your Data',
                          'The data you log (cycle dates, symptoms, diary entries, and health '
                          'profile answers) belongs to you. We process it to provide the App\'s '
                          'features. See our Privacy Policy for details on how your data is '
                          'collected, stored, and protected.'),
                      _section('7. Acceptable Use',
                          'You agree not to misuse the App, including attempting to access other '
                          'users\' accounts or data, or using the App for any unlawful purpose.'),
                      _section('8. Termination',
                          'We may suspend or terminate your access to the App if you violate these '
                          'Terms. You may stop using the App and request account deletion at any '
                          'time.'),
                      _section('9. Limitation of Liability',
                          'The App is provided "as is" without warranties of any kind. To the '
                          'fullest extent permitted by law, the developer is not liable for any '
                          'indirect, incidental, or consequential damages arising from your use of '
                          'the App.'),
                      _section('10. Changes to These Terms',
                          'We may update these Terms from time to time. Continued use of the App '
                          'after changes take effect constitutes acceptance of the revised Terms.'),
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _Glass.blue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 16, color: _Glass.blueDeep),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "You've reached the end — you can now agree below.",
                                style: _Glass.body(size: 12, color: _Glass.blueDeep),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _reachedBottom
                      ? () => Navigator.pop(context, true)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Glass.blueDeep,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _Glass.textHint.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    _reachedBottom ? 'I Agree' : 'Scroll to the bottom to continue',
                    style: _Glass.body(
                      size: 14,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _Glass.body(size: 13, weight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(body,
              style: _Glass.body(size: 12, color: _Glass.textMuted).copyWith(height: 1.5)),
        ],
      ),
    );
  }
}

// ─── Glass design tokens ───────────────────────────────────────────────────────
// Shared frosted-glass / ambient-blob design system reused across every
// screen (Home, Mood, Diary, Learn, Lifestyle, Profile, and the auth flow).

class _Glass {
  static const Color pageBackground = Color(0xFFF3F1FB);

  static const Color blue = Color(0xFF9FC8FF);
  static const Color blueDeep = Color(0xFF5B93E0);
  static const Color pink = Color(0xFFFFA7CE);
  static const Color pinkDeep = Color(0xFFE0679A);
  static const Color purple = Color(0xFFC6ACFF);
  static const Color purpleDeep = Color(0xFF9A78E0);

  static const Color textDark = Color(0xFF2B2638);
  static const Color textMuted = Color(0xFF6E677D);
  static const Color textHint = Color(0xFFA6A0B4);

  static TextStyle heading({
    double size = 22,
    FontWeight weight = FontWeight.w700,
    Color color = textDark,
  }) =>
      GoogleFonts.quicksand(fontSize: size, fontWeight: weight, color: color);

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = textDark,
  }) =>
      GoogleFonts.nunito(fontSize: size, fontWeight: weight, color: color);

  static Widget card({
    required Widget child,
    Key? key,
    double radius = 24,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double opacity = 0.55,
  }) {
    return ClipRRect(
      key: key,
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: purpleDeep.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  static InputDecoration fieldDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: body(size: 14, color: textHint),
      filled: true,
      fillColor: Colors.white.withOpacity(0.55),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: blueDeep.withOpacity(0.7), width: 1.4),
      ),
      suffixIcon: suffixIcon,
    );
  }

  static ButtonStyle primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: blueDeep,
      foregroundColor: Colors.white,
      disabledBackgroundColor: blueDeep.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
    );
  }
}

class _AmbientBackground extends StatefulWidget {
  const _AmbientBackground();

  @override
  State<_AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<_AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 * math.pi;
        return Stack(
          children: [
            Container(color: _Glass.pageBackground),
            Positioned(
              top: -60 + 24 * math.sin(t),
              left: -70 + 20 * math.cos(t),
              child: _blob(size.width * 0.7, _Glass.blue.withOpacity(0.55)),
            ),
            Positioned(
              top: size.height * 0.35 + 26 * math.cos(t * 0.85),
              right: -90 + 22 * math.sin(t * 0.85),
              child: _blob(size.width * 0.75, _Glass.pink.withOpacity(0.5)),
            ),
            Positioned(
              bottom: -80 + 20 * math.sin(t * 1.15),
              left: size.width * 0.15 + 18 * math.cos(t * 1.15),
              child: _blob(size.width * 0.65, _Glass.purple.withOpacity(0.5)),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(double diameter, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}