import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_bottom_nav.dart';
import '../services/notification_service.dart';
import '../widgets/coach_mark_overlay.dart';
import '../services/tutorial_storage_service.dart';
import '../widgets/glass.dart';
import 'checkup_types.dart';

// Re-export so any other file that imports checkup_screen.dart and uses
// kSuggestions / CheckupSuggestion keeps working.
export 'checkup_types.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

class Checkup {
  final int id;
  final String title;
  final String notes;
  final DateTime date;
  String time; // e.g. "9:00 AM"
  String status; // 'upcoming' | 'done' | 'overdue'
  final bool isRecurring;
  final String recurringType; // 'monthly' | 'quarterly' | 'yearly' | 'none'
  final String type; // icon key

  Checkup({
    required this.id,
    required this.title,
    required this.notes,
    required this.date,
    this.time = '',
    this.status = 'upcoming',
    this.isRecurring = false,
    this.recurringType = 'none',
    this.type = 'general',
  });

  Checkup copyWith({
    String? title,
    String? notes,
    DateTime? date,
    String? time,
    String? status,
    bool? isRecurring,
    String? recurringType,
    String? type,
  }) =>
      Checkup(
        id: id,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        date: date ?? this.date,
        time: time ?? this.time,
        status: status ?? this.status,
        isRecurring: isRecurring ?? this.isRecurring,
        recurringType: recurringType ?? this.recurringType,
        type: type ?? this.type,
      );
  factory Checkup.fromJson(Map<String, dynamic> json) {
    return Checkup(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      notes: json['notes'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      time: json['time'] ?? '',
      status: json['status'] ?? 'upcoming',
      isRecurring: json['is_recurring'] is int
          ? json['is_recurring'] == 1
          : (json['is_recurring'] ?? false),
      recurringType: json['recurring_type'] ?? 'none',
      type: json['type'] ?? 'general',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date.toIso8601String().split('T')[0],
      'time': time,
      'notes': notes,
      'status': status,
      'is_recurring': isRecurring ? 1 : 0,
      'recurring_type': recurringType,
      'type': type,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class CheckupScreen extends StatefulWidget {
  const CheckupScreen({super.key});

  @override
  State<CheckupScreen> createState() => _CheckupScreenState();
}

class _CheckupScreenState extends State<CheckupScreen> {
  final DateTime _today = DateTime.now();
  late DateTime _currentMonth;

  // ── Coach-mark tour targets ──
  final GlobalKey _calendarKey = GlobalKey();
  final GlobalKey _summaryKey = GlobalKey();
  final GlobalKey _addButtonKey = GlobalKey();

  List<Checkup> _checkups = [
  ];

  bool _isLoading = true;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String apiUrl = 'https://femcycleapp-production.up.railway.app/api/checkups'; // Laravel IP

  Future<Map<String, String>> _getHeaders() async {
    String? token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  Future<void> _fetchCheckups() async {
  setState(() => _isLoading = true);

  try {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      final loadedCheckups =
          data.map((json) => Checkup.fromJson(json)).toList();

      // Automatically mark old upcoming check-ups as overdue
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);

      for (final c in loadedCheckups) {
        final checkupDate = DateTime(
          c.date.year,
          c.date.month,
          c.date.day,
        );

        if (c.status == 'upcoming' &&
            checkupDate.isBefore(todayOnly)) {
          c.status = 'overdue';
        }
      }

      setState(() {
        _checkups = loadedCheckups;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);

      _showSnack(
        'Failed to load check-ups (${response.statusCode})',
        Glass.pinkDeep,
      );
    }
  } catch (e) {
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error connecting to FemCycle server'),
      ),
    );
  }
}

  // Returns true only if the checkup was actually saved server-side —
  // callers use this to decide whether to close the sheet / show success.
  Future<bool> _apiCreateCheckup(Checkup newCheckup) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(Uri.parse(apiUrl),
          headers: headers, body: json.encode(newCheckup.toJson()));
      if (response.statusCode == 201 || response.statusCode == 200) {
        // The backend assigns the real id — parse it from the response so
        // the reminders are scheduled against the id that will later be
        // used to cancel/reschedule them (edits, deletes).
        try {
          final decoded = json.decode(response.body);
          // Your Laravel store() returns {"message": ..., "checkup": {...}}
          // — the checkup isn't at the top level, so pull it out of the
          // 'checkup' key. Falls back to the top-level object just in case
          // the response shape ever changes.
          final checkupJson = decoded is Map && decoded.containsKey('checkup')
              ? decoded['checkup']
              : decoded;
          final created = Checkup.fromJson(checkupJson);
          if (created.id != 0 && created.status != 'done') {
            await NotificationService.scheduleCheckupReminders(
              checkupId: created.id,
              title: created.title,
              date: created.date,
              time: created.time,
            );
          }
        } catch (_) {
          // If the create response doesn't return the full object, the
          // reminder simply won't be scheduled — check the backend's
          // response shape for POST /api/checkups if this happens.
        }
        await _fetchCheckups();
        return true;
      } else {
        _showSnack('Failed to save check-up (${response.statusCode})',
            Glass.pinkDeep);
        return false;
      }
    } catch (_) {
      _showSnack('Error connecting to FemCycle server',
          Glass.pinkDeep);
      return false;
    }
  }

  Future<bool> _apiUpdateCheckup(Checkup updatedCheckup) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
          Uri.parse('$apiUrl/${updatedCheckup.id}'),
          headers: headers, body: json.encode(updatedCheckup.toJson()));
      if (response.statusCode == 200) {
        // Reschedule reminders against the updated date/time. If the
        // checkup was marked done, drop the reminders instead — no point
        // reminding about something already completed.
        if (updatedCheckup.status == 'done') {
          await NotificationService.cancelCheckupReminders(updatedCheckup.id);
        } else {
          await NotificationService.scheduleCheckupReminders(
            checkupId: updatedCheckup.id,
            title: updatedCheckup.title,
            date: updatedCheckup.date,
            time: updatedCheckup.time,
          );
        }
        await _fetchCheckups();
        return true;
      } else {
        _showSnack('Failed to update check-up (${response.statusCode})',
            Glass.pinkDeep);
        await _fetchCheckups(); // resync in case local state drifted
        return false;
      }
    } catch (_) {
      _showSnack('Error connecting to FemCycle server',
          Glass.pinkDeep);
      return false;
    }
  }

  Future<void> _apiDeleteCheckup(int id) async {
    try {
      final headers = await _getHeaders();
      final response =
          await http.delete(Uri.parse('$apiUrl/$id'), headers: headers);
      if (response.statusCode == 200 || response.statusCode == 204) {
        await NotificationService.cancelCheckupReminders(id);
        _fetchCheckups();
      } else {
        _showSnack('Failed to delete check-up (${response.statusCode})',
            Glass.pinkDeep);
        _fetchCheckups();
      }
    } catch (_) {
      _showSnack('Error connecting to FemCycle server',
          Glass.pinkDeep);
    }
  }

  @override
  void initState() {
    super.initState();

    _currentMonth = DateTime(_today.year, _today.month);

    _fetchCheckups();
    _maybeShowCoachTour();
  }

  Future<void> _maybeShowCoachTour() async {
    final seen = await TutorialStorageService.hasSeenTour(TutorialStorageService.checkup);
    if (seen || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCoachTour());
  }

  void _startCoachTour() {
    showCoachMarkTour(
      context: context,
      steps: [
        CoachMarkStep(
          targetKey: _summaryKey,
          title: 'At a glance',
          description: 'A quick count of what\'s upcoming, overdue, or already done.',
        ),
        CoachMarkStep(
          targetKey: _calendarKey,
          title: 'Check-up calendar',
          description: 'Scheduled visits show up on their date here, color-coded by status. Tap a day to see or edit its check-ups.',
        ),
        CoachMarkStep(
          targetKey: _addButtonKey,
          title: 'Schedule a check-up',
          description: 'Tap here to add a new appointment, with optional recurring reminders.',
        ),
      ],
    ).then((_) => TutorialStorageService.markTourSeen(TutorialStorageService.checkup));
  }

  void _autoMarkOverdue() {
    for (final c in _checkups) {
      if (c.status == 'upcoming' && c.date.isBefore(_today) &&
          !(c.date.year == _today.year && c.date.month == _today.month &&
              c.date.day == _today.day)) {
        c.status = 'overdue';
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<Checkup> get _thisMonthCheckups => _checkups
      .where((c) =>
          c.date.month == _currentMonth.month &&
          c.date.year == _currentMonth.year)
      .toList();

  int get _upcomingCount =>
      _checkups.where((c) => c.status == 'upcoming').length;
  int get _overdueCount =>
      _checkups.where((c) => c.status == 'overdue').length;
  int get _doneCount => _checkups.where((c) => c.status == 'done').length;

  List<int> _daysWithStatus(String status) => _checkups
      .where((c) =>
          c.date.month == _currentMonth.month &&
          c.date.year == _currentMonth.year &&
          c.status == status)
      .map((c) => c.date.day)
      .toList();

  // ── Status colors ──────────────────────────────────────────────────────────

  Color _statusBg(String s) {
    switch (s) {
      case 'overdue': return Glass.pink.withOpacity(0.25);
      case 'done': return const Color(0xFF3BAF7E).withOpacity(0.18);
      default: return Glass.blue.withOpacity(0.25);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'overdue': return Glass.pinkDeep;
      case 'done': return const Color(0xFF1D9E75);
      default: return Glass.blueDeep;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'overdue': return 'Overdue';
      case 'done': return 'Done';
      default: return 'Upcoming';
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'overdue': return Icons.error_outline_rounded;
      case 'done': return Icons.check_circle_outline_rounded;
      default: return Icons.calendar_today_rounded;
    }
  }

  // ── Month helpers ──────────────────────────────────────────────────────────

  String _monthName(int m) {
    const n = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return n[m - 1];
  }

  String _shortMonth(int m) {
    const n = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return n[m - 1];
  }

  String _formatDate(DateTime d) =>
      '${d.day} ${_monthName(d.month)} ${d.year}';

  // ── CRUD actions ───────────────────────────────────────────────────────────

  // An appointment can only be marked done once its date has arrived —
  // this compares date-only (ignores time of day).
  bool _isFutureDate(DateTime d) {
    final today0 = DateTime(_today.year, _today.month, _today.day);
    final d0 = DateTime(d.year, d.month, d.day);
    return d0.isAfter(today0);
  }

  void _markDone(Checkup c) {
    if (_isFutureDate(c.date)) {
      _showSnack("Can't mark a future check-up as done yet", Glass.pinkDeep);
      return;
    }
    setState(() => c.status = 'done');
    _showSnack('Marked as done ✓', const Color(0xFF1D9E75));
    _apiUpdateCheckup(c);
  }

  void _markUpcoming(Checkup c) {
    setState(() => c.status = 'upcoming');
    _showSnack('Restored to upcoming', Glass.blueDeep);
    _apiUpdateCheckup(c);
  }

  void _delete(Checkup c) {
    setState(() => _checkups.remove(c));
    _showSnack('Deleted "${c.title}"', Glass.pinkDeep);
    _apiDeleteCheckup(c.id);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: Glass.body(size: 13, color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(14),
      duration: const Duration(seconds: 2),
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Glass.pageBackground,
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientBackground()),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KeyedSubtree(key: _summaryKey, child: _buildSummaryRow()),
                        const SizedBox(height: 12),
                        KeyedSubtree(key: _calendarKey, child: _buildCalendar()),
                        const SizedBox(height: 14),
                        KeyedSubtree(key: _addButtonKey, child: _buildAddButton()),
                      ],
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

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
    child: Glass.card(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Expanded(
          child: Text('Check-up Scheduler',
              style: Glass.heading(size: 16, weight: FontWeight.w600)),
        ),
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
      ]),
    ),
  );

  // ── Calendar ───────────────────────────────────────────────────────────────

  Widget _buildCalendar() {
    final daysInMonth = DateUtils.getDaysInMonth(
        _currentMonth.year, _currentMonth.month);
    final firstWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;
    final upcomingDays = _daysWithStatus('upcoming');
    final overdueDays = _daysWithStatus('overdue');
    final doneDays = _daysWithStatus('done');

    return Glass.card(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        // Month nav
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_monthName(_currentMonth.month)} ${_currentMonth.year}',
                style: Glass.body(size: 14, weight: FontWeight.w700)),
            Row(children: [
              _calNavBtn(Icons.chevron_left, () => setState(() =>
                  _currentMonth = DateTime(
                      _currentMonth.year, _currentMonth.month - 1))),
              const SizedBox(width: 4),
              _calNavBtn(Icons.chevron_right, () => setState(() =>
                  _currentMonth = DateTime(
                      _currentMonth.year, _currentMonth.month + 1))),
            ]),
          ],
        ),
        const SizedBox(height: 10),

        // Weekday labels
        Row(
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: Glass.body(size: 10, color: Glass.textHint)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),

        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, childAspectRatio: 1.0),
          itemCount: firstWeekday + daysInMonth,
          itemBuilder: (_, index) {
            if (index < firstWeekday) return const SizedBox();
            final day = index - firstWeekday + 1;
            final isToday = _currentMonth.year == _today.year &&
                _currentMonth.month == _today.month &&
                day == _today.day;
            final isOverdue = overdueDays.contains(day);
            final isCheckup = upcomingDays.contains(day);
            final isDone = doneDays.contains(day);

            Color bg = Colors.transparent;
            Color textColor = Glass.textDark;
            Color dotColor = Colors.transparent;

            if (isToday) {
              bg = Glass.blueDeep;
              textColor = Colors.white;
            } else if (isOverdue) {
              bg = Glass.pink.withOpacity(0.25);
              textColor = Glass.pinkDeep;
              dotColor = Glass.pinkDeep;
            } else if (isCheckup) {
              bg = Glass.blue.withOpacity(0.25);
              textColor = Glass.blueDeep;
              dotColor = Glass.blueDeep;
            } else if (isDone) {
              bg = const Color(0xFF3BAF7E).withOpacity(0.18);
              textColor = const Color(0xFF0F6E56);
              dotColor = const Color(0xFF1D9E75);
            }

            return GestureDetector(
              onTap: () => _onCalendarDayTap(day),
              child: Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$day',
                        style: Glass.body(
                          size: 11,
                          color: textColor,
                          weight: isToday ? FontWeight.w700 : FontWeight.normal,
                        )),
                    if (dotColor != Colors.transparent)
                      Container(
                        width: 4, height: 4,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                            color: dotColor, shape: BoxShape.circle),
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 10),
        Divider(height: 1, color: Colors.white.withOpacity(0.6)),
        const SizedBox(height: 8),

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendDot(Glass.blueDeep, 'Check-up'),
            const SizedBox(width: 10),
            _legendDot(Glass.pinkDeep, 'Overdue'),
            const SizedBox(width: 10),
            _legendDot(const Color(0xFF1D9E75), 'Done'),
          ],
        ),
      ]),
    );
  }

  void _onCalendarDayTap(int day) {
    final matches = _checkups.where((c) =>
        c.date.day == day &&
        c.date.month == _currentMonth.month &&
        c.date.year == _currentMonth.year).toList();
    if (matches.isEmpty) return;
    if (matches.length == 1) {
      _showCheckupDetailSheet(matches.first);
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _DayCheckupsSheet(
          checkups: matches,
          onTap: _showCheckupDetailSheet,
          statusBg: _statusBg,
          statusColor: _statusColor,
          statusLabel: _statusLabel,
          statusIcon: _statusIcon,
        ),
      );
    }
  }

  Widget _calNavBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 26, height: 26,
      decoration: BoxDecoration(
        color: Glass.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 16, color: Glass.blueDeep),
    ),
  );

  Widget _legendDot(Color color, String label) => Row(children: [
    Container(width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: Glass.body(size: 9, color: Glass.textMuted)),
  ]);

  // ── Summary row ────────────────────────────────────────────────────────────

  Widget _buildSummaryRow() => Row(children: [
    _summaryCard('$_upcomingCount', 'Upcoming', Glass.blueDeep),
    const SizedBox(width: 8),
    _summaryCard('$_overdueCount', 'Overdue', Glass.pinkDeep),
    const SizedBox(width: 8),
    _summaryCard('$_doneCount', 'Done', const Color(0xFF1D9E75)),
  ]);

  Widget _summaryCard(String num, String label, Color color) => Expanded(
    child: Glass.card(
      radius: 14,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(children: [
        Text(num, style: Glass.heading(size: 22, weight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: Glass.body(size: 10, color: Glass.textMuted)),
      ]),
    ),
  );

  // ── Add button ─────────────────────────────────────────────────────────────

  Widget _buildAddButton() => SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton.icon(
      onPressed: () => _showAddEditSheet(null),
      icon: const Icon(Icons.add, color: Colors.white, size: 20),
      label: Text('Add Check-up',
          style: Glass.body(size: 15, weight: FontWeight.w600, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Glass.pinkDeep,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    ),
  );

  // ── Detail sheet ───────────────────────────────────────────────────────────

  void _showCheckupDetailSheet(Checkup c) {
    final col = _statusColor(c.status);
    final bg = _statusBg(c.status);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Glass.textHint.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 18),

          Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(14)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${c.date.day}',
                      style: Glass.heading(size: 18, weight: FontWeight.w700, color: col).copyWith(height: 1)),
                  Text(_shortMonth(c.date.month),
                      style: Glass.body(size: 10, weight: FontWeight.w600, color: col)),
                ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.title, style: Glass.heading(size: 16, weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(c.notes, style: Glass.body(size: 12, color: Glass.textMuted)),
                ]),
            ),
          ]),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Glass.pageBackground,
              borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _detailRow(Icons.calendar_today_rounded, 'Date', _formatDate(c.date)),
              if (c.time.isNotEmpty) ...[
                const SizedBox(height: 8),
                _detailRow(Icons.access_time_rounded, 'Time', c.time),
              ],
              const SizedBox(height: 8),
              _detailRow(_statusIcon(c.status), 'Status', _statusLabel(c.status), color: col),
              if (c.isRecurring) ...[
                const SizedBox(height: 8),
                _detailRow(Icons.repeat_rounded, 'Recurring',
                    '${c.recurringType[0].toUpperCase()}${c.recurringType.substring(1)}'),
              ],
            ]),
          ),

          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showAddEditSheet(c);
                },
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text('Edit', style: Glass.body(size: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Glass.blueDeep,
                  side: BorderSide(color: Glass.blueDeep),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            // "Mark done" only makes sense once the appointment date has
            // arrived — for a future check-up we just don't offer it here.
            if (c.status == 'done' || !_isFutureDate(c.date)) ...[
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    if (c.status != 'done') {
                      _markDone(c);
                    } else {
                      _markUpcoming(c);
                    }
                  },
                  icon: Icon(
                    c.status != 'done' ? Icons.check_circle_outline_rounded : Icons.undo_rounded,
                    size: 16,
                  ),
                  label: Text(c.status != 'done' ? 'Mark done' : 'Undo',
                      style: Glass.body(size: 13, weight: FontWeight.w600, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.status != 'done' ? const Color(0xFF1D9E75) : Glass.blueDeep,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ]),

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Colors.white.withOpacity(0.92),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text('Delete check-up?',
                        style: Glass.heading(size: 17, weight: FontWeight.w700)),
                    content: Text('Remove "${c.title}" from your schedule?',
                        style: Glass.body(size: 13, color: Glass.textMuted)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('Cancel', style: Glass.body(color: Glass.textMuted)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
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
                if (confirm == true && mounted) {
                  Navigator.pop(context);
                  _delete(c);
                }
              },
              icon: Icon(Icons.delete_outline_rounded, size: 16, color: Glass.pinkDeep),
              label: Text('Delete check-up',
                  style: Glass.body(size: 13, color: Glass.pinkDeep)),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 8),
        ]),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? color}) =>
      Row(children: [
        Icon(icon, size: 14, color: color ?? Glass.textMuted),
        const SizedBox(width: 8),
        Text(label, style: Glass.body(size: 12, color: Glass.textMuted)),
        const Spacer(),
        Text(value, style: Glass.body(size: 12, weight: FontWeight.w600, color: color ?? Glass.textDark)),
      ]);

  // ── Add / Edit sheet ───────────────────────────────────────────────────────

  void _showAddEditSheet(Checkup? existing) {
    final isEdit = existing != null;

    // Dropdown state. When editing, pre-select the matching type; if the
    // saved title isn't in the list, select "Others" and fill the text box.
    String? selectedType;
    final otherCtrl = TextEditingController();
    if (isEdit) {
      if (kAppointmentTypes.contains(existing.title) &&
          existing.title != kOthersLabel) {
        selectedType = existing.title;
      } else {
        selectedType = kOthersLabel;
        otherCtrl.text = existing.title;
      }
    }

    final notesCtrl =
        TextEditingController(text: isEdit ? existing.notes : '');
    DateTime selDate = isEdit ? existing.date : DateTime.now();
    TimeOfDay selTime = const TimeOfDay(hour: 9, minute: 0);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.96),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: Glass.textHint.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(isEdit ? 'Edit Check-up' : 'New Check-up',
                      style: Glass.heading(size: 18, weight: FontWeight.w700)),
                  const SizedBox(height: 16),

                  // ── Appointment type dropdown ──
                  _label('Appointment Type'),
                  if (selectedType == kOthersLabel)
                    // "Others" picked → the dropdown itself becomes a text
                    // field, focused right away. The arrow goes back to the list.
                    TextField(
                      controller: otherCtrl,
                      autofocus: otherCtrl.text.isEmpty,
                      textCapitalization: TextCapitalization.sentences,
                      style: Glass.body(size: 13, color: Glass.textDark),
                      decoration: InputDecoration(
                        hintText: 'Type appointment type (e.g. Colposcopy)',
                        hintStyle:
                            Glass.body(size: 13, color: Glass.textHint),
                        filled: true,
                        fillColor: Glass.pageBackground,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        suffixIcon: IconButton(
                          tooltip: 'Choose from list',
                          icon: Icon(Icons.keyboard_arrow_down_rounded,
                              color: Glass.blueDeep),
                          onPressed: () => setSheetState(() {
                            selectedType = null;
                            otherCtrl.clear();
                          }),
                        ),
                      ),
                    )
                  else
                    _typeDropdown(
                      selected: selectedType,
                      onChanged: (v) => setSheetState(() => selectedType = v),
                    ),
                  const SizedBox(height: 12),

                  _label('Notes (optional)'),
                  _input(notesCtrl, 'e.g. Dr. Santos · 9:00 AM'),
                  const SizedBox(height: 12),

                  _label('Date'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(primary: Glass.blueDeep),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setSheetState(() => selDate = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                          color: Glass.pageBackground,
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        Icon(Icons.calendar_today_outlined, size: 16, color: Glass.blueDeep),
                        const SizedBox(width: 8),
                        Text(_formatDate(selDate), style: Glass.body(size: 13, color: Glass.textMuted)),
                        const Spacer(),
                        Text('Change', style: Glass.body(size: 11, color: Glass.blueDeep)),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 12),

                  _label('Time'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: selTime,
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(primary: Glass.blueDeep),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setSheetState(() => selTime = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                          color: Glass.pageBackground,
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        Icon(Icons.access_time_rounded, size: 16, color: Glass.blueDeep),
                        const SizedBox(width: 8),
                        Text(selTime.format(ctx),
                            style: Glass.body(size: 13, color: Glass.textMuted)),
                        const Spacer(),
                        Text('Change', style: Glass.body(size: 11, color: Glass.blueDeep)),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              // ── Validation ──
                              if (selectedType == null) {
                                _showSnack('Please select an appointment type',
                                    Glass.pinkDeep);
                                return;
                              }
                              final String title;
                              if (selectedType == kOthersLabel) {
                                title = otherCtrl.text.trim();
                                if (title.isEmpty) {
                                  _showSnack('Please type the appointment type',
                                      Glass.pinkDeep);
                                  return;
                                }
                              } else {
                                title = selectedType!;
                              }

                              setSheetState(() => isSaving = true);

                              bool ok;
                              if (isEdit) {
                                final updated = existing.copyWith(
                                  title: title,
                                  notes: notesCtrl.text.trim().isEmpty
                                      ? 'Reminder'
                                      : notesCtrl.text.trim(),
                                  date: selDate,
                                  time: selTime.format(ctx),
                                );
                                ok = await _apiUpdateCheckup(updated);
                              } else {
                                final newCheckup = Checkup(
                                  id: 0, // server assigns the real id
                                  title: title,
                                  notes: notesCtrl.text.trim().isEmpty
                                      ? 'Reminder'
                                      : notesCtrl.text.trim(),
                                  date: selDate,
                                  time: selTime.format(ctx),
                                  status: selDate.isBefore(DateTime(
                                          _today.year, _today.month, _today.day))
                                      ? 'overdue'
                                      : 'upcoming',
                                );
                                ok = await _apiCreateCheckup(newCheckup);
                              }

                              if (!mounted) return;

                              if (ok) {
                                Navigator.pop(ctx);
                                _showSnack(
                                  isEdit ? 'Check-up updated ✓' : 'Check-up added ✓',
                                  Glass.blueDeep,
                                );
                              } else {
                                // Keep the sheet open on failure — the API
                                // methods already show their own error
                                // snack, so just re-enable the button so
                                // the user can retry.
                                setSheetState(() => isSaving = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Glass.blueDeep,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Glass.blueDeep.withOpacity(0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(isEdit ? 'Save Changes' : 'Save',
                              style: Glass.body(
                                  size: 15, weight: FontWeight.w600, color: Colors.white)),
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

  // Styled to match the `_input` text fields.
  Widget _typeDropdown({
    required String? selected,
    required ValueChanged<String?> onChanged,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Glass.pageBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selected,
            isExpanded: true,
            hint: Text('Select appointment type',
                style: Glass.body(size: 13, color: Glass.textHint)),
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: Glass.blueDeep),
            borderRadius: BorderRadius.circular(12),
            dropdownColor: Colors.white,
            menuMaxHeight: 320,
            style: Glass.body(size: 13, color: Glass.textDark),
            items: kAppointmentTypes
                .map((t) => DropdownMenuItem<String>(
                      value: t,
                      child: Text(
                        t,
                        overflow: TextOverflow.ellipsis,
                        style: Glass.body(
                          size: 13,
                          color: Glass.textDark,
                          weight: t == kOthersLabel
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );

  Widget _recurChip(String label, String value, String current,
      ValueChanged<String> onTap) {
    final isOn = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isOn ? Glass.blueDeep : Glass.pageBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isOn ? Glass.blueDeep : Glass.textHint.withOpacity(0.4)),
        ),
        child: Text(label,
            style: Glass.body(
                size: 12, weight: FontWeight.w600, color: isOn ? Colors.white : Glass.textMuted)),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text, style: Glass.body(size: 12, color: Glass.textHint)),
  );

  Widget _input(TextEditingController ctrl, String hint) => TextField(
    controller: ctrl,
    style: Glass.body(size: 13, color: Glass.textDark),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: Glass.body(size: 13, color: Glass.textHint),
      filled: true,
      fillColor: Glass.pageBackground,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );

  // ── Suggestions sheet ──────────────────────────────────────────────────────

  void _showSuggestionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            const SizedBox(height: 10),
            Container(width: 36, height: 4,
              decoration: BoxDecoration(
                color: Glass.textHint.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Text('Suggested Check-ups',
                    style: Glass.heading(size: 17, weight: FontWeight.w700)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Tap any suggestion to quickly add it to your schedule.',
                style: Glass.body(size: 12, color: Glass.textMuted)),
            ),
            Expanded(
              child: ListView.separated(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: kSuggestions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final s = kSuggestions[i];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showAddEditSheetWithSuggestion(s);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Glass.pageBackground,
                          borderRadius: BorderRadius.circular(14)),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12)),
                          alignment: Alignment.center,
                          child: Text(s.icon, style: const TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.title,
                                  style: Glass.body(size: 13, weight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(s.note,
                                  style: Glass.body(size: 11, color: Glass.textMuted)),
                            ]),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Glass.blue.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(s.frequency,
                              style: Glass.body(size: 9, weight: FontWeight.w600, color: Glass.blueDeep)),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showAddEditSheetWithSuggestion(CheckupSuggestion s) {
    final titleCtrl = TextEditingController(text: s.title);
    final notesCtrl = TextEditingController(text: s.note);
    DateTime selDate = DateTime.now();
    bool recurring = s.frequency == 'Monthly' || s.frequency == 'Yearly' ||
        s.frequency == 'Every 6 months' || s.frequency == 'Every 3 years' ||
        s.frequency == 'Every 2 years' || s.frequency == 'Every 5 years';
    String recurType = s.frequency == 'Monthly'
        ? 'monthly'
        : s.frequency == 'Yearly' || s.frequency == 'Every 3 years' ||
                s.frequency == 'Every 2 years' || s.frequency == 'Every 5 years'
            ? 'yearly'
            : 'none';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.96),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                        color: Glass.textHint.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 14),

                Row(children: [
                  Text(s.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Text('Add Check-up',
                      style: Glass.heading(size: 18, weight: FontWeight.w700)),
                ]),
                const SizedBox(height: 16),

                _label('Title'),
                _input(titleCtrl, 'Title'),
                const SizedBox(height: 12),
                _label('Notes (optional)'),
                _input(notesCtrl, 'Notes'),
                const SizedBox(height: 12),
                _label('Date'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(primary: Glass.blueDeep)),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setSheetState(() => selDate = picked);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                        color: Glass.pageBackground,
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: Glass.blueDeep),
                      const SizedBox(width: 8),
                      Text(_formatDate(selDate), style: Glass.body(size: 13, color: Glass.textMuted)),
                      const Spacer(),
                      Text('Change', style: Glass.body(size: 11, color: Glass.blueDeep)),
                    ]),
                  ),
                ),

                if (recurring) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                        color: Glass.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      Icon(Icons.repeat_rounded, size: 14, color: Glass.blueDeep),
                      const SizedBox(width: 8),
                      Text(
                          'Recommended: ${s.frequency} · set to '
                          '${recurType[0].toUpperCase()}${recurType.substring(1)}',
                          style: Glass.body(size: 11, color: Glass.blueDeep)),
                    ]),
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final title = titleCtrl.text.trim();
                            if (title.isEmpty) return;
                            setSheetState(() => isSaving = true);

                            final newCheckup = Checkup(
                              id: 0, // server assigns the real id
                              title: title,
                              notes: notesCtrl.text.trim().isEmpty
                                  ? 'Reminder'
                                  : notesCtrl.text.trim(),
                              date: selDate,
                              status: selDate.isBefore(DateTime(
                                      _today.year, _today.month, _today.day))
                                  ? 'overdue'
                                  : 'upcoming',
                              isRecurring: recurring,
                              recurringType:
                                  recurring ? recurType : 'none',
                            );
                            final ok = await _apiCreateCheckup(newCheckup);

                            if (!mounted) return;

                            if (ok) {
                              Navigator.pop(ctx);
                              _showSnack('Check-up added ✓', Glass.blueDeep);
                            } else {
                              setSheetState(() => isSaving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Glass.blueDeep,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Glass.blueDeep.withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text('Save',
                            style: Glass.body(
                                size: 15, weight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DAY CHECKUPS SHEET (when multiple checkups fall on same day)
// ─────────────────────────────────────────────────────────────────────────────

class _DayCheckupsSheet extends StatelessWidget {
  final List<Checkup> checkups;
  final void Function(Checkup) onTap;
  final Color Function(String) statusBg;
  final Color Function(String) statusColor;
  final String Function(String) statusLabel;
  final IconData Function(String) statusIcon;

  const _DayCheckupsSheet({
    required this.checkups,
    required this.onTap,
    required this.statusBg,
    required this.statusColor,
    required this.statusLabel,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
              color: Glass.textHint.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        Text('Check-ups this day',
            style: Glass.heading(size: 16, weight: FontWeight.w700)),
        const SizedBox(height: 14),
        ...checkups.map((c) {
          final col = statusColor(c.status);
          final bg = statusBg(c.status);
          return GestureDetector(
            onTap: () {
              Navigator.pop(context);
              onTap(c);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Glass.pageBackground,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: bg, borderRadius: BorderRadius.circular(10)),
                  child: Icon(statusIcon(c.status), color: col, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title, style: Glass.body(size: 13, weight: FontWeight.w700)),
                      Text(c.notes, style: Glass.body(size: 11, color: Glass.textMuted)),
                    ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: bg, borderRadius: BorderRadius.circular(10)),
                  child: Text(statusLabel(c.status),
                      style: Glass.body(size: 9, weight: FontWeight.w600, color: col)),
                ),
              ]),
            ),
          );
        }),
        const SizedBox(height: 6),
      ]),
    );
  }
}