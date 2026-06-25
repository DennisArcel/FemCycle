import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SegmentedAuthSwitch extends StatelessWidget {
  final bool isRegister;
  final VoidCallback onRegister;
  final VoidCallback onLogin;

  const SegmentedAuthSwitch({
    super.key,
    required this.isRegister,
    required this.onRegister,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(.18),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _tab("Register", isRegister, onRegister),
          _tab("Log in", !isRegister, onLogin),
        ],
      ),
    );
  }

  Widget _tab(String text, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: active ? Colors.white : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
