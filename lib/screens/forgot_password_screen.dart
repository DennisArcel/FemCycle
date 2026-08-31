import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      content: Text(msg, style: _Glass.body(color: Colors.white)),
      backgroundColor: isError ? _Glass.pinkDeep : const Color(0xFF4CAF7D),
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
                style: _Glass.heading(size: 18, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Your password has been updated successfully. Please log in with your new password.',
              textAlign: TextAlign.center,
              style: _Glass.body(size: 13, color: _Glass.textMuted).copyWith(height: 1.5),
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
                style: _Glass.primaryButtonStyle(),
                child: Text('Back to Login',
                    style: _Glass.body(
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _Glass.card(
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
      child: _Glass.card(
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
                child: Icon(Icons.chevron_left, color: _Glass.textDark, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Text('Forgot Password', style: _Glass.heading(size: 18, weight: FontWeight.w600)),
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
                                ? _Glass.blueDeep
                                : Colors.white.withOpacity(0.5),
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 14)
                            : Text(
                                '${i + 1}',
                                style: _Glass.body(
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: isActive ? Colors.white : _Glass.textMuted,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: _Glass.body(
                        size: 10,
                        weight: isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive ? _Glass.blueDeep : _Glass.textHint,
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
            color: _Glass.blue.withOpacity(0.25),
            shape: BoxShape.circle,
            border: Border.all(color: _Glass.blueDeep, width: 2),
          ),
          child: Icon(Icons.lock_reset_rounded, color: _Glass.blueDeep, size: 38),
        ),
        const SizedBox(height: 20),

        Text('Forgot your password?',
            style: _Glass.heading(size: 20, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          "No worries! Enter your email and we'll send you a verification code.",
          textAlign: TextAlign.center,
          style: _Glass.body(size: 13, color: _Glass.textMuted).copyWith(height: 1.5),
        ),
        const SizedBox(height: 28),

        // Email field
        Align(alignment: Alignment.centerLeft, child: _label('Email Address')),
        const SizedBox(height: 6),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: _Glass.body(size: 15),
          decoration: InputDecoration(
            hintText: 'stacey@gmail.com',
            hintStyle: _Glass.body(color: _Glass.textHint),
            filled: true,
            fillColor: Colors.white.withOpacity(0.55),
            prefixIcon: Icon(Icons.email_outlined, color: _Glass.blueDeep, size: 20),
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
              borderSide: BorderSide(color: _Glass.blueDeep.withOpacity(0.7), width: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSendCode,
            style: _Glass.primaryButtonStyle(),
            child: _isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text('Send Verification Code',
                    style: _Glass.heading(size: 16, weight: FontWeight.w600, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 18),

        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            'Back to Login',
            style: _Glass.body(
              size: 13,
              weight: FontWeight.w700,
              color: _Glass.blueDeep,
            ).copyWith(decoration: TextDecoration.underline),
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
        _buildStepIndicator(),
        const SizedBox(height: 28),

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

        Text('Check your email',
            style: _Glass.heading(size: 20, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'We sent a 4-digit code to\n${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: _Glass.body(size: 13, color: _Glass.textMuted).copyWith(height: 1.5),
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
            onPressed: _isLoading ? null : _handleVerifyOtp,
            style: _Glass.primaryButtonStyle(),
            child: _isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text('Verify Code',
                    style: _Glass.heading(size: 16, weight: FontWeight.w600, color: Colors.white)),
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
                style: _Glass.body(
                  size: 13,
                  weight: FontWeight.w700,
                  color: _Glass.blueDeep,
                ).copyWith(decoration: TextDecoration.underline),
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
            color: _Glass.purple.withOpacity(0.25),
            shape: BoxShape.circle,
            border: Border.all(color: _Glass.purpleDeep, width: 2),
          ),
          child: Icon(Icons.lock_outline_rounded, color: _Glass.purpleDeep, size: 38),
        ),
        const SizedBox(height: 20),

        Text('Set new password', style: _Glass.heading(size: 20, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'Your new password must be at least\n8 characters long.',
          textAlign: TextAlign.center,
          style: _Glass.body(size: 13, color: _Glass.textMuted).copyWith(height: 1.5),
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
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleResetPassword,
            style: _Glass.primaryButtonStyle(),
            child: _isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text('Reset Password',
                    style: _Glass.heading(size: 16, weight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────
  Widget _label(String text) {
    return Text(text, style: _Glass.body(size: 14, weight: FontWeight.w700));
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
      style: _Glass.body(size: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: _Glass.body(color: _Glass.textHint).copyWith(letterSpacing: 3),
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
          borderSide: BorderSide(color: _Glass.blueDeep.withOpacity(0.7), width: 1.4),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: _Glass.textMuted,
            size: 20,
          ),
          onPressed: onToggle,
        ),
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

  /// Frosted translucent card: blurred backdrop + soft white glass fill.
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

/// Three soft, blurred color blobs (blue / pink / purple) that gently drift
/// behind the frosted glass content. Purely decorative — no state that
/// affects the rest of the screen.
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