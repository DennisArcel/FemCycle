import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SoftField extends StatelessWidget {
  final String hint;
  final bool obscure;

  const SoftField({
    super.key,
    required this.hint,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        obscureText: obscure,
        decoration: const InputDecoration(border: InputBorder.none),
      ),
    );
  }
}
