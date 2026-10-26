import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'account_info_screen.dart';
import 'change_password_screen.dart';
import 'health_profile_screen.dart';
import 'login_screen.dart';
import '../theme/theme_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/glass.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _displayName = '';
  String _displayEmail = '';
  bool _isLoading = true;

  // ── Notifications toggle state ────────────────────────────────────────────
  bool _notificationsEnabled = true;
  bool _isLoadingNotifPref = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final enabled = await NotificationService.areNotificationsEnabled();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = enabled;
      _isLoadingNotifPref = false;
    });
  }

  Future<void> _onToggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await NotificationService.setNotificationsEnabled(value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        value
            ? 'Notifications turned on.'
            : 'Notifications turned off — all scheduled reminders were cancelled.',
        style: Glass.body(color: Colors.white),
      ),
      backgroundColor: value ? Glass.blueDeep : const Color(0xFFE24B4A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _loadProfile() async {
    final result = await ApiService.getProfile();
    if (!mounted) return;
    if (result['success'] == true) {
      final user = result['user'] as Map<String, dynamic>;
      setState(() {
        _displayName =
            '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
        _displayEmail = user['email'] ?? '';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Glass.pageBackground,
      body: Stack(
        // Without this, the Stack shrinks to the height of the content and
        // the background only paints that far, leaving a plain band below.
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: AmbientBackground()),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: GlassBlur(sigma: 12, child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.chevron_left,
                                    color: Glass.blueDeep, size: 22),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                              color: Glass.blueDeep),
                        )
                      : _buildHeader(),
                  const SizedBox(height: 30),
                  _buildMenuCard(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
  return Column(
    children: [
      Text('Profile', style: Glass.heading(size: 22, weight: FontWeight.w700)),
      const SizedBox(height: 20),
      // Matches the avatar style used in HomeScreen's top bar —
      // gradient circle with the user's first initial, instead of a
      // static generic image.
      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Glass.pinkDeep, Glass.purpleDeep]),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 3),
        ),
        alignment: Alignment.center,
        child: Text(
          _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'U',
          style: Glass.heading(size: 38, weight: FontWeight.w700, color: Colors.white),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        _displayName.isNotEmpty ? _displayName : 'Your Name',
        style: Glass.heading(size: 18, weight: FontWeight.w700),
      ),
      const SizedBox(height: 6),
      if (_displayEmail.isNotEmpty)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Glass.blue.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _displayEmail,
            style: Glass.body(size: 13, color: Glass.blueDeep),
          ),
        ),
    ],
  );
}

  Widget _buildMenuCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Glass.card(
        radius: 22,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _buildMenuItem(
              icon: Icons.person_outline,
              iconColor: Glass.blueDeep,
              label: 'Personal Details',
              onTap: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AccountInfoScreen()));
                // Refresh name/email after returning from account info
                _loadProfile();
              },
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.favorite_border,
              iconColor: Glass.pinkDeep,
              label: 'Health Profile',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HealthProfileScreen())),
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.lock_outline,
              iconColor: Glass.blueDeep,
              label: 'Password',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
            ),
            _buildDivider(),
            _buildNotificationsMenuItem(),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.logout,
              iconColor: Glass.pinkDeep,
              label: 'Logout',
              labelColor: Glass.pinkDeep,
              showArrow: false,
              onTap: () => _showLogoutDialog(context),
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.delete_forever_outlined,
              iconColor: const Color(0xFFE24B4A),
              label: 'Delete Account',
              labelColor: const Color(0xFFE24B4A),
              showArrow: false,
              onTap: () => _showDeleteAccountDialog(context),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    Color? labelColor,
    bool showArrow = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: Glass.body(
                  size: 15,
                  weight: FontWeight.w600,
                  color: labelColor ?? Glass.textDark,
                ),
              ),
            ),
            if (showArrow)
              Icon(Icons.arrow_forward, size: 18, color: Glass.textMuted),
          ],
        ),
      ),
    );
  }

  // ── Notifications row (menu card, above Logout) ───────────────────────────
  Widget _buildNotificationsMenuItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Glass.blueDeep.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _notificationsEnabled
                  ? Icons.notifications_outlined
                  : Icons.notifications_off_outlined,
              color: Glass.blueDeep,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Notifications',
              style: Glass.body(
                size: 15,
                weight: FontWeight.w600,
                color: Glass.textDark,
              ),
            ),
          ),
          _isLoadingNotifPref
              ? SizedBox(
                  width: 32,
                  height: 18,
                  child: Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Glass.blueDeep,
                      ),
                    ),
                  ),
                )
              : Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: _notificationsEnabled,
                    onChanged: _onToggleNotifications,
                    activeColor: Colors.white,
                    activeTrackColor: Glass.pinkDeep,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Glass.textHint.withOpacity(0.5),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 20,
      endIndent: 20,
      color: Colors.white.withOpacity(0.5),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log out',
            style: Glass.heading(size: 18, weight: FontWeight.w700)),
        content: Text('Are you sure you want to log out?',
            style: Glass.body(size: 14, color: Glass.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: Glass.body(color: Glass.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Glass.pinkDeep,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text('Log out', style: Glass.body(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Delete account dialog ──────────────────────────────────────────────
  // Requires the current password as re-confirmation before calling
  // ApiService.deleteAccount(). On success, the account + all its data is
  // gone server-side, so we just clear local session and drop to Login —
  // same as logout, but there's no account to come back to.
  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();
    bool obscure = true;
    bool isDeleting = false;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> handleDelete() async {
            if (passwordController.text.isEmpty) {
              setDialogState(() => errorText = 'Password is required');
              return;
            }
            setDialogState(() {
              isDeleting = true;
              errorText = null;
            });

            final result = await ApiService.deleteAccount(
              password: passwordController.text,
            );

            if (!ctx.mounted) return;

            if (result['success'] == true) {
              Navigator.pop(ctx);
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            } else {
              setDialogState(() {
                isDeleting = false;
                errorText = result['message'] ?? 'Could not delete account.';
              });
            }
          }

          return AlertDialog(
            backgroundColor: Colors.white.withOpacity(0.95),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Delete account',
                style: Glass.heading(size: 18, weight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This permanently deletes your account and all your data — '
                  'cycles, mood logs, diary entries, everything. This cannot '
                  'be undone.',
                  style: Glass.body(size: 13, color: Glass.textMuted),
                ),
                const SizedBox(height: 16),
                Text('Enter your password to confirm',
                    style: Glass.body(size: 13, weight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: obscure,
                  enabled: !isDeleting,
                  autofocus: true,
                  onSubmitted: (_) => handleDelete(),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    errorText: errorText,
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: Glass.textMuted,
                      ),
                      onPressed: () =>
                          setDialogState(() => obscure = !obscure),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                child:
                    Text('Cancel', style: Glass.body(color: Glass.textMuted)),
              ),
              ElevatedButton(
                onPressed: isDeleting ? null : handleDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE24B4A),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFFE24B4A).withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Delete', style: Glass.body(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}