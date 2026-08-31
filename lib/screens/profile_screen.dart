import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'account_info_screen.dart';
import 'change_password_screen.dart';
import 'health_profile_screen.dart';
import 'login_screen.dart';
import '../theme/theme_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

// NOTE: to actually persist the picture, add a method to ApiService
// following the pattern of your other endpoints, e.g.:
//
//   static Future<Map<String, dynamic>> uploadAvatar(File file) async {
//     ... multipart POST /user/avatar, field name 'avatar' ...
//   }
//
// Once that exists, call it from _pickAvatar() below (marked with a TODO)
// so the picked image is actually saved server-side, not just shown locally.

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _displayName = '';
  String _displayEmail = '';
  bool _isLoading = true;

  final ImagePicker _picker = ImagePicker();
  File? _pickedAvatar;
  bool _isUploadingAvatar = false;

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
        style: _Glass.body(color: Colors.white),
      ),
      backgroundColor: value ? _Glass.blueDeep : const Color(0xFFE24B4A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AvatarSourceSheet(
        onPick: (s) => Navigator.pop(ctx, s),
      ),
    );
    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _pickedAvatar = File(picked.path);
    });

    // TODO: once ApiService.uploadAvatar exists (see NOTE at top of file),
    // upload it here, e.g.:
    //
    // setState(() => _isUploadingAvatar = true);
    // final result = await ApiService.uploadAvatar(_pickedAvatar!);
    // if (!mounted) return;
    // setState(() => _isUploadingAvatar = false);
    // if (result['success'] != true) {
    //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //     content: Text(result['message'] ?? 'Could not upload photo.'),
    //   ));
    // }
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
      backgroundColor: _Glass.pageBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientBackground()),
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
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.chevron_left,
                                    color: _Glass.blueDeep, size: 22),
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
                              color: _Glass.blueDeep),
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
        Text('Profile', style: _Glass.heading(size: 22, weight: FontWeight.w700)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _isUploadingAvatar ? null : _pickAvatar,
          child: Stack(
            children: [
              _Glass.frostedCircle(
                size: 100,
                child: _pickedAvatar != null
                    ? Image.file(_pickedAvatar!, fit: BoxFit.cover)
                    : Image.asset(
                        'assets/images/avatar.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF5D5A0).withOpacity(0.6),
                          child: Icon(Icons.person, size: 55, color: _Glass.pinkDeep),
                        ),
                      ),
              ),
              if (_isUploadingAvatar)
                Positioned.fill(
                  child: ClipOval(
                    child: Container(
                      color: Colors.black.withOpacity(0.35),
                      child: const Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [_Glass.purpleDeep, _Glass.blueDeep]),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _displayName.isNotEmpty ? _displayName : 'Your Name',
          style: _Glass.heading(size: 18, weight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        if (_displayEmail.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: _Glass.blue.withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _displayEmail,
              style: _Glass.body(size: 13, color: _Glass.blueDeep),
            ),
          ),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _Glass.card(
        radius: 22,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _buildMenuItem(
              icon: Icons.person_outline,
              iconColor: _Glass.blueDeep,
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
              iconColor: _Glass.pinkDeep,
              label: 'Health Profile',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HealthProfileScreen())),
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.lock_outline,
              iconColor: _Glass.blueDeep,
              label: 'Password',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
            ),
            _buildDivider(),
            _buildNotificationsMenuItem(),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.logout,
              iconColor: _Glass.pinkDeep,
              label: 'Logout',
              labelColor: _Glass.pinkDeep,
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
                style: _Glass.body(
                  size: 15,
                  weight: FontWeight.w600,
                  color: labelColor ?? _Glass.textDark,
                ),
              ),
            ),
            if (showArrow)
              Icon(Icons.arrow_forward, size: 18, color: _Glass.textMuted),
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
              color: _Glass.blueDeep.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _notificationsEnabled
                  ? Icons.notifications_outlined
                  : Icons.notifications_off_outlined,
              color: _Glass.blueDeep,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Notifications',
              style: _Glass.body(
                size: 15,
                weight: FontWeight.w600,
                color: _Glass.textDark,
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
                        color: _Glass.blueDeep,
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
                    activeTrackColor: _Glass.pinkDeep,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: _Glass.textHint.withOpacity(0.5),
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
            style: _Glass.heading(size: 18, weight: FontWeight.w700)),
        content: Text('Are you sure you want to log out?',
            style: _Glass.body(size: 14, color: _Glass.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: _Glass.body(color: _Glass.textMuted)),
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
              backgroundColor: _Glass.pinkDeep,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text('Log out', style: _Glass.body(color: Colors.white)),
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
                style: _Glass.heading(size: 18, weight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This permanently deletes your account and all your data — '
                  'cycles, mood logs, diary entries, everything. This cannot '
                  'be undone.',
                  style: _Glass.body(size: 13, color: _Glass.textMuted),
                ),
                const SizedBox(height: 16),
                Text('Enter your password to confirm',
                    style: _Glass.body(size: 13, weight: FontWeight.w600)),
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
                        color: _Glass.textMuted,
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
                    Text('Cancel', style: _Glass.body(color: _Glass.textMuted)),
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
                    : Text('Delete', style: _Glass.body(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Glass bottom sheet offering Camera / Gallery / Cancel for picking a new
/// profile picture. Purely presentational — the choice is returned to the
/// caller via Navigator.pop, no state of its own besides the tap.
class _AvatarSourceSheet extends StatelessWidget {
  final ValueChanged<ImageSource> onPick;

  const _AvatarSourceSheet({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: _Glass.card(
        radius: 24,
        padding: const EdgeInsets.all(20),
        opacity: 0.85,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _Glass.textHint.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Update profile photo',
                style: _Glass.heading(size: 17, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Choose a new picture',
                style: _Glass.body(size: 12, color: _Glass.textMuted)),
            const SizedBox(height: 16),
            _sourceTile(
              icon: Icons.photo_camera_outlined,
              label: 'Take a photo',
              onTap: () => onPick(ImageSource.camera),
            ),
            const SizedBox(height: 8),
            _sourceTile(
              icon: Icons.photo_library_outlined,
              label: 'Choose from gallery',
              onTap: () => onPick(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [_Glass.purpleDeep, _Glass.blueDeep]),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 17),
            ),
            const SizedBox(width: 12),
            Text(label, style: _Glass.body(size: 14, weight: FontWeight.w600)),
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