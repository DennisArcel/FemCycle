import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme_provider.dart';
import '../services/api_service.dart';
import '../widgets/glass.dart';

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
  // True once a birthday is saved on the server. It can't be changed after that.
  bool _birthdayLocked = false;
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
        // A saved birthday is locked.
        _birthdayLocked = _birthdayDate != null;
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

    // The email is changed through its own dialog, so it is neither
    // validated nor sent here.
    if (firstName.isEmpty || lastName.isEmpty) {
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
          // Once a birthday is saved, lock it.
          if (user['birthday'] != null) _birthdayLocked = true;
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
        content: Text(msg, style: Glass.body(color: Colors.white)),
        backgroundColor: isError ? Glass.pinkDeep : Glass.blueDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _showChangeEmailDialog() async {
    final newEmail = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ChangeEmailDialog(currentEmail: _emailController.text),
    );
    if (newEmail == null || !mounted) return;
    setState(() {
      _emailController.text = newEmail;
      _displayEmail = newEmail;
    });
    _showSnack('Email updated!', isError: false);
  }

  Future<void> _pickBirthday() async {
    if (_birthdayLocked) return;

    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthdayDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1950),
      // Users must be at least 15.
      lastDate: DateTime(now.year - 15, now.month, now.day),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: Glass.blueDeep),
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
                                    _buildEmailField(),
                                  ]),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isSaving ? null : _handleSave,
                                      style: Glass.primaryButtonStyle(),
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
            Text('Personal Details',
                style: Glass.heading(size: 16, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Column(
      children: [
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
            style: Glass.heading(
                size: 38, weight: FontWeight.w700, color: Colors.white),
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

  Widget _buildFieldCard(List<Widget> children) {
    return Glass.card(
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
              style: Glass.body(
                size: 10,
                weight: FontWeight.w700,
                color: Glass.textMuted,
              ).copyWith(letterSpacing: 0.5)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: Glass.body(size: 14),
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
              style: Glass.body(
                size: 10,
                weight: FontWeight.w700,
                color: Glass.textMuted,
              ).copyWith(letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                _birthdayDate != null ? '$_age years old' : '—',
                style: Glass.body(size: 14),
              ),
              if (_birthdayDate != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Glass.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Auto-calculated',
                      style: Glass.body(size: 10, color: Glass.blueDeep)),
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
      onTap: _birthdayLocked ? null : _pickBirthday,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5), width: 0.5))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BIRTHDAY',
                style: Glass.body(
                  size: 10,
                  weight: FontWeight.w700,
                  color: Glass.textMuted,
                ).copyWith(letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _birthdayController.text.isEmpty
                        ? 'Tap to select'
                        : _birthdayController.text,
                    style: Glass.body(
                      size: 14,
                      color: _birthdayController.text.isEmpty
                          ? Glass.textHint
                          : Glass.textDark,
                    ),
                  ),
                ),
                Icon(
                  _birthdayLocked ? Icons.lock_outline : Icons.calendar_today,
                  size: 15,
                  color: _birthdayLocked ? Glass.textMuted : Glass.blueDeep,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _birthdayLocked
                  ? "Your birthday can't be changed."
                  : "Once saved, your birthday can't be changed.",
              style: Glass.body(size: 11, color: Glass.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  // The email can only be changed through the dialog, which requires the
  // current password.
  Widget _buildEmailField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EMAIL ADDRESS',
              style: Glass.body(
                size: 10,
                weight: FontWeight.w700,
                color: Glass.textMuted,
              ).copyWith(letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  _emailController.text,
                  style: Glass.body(size: 14, color: Glass.textDark),
                ),
              ),
              GestureDetector(
                onTap: _showChangeEmailDialog,
                child: Text('Change email',
                    style: Glass.body(
                        size: 13,
                        weight: FontWeight.w600,
                        color: Glass.blueDeep)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "You'll need your current password to change your email.",
            style: Glass.body(size: 11, color: Glass.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Glass.card(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 44, color: Glass.textHint),
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Glass.body(size: 13, color: Glass.textMuted),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfile,
                style: Glass.primaryButtonStyle(),
                child: Text('Try Again', style: Glass.body(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChangeEmailDialog extends StatefulWidget {
  final String currentEmail;
  const _ChangeEmailDialog({required this.currentEmail});

  @override
  State<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<_ChangeEmailDialog> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!valid) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (email.toLowerCase() == widget.currentEmail.toLowerCase()) {
      setState(() => _error = 'That is already your email.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Enter your current password.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await ApiService.changeEmail(
      newEmail: email,
      currentPassword: password,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final user = result['user'] as Map<String, dynamic>?;
      Navigator.pop(context, (user?['email'] as String?) ?? email);
    } else {
      setState(() {
        _submitting = false;
        _error = result['message'] ?? 'Could not change email.';
      });
    }
  }

  InputDecoration _decoration(String hint, {Widget? suffix}) => InputDecoration(
        hintText: hint,
        hintStyle: Glass.body(size: 14, color: Glass.textHint),
        suffixIcon: suffix,
        isDense: true,
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('Change email',
          style: Glass.heading(size: 17, weight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              enabled: !_submitting,
              style: Glass.body(size: 14),
              decoration: _decoration('New email address'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              enabled: !_submitting,
              style: Glass.body(size: 14),
              onSubmitted: (_) => _submit(),
              decoration: _decoration(
                'Current password',
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: Glass.body(size: 12, color: Glass.pinkDeep)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text('Cancel', style: Glass.body(color: Glass.textMuted)),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: Glass.primaryButtonStyle(),
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Text('Update', style: Glass.body(color: Colors.white)),
        ),
      ],
    );
  }
}