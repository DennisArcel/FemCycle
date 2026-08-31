import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme_provider.dart';

// NOTE: This is a starting template, not legal advice. Have an actual lawyer
// or your school's legal/compliance resource review this before real
// publishing — especially the health-data and medical-disclaimer sections,
// given FemCycle collects cycle, symptom, and diary data. If you're
// targeting users in the Philippines, this should also be checked against
// the Data Privacy Act of 2012 (RA 10173) requirements, not just Play
// Store's generic policy.

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const String _lastUpdated = 'August 2026';

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
                _buildTopBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _Glass.card(
                      radius: 20,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Last updated: $_lastUpdated',
                              style: _Glass.body(size: 11, color: _Glass.textHint)),
                          const SizedBox(height: 20),

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
                              'qualified healthcare provider for medical concerns, and never disregard or '
                              'delay seeking professional medical advice because of something you read '
                              'in this App.'),

                          _section('4. Eligibility',
                              'You must be able to form a legally binding agreement to use this App. If '
                              'you are using the App on behalf of a minor or are a minor yourself, please '
                              'use the App only with the involvement of a parent or guardian, as '
                              'appropriate in your jurisdiction.'),

                          _section('5. Your Account',
                              'You are responsible for maintaining the confidentiality of your login '
                              'credentials and for all activity under your account. Notify us promptly '
                              'of any unauthorized use of your account.'),

                          _section('6. Your Data',
                              'The data you log (cycle dates, symptoms, diary entries, and health '
                              'profile answers) belongs to you. We process it to provide the App\'s '
                              'features, including predictions and cycle-health signals. See our Privacy '
                              'Policy for details on how your data is collected, stored, and protected.'),

                          _section('7. Acceptable Use',
                              'You agree not to misuse the App, including attempting to access other '
                              'users\' accounts or data, interfering with the App\'s normal operation, or '
                              'using the App for any unlawful purpose.'),

                          _section('8. Intellectual Property',
                              'The App, including its design, branding, and content (excluding data you '
                              'provide), is owned by the developer and protected by applicable '
                              'intellectual property laws.'),

                          _section('9. Termination',
                              'We may suspend or terminate your access to the App if you violate these '
                              'Terms. You may stop using the App and request account deletion at any '
                              'time.'),

                          _section('10. Limitation of Liability',
                              'The App is provided "as is" without warranties of any kind. To the '
                              'fullest extent permitted by law, the developer is not liable for any '
                              'indirect, incidental, or consequential damages arising from your use of '
                              'the App, including decisions made based on predictions or cycle-health '
                              'signals shown in the App.'),

                          _section('11. Changes to These Terms',
                              'We may update these Terms from time to time. Continued use of the App '
                              'after changes take effect constitutes acceptance of the revised Terms.'),

                          _section('12. Contact',
                              'For questions about these Terms, contact the developer through the '
                              'support channel listed on the App\'s store page.'),

                          const SizedBox(height: 4),
                        ],
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

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _Glass.body(size: 14, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(body,
              style: _Glass.body(size: 13, color: _Glass.textMuted).copyWith(height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: _Glass.card(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
                child: Icon(Icons.chevron_left, color: _Glass.textDark, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Text('Terms & Conditions',
                style: _Glass.heading(size: 16, weight: FontWeight.w600)),
          ],
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
    double radius = 24,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double opacity = 0.55,
  }) {
    return ClipRRect(
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