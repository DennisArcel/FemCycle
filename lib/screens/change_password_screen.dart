import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleUpdate() {
    if (_currentController.text.isEmpty ||
        _newController.text.isEmpty ||
        _confirmController.text.isEmpty) {
      _showSnack('Please fill in all fields.', const Color(0xFFE96A8F));
      return;
    }
    if (_newController.text.length < 8) {
      _showSnack('Password must be at least 8 characters.', const Color(0xFFE96A8F));
      return;
    }
    if (_newController.text != _confirmController.text) {
      _showSnack('New passwords do not match.', const Color(0xFFE96A8F));
      return;
    }
    // TODO: Connect to Laravel API
    _showSnack('Password updated successfully!', const Color(0xFF84B2E9));
    Navigator.pop(context);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = context.cardColor;
    final bgColor = context.bgColor;
    final labelColor = context.textSecondary;
    final textColor = context.textPrimary;
    final hintColor = context.textHint;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter your current password and choose a new one to update your account security.',
                      style: TextStyle(fontFamily: 'Mallanna', fontSize: 13,
                          color: labelColor, height: 1.5),
                    ),
                    const SizedBox(height: 20),

                    _buildPasswordField(
                      label: 'CURRENT PASSWORD',
                      controller: _currentController,
                      show: _showCurrent,
                      onToggle: () => setState(() => _showCurrent = !_showCurrent),
                      cardColor: cardColor,
                      labelColor: labelColor,
                      textColor: textColor,
                      hintColor: hintColor,
                    ),
                    const SizedBox(height: 10),

                    _buildPasswordField(
                      label: 'NEW PASSWORD',
                      controller: _newController,
                      show: _showNew,
                      onToggle: () => setState(() => _showNew = !_showNew),
                      cardColor: cardColor,
                      labelColor: labelColor,
                      textColor: textColor,
                      hintColor: hintColor,
                    ),
                    const SizedBox(height: 10),

                    _buildPasswordField(
                      label: 'CONFIRM NEW PASSWORD',
                      controller: _confirmController,
                      show: _showConfirm,
                      onToggle: () => setState(() => _showConfirm = !_showConfirm),
                      cardColor: cardColor,
                      labelColor: labelColor,
                      textColor: textColor,
                      hintColor: hintColor,
                    ),
                    const SizedBox(height: 10),

                    // Hint
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF84B2E9).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 16, color: Color(0xFF84B2E9)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Password must be at least 8 characters and contain a mix of letters and numbers.',
                              style: TextStyle(
                                  fontFamily: 'Mallanna', fontSize: 11,
                                  color: labelColor, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _handleUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF84B2E9),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Update Password',
                            style: TextStyle(fontFamily: 'Mallanna',
                                fontSize: 16, fontWeight: FontWeight.w600)),
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
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle),
              child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          const Text('Change Password',
              style: TextStyle(color: Colors.white, fontFamily: 'Mallanna',
                  fontSize: 17, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool show,
    required VoidCallback onToggle,
    required Color cardColor,
    required Color labelColor,
    required Color textColor,
    required Color hintColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontFamily: 'Mallanna', fontSize: 10,
                  fontWeight: FontWeight.w700, color: labelColor,
                  letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: !show,
                  style: TextStyle(fontFamily: 'Archivo', fontSize: 14,
                      color: textColor),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: TextStyle(color: hintColor),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                  show ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18, color: labelColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}