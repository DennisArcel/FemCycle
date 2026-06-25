import 'package:flutter/material.dart';

class DiaryEntryScreen extends StatefulWidget {
  final Map<String, dynamic>? entry;

  const DiaryEntryScreen({super.key, this.entry});

  @override
  State<DiaryEntryScreen> createState() => _DiaryEntryScreenState();
}

class _DiaryEntryScreenState extends State<DiaryEntryScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  int _selectedMood = -1;
  bool _isEditing = false;

  final List<Map<String, dynamic>> _moods = [
    {'label': '😊 Happy', 'color': const Color(0xFF185FA5), 'bg': const Color(0xFFE4E8FE)},
    {'label': '😔 Sad', 'color': const Color(0xFFBC6B9C), 'bg': const Color(0xFFF5EAF7)},
    {'label': '😤 Irritable', 'color': const Color(0xFFBC6B9C), 'bg': const Color(0xFFF5EAF7)},
    {'label': '🌸 Calm', 'color': const Color(0xFF185FA5), 'bg': const Color(0xFFE4E8FE)},
    {'label': '😢 Cry', 'color': const Color(0xFFE96A8F), 'bg': const Color(0xFFFBEAF0)},
    {'label': '⚡ Energetic', 'color': const Color(0xFF84B2E9), 'bg': const Color(0xFFE4E8FE)},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _titleController.text = widget.entry!['title'] ?? '';
      _bodyController.text = widget.entry!['body'] ?? '';
      final moodLabel = widget.entry!['mood'] as String?;
      if (moodLabel != null) {
        _selectedMood = _moods.indexWhere((m) => m['label'] == moodLabel);
      }
      _isEditing = false;
    } else {
      _isEditing = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  String get _formattedDate {
    final now = DateTime.now();
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  String get _timeNow {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : now.hour == 0 ? 12 : now.hour;
    final min = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $period';
  }

  void _handleSave() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add a title to your entry.'),
          backgroundColor: const Color(0xFFE96A8F),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final mood = _selectedMood >= 0 ? _moods[_selectedMood] : null;
    final now = DateTime.now();
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    Navigator.pop(context, {
      'day': now.day,
      'weekday': weekdays[now.weekday - 1],
      'title': _titleController.text.trim(),
      'preview': _bodyController.text.trim().length > 80
          ? '${_bodyController.text.trim().substring(0, 80)}...'
          : _bodyController.text.trim(),
      'body': _bodyController.text.trim(),
      'mood': mood?['label'] ?? '🌸 Calm',
      'moodColor': mood?['color'] ?? const Color(0xFF185FA5),
      'moodBg': mood?['bg'] ?? const Color(0xFFE4E8FE),
      'accentColor': const Color(0xFF84B2E9),
      'time': _timeNow,
    });
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete entry',
          style: TextStyle(fontFamily: 'Mallanna', fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to delete this entry? This cannot be undone.',
          style: TextStyle(fontFamily: 'Mallanna', color: Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(
                    fontFamily: 'Mallanna', color: Color(0xFF888888))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, 'deleted');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE96A8F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Delete',
                style: TextStyle(fontFamily: 'Mallanna')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4E8FE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 13, color: Color(0xFF84B2E9)),
                          const SizedBox(width: 5),
                          Text(
                            widget.entry != null
                                ? 'Thu, Jan ${widget.entry!['day']}, 2026'
                                : _formattedDate,
                            style: const TextStyle(
                              fontFamily: 'Mallanna',
                              fontSize: 12,
                              color: Color(0xFF84B2E9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mood label
                    const Text(
                      'How are you feeling?',
                      style: TextStyle(
                        fontFamily: 'Mallanna',
                        fontSize: 12,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Mood chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(_moods.length, (i) {
                        final isSelected = _selectedMood == i;
                        final mood = _moods[i];
                        return GestureDetector(
                          onTap: _isEditing
                              ? () => setState(() => _selectedMood = i)
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? mood['bg'] as Color
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? mood['color'] as Color
                                    : const Color(0xFFDDE2F0),
                                width: isSelected ? 1.5 : 0.5,
                              ),
                            ),
                            child: Text(
                              mood['label'] as String,
                              style: TextStyle(
                                fontFamily: 'Mallanna',
                                fontSize: 12,
                                color: isSelected
                                    ? mood['color'] as Color
                                    : const Color(0xFF888888),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    TextField(
                      controller: _titleController,
                      enabled: _isEditing,
                      style: const TextStyle(
                        fontFamily: 'Mallanna',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Give your entry a title...',
                        hintStyle: TextStyle(
                          fontFamily: 'Mallanna',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFCCCCCC),
                        ),
                        border: InputBorder.none,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Color(0xFFE4E8FE), width: 1.5),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Color(0xFF84B2E9), width: 1.5),
                        ),
                        disabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Color(0xFFEEEEEE), width: 1),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Body label
                    const Text(
                      "What's on your mind?",
                      style: TextStyle(
                        fontFamily: 'Mallanna',
                        fontSize: 12,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Body
                    TextField(
                      controller: _bodyController,
                      enabled: _isEditing,
                      maxLines: null,
                      maxLength: 500,
                      style: const TextStyle(
                        fontFamily: 'Mallanna',
                        fontSize: 14,
                        color: Color(0xFF555555),
                        height: 1.7,
                      ),
                      decoration: const InputDecoration(
                        hintText:
                            'Write about how you\'re feeling, your day, or anything on your mind...',
                        hintStyle: TextStyle(
                          fontFamily: 'Mallanna',
                          fontSize: 14,
                          color: Color(0xFFCCCCCC),
                          height: 1.7,
                        ),
                        border: InputBorder.none,
                        counterStyle: TextStyle(
                          fontFamily: 'Mallanna',
                          fontSize: 11,
                          color: Color(0xFFBBBBBB),
                        ),
                      ),
                    ),
                  ],
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
          Text(
            widget.entry != null ? 'Diary Entry' : 'New Entry',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Mallanna',
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Edit or Delete button when viewing
          if (widget.entry != null && !_isEditing) ...[
            GestureDetector(
              onTap: _handleDelete,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline,
                    color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _isEditing = true),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_outlined,
                    color: Colors.white, size: 18),
              ),
            ),
          ],
          // Save button when writing
          if (_isEditing)
            GestureDetector(
              onTap: _handleSave,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Mallanna',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}