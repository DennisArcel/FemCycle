import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import 'terms_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotif = true;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

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
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        _Glass.card(
                          radius: 18,
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              _toggleItem(
                                icon: Icons.notifications_outlined,
                                iconColor: _Glass.pinkDeep,
                                title: 'Push Notifications',
                                sub: 'Cycle alerts, reminders & updates',
                                value: _pushNotif,
                                onChanged: (v) => setState(() => _pushNotif = v),
                              ),
                              _divider(),
                              _toggleItem(
                                icon: Icons.dark_mode_outlined,
                                iconColor: _Glass.blueDeep,
                                title: 'Dark Mode',
                                sub: isDark ? 'Currently dark' : 'Currently light',
                                value: isDark,
                                onChanged: (_) => themeProvider.toggleTheme(),
                              ),
                              _divider(),
                              _arrowItem(
                                icon: Icons.shield_outlined,
                                iconColor: _Glass.blueDeep,
                                title: 'Privacy Policy',
                                sub: 'Read our privacy terms',
                                onTap: () {},
                              ),
                              _divider(),
                              _arrowItem(
                                icon: Icons.description_outlined,
                                iconColor: _Glass.purpleDeep,
                                title: 'Terms & Conditions',
                                sub: 'Read our terms of use',
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const TermsScreen())),
                              ),
                              _divider(),
                              _arrowItem(
                                icon: Icons.info_outline,
                                iconColor: _Glass.purpleDeep,
                                title: 'App Version',
                                sub: 'FemCycle v2.0.0',
                                showArrow: false,
                                onTap: () {},
                              ),
                            ],
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
        child: Row(children: [
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
          Text('Settings', style: _Glass.heading(size: 18, weight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _divider() => Divider(
      height: 1, thickness: 0.5, color: Colors.white.withOpacity(0.5), indent: 14, endIndent: 14);

  Widget _iconBox(IconData icon, Color iconColor) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: iconColor, size: 18),
    );
  }

  Widget _toggleItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String sub,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        _iconBox(icon, iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _Glass.body(size: 14, weight: FontWeight.w600)),
              Text(sub, style: _Glass.body(size: 11, color: _Glass.textMuted)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: _Glass.pinkDeep,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: _Glass.textHint.withOpacity(0.5),
        ),
      ]),
    );
  }

  Widget _arrowItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String sub,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          _iconBox(icon, iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _Glass.body(size: 14, weight: FontWeight.w600)),
                Text(sub, style: _Glass.body(size: 11, color: _Glass.textMuted)),
              ],
            ),
          ),
          if (showArrow)
            Icon(Icons.arrow_forward_ios, size: 14, color: _Glass.textMuted),
        ]),
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