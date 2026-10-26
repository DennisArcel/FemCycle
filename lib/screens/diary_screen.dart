import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'diary_entry_screen.dart';
import '../theme/theme_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/coach_mark_overlay.dart';
import '../services/tutorial_storage_service.dart';
import '../widgets/glass.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;
  String? _errorMessage;

  // ── Coach-mark tour targets ──
  final GlobalKey _topBarKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey();

  static const List<String> _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];
  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  // Mood label -> color mapping (kept client-side; DB only stores the
  // label(s)). Keys stay exactly as the backend sends/expects them (still
  // emoji-prefixed in the stored value, e.g. '😊 Happy') for backward
  // compatibility with already-logged entries and diary_entry_screen.dart's
  // stored mood value.
  // Only the DISPLAY strips the emoji — see _cleanMoodLabel().
  static const Map<String, Map<String, Color>> _moodStyles = {
    '😊 Happy': {'color': Color(0xFF185FA5), 'bg': Color(0xFFE4E8FE)},
    '😔 Sad': {'color': Color(0xFFBC6B9C), 'bg': Color(0xFFF5EAF7)},
    '😤 Irritable': {'color': Color(0xFFBC6B9C), 'bg': Color(0xFFF5EAF7)},
    '🌸 Calm': {'color': Color(0xFF185FA5), 'bg': Color(0xFFE4E8FE)},
    '😢 Cry': {'color': Color(0xFFE96A8F), 'bg': Color(0xFFFBEAF0)},
    '⚡ Energetic': {'color': Color(0xFF84B2E9), 'bg': Color(0xFFE4E8FE)},
  };

  // Style used for custom "Others" moods that aren't one of the fixed
  // labels above — must match _othersColor / _othersBg in
  // diary_entry_screen.dart.
  static const Color _customMoodColor = Color(0xFF9A78E0);
  static const Color _customMoodBg = Color(0xFFF3E8FA);

  // Strips a leading emoji + space for display — only ever applied to a
  // KNOWN mood label (see _parseMoodChips), never to free-typed custom
  // text, so a custom mood like "feeling great" never gets mangled into
  // "great".
  static String _cleanMoodLabel(String raw) =>
      raw.replaceFirst(RegExp(r'^\S+\s+'), '');

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _maybeShowCoachTour();
  }

  Future<void> _maybeShowCoachTour() async {
    final seen = await TutorialStorageService.hasSeenTour(TutorialStorageService.diary);
    if (seen || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCoachTour());
  }

  void _startCoachTour() {
    showCoachMarkTour(
      context: context,
      steps: [
        CoachMarkStep(
          targetKey: _topBarKey,
          title: 'Your diary',
          description: 'Every entry you write gets grouped by month here, so you can look back on how you felt over time.',
        ),
        CoachMarkStep(
          targetKey: _fabKey,
          title: 'Write a new entry',
          description: 'Tap here anytime to jot down how today felt — mood, symptoms, or anything on your mind.',
          isCircle: true,
        ),
      ],
    ).then((_) => TutorialStorageService.markTourSeen(TutorialStorageService.diary));
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.getDiaryEntries();

    if (!mounted) return;

    if (result['success'] == true) {
      final rawEntries = result['data'] as List<dynamic>;
      setState(() {
        _entries = rawEntries
            .map((e) => _mapApiEntry(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Could not load your diary.';
        _isLoading = false;
      });
    }
  }

  // Converts a raw Laravel diary_entries row into the shape the UI expects
  Map<String, dynamic> _mapApiEntry(Map<String, dynamic> raw) {
    final createdAt = DateTime.parse(raw['created_at']);
    final moodField = raw['mood'] as String?;
    final body = raw['body'] as String? ?? '';

    return {
      'id': raw['id'],
      // Raw ISO timestamp, kept as-is so DiaryEntryScreen can preselect the
      // real date when the user edits an entry (the fields below are for
      // display/grouping only and lose precision).
      'date': raw['created_at'],
      'day': createdAt.day,
      'weekday': _weekdays[createdAt.weekday - 1],
      'month': '${_months[createdAt.month - 1]} ${createdAt.year}',
      'title': raw['title'] as String? ?? '',
      'preview': body.length > 80 ? '${body.substring(0, 80)}...' : body,
      'body': body,
      'mood': moodField,
      // One or more chips to render — an entry can now have multiple moods
      // plus a free-typed "Others" mood, comma-separated in `moodField`.
      'moodChips': _parseMoodChips(moodField),
      'accentColor': Glass.blueDeep,
      'time': _formatTime(createdAt),
    };
  }

  List<Map<String, dynamic>> _parseMoodChips(String? moodField) {
    if (moodField == null || moodField.trim().isEmpty) {
      const fallback = '🌸 Calm';
      final style = _moodStyles[fallback]!;
      return [
        {
          'label': _cleanMoodLabel(fallback),
          'color': style['color'],
          'bg': style['bg'],
        }
      ];
    }

    final tokens = moodField
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty);

    return tokens.map((token) {
      final style = _moodStyles[token];
      if (style != null) {
        return {
          'label': _cleanMoodLabel(token),
          'color': style['color'],
          'bg': style['bg'],
        };
      }
      // Unrecognized token = a custom "Others" mood the user typed in.
      return {
        'label': token,
        'color': _customMoodColor,
        'bg': _customMoodBg,
      };
    }).toList();
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $period';
  }

  Map<String, List<Map<String, dynamic>>> get _grouped {
    final Map<String, List<Map<String, dynamic>>> map = {};
    for (final e in _entries) {
      final month = e['month'] as String;
      map.putIfAbsent(month, () => []).add(e);
    }
    return map;
  }

  void _openNewEntry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DiaryEntryScreen()),
    );
    if (result != null) {
      _loadEntries();
    }
  }

  void _openEntry(Map<String, dynamic> entry) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiaryEntryScreen(entry: entry),
      ),
    );
    if (result != null) {
      _loadEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Glass.pageBackground,
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBackground()),
          SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: Glass.blueDeep,
                              ),
                            )
                          : _errorMessage != null
                              ? _buildErrorState()
                              : _entries.isEmpty
                                  ? _buildEmptyState()
                                  : _buildEntryList(),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 24,
                  right: 20,
                  child: GestureDetector(
                    key: _fabKey,
                    onTap: _openNewEntry,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Glass.pinkDeep, Glass.purpleDeep],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.7),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Glass.pinkDeep.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 28),
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: KeyedSubtree(
        key: _topBarKey,
        child: Glass.card(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Text(
              'My Diary',
              style: Glass.heading(size: 18, weight: FontWeight.w600),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _startCoachTour,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Glass.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.question_mark_rounded, size: 15, color: Glass.blueDeep),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildEntryList() {
    final grouped = _grouped;
    final months = grouped.keys.toList();

    return RefreshIndicator(
      color: Glass.blueDeep,
      onRefresh: _loadEntries,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
        itemCount: months.length,
        itemBuilder: (context, i) {
          final month = months[i];
          final entries = grouped[month]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 4, left: 4),
                child: Text(
                  month.toUpperCase(),
                  style: Glass.body(
                    size: 11,
                    weight: FontWeight.w700,
                    color: Glass.textMuted,
                  ).copyWith(letterSpacing: 1.2),
                ),
              ),
              ...entries.map((e) => _buildEntryCard(e)),
              const SizedBox(height: 6),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEntryCard(Map<String, dynamic> entry) {
    final accentColor = entry['accentColor'] as Color;
    final moodChips = entry['moodChips'] as List<Map<String, dynamic>>;
    return GestureDetector(
      onTap: () => _openEntry(entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Glass.card(
          radius: 18,
          padding: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: accentColor, width: 4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Text(
                        '${entry['day']}',
                        style: Glass.heading(
                          size: 22,
                          weight: FontWeight.w700,
                          color: accentColor,
                        ).copyWith(height: 1),
                      ),
                      Text(
                        entry['weekday'] as String,
                        style: Glass.body(size: 10, color: Glass.textHint),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry['title'] as String,
                          style: Glass.body(size: 14, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry['preview'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Glass.body(
                            size: 12,
                            color: Glass.textMuted,
                          ).copyWith(height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  for (final chip in moodChips)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: chip['bg'] as Color,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                                color: chip['color'] as Color,
                                                shape: BoxShape.circle),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            chip['label'] as String,
                                            style: Glass.body(
                                              size: 10,
                                              weight: FontWeight.w600,
                                              color: chip['color'] as Color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              entry['time'] as String,
                              style: Glass.body(size: 10, color: Glass.textHint),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Glass.card(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_outlined,
                  size: 46, color: Glass.textMuted.withOpacity(0.6)),
              const SizedBox(height: 16),
              Text(
                'No entries yet',
                style: Glass.heading(size: 17, weight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap + to write your first diary entry',
                textAlign: TextAlign.center,
                style: Glass.body(size: 13, color: Glass.textMuted),
              ),
            ],
          ),
        ),
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
                onPressed: _loadEntries,
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
