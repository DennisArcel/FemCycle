import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

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
  bool _isSaving = false;

  // NOTE: 'label' is the exact value stored/sent to the backend — kept
  // emoji-prefixed for backward compatibility with already-logged entries.
  // Only the on-screen chip rendering strips the emoji (see _cleanLabel) —
  // the stored value itself is untouched.
  final List<Map<String, dynamic>> _moods = [
    {'label': '😊 Happy', 'color': const Color(0xFF185FA5), 'bg': const Color(0xFFE4E8FE)},
    {'label': '😔 Sad', 'color': const Color(0xFFBC6B9C), 'bg': const Color(0xFFF5EAF7)},
    {'label': '😤 Irritable', 'color': const Color(0xFFBC6B9C), 'bg': const Color(0xFFF5EAF7)},
    {'label': '🌸 Calm', 'color': const Color(0xFF185FA5), 'bg': const Color(0xFFE4E8FE)},
    {'label': '😢 Cry', 'color': const Color(0xFFE96A8F), 'bg': const Color(0xFFFBEAF0)},
    {'label': '⚡ Energetic', 'color': const Color(0xFF84B2E9), 'bg': const Color(0xFFE4E8FE)},
  ];

  static String _cleanLabel(String raw) =>
      raw.replaceFirst(RegExp(r'^\S+\s+'), '');

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

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: _Glass.body(color: Colors.white)),
        backgroundColor: isError ? _Glass.pinkDeep : const Color(0xFF4CAF7D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty) {
      _showSnack('Please add a title to your entry.');
      return;
    }

    final mood = _selectedMood >= 0 ? _moods[_selectedMood]['label'] as String : null;

    setState(() => _isSaving = true);

    final isUpdate = widget.entry != null && widget.entry!['id'] != null;

    final result = isUpdate
        ? await ApiService.updateDiaryEntry(
            id: widget.entry!['id'] as int,
            title: title,
            body: body,
            mood: mood,
          )
        : await ApiService.createDiaryEntry(
            title: title,
            body: body,
            mood: mood,
          );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == true) {
      Navigator.pop(context, 'saved');
    } else {
      _showSnack(result['message'] ?? 'Could not save your entry. Please try again.');
    }
  }

  Future<void> _confirmAndDelete() async {
    final id = widget.entry?['id'] as int?;
    if (id == null) return;

    setState(() => _isSaving = true);
    final result = await ApiService.deleteDiaryEntry(id);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result['success'] == true) {
      Navigator.pop(context, 'deleted');
    } else {
      _showSnack(result['message'] ?? 'Could not delete entry. Please try again.');
    }
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete entry',
            style: _Glass.heading(size: 17, weight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete this entry? This cannot be undone.',
          style: _Glass.body(size: 13, color: _Glass.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: _Glass.body(color: _Glass.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmAndDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _Glass.pinkDeep,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Delete', style: _Glass.body(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Glass.pageBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientBackground()),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: _Glass.card(
                      radius: 22,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _Glass.blue.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today, size: 13, color: _Glass.blueDeep),
                                const SizedBox(width: 5),
                                Text(
                                  widget.entry != null
                                      ? '${widget.entry!['weekday'] ?? ''}, ${widget.entry!['month'] ?? ''} ${widget.entry!['day'] ?? ''}'
                                      : _formattedDate,
                                  style: _Glass.body(
                                      size: 12, weight: FontWeight.w600, color: _Glass.blueDeep),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('How are you feeling?',
                              style: _Glass.body(size: 12, color: _Glass.textHint)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: List.generate(_moods.length, (i) {
                              final isSelected = _selectedMood == i;
                              final mood = _moods[i];
                              final moodColor = mood['color'] as Color;
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
                                        : Colors.white.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? moodColor
                                          : Colors.white.withOpacity(0.7),
                                      width: isSelected ? 1.5 : 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 7, height: 7,
                                        decoration: BoxDecoration(
                                          color: isSelected ? moodColor : _Glass.textHint,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _cleanLabel(mood['label'] as String),
                                        style: _Glass.body(
                                          size: 12,
                                          weight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isSelected ? moodColor : _Glass.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _titleController,
                            enabled: _isEditing,
                            style: _Glass.heading(size: 20, weight: FontWeight.w700),
                            decoration: InputDecoration(
                              hintText: 'Give your entry a title...',
                              hintStyle: _Glass.heading(
                                  size: 20, weight: FontWeight.w700, color: _Glass.textHint),
                              border: InputBorder.none,
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.7), width: 1.5),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: _Glass.blueDeep.withOpacity(0.7), width: 1.5),
                              ),
                              disabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.4), width: 1),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text("What's on your mind?",
                              style: _Glass.body(size: 12, color: _Glass.textHint)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _bodyController,
                            enabled: _isEditing,
                            maxLines: null,
                            maxLength: 500,
                            style: _Glass.body(size: 14, color: _Glass.textMuted).copyWith(height: 1.7),
                            decoration: InputDecoration(
                              hintText:
                                  'Write about how you\'re feeling, your day, or anything on your mind...',
                              hintStyle: _Glass.body(size: 14, color: _Glass.textHint).copyWith(height: 1.7),
                              border: InputBorder.none,
                              counterStyle: _Glass.body(size: 11, color: _Glass.textHint),
                            ),
                          ),
                        ],
                      ),
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
      child: _Glass.card(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            GestureDetector(
              onTap: _isSaving ? null : () => Navigator.pop(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
                child: Icon(Icons.chevron_left, color: _Glass.textDark, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.entry != null ? 'Diary Entry' : 'New Entry',
              style: _Glass.heading(size: 16, weight: FontWeight.w600),
            ),
            const Spacer(),
            if (widget.entry != null && !_isEditing && !_isSaving) ...[
              GestureDetector(
                onTap: _handleDelete,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
                  child: Icon(Icons.delete_outline, color: _Glass.pinkDeep, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _isEditing = true),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
                  child: Icon(Icons.edit_outlined, color: _Glass.blueDeep, size: 18),
                ),
              ),
            ],
            if (_isEditing)
              GestureDetector(
                onTap: _isSaving ? null : _handleSave,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_Glass.blueDeep, _Glass.purpleDeep]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save',
                          style: _Glass.body(
                              size: 13, weight: FontWeight.w600, color: Colors.white),
                        ),
                ),
              ),
          ],
        ),
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