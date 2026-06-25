import 'package:flutter/material.dart';
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
        content: const Text(
          'Could not open the link. Check your internet connection.',
          style: TextStyle(fontFamily: 'Mallanna', fontSize: 13),
        ),
        backgroundColor: const Color(0xFFE96A8F),
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
      backgroundColor: const Color(0xFFFBF7F1),
      body: SafeArea(
        child: Stack(
          children: [

            // ── Scrollable content ─────────────────────────────────────
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Space for the sticky top bar
                  const SizedBox(height: 54),

                  // ── Hero banner ────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    height: 220,
                    color: c.surface,
                    alignment: Alignment.center,
                    child: Text(
                      article.emoji,
                      style: const TextStyle(fontSize: 90),
                    ),
                  ),

                  // ── White article card ─────────────────────────────────
                  Transform.translate(
                    offset: const Offset(0, -24),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Category pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: c.surface,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              article.tag.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Mallanna',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: c.deep,
                                letterSpacing: .5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Title
                          Text(
                            article.title,
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Byline
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: const BoxDecoration(
                              border: Border.symmetric(
                                horizontal: BorderSide(
                                    color: Color(0xFFF0EDE8), width: .5),
                              ),
                            ),
                            child: Row(children: [
                              CircleAvatar(
                                radius: 17,
                                backgroundColor: c.accent,
                                child: const Text('FC',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ),
                              const SizedBox(width: 10),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('FemCycle Health',
                                      style: TextStyle(
                                          fontFamily: 'Mallanna',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF333333))),
                                  Text('Editorial team',
                                      style: TextStyle(
                                          fontFamily: 'Mallanna',
                                          fontSize: 11,
                                          color: Color(0xFFABABAB))),
                                ],
                              ),
                              const Spacer(),
                              Row(children: [
                                const Icon(Icons.access_time_rounded,
                                    size: 12, color: Color(0xFFABABAB)),
                                const SizedBox(width: 4),
                                Text(article.readTime,
                                    style: const TextStyle(
                                        fontFamily: 'Mallanna',
                                        fontSize: 11,
                                        color: Color(0xFFABABAB))),
                              ]),
                            ]),
                          ),
                          const SizedBox(height: 16),

                          // Intro — italic serif
                          Text(
                            article.intro,
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3A3A3A),
                              height: 1.75,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Pull quote
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: c.surface,
                              border: Border(
                                  left: BorderSide(color: c.accent, width: 3)),
                            ),
                            child: Text(
                              article.pullQuote,
                              style: TextStyle(
                                fontFamily: 'Georgia',
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
                                  const Divider(
                                      height: 32,
                                      thickness: .5,
                                      color: Color(0xFFF0EDE8))
                                else
                                  const SizedBox(height: 20),
                                Text(s.heading,
                                    style: const TextStyle(
                                        fontFamily: 'Mallanna',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1A1A1A))),
                                const SizedBox(height: 8),
                                Text(s.body,
                                    style: const TextStyle(
                                        fontFamily: 'Mallanna',
                                        fontSize: 13.5,
                                        color: Color(0xFF4A4A4A),
                                        height: 1.78)),
                              ],
                            );
                          }),

                          const SizedBox(height: 20),

                          // Callout box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: calloutColor.surface,
                              border: Border(
                                left: BorderSide(
                                    color: calloutColor.accent, width: 3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  article.callout.label.toUpperCase(),
                                  style: TextStyle(
                                      fontFamily: 'Mallanna',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: calloutColor.deep,
                                      letterSpacing: .6),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  article.callout.text,
                                  style: TextStyle(
                                      fontFamily: 'Mallanna',
                                      fontSize: 13,
                                      color: calloutColor.deep,
                                      height: 1.6),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Related topics
                          const Text('RELATED TOPICS',
                              style: TextStyle(
                                  fontFamily: 'Mallanna',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFABABAB),
                                  letterSpacing: .6)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: article.pills
                                .map((p) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 13, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: c.surface,
                                        borderRadius:
                                            BorderRadius.circular(30),
                                      ),
                                      child: Text(p,
                                          style: TextStyle(
                                              fontFamily: 'Mallanna',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: c.deep)),
                                    ))
                                .toList(),
                          ),

                          const SizedBox(height: 24),
                          const Divider(
                              height: 1,
                              thickness: .5,
                              color: Color(0xFFF0EDE8)),
                          const SizedBox(height: 20),

                          // ── Source section ─────────────────────────────
                          Row(children: [
                            Icon(Icons.verified_outlined,
                                size: 14, color: c.accent),
                            const SizedBox(width: 6),
                            Text('Source: ${article.sourceName}',
                                style: TextStyle(
                                    fontFamily: 'Mallanna',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: c.deep)),
                          ]),
                          const SizedBox(height: 6),
                          Text(
                            'This article draws from peer-reviewed research and '
                            'trusted health publications. Tap the button below '
                            'to read the full article on ${article.sourceName}.',
                            style: TextStyle(
                                fontFamily: 'Mallanna',
                                fontSize: 11,
                                color: c.deep.withOpacity(0.6),
                                height: 1.5),
                          ),
                          const SizedBox(height: 14),

                          // ── PRIMARY CTA — opens browser ────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () => _openUrl(context),
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Read full article on ${article.sourceName}',
                                style: const TextStyle(
                                  fontFamily: 'Mallanna',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: c.accent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: c.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(children: [
                                Icon(Icons.link_rounded,
                                    size: 16, color: c.accent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    article.sourceUrl
                                        .replaceFirst('https://', '')
                                        .replaceFirst('www.', ''),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Mallanna',
                                      fontSize: 12,
                                      color: c.accent,
                                      decoration: TextDecoration.underline,
                                      decorationColor: c.accent,
                                    ),
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    size: 11, color: c.accent),
                              ]),
                            ),
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Sticky top bar ─────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: const Color(0xFF84B2E9),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      article.tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Mallanna',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
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
                        color: Colors.white.withOpacity(0.22),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.open_in_new_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ]),
              ),
            ),

          ],
        ),
      ),
    );
  }
}