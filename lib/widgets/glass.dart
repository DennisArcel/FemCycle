import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared frosted-glass design tokens for every FemCycle screen.
///
/// This replaces the private `_Glass` copy that used to live in each screen.
///
/// PERFORMANCE NOTES
/// * [useBlur] is the master switch for real `BackdropFilter` blur. It is OFF
///   by default: a live blur re-runs on the GPU every frame it is on screen,
///   which is what made the release APK feel laggy on mid-range phones. With
///   it off, cards use a slightly more opaque white fill instead, which looks
///   almost identical over the soft pastel background.
/// * Text styles are cached per font weight so `GoogleFonts.xxx()` is not
///   re-resolved on every rebuild.
class Glass {
  Glass._();

  /// Flip to true to bring back real backdrop blur (costly on low-end GPUs).
  static bool useBlur = false;

  // ── Colors ────────────────────────────────────────────────────────────────
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

  // ── Text styles (cached per weight) ───────────────────────────────────────
  static final Map<FontWeight, TextStyle> _quicksandBase = {};
  static final Map<FontWeight, TextStyle> _nunitoBase = {};

  static TextStyle heading({
    double size = 22,
    FontWeight weight = FontWeight.w700,
    Color color = textDark,
  }) =>
      _quicksandBase
          .putIfAbsent(weight, () => GoogleFonts.quicksand(fontWeight: weight))
          .copyWith(fontSize: size, color: color);

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = textDark,
  }) =>
      _nunitoBase
          .putIfAbsent(weight, () => GoogleFonts.nunito(fontWeight: weight))
          .copyWith(fontSize: size, color: color);

  // ── Card ──────────────────────────────────────────────────────────────────
  /// Translucent glass card. Real blur only when [useBlur] is true.
  static Widget card({
    required Widget child,
    Key? key,
    double radius = 24,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double opacity = 0.55,
  }) {
    // No blur behind the card -> a touch more white so text stays readable.
    final fill = useBlur ? opacity : (opacity + 0.14).clamp(0.0, 0.92);

    final box = Container(
      key: useBlur ? null : key,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(fill),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: purpleDeep.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );

    if (!useBlur) return box;

    return ClipRRect(
      key: key,
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: box,
      ),
    );
  }

  /// A circular frosted-glass avatar/logo frame.
  static Widget frostedCircle({
    required double size,
    required Widget child,
    Color? borderColor,
    double borderWidth = 2,
  }) {
    return GlassBlur(
      sigma: 12,
      clipOval: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.5),
          border: Border.all(
            color: borderColor ?? blueDeep.withOpacity(0.6),
            width: borderWidth,
          ),
        ),
        child: ClipOval(child: child),
      ),
    );
  }

  static InputDecoration fieldDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: body(size: 14, color: textHint),
      filled: true,
      fillColor: Colors.white.withOpacity(0.55),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: blueDeep.withOpacity(0.7), width: 1.4),
      ),
      suffixIcon: suffixIcon,
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

/// Drop-in replacement for `BackdropFilter(filter: ImageFilter.blur(...))`.
/// Blurs only when [Glass.useBlur] is true; otherwise just returns [child].
class GlassBlur extends StatelessWidget {
  final double sigma;
  final bool clipOval;
  final Widget child;

  const GlassBlur({
    super.key,
    this.sigma = 20,
    this.clipOval = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!Glass.useBlur) return child;
    final blurred = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: child,
    );
    return clipOval ? ClipOval(child: blurred) : blurred;
  }
}

/// Soft blue / pink / purple color blobs behind the glass content.
///
/// Drawn with a single CustomPainter using radial gradients (no blur filters)
/// inside a RepaintBoundary, so it costs almost nothing and never forces the
/// content on top to repaint. It is static by default; pass `animated: true`
/// for a slow drift (still cheap, but keeps the GPU busy every frame).
class AmbientBackground extends StatefulWidget {
  final bool animated;
  const AmbientBackground({super.key, this.animated = false});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.animated) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 30),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _AmbientPainter(_controller),
        size: Size.infinite,
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  final Animation<double>? anim;
  _AmbientPainter(this.anim) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    final t = (anim?.value ?? 0.0) * 2 * math.pi;

    // Base fill + soft top-to-bottom tint.
    canvas.drawRect(rect, Paint()..color = Glass.pageBackground);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Glass.pageBackground,
            Glass.blue.withOpacity(0.10),
            Glass.purple.withOpacity(0.22),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(rect),
    );

    // Blue blob (top-left)
    final d1 = w * 0.7;
    _blob(
      canvas,
      Offset(-70 + 20 * math.cos(t) + d1 / 2, -60 + 24 * math.sin(t) + d1 / 2),
      d1,
      Glass.blue,
      0.55,
    );

    // Pink blob (right, mid-screen)
    final d2 = w * 0.75;
    _blob(
      canvas,
      Offset(w - (-90 + 22 * math.sin(t * 0.85)) - d2 / 2,
          h * 0.35 + 26 * math.cos(t * 0.85) + d2 / 2),
      d2,
      Glass.pink,
      0.5,
    );

    // Purple blob (bottom)
    final d3 = w * 0.95;
    _blob(
      canvas,
      Offset(w * 0.05 + 18 * math.cos(t * 1.15) + d3 / 2,
          h - (-40 + 20 * math.sin(t * 1.15)) - d3 / 2),
      d3,
      Glass.purple,
      0.55,
    );
  }

  void _blob(Canvas canvas, Offset center, double diameter, Color color,
      double peak) {
    // Radius a bit larger than the old circle so the gradient's soft edge
    // covers the area the 60px blur used to spread over.
    final radius = diameter * 0.5 * 1.35;
    final shader = RadialGradient(
      colors: [
        color.withOpacity(peak),
        color.withOpacity(peak * 0.5),
        color.withOpacity(0),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter old) => old.anim != anim;
}