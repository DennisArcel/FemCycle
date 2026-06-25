import 'package:flutter/material.dart';
import 'diary_entry_screen.dart';
import '../theme/theme_provider.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  // Sample diary entries
  final List<Map<String, dynamic>> _entries = [
    {
      'id': 1,
      'day': 16,
      'weekday': 'Thu',
      'month': 'January 2026',
      'title': 'Feeling overwhelmed today',
      'preview': 'Had really bad cramps in the morning. Couldn\'t focus on anything. Took some pain relief and rested...',
      'mood': '😔 Sad',
      'moodColor': Color(0xFFBC6B9C),
      'moodBg': Color(0xFFF5EAF7),
      'accentColor': Color(0xFFE96A8F),
      'time': '9:32 AM',
      'body': 'Had really bad cramps in the morning. Couldn\'t focus on anything. Took some pain relief and rested for most of the day. Feeling a bit better now but still drained.',
    },
    {
      'id': 2,
      'day': 14,
      'weekday': 'Tue',
      'month': 'January 2026',
      'title': 'Good energy day!',
      'preview': 'Woke up feeling great. Went for a walk and felt so alive. My cycle seems to be ending soon...',
      'mood': '😊 Happy',
      'moodColor': Color(0xFF185FA5),
      'moodBg': Color(0xFFE4E8FE),
      'accentColor': Color(0xFF84B2E9),
      'time': '7:15 AM',
      'body': 'Woke up feeling great. Went for a walk and felt so alive. My cycle seems to be ending soon and I can already feel my energy coming back.',
    },
    {
      'id': 3,
      'day': 12,
      'weekday': 'Sun',
      'month': 'January 2026',
      'title': 'Mood swings again',
      'preview': 'Not sure why I felt so irritable today. Everything bothered me. Need to track this pattern...',
      'mood': '😤 Irritable',
      'moodColor': Color(0xFFBC6B9C),
      'moodBg': Color(0xFFF5EAF7),
      'accentColor': Color(0xFFBC6B9C),
      'time': '10:00 PM',
      'body': 'Not sure why I felt so irritable today. Everything bothered me. Need to track this pattern more carefully.',
    },
    {
      'id': 4,
      'day': 28,
      'weekday': 'Sun',
      'month': 'December 2025',
      'title': 'End of year reflection',
      'preview': 'Looking back at this year\'s cycle patterns. I\'ve learned so much about my body...',
      'mood': '🌸 Calm',
      'moodColor': Color(0xFF185FA5),
      'moodBg': Color(0xFFE4E8FE),
      'accentColor': Color(0xFF84B2E9),
      'time': '8:00 PM',
      'body': 'Looking back at this year\'s cycle patterns. I\'ve learned so much about my body and how to take care of myself.',
    },
  ];

  // Group entries by month
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
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _entries.insert(0, {
          ...result,
          'id': _entries.length + 1,
          'month': 'January 2026',
        });
      });
    }
  }

  void _openEntry(Map<String, dynamic> entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiaryEntryScreen(entry: entry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _entries.isEmpty
                      ? _buildEmptyState()
                      : _buildEntryList(),
                ),
              ],
            ),
            // Floating Action Button
            Positioned(
              bottom: 24,
              right: 20,
              child: GestureDetector(
                onTap: _openNewEntry,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE96A8F),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE4E8FE),
                      width: 3,
                    ),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 26),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: const Color(0xFF84B2E9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
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
          const Text(
            'My Diary',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Mallanna',
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildEntryList() {
    final grouped = _grouped;
    final months = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
      itemCount: months.length,
      itemBuilder: (context, i) {
        final month = months[i];
        final entries = grouped[month]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 4),
              child: Text(
                month.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Mallanna',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF888888),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...entries.map((e) => _buildEntryCard(e)),
            const SizedBox(height: 6),
          ],
        );
      },
    );
  }

  Widget _buildEntryCard(Map<String, dynamic> entry) {
    final accentColor = entry['accentColor'] as Color;
    return GestureDetector(
      onTap: () => _openEntry(entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: accentColor, width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date
              Column(
                children: [
                  Text(
                    '${entry['day']}',
                    style: TextStyle(
                      fontFamily: 'Mallanna',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      height: 1,
                    ),
                  ),
                  Text(
                    entry['weekday'] as String,
                    style: const TextStyle(
                      fontFamily: 'Mallanna',
                      fontSize: 10,
                      color: Color(0xFFAAAAAA),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry['title'] as String,
                      style: const TextStyle(
                        fontFamily: 'Mallanna',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry['preview'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Mallanna',
                        fontSize: 12,
                        color: Color(0xFF888888),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: entry['moodBg'] as Color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            entry['mood'] as String,
                            style: TextStyle(
                              fontFamily: 'Mallanna',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: entry['moodColor'] as Color,
                            ),
                          ),
                        ),
                        Text(
                          entry['time'] as String,
                          style: const TextStyle(
                            fontFamily: 'Mallanna',
                            fontSize: 10,
                            color: Color(0xFFBBBBBB),
                          ),
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
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📔', style: TextStyle(fontSize: 50)),
          SizedBox(height: 16),
          Text(
            'No entries yet',
            style: TextStyle(
              fontFamily: 'Mallanna',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF888888),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap + to write your first diary entry',
            style: TextStyle(
              fontFamily: 'Mallanna',
              fontSize: 13,
              color: Color(0xFFAAAAAA),
            ),
          ),
        ],
      ),
    );
  }
}