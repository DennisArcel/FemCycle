import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import 'terms_screen.dart';
import '../widgets/glass.dart';

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
      backgroundColor: Glass.pageBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBackground()),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Glass.card(
                          radius: 18,
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              _toggleItem(
                                icon: Icons.notifications_outlined,
                                iconColor: Glass.pinkDeep,
                                title: 'Push Notifications',
                                sub: 'Cycle alerts, reminders & updates',
                                value: _pushNotif,
                                onChanged: (v) => setState(() => _pushNotif = v),
                              ),
                              _divider(),
                              _toggleItem(
                                icon: Icons.dark_mode_outlined,
                                iconColor: Glass.blueDeep,
                                title: 'Dark Mode',
                                sub: isDark ? 'Currently dark' : 'Currently light',
                                value: isDark,
                                onChanged: (_) => themeProvider.toggleTheme(),
                              ),
                              _divider(),
                              _arrowItem(
                                icon: Icons.shield_outlined,
                                iconColor: Glass.blueDeep,
                                title: 'Privacy Policy',
                                sub: 'Read our privacy terms',
                                onTap: () {},
                              ),
                              _divider(),
                              _arrowItem(
                                icon: Icons.description_outlined,
                                iconColor: Glass.purpleDeep,
                                title: 'Terms & Conditions',
                                sub: 'Read our terms of use',
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const TermsScreen())),
                              ),
                              _divider(),
                              _arrowItem(
                                icon: Icons.info_outline,
                                iconColor: Glass.purpleDeep,
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
      child: Glass.card(
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
              child: Icon(Icons.chevron_left, color: Glass.textDark, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Text('Settings', style: Glass.heading(size: 18, weight: FontWeight.w600)),
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
              Text(title, style: Glass.body(size: 14, weight: FontWeight.w600)),
              Text(sub, style: Glass.body(size: 11, color: Glass.textMuted)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: Glass.pinkDeep,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Glass.textHint.withOpacity(0.5),
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
                Text(title, style: Glass.body(size: 14, weight: FontWeight.w600)),
                Text(sub, style: Glass.body(size: 11, color: Glass.textMuted)),
              ],
            ),
          ),
          if (showArrow)
            Icon(Icons.arrow_forward_ios, size: 14, color: Glass.textMuted),
        ]),
      ),
    );
  }
}
