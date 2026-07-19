import 'package:flutter/material.dart';
import 'account_info_screen.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';
import '../theme/theme_provider.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _displayName = '';
  String _displayEmail = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
    final bgColor = context.bgColor;
    final cardColor = context.cardColor;
    final textColor = context.textPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
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
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF84B2E9).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chevron_left,
                            color: Color(0xFF84B2E9), size: 22),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                          color: Color(0xFF84B2E9)),
                    )
                  : _buildHeader(context.isDark, textColor),
              const SizedBox(height: 30),
              _buildMenuCard(context, cardColor, textColor),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textColor) {
    return Column(
      children: [
        Text('Profile',
            style: TextStyle(
              fontFamily: 'Mallanna',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textColor,
            )),
        const SizedBox(height: 20),
        Stack(
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                color: const Color(0xFFF5D5A0),
              ),
              child: ClipOval(
                child: Image.asset('assets/images/avatar.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF5D5A0),
                          child: const Icon(Icons.person,
                              size: 55, color: Color(0xFFBC6B9C)),
                        )),
              ),
            ),
            Positioned(
              bottom: 2, right: 2,
              child: Container(
                width: 28, height: 28,
                decoration: const BoxDecoration(
                    color: Color(0xFF7F77DD), shape: BoxShape.circle),
                child: const Icon(Icons.edit, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _displayName.isNotEmpty ? _displayName : 'Your Name',
          style: TextStyle(
            fontFamily: 'Mallanna',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF84B2E9).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _displayEmail.isNotEmpty ? _displayEmail : '',
            style: const TextStyle(
              fontFamily: 'Mallanna',
              fontSize: 13,
              color: Color(0xFF185FA5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context, Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline,
            iconColor: const Color(0xFF84B2E9),
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
            icon: Icons.lock_outline,
            iconColor: const Color(0xFF84B2E9),
            label: 'Password',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.logout,
            iconColor: const Color(0xFFE96A8F),
            label: 'Logout',
            labelColor: const Color(0xFFE96A8F),
            showArrow: false,
            onTap: () => _showLogoutDialog(context),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    Color labelColor = const Color(0xFF333333),
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
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontFamily: 'Mallanna',
                    fontSize: 15,
                    color: labelColor,
                    fontWeight: FontWeight.w500,
                  )),
            ),
            if (showArrow)
              const Icon(Icons.arrow_forward, size: 18, color: Color(0xFF888888)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1, thickness: 0.5,
      indent: 20, endIndent: 20,
      color: Color(0xFFEEEEEE),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out',
            style: TextStyle(
                fontFamily: 'Mallanna', fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(
                fontFamily: 'Mallanna', color: Color(0xFF666666))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(
                    fontFamily: 'Mallanna', color: Color(0xFF888888))),
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
              backgroundColor: const Color(0xFFE96A8F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Log out',
                style: TextStyle(fontFamily: 'Mallanna')),
          ),
        ],
      ),
    );
  }
}