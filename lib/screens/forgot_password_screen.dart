import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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
    setState(() => _isLoading = true);
    final result = await ApiService.sendOtp(email: _emailController.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSnack('A new code has been sent to your email.', isError: false);
    } else {
      _showSnack(result['message'] ?? 'Could not resend code.');
    }
  }

  // ── Step 2: Reset Password ───────────────────────────────────────────
  Future<void> _handleResetPassword() async {
    if (_newPasswordController.text.length < 8) {
      _showSnack('Password must be at least 8 characters.');
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
      content: Text(msg, style: const TextStyle(fontFamily: 'Mallanna')),
      backgroundColor: isError ? const Color(0xFFE96A8F) : const Color(0xFF4CAF7D),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFE4F7EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Color(0xFF4CAF7D), size: 34),
            ),
            const SizedBox(height: 16),
            const Text(
              'Password Reset!',
              style: TextStyle(
                fontFamily: 'Mallanna',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your password has been updated successfully. Please log in with your new password.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Mallanna',
                fontSize: 13,
                color: Color(0xFF888888),
                height: 1.5,
              ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF84B2E9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Back to Login',
                    style: TextStyle(
                        fontFamily: 'Mallanna',
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
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
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _step == 0
                      ? _buildEmailStep()
                      : _step == 1
                          ? _buildOtpStep()
                          : _buildResetStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      color: const Color(0xFF84B2E9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_left,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Forgot Password',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Mallanna',
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
                                ? const Color(0xFF84B2E9)
                                : const Color(0xFFDDDDDD),
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 14)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontFamily: 'Mallanna',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? Colors.white
                                      : const Color(0xFF888888),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontFamily: 'Mallanna',
                        fontSize: 10,
                        color: isActive
                            ? const Color(0xFF84B2E9)
                            : const Color(0xFFAAAAAA),
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
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
                        : const Color(0xFFDDDDDD),
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
        const SizedBox(height: 12),
        _buildStepIndicator(),
        const SizedBox(height: 32),

        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFE4E8FE),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF84B2E9), width: 2),
          ),
          child: const Icon(Icons.lock_reset_rounded,
              color: Color(0xFF84B2E9), size: 38),
        ),
        const SizedBox(height: 20),

        const Text(
          'Forgot your password?',
          style: TextStyle(
            fontFamily: 'Mallanna',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "No worries! Enter your email and we'll send you a verification code.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Mallanna',
            fontSize: 13,
            color: Color(0xFF888888),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        // Email field
        Align(
          alignment: Alignment.centerLeft,
          child: _label('Email Address'),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(
              fontFamily: 'Archivo', fontSize: 15, color: Color(0xFF000000)),
          decoration: InputDecoration(
            hintText: 'stacey@gmail.com',
            hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.email_outlined,
                color: Color(0xFF84B2E9), size: 20),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSendCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF84B2E9),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF84B2E9).withOpacity(0.6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text('Send Verification Code',
                    style: TextStyle(
                        fontFamily: 'Mallanna',
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 20),

        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'Back to Login',
            style: TextStyle(
              fontFamily: 'Mallanna',
              fontSize: 13,
              color: Color(0xFF84B2E9),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 1: OTP ───────────────────────────────────────────────────────────
  Widget _buildOtpStep() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        _buildStepIndicator(),
        const SizedBox(height: 32),

        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F5),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE96A8F), width: 2),
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              color: Color(0xFFE96A8F), size: 38),
        ),
        const SizedBox(height: 20),

        const Text(
          'Check your email',
          style: TextStyle(
            fontFamily: 'Mallanna',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a 4-digit code to\n${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Mallanna',
            fontSize: 13,
            color: Color(0xFF888888),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        // OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            return Container(
              width: 58,
              height: 58,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _otpControllers[i].text.isNotEmpty
                      ? const Color(0xFF84B2E9)
                      : const Color(0xFFDDDDDD),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _otpControllers[i],
                focusNode: _otpFocusNodes[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(
                  fontFamily: 'Mallanna',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
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
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF84B2E9),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF84B2E9).withOpacity(0.6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text('Verify Code',
                    style: TextStyle(
                        fontFamily: 'Mallanna',
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Didn't receive the code? ",
              style: TextStyle(
                  fontFamily: 'Mallanna',
                  fontSize: 13,
                  color: Color(0xFF888888)),
            ),
            GestureDetector(
              onTap: _isLoading ? null : _handleResendOtp,
              child: const Text(
                'Resend',
                style: TextStyle(
                  fontFamily: 'Mallanna',
                  fontSize: 13,
                  color: Color(0xFF84B2E9),
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
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
        const SizedBox(height: 12),
        _buildStepIndicator(),
        const SizedBox(height: 32),

        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFF5EAF7),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFBC6B9C), width: 2),
          ),
          child: const Icon(Icons.lock_outline_rounded,
              color: Color(0xFFBC6B9C), size: 38),
        ),
        const SizedBox(height: 20),

        const Text(
          'Set new password',
          style: TextStyle(
            fontFamily: 'Mallanna',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your new password must be at least\n8 characters long.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Mallanna',
            fontSize: 13,
            color: Color(0xFF888888),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        // New password
        Align(alignment: Alignment.centerLeft, child: _label('New Password')),
        const SizedBox(height: 6),
        _passwordField(
          controller: _newPasswordController,
          hint: '••••••••',
          obscure: _obscureNew,
          onToggle: () => setState(() => _obscureNew = !_obscureNew),
        ),
        const SizedBox(height: 16),

        // Confirm password
        Align(
            alignment: Alignment.centerLeft,
            child: _label('Confirm Password')),
        const SizedBox(height: 6),
        _passwordField(
          controller: _confirmPasswordController,
          hint: '••••••••',
          obscure: _obscureConfirm,
          onToggle: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleResetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF84B2E9),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF84B2E9).withOpacity(0.6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text('Reset Password',
                    style: TextStyle(
                        fontFamily: 'Mallanna',
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────
  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Mallanna',
        fontSize: 14,
        color: Color(0xFF333333),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(
          fontFamily: 'Archivo', fontSize: 15, color: Color(0xFF000000)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: Color(0xFFAAAAAA), letterSpacing: 3),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: context.textHint,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}