import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme_provider.dart';
import '../services/api_service.dart';

class AccountInfoScreen extends StatefulWidget {
  const AccountInfoScreen({super.key});

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _emailController = TextEditingController();

  DateTime? _birthdayDate;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String _displayName = '';
  String _displayEmail = '';

  int get _age {
    if (_birthdayDate == null) return 0;
    final today = DateTime.now();
    int age = today.year - _birthdayDate!.year;
    if (today.month < _birthdayDate!.month ||
        (today.month == _birthdayDate!.month &&
            today.day < _birthdayDate!.day)) {
      age--;
    }
    return age;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _birthdayController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.getProfile();

    if (!mounted) return;

    if (result['success'] == true) {
      final user = result['user'] as Map<String, dynamic>;
      setState(() {
        _firstNameController.text = user['first_name'] ?? '';
        _middleNameController.text = user['middle_name'] ?? '';
        _lastNameController.text = user['last_name'] ?? '';
        _emailController.text = user['email'] ?? '';
        _displayName =
            '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
        _displayEmail = user['email'] ?? '';

        if (user['birthday'] != null) {
          _birthdayDate = DateTime.tryParse(user['birthday']);
          if (_birthdayDate != null) {
            const months = [
              'January', 'February', 'March', 'April', 'May', 'June',
              'July', 'August', 'September', 'October', 'November', 'December'
            ];
            _birthdayController.text =
                '${months[_birthdayDate!.month - 1]} ${_birthdayDate!.day}, ${_birthdayDate!.year}';
          }
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Could not load profile.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSave() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty) {
      _showSnack('Please fill in all required fields.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    String? birthdayStr;
    if (_birthdayDate != null) {
      birthdayStr =
          '${_birthdayDate!.year}-${_birthdayDate!.month.toString().padLeft(2, '0')}-${_birthdayDate!.day.toString().padLeft(2, '0')}';
    }

    final result = await ApiService.updateProfile(
      firstName: firstName,
      middleName: _middleNameController.text.trim().isEmpty
          ? null
          : _middleNameController.text.trim(),
      lastName: lastName,
      email: email,
      birthday: birthdayStr,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == true) {
      final user = result['user'] as Map<String, dynamic>?;
      if (user != null) {
        setState(() {
          _displayName =
              '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
          _displayEmail = user['email'] ?? '';
        });
      }
      _showSnack('Account information updated!', isError: false);
    } else {
      _showSnack(result['message'] ?? 'Could not update profile.', isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: _Glass.body(color: Colors.white)),
        backgroundColor: isError ? _Glass.pinkDeep : _Glass.blueDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthdayDate ?? DateTime(2000, 1, 15),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: _Glass.blueDeep),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      setState(() {
        _birthdayDate = picked;
        _birthdayController.text =
            '${months[picked.month - 1]} ${picked.day}, ${picked.year}';
      });
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
                _buildTopBar(context),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: _Glass.blueDeep))
                      : _errorMessage != null
                          ? _buildErrorState()
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildAvatar(),
                                  const SizedBox(height: 20),
                                  _buildFieldCard([
                                    _buildField('FIRST NAME', _firstNameController),
                                    _buildField('MIDDLE NAME', _middleNameController),
                                    _buildField('LAST NAME', _lastNameController),
                                    _buildBirthdayField(),
                                    _buildAgeField(),
                                    _buildField('EMAIL ADDRESS', _emailController,
                                        keyboardType: TextInputType.emailAddress),
                                  ]),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isSaving ? null : _handleSave,
                                      style: _Glass.primaryButtonStyle(),
                                      child: _isSaving
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : Text('Save Changes',
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
            Text('Account Information',
                style: _Glass.heading(size: 16, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Column(
      children: [
        Stack(
          children: [
            _Glass.frostedCircle(
              size: 85,
              child: Image.asset('assets/images/avatar.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFF5D5A0).withOpacity(0.6),
                        child: Icon(Icons.person, size: 45, color: _Glass.pinkDeep),
                      )),
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [_Glass.purpleDeep, _Glass.blueDeep]),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(_displayName.isNotEmpty ? _displayName : 'Your Name',
            style: _Glass.heading(size: 16, weight: FontWeight.w700)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _Glass.blue.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(_displayEmail.isNotEmpty ? _displayEmail : '',
              style: _Glass.body(size: 12, color: _Glass.blueDeep)),
        ),
      ],
    );
  }

  Widget _buildFieldCard(List<Widget> children) {
    return _Glass.card(
      radius: 16,
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5), width: 0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: _Glass.body(
                size: 10,
                weight: FontWeight.w700,
                color: _Glass.textMuted,
              ).copyWith(letterSpacing: 0.5)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: _Glass.body(size: 14),
            decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5), width: 0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AGE',
              style: _Glass.body(
                size: 10,
                weight: FontWeight.w700,
                color: _Glass.textMuted,
              ).copyWith(letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                _birthdayDate != null ? '$_age years old' : '—',
                style: _Glass.body(size: 14),
              ),
              if (_birthdayDate != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _Glass.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Auto-calculated',
                      style: _Glass.body(size: 10, color: _Glass.blueDeep)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBirthdayField() {
    return GestureDetector(
      onTap: _pickBirthday,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5), width: 0.5))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BIRTHDAY',
                style: _Glass.body(
                  size: 10,
                  weight: FontWeight.w700,
                  color: _Glass.textMuted,
                ).copyWith(letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _birthdayController.text.isEmpty
                        ? 'Tap to select'
                        : _birthdayController.text,
                    style: _Glass.body(
                      size: 14,
                      color: _birthdayController.text.isEmpty
                          ? _Glass.textHint
                          : _Glass.textDark,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today, size: 15, color: _Glass.blueDeep),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _Glass.card(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 44, color: _Glass.textHint),
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: _Glass.body(size: 13, color: _Glass.textMuted),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfile,
                style: _Glass.primaryButtonStyle(),
                child: Text('Try Again', style: _Glass.body(color: Colors.white)),
              ),
            ],
          ),
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

  /// A circular frosted-glass avatar/logo frame.
  static Widget frostedCircle({required double size, required Widget child}) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.5),
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 3),
          ),
          child: ClipOval(child: child),
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