import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/glass.dart';

class DiaryEntryScreen extends StatefulWidget {
  final Map<String, dynamic>? entry;

  const DiaryEntryScreen({super.key, this.entry});

  @override
  State<DiaryEntryScreen> createState() => _DiaryEntryScreenState();
}

class _DiaryEntryScreenState extends State<DiaryEntryScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  // Multiple moods can be selected at once from the fixed list.
  final Set<int> _selectedMoods = {};

  // Any number of custom "Others" moods the user has typed in and confirmed.
  final List<String> _customMoods = [];
  // Controller + flag for the ONE custom mood currently being typed (if any).
  // Once confirmed, its text moves into _customMoods and this resets, so the
  // "+ Others" chip is ready to add another.
  final TextEditingController _newCustomController = TextEditingController();
  bool _addingCustom = false;

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

  // Colors used for every custom "Others" mood chip.
  static const Color _othersColor = Glass.purpleDeep;
  static const Color _othersBg = Color(0xFFF3E8FA);

  static String _cleanLabel(String raw) =>
      raw.replaceFirst(RegExp(r'^\S+\s+'), '');

  // The body has NO real limit. The counter just shows a "milestone" that
  // keeps growing: 500 -> 1000 -> 2000 -> 4000 -> ... as the entry gets longer.
  static int _counterTarget(int count) {
    int target = 500;
    while (count >= target) {
      target *= 2;
    }
    return target;
  }

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
      // "😊 Happy, 🌸 Calm, feeling nostalgic, missing my dog". Split it back
      // out into the known mood chips plus ANY number of custom "Others"
      // values — every unrecognized token becomes its own custom chip.
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
            _customMoods.add(token);
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
    _newCustomController.dispose();
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
          colorScheme: ColorScheme.light(primary: Glass.blueDeep),
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
        content: Text(msg, style: Glass.body(color: Colors.white)),
        backgroundColor: isError ? Glass.pinkDeep : const Color(0xFF4CAF7D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Confirms whatever is currently typed in the "add a custom mood" field:
  // moves it into _customMoods as its own chip, then resets so the
  // "+ Others" chip is ready to add another one.
  void _confirmNewCustomMood() {
    final text = _newCustomController.text.trim();
    setState(() {
      if (text.isNotEmpty) {
        _customMoods.add(text);
      }
      _newCustomController.clear();
      _addingCustom = false;
    });
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty) {
      _showSnack('Please add a title to your entry.');
      return;
    }

    // If the user left a custom mood mid-typing without confirming it,
    // capture it anyway rather than silently discarding it on save.
    final pendingCustom = _newCustomController.text.trim();

    final moodLabels = <String>[
      for (final i in _selectedMoods) _moods[i]['label'] as String,
      ..._customMoods,
      if (pendingCustom.isNotEmpty) pendingCustom,
    ];
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
            style: Glass.heading(size: 17, weight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete this entry? This cannot be undone.',
          style: Glass.body(size: 13, color: Glass.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: Glass.body(color: Glass.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmAndDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Glass.pinkDeep,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Delete', style: Glass.body(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Glass.pageBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBackground()),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Glass.card(
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
                                color: Glass.blue.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today, size: 13, color: Glass.blueDeep),
                                  const SizedBox(width: 5),
                                  Text(
                                    _formattedDate,
                                    style: Glass.body(
                                        size: 12, weight: FontWeight.w600, color: Glass.blueDeep),
                                  ),
                                  if (_isEditing) ...[
                                    const SizedBox(width: 5),
                                    Icon(Icons.edit_calendar_outlined,
                                        size: 13, color: Glass.blueDeep),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('How are you feeling?',
                              style: Glass.body(size: 12, color: Glass.textHint)),
                          const SizedBox(height: 4),
                          Text('Select one or more, or add your own — you can add several.',
                              style: Glass.body(size: 11, color: Glass.textHint)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              ...List.generate(_moods.length, (i) => _buildMoodChip(i)),
                              // One pill per confirmed custom mood, each individually removable.
                              for (int i = 0; i < _customMoods.length; i++)
                                _buildCustomMoodChip(i),
                              // The inline text field, shown only while actively adding one.
                              if (_addingCustom) _buildCustomMoodInput(),
                              // "+ Others" — always available so more can be added,
                              // even after one or several are already set.
                              if (!_addingCustom) _buildAddOthersChip(),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _titleController,
                            enabled: _isEditing,
                            style: Glass.heading(size: 20, weight: FontWeight.w700),
                            decoration: InputDecoration(
                              hintText: 'Give your entry a title...',
                              hintStyle: Glass.heading(
                                  size: 20, weight: FontWeight.w700, color: Glass.textHint),
                              border: InputBorder.none,
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.7), width: 1.5),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Glass.blueDeep.withOpacity(0.7), width: 1.5),
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
                              style: Glass.body(size: 12, color: Glass.textHint)),
                          const SizedBox(height: 8),
                          // No maxLength and no input formatter: typing is
                          // completely unlimited.
                          TextField(
                            controller: _bodyController,
                            enabled: _isEditing,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            style: Glass.body(size: 14, color: Glass.textMuted).copyWith(height: 1.7),
                            decoration: InputDecoration(
                              hintText:
                                  'Write about how you\'re feeling, your day, or anything on your mind...',
                              hintStyle: Glass.body(size: 14, color: Glass.textHint).copyWith(height: 1.7),
                              border: InputBorder.none,
                            ),
                          ),
                          // Live character counter, driven directly by the
                          // text controller. The target steps up
                          // 500 -> 1000 -> 2000 -> 4000 ... as you write.
                          const SizedBox(height: 4),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _bodyController,
                            builder: (context, value, _) {
                              final count = value.text.length;
                              final target = _counterTarget(count);
                              return Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '$count / $target characters',
                                  style: Glass.body(size: 11, color: Glass.textHint),
                                ),
                              );
                            },
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

  // A confirmed custom mood, rendered just like a built-in mood chip, with
  // its own remove (x) button while editing.
  Widget _buildCustomMoodChip(int i) {
    final label = _customMoods[i];
    return _moodPill(
      isSelected: true,
      color: _othersColor,
      bg: _othersBg,
      label: label,
      trailing: _isEditing
          ? GestureDetector(
              onTap: () => setState(() => _customMoods.removeAt(i)),
              child: Icon(Icons.close_rounded, size: 13, color: _othersColor),
            )
          : null,
    );
  }

  // The inline text field shown while the user is actively typing a new
  // custom mood. Confirming (checkmark or submit) adds it to _customMoods
  // and returns to the "+ Others" chip so another can be added.
  Widget _buildCustomMoodInput() {
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
              controller: _newCustomController,
              autofocus: true,
              enabled: _isEditing,
              maxLength: 24,
              style: Glass.body(size: 12, weight: FontWeight.w600, color: _othersColor),
              decoration: const InputDecoration(
                isDense: true,
                isCollapsed: true,
                counterText: '',
                border: InputBorder.none,
                hintText: 'Type a feeling',
              ),
              onSubmitted: (_) => _confirmNewCustomMood(),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _confirmNewCustomMood,
            child: Icon(Icons.check_rounded, size: 15, color: _othersColor),
          ),
        ],
      ),
    );
  }

  // The "+ Others" chip — always shown when not currently typing, so the
  // user can add a first custom mood, or another one after already adding some.
  Widget _buildAddOthersChip() {
    return GestureDetector(
      onTap: _isEditing ? () => setState(() => _addingCustom = true) : null,
      child: _moodPill(
        isSelected: false,
        color: _othersColor,
        bg: _othersBg,
        label: _customMoods.isEmpty ? 'Others' : '+ Add another',
      ),
    );
  }

  /// Shared pill styling so built-in moods and every custom "Others" mood
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
              color: isSelected ? color : Glass.textHint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Glass.body(
              size: 12,
              weight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? color : Glass.textMuted,
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
      child: Glass.card(
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
                child: Icon(Icons.chevron_left, color: Glass.textDark, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.entry != null ? 'Diary Entry' : 'New Entry',
              style: Glass.heading(size: 16, weight: FontWeight.w600),
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
                  child: Icon(Icons.delete_outline, color: Glass.pinkDeep, size: 18),
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
                  child: Icon(Icons.edit_outlined, color: Glass.blueDeep, size: 18),
                ),
              ),
            ],
            if (_isEditing)
              GestureDetector(
                onTap: _isSaving ? null : _handleSave,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Glass.blueDeep, Glass.purpleDeep]),
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
                          style: Glass.body(
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