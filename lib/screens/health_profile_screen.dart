import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme_provider.dart';
import '../services/api_service.dart';
import '../widgets/glass.dart';

// NOTE: add these two methods to ApiService, following the same pattern as
// your other endpoints (e.g. getProfile()):
//
//   static Future<Map<String, dynamic>> getSymptomProfile() async { ... GET /user/symptom-profile ... }
//   static Future<Map<String, dynamic>> updateSymptomProfile(Map<String, bool?> answers) async {
//     ... PUT /user/symptom-profile with body: answers ...
//   }

int _ageFromBirthday(DateTime b) {
  final t = DateTime.now();
  var age = t.year - b.year;
  if (t.month < b.month || (t.month == b.month && t.day < b.day)) age--;
  return age;
}

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  bool _isLoading = true;
  bool _loadFailed = false;
  bool _isSaving = false;

  // Age in years, or null if the birthday couldn't be loaded. Only used to
  // decide whether to show the under-18 note.
  int? _age;

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
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });

    // Start both requests together so the screen doesn't wait twice.
    final symptomFuture = ApiService.getSymptomProfile();
    final profileFuture = ApiService.getProfile();

    final result = await symptomFuture;
    final profileResult = await profileFuture;
    if (!mounted) return;

    // The age is only for the note. If this fails, we just don't show it.
    int? age;
    if (profileResult['success'] == true) {
      final user = profileResult['user'] as Map<String, dynamic>?;
      final b = DateTime.tryParse((user?['birthday'] as String?) ?? '');
      if (b != null) age = _ageFromBirthday(b);
    }

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _age = age;
        _hirsutism = data['hirsutism'] as bool?;
        _acne = data['acne'] as bool?;
        _hairThinning = data['hair_thinning'] as bool?;
        _weightDifficulty = data['weight_difficulty'] as bool?;
        _skinDarkening = data['skin_darkening'] as bool?;
        _familyHistory = data['family_history'] as bool?;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _save() async {
    // Never save over existing answers if we couldn't load them.
    if (_loadFailed) return;

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
        style: Glass.body(color: Colors.white),
      ),
      backgroundColor:
          result['success'] == true ? Glass.blueDeep : Glass.pinkDeep,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
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
                _buildTopBar(context),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: Glass.blueDeep))
                      : _loadFailed
                          ? _buildLoadError()
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildIntro(),
                                  if (_age != null && _age! < 18) ...[
                                    const SizedBox(height: 12),
                                    _buildYoungUserNote(),
                                  ],
                                  const SizedBox(height: 16),
                                  _buildQuestionCard(
                                    title: 'Excess or unwanted hair growth',
                                    sub: 'Face, chest, or back',
                                    value: _hirsutism,
                                    onChanged: (v) =>
                                        setState(() => _hirsutism = v),
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
                                      style: Glass.primaryButtonStyle(),
                                      child: _isSaving
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2.5),
                                            )
                                          : Text('Save',
                                              style: Glass.heading(
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

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Glass.card(
          radius: 14,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 32, color: Glass.textMuted),
              const SizedBox(height: 12),
              Text(
                "Couldn't load your health profile",
                textAlign: TextAlign.center,
                style: Glass.body(size: 14, weight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Check your connection and try again.',
                textAlign: TextAlign.center,
                style: Glass.body(size: 12, color: Glass.textMuted),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _loadProfile,
                  style: Glass.primaryButtonStyle(),
                  child: Text('Retry',
                      style: Glass.heading(
                          size: 14,
                          weight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Glass.card(
      radius: 14,
      padding: const EdgeInsets.all(14),
      opacity: 0.5,
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Glass.blueDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'These are optional and private. Answering helps give you a more '
              'complete picture alongside your cycle history — this is not a '
              'diagnosis, and none of this replaces seeing a doctor.',
              style: Glass.body(size: 12, color: Glass.textMuted).copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // Shown only to users under 18. Matches the backend, which doesn't count
  // cycle irregularity toward the screening for this age group.
  Widget _buildYoungUserNote() {
    return Glass.card(
      radius: 14,
      padding: const EdgeInsets.all(14),
      opacity: 0.5,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.favorite_border, size: 18, color: Glass.pinkDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Your cycles may still be settling at your age, so irregular "
              "periods are common and aren't counted in this screening. These "
              "answers can't diagnose anything. If something worries you, talk "
              "to a parent, a trusted adult, or a doctor.",
              style: Glass.body(size: 12, color: Glass.textMuted).copyWith(height: 1.4),
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
      child: Glass.card(
        radius: 14,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Glass.body(size: 14, weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(sub, style: Glass.body(size: 11, color: Glass.textMuted)),
            const SizedBox(height: 10),
            Row(
              children: [
                _choiceChip('Yes', value == true, () => onChanged(true)),
                const SizedBox(width: 8),
                _choiceChip('No', value == false, () => onChanged(false))
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
          color: selected ? Glass.blueDeep : Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Glass.blueDeep : Colors.white.withOpacity(0.7),
          ),
        ),
        child: Text(
          label,
          style: Glass.body(
            size: 12,
            weight: FontWeight.w600,
            color: selected ? Colors.white : Glass.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Glass.card(
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
                child: Icon(Icons.chevron_left, color: Glass.textDark, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Text('Health Profile', style: Glass.heading(size: 18, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}