import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens mirrored from the app's frosted-glass theme. Kept local
/// (rather than importing a screen's private `_Glass`) so this widget has
/// zero coupling to any one screen and can be dropped into all of them.
class CoachColors {
  static const Color purpleDeep = Color(0xFF9A78E0);
  static const Color pinkDeep = Color(0xFFE0679A);
  static const Color blueDeep = Color(0xFF5B93E0);
  static const Color textDark = Color(0xFF2B2638);
  static const Color textMuted = Color(0xFF6E677D);
}

/// One stop on a coach-mark tour: spotlights whatever widget is attached to
/// [targetKey] and shows [title] / [description] in a tooltip card next to it.
class CoachMarkStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final BorderRadius highlightRadius;
  final EdgeInsets highlightPadding;
  final bool isCircle;

  const CoachMarkStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.highlightRadius = const BorderRadius.all(Radius.circular(16)),
    this.highlightPadding = const EdgeInsets.all(6),
    this.isCircle = false,
  });
}

/// Runs a dismissible spotlight tour over [steps], one at a time: dimmed
/// backdrop, a cut-out highlight ring around the current target, and a
/// tooltip card with Skip / Next / Got it controls.
///
/// Automatically scrolls the target into view if it's inside a [Scrollable].
/// Resolves once the tour finishes or is skipped.
Future<void> showCoachMarkTour({
  required BuildContext context,
  required List<CoachMarkStep> steps,
}) async {
  if (steps.isEmpty) return;
  final completer = Completer<void>();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _CoachMarkTourView(
      steps: steps,
      onFinished: () {
        entry.remove();
        if (!completer.isCompleted) completer.complete();
      },
    ),
  );
  Overlay.of(context, rootOverlay: true).insert(entry);
  return completer.future;
}

class _CoachMarkTourView extends StatefulWidget {
  final List<CoachMarkStep> steps;
  final VoidCallback onFinished;
  const _CoachMarkTourView({required this.steps, required this.onFinished});

  @override
  State<_CoachMarkTourView> createState() => _CoachMarkTourViewState();
}

class _CoachMarkTourViewState extends State<_CoachMarkTourView>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  Rect? _targetRect;
  late final AnimationController _pulse;

  CoachMarkStep get _step => widget.steps[_index];
  bool get _isLast => _index == widget.steps.length - 1;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _measure() async {
    final ctx = _step.targetKey.currentContext;
    if (ctx != null) {
      // Bring the target into view first — it may be inside a scroll view.
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        alignment: 0.2,
      );
    }
    if (!mounted) return;
    // One more frame so the scroll settles before we measure position.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box =
          _step.targetKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) {
        setState(() => _targetRect = null);
        return;
      }
      final topLeft = box.localToGlobal(Offset.zero);
      setState(() => _targetRect = topLeft & box.size);
    });
  }

  void _next() {
    if (_isLast) {
      widget.onFinished();
      return;
    }
    setState(() {
      _index++;
      _targetRect = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _skip() => widget.onFinished();

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final rect = _targetRect;
    final padded = rect == null
        ? null
        : Rect.fromLTRB(
            rect.left - _step.highlightPadding.left,
            rect.top - _step.highlightPadding.top,
            rect.right + _step.highlightPadding.right,
            rect.bottom + _step.highlightPadding.bottom,
          );

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {}, // absorb taps outside the tooltip
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => CustomPaint(
                  painter: _SpotlightPainter(
                    rect: padded,
                    radius: _step.highlightRadius,
                    isCircle: _step.isCircle,
                    pulse: _pulse.value,
                  ),
                ),
              ),
            ),
          ),
          if (padded != null) _buildTooltip(context, screen, padded),
          if (padded == null)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: TextButton(
              onPressed: _skip,
              style: TextButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.35),
                foregroundColor: Colors.white,
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              ),
              child: Text(
                'Skip',
                style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTooltip(BuildContext context, Size screen, Rect target) {
    const cardWidth = 260.0;
    final spaceBelow = screen.height - target.bottom;
    final placeBelow = spaceBelow > 190;
    final left = (target.center.dx - cardWidth / 2)
        .clamp(16.0, screen.width - cardWidth - 16);

    final card = Container(
      width: cardWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _step.title,
            style: GoogleFonts.quicksand(
                fontSize: 15, fontWeight: FontWeight.w700, color: CoachColors.textDark),
          ),
          const SizedBox(height: 6),
          Text(
            _step.description,
            style: GoogleFonts.nunito(
                fontSize: 12.5, color: CoachColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(
                  widget.steps.length,
                  (i) => Container(
                    margin: const EdgeInsets.only(right: 4),
                    width: i == _index ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? CoachColors.pinkDeep
                          : CoachColors.pinkDeep.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CoachColors.blueDeep,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 0,
                ),
                child: Text(
                  _isLast ? 'Got it' : 'Next',
                  style: GoogleFonts.nunito(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return placeBelow
        ? Positioned(left: left, top: target.bottom + 16, child: card)
        : Positioned(left: left, bottom: screen.height - target.top + 16, child: card);
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? rect;
  final BorderRadius radius;
  final bool isCircle;
  final double pulse;

  _SpotlightPainter({
    required this.rect,
    required this.radius,
    required this.isCircle,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backdrop = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final dimPaint = Paint()..color = Colors.black.withOpacity(0.68);

    if (rect == null) {
      canvas.drawPath(backdrop, dimPaint);
      return;
    }

    final holePath = isCircle
        ? (Path()..addOval(rect!))
        : (Path()
          ..addRRect(RRect.fromRectAndCorners(
            rect!,
            topLeft: radius.topLeft,
            topRight: radius.topRight,
            bottomLeft: radius.bottomLeft,
            bottomRight: radius.bottomRight,
          )));

    canvas.drawPath(Path.combine(PathOperation.difference, backdrop, holePath), dimPaint);

    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final ringRect = rect!.inflate(2 + pulse * 3);

    if (isCircle) {
      canvas.drawOval(ringRect, ringPaint);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          ringRect,
          topLeft: radius.topLeft,
          topRight: radius.topRight,
          bottomLeft: radius.bottomLeft,
          bottomRight: radius.bottomRight,
        ),
        ringPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.rect != rect || oldDelegate.pulse != pulse;
}