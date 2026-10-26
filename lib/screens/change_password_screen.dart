import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme_provider.dart';
import '../services/api_service.dart';
import '../widgets/glass.dart';

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
  bool _isSaving = false;

  // Minimum password length.
  static const int _minPasswordLength = 8;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ── Password rules ───────────────────────────────────────────────────
  bool _hasMinLength(String p) => p.length >= _minPasswordLength;
  bool _hasUppercase(String p) => RegExp(r'[A-Z]').hasMatch(p);
  bool _hasLowercase(String p) => RegExp(r'[a-z]').hasMatch(p);
  bool _hasNumber(String p) => RegExp(r'[0-9]').hasMatch(p);
  bool _hasSpecialChar(String p) => RegExp(r'[^A-Za-z0-9\s]').hasMatch(p);

  bool _isPasswordStrong(String p) =>
      _hasMinLength(p) &&
      _hasUppercase(p) &&
      _hasLowercase(p) &&
      _hasNumber(p) &&
      _hasSpecialChar(p);

  Future<void> _handleUpdate() async {
    if (_currentController.text.isEmpty ||
        _newController.text.isEmpty ||
        _confirmController.text.isEmpty) {
      _showSnack('Please fill in all fields.', isError: true);
      return;
    }
    if (!_isPasswordStrong(_newController.text)) {
      _showSnack(
          'Password must be at least $_minPasswordLength characters and include an '
          'uppercase letter, a lowercase letter, a number, and a special character.',
          isError: true);
      return;
    }
    if (_newController.text != _confirmController.text) {
      _showSnack('New passwords do not match.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final result = await ApiService.changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
      newPasswordConfirmation: _confirmController.text,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == true) {
      _showSnack('Password updated successfully!', isError: false);
      Navigator.pop(context);
    } else {
      _showSnack(
          result['message'] ?? 'Could not update password. Please try again.',
          isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: Glass.body(color: Colors.white)),
      backgroundColor: isError ? Glass.pinkDeep : Glass.blueDeep,
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter your current password and choose a new one to update your account security.',
                          style: Glass.body(
                              size: 13, color: Glass.textMuted).copyWith(height: 1.5),
                        ),
                        const SizedBox(height: 20),
                        _buildPasswordField(
                          label: 'CURRENT PASSWORD',
                          controller: _currentController,
                          show: _showCurrent,
                          onToggle: () =>
                              setState(() => _showCurrent = !_showCurrent),
                        ),
                        const SizedBox(height: 10),
                        _buildPasswordField(
                          label: 'NEW PASSWORD',
                          controller: _newController,
                          show: _showNew,
                          onToggle: () => setState(() => _showNew = !_showNew),
                          // Rebuild on every keystroke so the checklist updates live.
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        _buildPasswordField(
                          label: 'CONFIRM NEW PASSWORD',
                          controller: _confirmController,
                          show: _showConfirm,
                          onToggle: () =>
                              setState(() => _showConfirm = !_showConfirm),
                        ),
                        const SizedBox(height: 12),
                        _buildPasswordChecklistCard(),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _handleUpdate,
                            style: Glass.primaryButtonStyle(),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Text('Update Password',
                                    style: Glass.heading(
                                        size: 16, weight: FontWeight.w600, color: Colors.white)),
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
            Text('Change Password', style: Glass.heading(size: 18, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Live password requirements checklist ──────────────────────────────────
  Widget _buildPasswordChecklistCard() {
    final p = _newController.text;
    return Glass.card(
      radius: 14,
      padding: const EdgeInsets.all(12),
      opacity: 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Glass.blueDeep),
              const SizedBox(width: 8),
              Text(
                'Your new password must have:',
                style: Glass.body(size: 12, weight: FontWeight.w700, color: Glass.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _requirementRow('At least $_minPasswordLength characters', _hasMinLength(p)),
          _requirementRow('One uppercase letter (A-Z)', _hasUppercase(p)),
          _requirementRow('One lowercase letter (a-z)', _hasLowercase(p)),
          _requirementRow('One number (0-9)', _hasNumber(p)),
          _requirementRow('One special character (e.g. ! @ # \$ %)', _hasSpecialChar(p)),
        ],
      ),
    );
  }

  Widget _requirementRow(String text, bool met) {
    const metColor = Color(0xFF4CAF7D);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 15,
            color: met ? metColor : Glass.textHint,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Glass.body(
                size: 12,
                color: met ? metColor : Glass.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool show,
    required VoidCallback onToggle,
    ValueChanged<String>? onChanged,
  }) {
    return Glass.card(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Glass.body(
                size: 10,
                weight: FontWeight.w700,
                color: Glass.textMuted,
              ).copyWith(letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: !show,
                  onChanged: onChanged,
                  style: Glass.body(size: 14),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: Glass.body(color: Glass.textHint),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                  show
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: Glass.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}