import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

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
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _toggleItem(
                            icon: '🔔', iconBg: const Color(0xFFFFF0F5),
                            title: 'Push Notifications',
                            sub: 'Cycle alerts, reminders & updates',
                            value: _pushNotif,
                            onChanged: (v) => setState(() => _pushNotif = v),
                            ctx: context,
                          ),
                          _divider(context),
                          _toggleItem(
                            icon: '🌙', iconBg: const Color(0xFFF0F5FF),
                            title: 'Dark Mode',
                            sub: isDark ? 'Currently dark' : 'Currently light',
                            value: isDark,
                            onChanged: (_) => themeProvider.toggleTheme(),
                            ctx: context,
                          ),
                          _divider(context),
                          _arrowItem(
                            icon: '🛡️', iconBg: const Color(0xFFF0F5FF),
                            title: 'Privacy Policy',
                            sub: 'Read our privacy terms',
                            ctx: context, onTap: () {},
                          ),
                          _divider(context),
                          _arrowItem(
                            icon: 'ℹ️', iconBg: const Color(0xFFE4E8FE),
                            title: 'App Version', sub: 'FemCycle v1.0.0',
                            ctx: context, showArrow: false, onTap: () {},
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
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: const Color(0xFF84B2E9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
            child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        const Text('Settings', style: TextStyle(color: Colors.white, fontFamily: 'Mallanna', fontSize: 17, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _divider(BuildContext context) => Divider(
      height: 1, thickness: 0.5, color: context.dividerColor, indent: 14, endIndent: 14);

  Widget _toggleItem({required String icon, required Color iconBg, required String title,
      required String sub, required bool value, required ValueChanged<bool> onChanged, required BuildContext ctx}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 18)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontFamily: 'Mallanna', fontSize: 14, fontWeight: FontWeight.w600, color: ctx.textPrimary)),
          Text(sub, style: TextStyle(fontFamily: 'Mallanna', fontSize: 11, color: ctx.textSecondary)),
        ])),
        Switch(value: value, onChanged: onChanged,
            activeColor: Colors.white, activeTrackColor: const Color(0xFFE96A8F),
            inactiveThumbColor: Colors.white, inactiveTrackColor: const Color(0xFFDDDDDD)),
      ]),
    );
  }

  Widget _arrowItem({required String icon, required Color iconBg, required String title,
      required String sub, required BuildContext ctx, required VoidCallback onTap, bool showArrow = true}) {
    return GestureDetector(
      onTap: onTap, behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(width: 36, height: 36,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 18)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontFamily: 'Mallanna', fontSize: 14, fontWeight: FontWeight.w600, color: ctx.textPrimary)),
            Text(sub, style: TextStyle(fontFamily: 'Mallanna', fontSize: 11, color: ctx.textSecondary)),
          ])),
          if (showArrow) Icon(Icons.arrow_forward_ios, size: 14, color: ctx.textSecondary),
        ]),
      ),
    );
  }
}