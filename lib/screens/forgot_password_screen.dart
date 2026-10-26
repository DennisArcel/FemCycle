import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import '../widgets/glass.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Steps: 0 = enter email, 1 = enter OTP, 2 = reset password
  int _step = 0;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _otpControllers = List.generate(4, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(4, (_) => FocusNode());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Minimum password length.
  static const int _minPasswordLength = 8;

  // ── Resend cooldown ──────────────────────────────────────────────────
  // How long the user must wait before they can request another code.
  static const int _resendCooldownSeconds = 60;
  int _resendSeconds = 0; // 0 = Resend is available
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Starts (or restarts) the 60-second countdown.
  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = _resendCooldownSeconds);

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  // ── Password rules ───────────────────────────────────────────────────
  bool _hasMinLength(String p) => p.length >= _minPasswordLength;
  bool _hasUppercase(String p) => RegExp(r'[A-Z]').hasMatch(p);
  bool _hasLowercase(String p) => RegExp(r'[a-z]').hasMatch(p);
  bool _hasNumber(String p) => RegExp(r'[0-9]').hasMatch(p);
  bool _hasSpecialChar(String p) => RegExp(r'[^A-Za-z0-9\s]').hasMatch(p);

  bool _isPasswordStrong(String p) =>
      _hasMinLength(p) &&
      _hasUppercase(p) &&
      _hasLowercase(p) &&
      _hasNumber(p) &&
      _hasSpecialChar(p);

  // ── Step 0: Send OTP ─────────────────────────────────────────────────
  Future<void> _handleSendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack('Please enter your email address.');
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.sendOtp(email: email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _startResendCooldown();
      setState(() => _step = 1);
    } else {
      _showSnack(result['message'] ?? 'Could not send code. Please try again.');
    }
  }

  // ── Step 1: Verify OTP ───────────────────────────────────────────────
  Future<void> _handleVerifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 4) {
      _showSnack('Please enter the 4-digit code.');
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.verifyOtp(
      email: _emailController.text.trim(),
      otp: otp,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() => _step = 2);
    } else {
      _showSnack(result['message'] ?? 'Invalid or expired code.');
      // Clear the boxes so they can re-type
      for (final c in _otpControllers) c.clear();
      _otpFocusNodes[0].requestFocus();
      setState(() {});
    }
  }

  // ── Step 1: Resend OTP ───────────────────────────────────────────────
  Future<void> _handleResendOtp() async {
    // Still cooling down — ignore taps.
    if (_resendSeconds > 0) return;

    setState(() => _isLoading = true);
    final result = await ApiService.sendOtp(email: _emailController.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _startResendCooldown();
      _showSnack('A new code has been sent to your email.', isError: false);
    } else {
      _showSnack(result['message'] ?? 'Could not resend code.');
    }
  }

  // ── Step 2: Reset Password ───────────────────────────────────────────
  Future<void> _handleResetPassword() async {
    if (!_isPasswordStrong(_newPasswordController.text)) {
      _showSnack(
          'Password must be at least $_minPasswordLength characters and include an '
          'uppercase letter, a lowercase letter, a number, and a special character.');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnack('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.resetPassword(
      email: _emailController.text.trim(),
      password: _newPasswordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSuccessDialog();
    } else {
      _showSnack(result['message'] ?? 'Could not reset password. Please try again.');
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: Glass.body(color: Colors.white)),
      backgroundColor: isError ? Glass.pinkDeep : const Color(0xFF4CAF7D),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF7D).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Color(0xFF4CAF7D), size: 34),
            ),
            const SizedBox(height: 16),
            Text('Password Reset!',
                style: Glass.heading(size: 18, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Your password has been updated successfully. Please log in with your new password.',
              textAlign: TextAlign.center,
              style: Glass.body(size: 13, color: Glass.textMuted).copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                style: Glass.primaryButtonStyle(),
                child: Text('Back to Login',
                    style: Glass.body(
                        size: 15, weight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Glass.pageBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBackground()),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Glass.card(
                        key: ValueKey(_step),
                        radius: 22,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: _step == 0
                            ? _buildEmailStep()
                            : _step == 1
                                ? _buildOtpStep()
                                : _buildResetStep(),
                      ),
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

  // ── Top Bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Glass.card(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (_step > 0) {
                  setState(() => _step--);
                } else {
                  Navigator.pop(context);
                }
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
                child: Icon(Icons.chevron_left, color: Glass.textDark, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Text('Forgot Password', style: Glass.heading(size: 18, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Step indicator ────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    final labels = ['Email', 'Verify', 'Reset'];
    return Row(
      children: List.generate(3, (i) {
        final isActive = i == _step;
        final isDone = i < _step;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? const Color(0xFF4CAF7D)
                            : isActive
                                ? Glass.blueDeep
                                : Colors.white.withOpacity(0.5),
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 14)
                            : Text(
                                '${i + 1}',
                                style: Glass.body(
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: isActive ? Colors.white : Glass.textMuted,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: Glass.body(
                        size: 10,
                        weight: isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive ? Glass.blueDeep : Glass.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < 2)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: i < _step
                        ? const Color(0xFF4CAF7D)
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  // ── Step 0: Enter Email ───────────────────────────────────────────────────
  Widget _buildEmailStep() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildStepIndicator(),
        const SizedBox(height: 28),

        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Glass.blue.withOpacity(0.25),
            shape: BoxShape.circle,
            border: Border.all(color: Glass.blueDeep, width: 2),
          ),
          child: Icon(Icons.lock_reset_rounded, color: Glass.blueDeep, size: 38),
        ),
        const SizedBox(height: 20),

        Text('Forgot your password?',
            style: Glass.heading(size: 20, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          "No worries! Enter your email and we'll send you a verification code.",
          textAlign: TextAlign.center,
          style: Glass.body(size: 13, color: Glass.textMuted).copyWith(height: 1.5),
        ),
        const SizedBox(height: 28),

        // Email field
        Align(alignment: Alignment.centerLeft, child: _label('Email Address')),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: Glass.body(size: 15),
          decoration: InputDecoration(
            hintText: 'stacey@gmail.com',
            hintStyle: Glass.body(color: Glass.textHint),
            filled: true,
            fillColor: Colors.white.withOpacity(0.55),
            prefixIcon: Icon(Icons.email_outlined, color: Glass.blueDeep, size: 20),
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
              borderSide: BorderSide(color: Glass.blueDeep.withOpacity(0.7), width: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSendCode,
            style: Glass.primaryButtonStyle(),
            child: _isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text('Send Verification Code',
                    style: Glass.heading(size: 16, weight: FontWeight.w600, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 18),

        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            'Back to Login',
            style: Glass.body(
              size: 13,
              weight: FontWeight.w700,
              color: Glass.blueDeep,
            ).copyWith(decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }

  // ── Step 1: OTP ───────────────────────────────────────────────────────────
  Widget _buildOtpStep() {
    final canResend = _resendSeconds == 0 && !_isLoading;

    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildStepIndicator(),
        const SizedBox(height: 28),

        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Glass.pink.withOpacity(0.25),
            shape: BoxShape.circle,
            border: Border.all(color: Glass.pinkDeep, width: 2),
          ),
          child: Icon(Icons.mark_email_read_outlined, color: Glass.pinkDeep, size: 38),
        ),
        const SizedBox(height: 20),

        Text('Check your email',
            style: Glass.heading(size: 20, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'We sent a 4-digit code to\n${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: Glass.body(size: 13, color: Glass.textMuted).copyWith(height: 1.5),
        ),
        const SizedBox(height: 28),

        // OTP boxes
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
                      ? Glass.blueDeep
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
                style: Glass.heading(size: 22, weight: FontWeight.w700),
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
            onPressed: _isLoading ? null : _handleVerifyOtp,
            style: Glass.primaryButtonStyle(),
            child: _isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text('Verify Code',
                    style: Glass.heading(size: 16, weight: FontWeight.w600, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Didn't receive the code? ",
                style: Glass.body(size: 13, color: Glass.textMuted)),
            GestureDetector(
              onTap: canResend ? _handleResendOtp : null,
              child: Text(
                _resendSeconds > 0 ? 'Resend in ${_resendSeconds}s' : 'Resend',
                style: Glass.body(
                  size: 13,
                  weight: FontWeight.w700,
                  color: canResend ? Glass.blueDeep : Glass.textHint,
                ).copyWith(
                  decoration:
                      canResend ? TextDecoration.underline : TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 2: New Password ──────────────────────────────────────────────────
  Widget _buildResetStep() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildStepIndicator(),
        const SizedBox(height: 28),

        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Glass.purple.withOpacity(0.25),
            shape: BoxShape.circle,
            border: Border.all(color: Glass.purpleDeep, width: 2),
          ),
          child: Icon(Icons.lock_outline_rounded, color: Glass.purpleDeep, size: 38),
        ),
        const SizedBox(height: 20),

        Text('Set new password', style: Glass.heading(size: 20, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'Choose a strong password that meets\nall the requirements below.',
          textAlign: TextAlign.center,
          style: Glass.body(size: 13, color: Glass.textMuted).copyWith(height: 1.5),
        ),
        const SizedBox(height: 28),

        // New password
        Align(alignment: Alignment.centerLeft, child: _label('New Password')),
        const SizedBox(height: 6),
        _passwordField(
          controller: _newPasswordController,
          hint: '••••••••',
          obscure: _obscureNew,
          onToggle: () => setState(() => _obscureNew = !_obscureNew),
          // Rebuild on every keystroke so the checklist and the
          // confirm-password match indicator update live.
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: _buildPasswordChecklist(),
        ),
        const SizedBox(height: 16),

        // Confirm password
        Align(alignment: Alignment.centerLeft, child: _label('Confirm Password')),
        const SizedBox(height: 6),
        _passwordField(
          controller: _confirmPasswordController,
          hint: '••••••••',
          obscure: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          // Rebuild on every keystroke so the match indicator is live.
          onChanged: (_) => setState(() {}),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: _buildPasswordMatchIndicator(),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleResetPassword,
            style: Glass.primaryButtonStyle(),
            child: _isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text('Reset Password',
                    style: Glass.heading(size: 16, weight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // ── Live password requirements checklist ──────────────────────────────────
  Widget _buildPasswordChecklist() {
    final p = _newPasswordController.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _requirementRow('At least $_minPasswordLength characters', _hasMinLength(p)),
        _requirementRow('One uppercase letter (A-Z)', _hasUppercase(p)),
        _requirementRow('One lowercase letter (a-z)', _hasLowercase(p)),
        _requirementRow('One number (0-9)', _hasNumber(p)),
        _requirementRow('One special character (e.g. ! @ # \$ %)', _hasSpecialChar(p)),
      ],
    );
  }

  Widget _requirementRow(String text, bool met) {
    const metColor = Color(0xFF4CAF7D);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 15,
            color: met ? metColor : Glass.textHint,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: Glass.body(
              size: 12,
              color: met ? metColor : Glass.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ── Live confirm-password match indicator ─────────────────────────────────
  // Hidden until the user starts typing in the confirm field, then shows
  // "Passwords do not match" (red) or "Passwords match" (green) in real time.
  Widget _buildPasswordMatchIndicator() {
    final confirm = _confirmPasswordController.text;
    if (confirm.isEmpty) return const SizedBox.shrink();

    final matches = confirm == _newPasswordController.text;
    const matchColor = Color(0xFF4CAF7D);
    final color = matches ? matchColor : Glass.pinkDeep;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            matches ? Icons.check_circle : Icons.error_outline,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            matches ? 'Passwords match' : 'Passwords do not match',
            style: Glass.body(size: 12, color: color),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────
  Widget _label(String text) {
    return Text(text, style: Glass.body(size: 14, weight: FontWeight.w700));
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      style: Glass.body(size: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Glass.body(color: Glass.textHint).copyWith(letterSpacing: 3),
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
          borderSide: BorderSide(color: Glass.blueDeep.withOpacity(0.7), width: 1.4),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Glass.textMuted,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}