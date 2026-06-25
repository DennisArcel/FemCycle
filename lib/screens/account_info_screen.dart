import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';

class AccountInfoScreen extends StatefulWidget {
  const AccountInfoScreen({super.key});

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  final _firstNameController = TextEditingController(text: 'Stacey');
  final _middleNameController = TextEditingController(text: 'Ann');
  final _lastNameController = TextEditingController(text: 'Miller');
  final _birthdayController = TextEditingController(text: 'January 15, 2000');
  final _emailController = TextEditingController(text: 'staceymiller@gmail.com');

  // Age is derived from birthday — updates when birthday changes
  DateTime _birthdayDate = DateTime(2000, 1, 15);

  int get _age {
    final today = DateTime.now();
    int age = today.year - _birthdayDate.year;
    if (today.month < _birthdayDate.month ||
        (today.month == _birthdayDate.month &&
            today.day < _birthdayDate.day)) {
      age--;
    }
    return age;
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

  void _handleSave() {
    // TODO: Connect to Laravel API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Account information updated!'),
        backgroundColor: const Color(0xFF84B2E9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 15),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF84B2E9),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      const months = ['January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'];
      setState(() {
        _birthdayDate = picked;
        _birthdayController.text =
            '${months[picked.month - 1]} ${picked.day}, ${picked.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = context.cardColor;
    final labelColor = context.textSecondary;
    final textColor = context.textPrimary;
    final bgColor = context.bgColor;

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
                  children: [
                    // Avatar
                    _buildAvatar(context.isDark),
                    const SizedBox(height: 20),

                    // Fields
                    _buildFieldCard(cardColor, [
                      _buildField('FIRST NAME', _firstNameController,
                          labelColor, textColor),
                      _buildField('MIDDLE NAME', _middleNameController,
                          labelColor, textColor),
                      _buildField('LAST NAME', _lastNameController,
                          labelColor, textColor),
                      _buildBirthdayField(labelColor, textColor),
                      _buildAgeField(labelColor, textColor),
                      _buildField('EMAIL ADDRESS', _emailController,
                          labelColor, textColor,
                          keyboardType: TextInputType.emailAddress),
                    ]),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF84B2E9),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Save Changes',
                            style: TextStyle(
                                fontFamily: 'Mallanna',
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
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
          const Text('Account Information',
              style: TextStyle(color: Colors.white, fontFamily: 'Mallanna',
                  fontSize: 17, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 85, height: 85,
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
                          size: 45, color: Color(0xFFBC6B9C)),
                    )),
              ),
            ),
            Positioned(
              bottom: 2, right: 2,
              child: GestureDetector(
                onTap: () {
                  // TODO: Pick image
                },
                child: Container(
                  width: 26, height: 26,
                  decoration: const BoxDecoration(
                      color: Color(0xFF7F77DD), shape: BoxShape.circle),
                  child: const Icon(Icons.edit, color: Colors.white, size: 13),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Stacey Miller',
            style: TextStyle(
                fontFamily: 'Mallanna', fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF2B2638))),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF84B2E9).withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('staceymiller@gmail.com',
              style: TextStyle(fontFamily: 'Mallanna', fontSize: 12,
                  color: Color(0xFF185FA5))),
        ),
      ],
    );
  }

  Widget _buildFieldCard(Color cardColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(children: children),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      Color labelColor, Color textColor,
      {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontFamily: 'Mallanna', fontSize: 10,
                  fontWeight: FontWeight.w700, color: labelColor,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(fontFamily: 'Archivo', fontSize: 14,
                color: textColor),
            decoration: const InputDecoration(
                border: InputBorder.none, isDense: true,
                contentPadding: EdgeInsets.zero),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeField(Color labelColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AGE',
              style: TextStyle(
                  fontFamily: 'Mallanna',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '$_age years old',
                style: TextStyle(
                    fontFamily: 'Archivo',
                    fontSize: 14,
                    color: textColor),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF84B2E9).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Auto-calculated',
                  style: TextStyle(
                    fontFamily: 'Mallanna',
                    fontSize: 10,
                    color: Color(0xFF84B2E9),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBirthdayField(Color labelColor, Color textColor) {
    return GestureDetector(
      onTap: _pickBirthday,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BIRTHDAY',
                style: TextStyle(fontFamily: 'Mallanna', fontSize: 10,
                    fontWeight: FontWeight.w700, color: labelColor,
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(_birthdayController.text,
                      style: TextStyle(fontFamily: 'Archivo', fontSize: 14,
                          color: textColor)),
                ),
                Icon(Icons.calendar_today,
                    size: 15, color: const Color(0xFF84B2E9)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}