import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme_provider.dart';
import '../services/api_service.dart';

// NOTE: add these two methods to ApiService, following the same pattern as
// your other endpoints (e.g. getProfile()):
//
//   static Future<Map<String, dynamic>> getSymptomProfile() async { ... GET /user/symptom-profile ... }
//   static Future<Map<String, dynamic>> updateSymptomProfile(Map<String, bool?> answers) async {
//     ... PUT /user/symptom-profile with body: answers ...
//   }

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // null = unanswered, true/false = answered. Every question is skippable.
  bool? _hirsutism;
  bool? _acne;
  bool? _hairThinning;
  bool? _weightDifficulty;
  bool? _skinDarkening;
  bool? _familyHistory;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final result = await ApiService.getSymptomProfile();
    if (!mounted) return;
    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _hirsutism = data['hirsutism'] as bool?;
        _acne = data['acne'] as bool?;
        _hairThinning = data['hair_thinning'] as bool?;
        _weightDifficulty = data['weight_difficulty'] as bool?;
        _skinDarkening = data['skin_darkening'] as bool?;
        _familyHistory = data['family_history'] as bool?;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final result = await ApiService.updateSymptomProfile({
      'hirsutism': _hirsutism,
      'acne': _acne,
      'hair_thinning': _hairThinning,
      'weight_difficulty': _weightDifficulty,
      'skin_darkening': _skinDarkening,
      'family_history': _familyHistory,
    });

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        result['success'] == true
            ? 'Health profile updated'
            : (result['message'] ?? 'Could not save. Please try again.'),
        style: _Glass.body(color: Colors.white),
      ),
      backgroundColor:
          result['success'] == true ? _Glass.blueDeep : _Glass.pinkDeep,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
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
                _buildTopBar(context),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: _Glass.blueDeep))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildIntro(),
                              const SizedBox(height: 16),
                              _buildQuestionCard(
                                title: 'Excess or unwanted hair growth',
                                sub: 'Face, chest, or back',
                                value: _hirsutism,
                                onChanged: (v) => setState(() => _hirsutism = v),
                              ),
                              _buildQuestionCard(
                                title: 'Persistent acne',
                                sub: 'Especially jawline or chest',
                                value: _acne,
                                onChanged: (v) => setState(() => _acne = v),
                              ),
                              _buildQuestionCard(
                                title: 'Scalp hair thinning',
                                sub: 'Noticeable thinning on the scalp',
                                value: _hairThinning,
                                onChanged: (v) =>
                                    setState(() => _hairThinning = v),
                              ),
                              _buildQuestionCard(
                                title: 'Difficulty losing weight',
                                sub: 'Or unexplained weight gain',
                                value: _weightDifficulty,
                                onChanged: (v) =>
                                    setState(() => _weightDifficulty = v),
                              ),
                              _buildQuestionCard(
                                title: 'Darkened patches of skin',
                                sub: 'Neck, underarms, or groin',
                                value: _skinDarkening,
                                onChanged: (v) =>
                                    setState(() => _skinDarkening = v),
                              ),
                              _buildQuestionCard(
                                title: 'Family history',
                                sub: 'PCOS or type 2 diabetes in your family',
                                value: _familyHistory,
                                onChanged: (v) =>
                                    setState(() => _familyHistory = v),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _save,
                                  style: _Glass.primaryButtonStyle(),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5),
                                        )
                                      : Text('Save',
                                          style: _Glass.heading(
                                              size: 16,
                                              weight: FontWeight.w600,
                                              color: Colors.white)),
                                ),
                              ),
                            ],
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

  Widget _buildIntro() {
    return _Glass.card(
      radius: 14,
      padding: const EdgeInsets.all(14),
      opacity: 0.5,
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: _Glass.blueDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'These are optional and private. Answering helps give you a more '
              'complete picture alongside your cycle history — this is not a '
              'diagnosis, and none of this replaces seeing a doctor.',
              style: _Glass.body(size: 12, color: _Glass.textMuted).copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard({
    required String title,
    required String sub,
    required bool? value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Glass.card(
        radius: 14,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: _Glass.body(size: 14, weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(sub, style: _Glass.body(size: 11, color: _Glass.textMuted)),
            const SizedBox(height: 10),
            Row(
              children: [
                _choiceChip('Yes', value == true, () => onChanged(true)),
                const SizedBox(width: 8),
                _choiceChip('No', value == false, () => onChanged(false)),
                const SizedBox(width: 8),
                _choiceChip('Skip', value == null, () => onChanged(null)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _choiceChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _Glass.blueDeep : Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _Glass.blueDeep : Colors.white.withOpacity(0.7),
          ),
        ),
        child: Text(
          label,
          style: _Glass.body(
            size: 12,
            weight: FontWeight.w600,
            color: selected ? Colors.white : _Glass.textMuted,
          ),
        ),
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
            Text('Health Profile', style: _Glass.heading(size: 18, weight: FontWeight.w600)),
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