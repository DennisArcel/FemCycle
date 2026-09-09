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
  final _customMoodController = TextEditingController();

  // Multiple moods can now be selected at once.
  final Set<int> _selectedMoods = {};

  // "Others" chip: active = chip is toggled on (has or is getting custom
  // text), editing = currently showing the inline text field.
  bool _customMoodActive = false;
  bool _customMoodEditing = false;

  DateTime _selectedDate = DateTime.now();

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

  // Colors used for the custom "Others" mood chip.
  static const Color _othersColor = _Glass.purpleDeep;
  static const Color _othersBg = Color(0xFFF3E8FA);

  static String _cleanLabel(String raw) =>
      raw.replaceFirst(RegExp(r'^\S+\s+'), '');

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _titleController.text = widget.entry!['title'] ?? '';
      _bodyController.text = widget.entry!['body'] ?? '';

      // 'date' is the raw ISO timestamp from the backend, passed through by
      // DiaryScreen._mapApiEntry alongside the already-formatted display
      // fields, so we can preselect the real date when editing.
      final rawDate = widget.entry!['date'] as String?;
      if (rawDate != null) {
        final parsed = DateTime.tryParse(rawDate);
        if (parsed != null) _selectedDate = parsed;
      }

      // The backend stores mood(s) as a single comma-separated string, e.g.
      // "😊 Happy, 🌸 Calm, feeling nostalgic". Split it back out into the
      // known mood chips plus (at most) one custom "Others" value.
      final moodField = widget.entry!['mood'] as String?;
      if (moodField != null && moodField.trim().isNotEmpty) {
        final tokens = moodField
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty);
        for (final token in tokens) {
          final idx = _moods.indexWhere((m) => m['label'] == token);
          if (idx != -1) {
            _selectedMoods.add(idx);
          } else {
            _customMoodActive = true;
            _customMoodController.text = token;
          }
        }
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
    _customMoodController.dispose();
    super.dispose();
  }

  String get _formattedDate {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final d = _selectedDate;
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: _Glass.blueDeep),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedDate.hour,
        _selectedDate.minute,
        _selectedDate.second,
      );
    });
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

    final moodLabels = <String>[
      for (final i in _selectedMoods) _moods[i]['label'] as String,
    ];
    final customText = _customMoodController.text.trim();
    if (_customMoodActive && customText.isNotEmpty) {
      moodLabels.add(customText);
    }
    final mood = moodLabels.isNotEmpty ? moodLabels.join(', ') : null;

    setState(() => _isSaving = true);

    final isUpdate = widget.entry != null && widget.entry!['id'] != null;

    // NOTE: ApiService.createDiaryEntry / updateDiaryEntry need a `date`
    // parameter added (DateTime, sent as an ISO string) so the backend logs
    // the entry under the chosen day instead of always "now".
    final result = isUpdate
        ? await ApiService.updateDiaryEntry(
            id: widget.entry!['id'] as int,
            title: title,
            body: body,
            mood: mood,
            date: _selectedDate,
          )
        : await ApiService.createDiaryEntry(
            title: title,
            body: body,
            mood: mood,
            date: _selectedDate,
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
                          GestureDetector(
                            onTap: _isEditing ? _pickDate : null,
                            child: Container(
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
                                    _formattedDate,
                                    style: _Glass.body(
                                        size: 12, weight: FontWeight.w600, color: _Glass.blueDeep),
                                  ),
                                  if (_isEditing) ...[
                                    const SizedBox(width: 5),
                                    Icon(Icons.edit_calendar_outlined,
                                        size: 13, color: _Glass.blueDeep),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('How are you feeling?',
                              style: _Glass.body(size: 12, color: _Glass.textHint)),
                          const SizedBox(height: 4),
                          Text('Select one or more, or add your own.',
                              style: _Glass.body(size: 11, color: _Glass.textHint)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              ...List.generate(_moods.length, (i) => _buildMoodChip(i)),
                              _buildOthersChip(),
                            ],
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

  // ── Mood chips ─────────────────────────────────────────────────────────

  Widget _buildMoodChip(int i) {
    final isSelected = _selectedMoods.contains(i);
    final mood = _moods[i];
    final moodColor = mood['color'] as Color;
    return GestureDetector(
      onTap: _isEditing
          ? () => setState(() {
                if (isSelected) {
                  _selectedMoods.remove(i);
                } else {
                  _selectedMoods.add(i);
                }
              })
          : null,
      child: _moodPill(
        isSelected: isSelected,
        color: moodColor,
        bg: mood['bg'] as Color,
        label: _cleanLabel(mood['label'] as String),
      ),
    );
  }

  Widget _buildOthersChip() {
    // Not toggled on yet: a plain "+ Others" chip.
    if (!_customMoodActive) {
      return GestureDetector(
        onTap: _isEditing
            ? () => setState(() {
                  _customMoodActive = true;
                  _customMoodEditing = true;
                })
            : null,
        child: _moodPill(
          isSelected: false,
          color: _othersColor,
          bg: _othersBg,
          label: 'Others',
        ),
      );
    }

    // Toggled on and currently typing.
    if (_customMoodEditing) {
      return Container(
        constraints: const BoxConstraints(minWidth: 100, maxWidth: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: _othersBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _othersColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: TextField(
                controller: _customMoodController,
                autofocus: true,
                enabled: _isEditing,
                maxLength: 24,
                style: _Glass.body(size: 12, weight: FontWeight.w600, color: _othersColor),
                decoration: const InputDecoration(
                  isDense: true,
                  isCollapsed: true,
                  counterText: '',
                  border: InputBorder.none,
                  hintText: 'Type a feeling',
                ),
                onSubmitted: (_) => setState(() => _customMoodEditing = false),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => setState(() {
                if (_customMoodController.text.trim().isEmpty) {
                  _customMoodActive = false;
                }
                _customMoodEditing = false;
              }),
              child: Icon(Icons.check_rounded, size: 15, color: _othersColor),
            ),
          ],
        ),
      );
    }

    // Toggled on with saved text: render exactly like the other mood chips.
    final label = _customMoodController.text.trim();
    if (label.isEmpty) {
      return GestureDetector(
        onTap: _isEditing ? () => setState(() => _customMoodEditing = true) : null,
        child: _moodPill(isSelected: false, color: _othersColor, bg: _othersBg, label: 'Others'),
      );
    }

    return GestureDetector(
      onTap: _isEditing ? () => setState(() => _customMoodEditing = true) : null,
      child: _moodPill(
        isSelected: true,
        color: _othersColor,
        bg: _othersBg,
        label: label,
        trailing: _isEditing
            ? GestureDetector(
                onTap: () => setState(() {
                  _customMoodActive = false;
                  _customMoodController.clear();
                }),
                child: Icon(Icons.close_rounded, size: 13, color: _othersColor),
              )
            : null,
      ),
    );
  }

  /// Shared pill styling so the built-in moods and the custom "Others" mood
  /// look identical once selected.
  Widget _moodPill({
    required bool isSelected,
    required Color color,
    required Color bg,
    required String label,
    Widget? trailing,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? bg : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? color : Colors.white.withOpacity(0.7),
          width: isSelected ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(
              color: isSelected ? color : _Glass.textHint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: _Glass.body(
              size: 12,
              weight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? color : _Glass.textMuted,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 5), trailing],
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