import 'package:flutter/material.dart';
import 'diary_entry_screen.dart';
import '../theme/theme_provider.dart';
import '../services/api_service.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const List<String> _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];
  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  // Mood label -> color mapping (kept client-side; DB only stores the label)
  static const Map<String, Map<String, Color>> _moodStyles = {
    '😊 Happy': {'color': Color(0xFF185FA5), 'bg': Color(0xFFE4E8FE)},
    '😔 Sad': {'color': Color(0xFFBC6B9C), 'bg': Color(0xFFF5EAF7)},
    '😤 Irritable': {'color': Color(0xFFBC6B9C), 'bg': Color(0xFFF5EAF7)},
    '🌸 Calm': {'color': Color(0xFF185FA5), 'bg': Color(0xFFE4E8FE)},
    '😢 Cry': {'color': Color(0xFFE96A8F), 'bg': Color(0xFFFBEAF0)},
    '⚡ Energetic': {'color': Color(0xFF84B2E9), 'bg': Color(0xFFE4E8FE)},
  };

  @override
  void initState() {
    super.initState();
    _loadEntries();
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
    final moodLabel = raw['mood'] as String? ?? '🌸 Calm';
    final style = _moodStyles[moodLabel] ??
        {'color': const Color(0xFF185FA5), 'bg': const Color(0xFFE4E8FE)};
    final body = raw['body'] as String? ?? '';

    return {
      'id': raw['id'],
      'day': createdAt.day,
      'weekday': _weekdays[createdAt.weekday - 1],
      'month': '${_months[createdAt.month - 1]} ${createdAt.year}',
      'title': raw['title'] as String? ?? '',
      'preview': body.length > 80 ? '${body.substring(0, 80)}...' : body,
      'body': body,
      'mood': moodLabel,
      'moodColor': style['color'],
      'moodBg': style['bg'],
      'accentColor': const Color(0xFF84B2E9),
      'time': _formatTime(createdAt),
    };
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
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF84B2E9),
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

    return RefreshIndicator(
      color: const Color(0xFF84B2E9),
      onRefresh: _loadEntries,
      child: ListView.builder(
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
      ),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📔', style: TextStyle(fontSize: 50)),
          const SizedBox(height: 16),
          const Text(
            'No entries yet',
            style: TextStyle(
              fontFamily: 'Mallanna',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 44, color: Color(0xFFAAAAAA)),
            const SizedBox(height: 14),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Mallanna',
                fontSize: 13,
                color: Color(0xFF888888),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEntries,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF84B2E9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text('Try Again',
                  style: TextStyle(fontFamily: 'Mallanna')),
            ),
          ],
        ),
      ),
    );
  }
}