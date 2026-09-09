import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'educational_screen.dart';

class ArticleDetailScreen extends StatelessWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  // ── Launch the real URL in the device browser ────────────────────────────
  Future<void> _openUrl(BuildContext context) async {
    final uri = Uri.parse(article.sourceUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // opens in Chrome/Safari
      );
      if (!launched && context.mounted) {
        _showError(context);
      }
    } catch (_) {
      if (context.mounted) _showError(context);
    }
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not open the link. Check your internet connection.',
          style: _Glass.body(size: 13, color: Colors.white),
        ),
        backgroundColor: _Glass.pinkDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = colorOf(article.colorKey);
    final calloutColor = colorOf(article.callout.colorKey);

    return Scaffold(
      backgroundColor: _Glass.pageBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientBackground()),
          SafeArea(
            child: Stack(
              children: [
                // ── Scrollable content ─────────────────────────────────────
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Space for the sticky top bar (was 68 when the hero
                      // banner sat directly under it; bumped up slightly now
                      // that the card starts here instead).
                      const SizedBox(height: 84),

                      // ── Frosted article card ────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: _Glass.card(
                          radius: 22,
                          padding: const EdgeInsets.all(20),
                          opacity: 0.65,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              // Category pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: c.surface,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  article.tag.toUpperCase(),
                                  style: _Glass.body(
                                    size: 10,
                                    weight: FontWeight.w700,
                                    color: c.deep,
                                  ).copyWith(letterSpacing: .5),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Title
                              Text(
                                article.title,
                                style: _Glass.heading(
                                  size: 24,
                                  weight: FontWeight.w800,
                                  color: _Glass.textDark,
                                ).copyWith(height: 1.2),
                              ),
                              const SizedBox(height: 12),

                              // Byline
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.symmetric(
                                    horizontal: BorderSide(color: Colors.white.withOpacity(0.6), width: .5),
                                  ),
                                ),
                                child: Row(children: [
                                  CircleAvatar(
                                    radius: 17,
                                    backgroundColor: c.accent,
                                    child: const Text('FC',
                                        style: TextStyle(
                                            fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('FemCycle Health',
                                          style: _Glass.body(size: 13, weight: FontWeight.w600)),
                                      Text('Editorial team',
                                          style: _Glass.body(size: 11, color: _Glass.textHint)),
                                    ],
                                  ),
                                  const Spacer(),
                                  Row(children: [
                                    Icon(Icons.access_time_rounded, size: 12, color: _Glass.textHint),
                                    const SizedBox(width: 4),
                                    Text(article.readTime,
                                        style: _Glass.body(size: 11, color: _Glass.textHint)),
                                  ]),
                                ]),
                              ),
                              const SizedBox(height: 16),

                              // Intro — italic serif kept for editorial feel
                              Text(
                                article.intro,
                                style: GoogleFonts.quicksand(
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                  color: _Glass.textDark,
                                  height: 1.75,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Pull quote
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: c.surface.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border(left: BorderSide(color: c.accent, width: 3)),
                                ),
                                child: Text(
                                  article.pullQuote,
                                  style: GoogleFonts.quicksand(
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic,
                                    color: c.deep,
                                    height: 1.65,
                                  ),
                                ),
                              ),

                              // Sections
                              ...article.sections.asMap().entries.map((entry) {
                                final i = entry.key;
                                final s = entry.value;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (i > 0)
                                      Divider(height: 32, thickness: .5, color: Colors.white.withOpacity(0.6))
                                    else
                                      const SizedBox(height: 20),
                                    Text(s.heading,
                                        style: _Glass.body(size: 15, weight: FontWeight.w700)),
                                    const SizedBox(height: 8),
                                    Text(s.body,
                                        style: _Glass.body(
                                          size: 13.5,
                                          color: _Glass.textMuted,
                                        ).copyWith(height: 1.78)),
                                  ],
                                );
                              }),

                              const SizedBox(height: 20),

                              // Callout box
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: calloutColor.surface.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border(left: BorderSide(color: calloutColor.accent, width: 3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      article.callout.label.toUpperCase(),
                                      style: _Glass.body(
                                        size: 10,
                                        weight: FontWeight.w700,
                                        color: calloutColor.deep,
                                      ).copyWith(letterSpacing: .6),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      article.callout.text,
                                      style: _Glass.body(
                                        size: 13,
                                        color: calloutColor.deep,
                                      ).copyWith(height: 1.6),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Related topics
                              Text('RELATED TOPICS',
                                  style: _Glass.body(
                                    size: 11,
                                    weight: FontWeight.w700,
                                    color: _Glass.textHint,
                                  ).copyWith(letterSpacing: .6)),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: article.pills
                                    .map((p) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: c.surface,
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          child: Text(p,
                                              style: _Glass.body(
                                                  size: 11, weight: FontWeight.w500, color: c.deep)),
                                        ))
                                    .toList(),
                              ),

                              const SizedBox(height: 24),
                              Divider(height: 1, thickness: .5, color: Colors.white.withOpacity(0.6)),
                              const SizedBox(height: 20),

                              // ── Source section ─────────────────────────────
                              Row(children: [
                                Icon(Icons.verified_outlined, size: 14, color: c.accent),
                                const SizedBox(width: 6),
                                Text('Source: ${article.sourceName}',
                                    style: _Glass.body(size: 12, weight: FontWeight.w700, color: c.deep)),
                              ]),
                              const SizedBox(height: 6),
                              Text(
                                'This article draws from peer-reviewed research and '
                                'trusted health publications. Tap the button below '
                                'to read the full article on ${article.sourceName}.',
                                style: _Glass.body(
                                  size: 11,
                                  color: c.deep.withOpacity(0.7),
                                ).copyWith(height: 1.5),
                              ),
                              const SizedBox(height: 14),

                              // ── PRIMARY CTA — opens browser ────────────────
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: () => _openUrl(context),
                                  icon: const Icon(Icons.open_in_new_rounded, size: 18, color: Colors.white),
                                  label: Text(
                                    'Read full article on ${article.sourceName}',
                                    style: _Glass.body(size: 14, weight: FontWeight.w600, color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: c.accent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // ── URL display — also tappable ────────────────
                              GestureDetector(
                                onTap: () => _openUrl(context),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: c.surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(children: [
                                    Icon(Icons.link_rounded, size: 16, color: c.accent),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        article.sourceUrl.replaceFirst('https://', '').replaceFirst('www.', ''),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: _Glass.body(size: 12, color: c.accent)
                                            .copyWith(decoration: TextDecoration.underline, decorationColor: c.accent),
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios_rounded, size: 11, color: c.accent),
                                  ]),
                                ),
                              ),

                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),

                // ── Sticky top bar ─────────────────────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                    child: _Glass.card(
                      radius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
                            child: Icon(Icons.chevron_left, color: _Glass.textDark, size: 20),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            article.tag,
                            style: _Glass.heading(size: 15, weight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Tap to open in browser — icon shortcut in the top bar
                        GestureDetector(
                          onTap: () => _openUrl(context),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
                            child: Icon(Icons.open_in_new_rounded, color: _Glass.blueDeep, size: 15),
                          ),
                        ),
                      ]),
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
}

// ─── Glass design tokens ───────────────────────────────────────────────────────
// Shared frosted-glass / ambient-blob design system reused across every
// screen (Home, Mood, Diary, Learn, Lifestyle, Profile, and the auth flow).

class _Glass {
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

  static TextStyle heading({
    double size = 22,
    FontWeight weight = FontWeight.w700,
    Color color = textDark,
  }) =>
      GoogleFonts.quicksand(fontSize: size, fontWeight: weight, color: color);

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = textDark,
  }) =>
      GoogleFonts.nunito(fontSize: size, fontWeight: weight, color: color);

  /// Frosted translucent card: blurred backdrop + soft white glass fill.
  static Widget card({
    required Widget child,
    double radius = 24,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double opacity = 0.55,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: purpleDeep.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Three soft, blurred color blobs (blue / pink / purple) that gently drift
/// behind the frosted glass content. Purely decorative — no state that
/// affects the rest of the screen.
class _AmbientBackground extends StatefulWidget {
  const _AmbientBackground();

  @override
  State<_AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<_AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 * math.pi;
        return Stack(
          children: [
            Container(color: _Glass.pageBackground),
            Positioned(
              top: -60 + 24 * math.sin(t),
              left: -70 + 20 * math.cos(t),
              child: _blob(size.width * 0.7, _Glass.blue.withOpacity(0.55)),
            ),
            Positioned(
              top: size.height * 0.35 + 26 * math.cos(t * 0.85),
              right: -90 + 22 * math.sin(t * 0.85),
              child: _blob(size.width * 0.75, _Glass.pink.withOpacity(0.5)),
            ),
            Positioned(
              bottom: -80 + 20 * math.sin(t * 1.15),
              left: size.width * 0.15 + 18 * math.cos(t * 1.15),
              child: _blob(size.width * 0.65, _Glass.purple.withOpacity(0.5)),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(double diameter, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}