import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BubbleBackground extends StatelessWidget {
  final Widget child;
  const BubbleBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          _bubble(-40, -30, 140),
          _bubble(40, null, 170, right: -35),
          _bubble(null, -35, 120, bottom: 120),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(double? top, double? left, double size,
      {double? right, double? bottom}) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(.35),
              AppColors.primaryDark.withOpacity(.35),
            ],
          ),
        ),
      ),
    );
  }
}
