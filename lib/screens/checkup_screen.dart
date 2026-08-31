import 'dart:math' as math;
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
// CHECKUP TYPE SUGGESTIONS
// ─────────────────────────────────────────────────────────────────────────────

class CheckupSuggestion {
  final String title;
  final String icon;
  final String frequency;
  final String note;
  const CheckupSuggestion({
    required this.title,
    required this.icon,
    required this.frequency,
    required this.note,
  });
}

const List<CheckupSuggestion> kSuggestions = [
  CheckupSuggestion(
    title: 'OB-GYN Consultation',
    icon: '👩‍⚕️',
    frequency: 'Yearly',
    note: 'Annual well-woman exam',
  ),
  CheckupSuggestion(
    title: 'Pap Smear',
    icon: '🔬',
    frequency: 'Every 3 years',
    note: 'Cervical cancer screening',
  ),
  CheckupSuggestion(
    title: 'Self Breast Exam',
    icon: '🎗️',
    frequency: 'Monthly',
    note: 'Best done after your period',
  ),
  CheckupSuggestion(
    title: 'Clinical Breast Exam',
    icon: '🏥',
    frequency: 'Yearly',
    note: 'By a healthcare professional',
  ),
  CheckupSuggestion(
    title: 'Blood Test',
    icon: '🩸',
    frequency: 'Yearly',
    note: 'CBC, iron, hormone levels',
  ),
  CheckupSuggestion(
    title: 'Hormone Panel',
    icon: '⚗️',
    frequency: 'As needed',
    note: 'Estrogen, progesterone, thyroid',
  ),
  CheckupSuggestion(
    title: 'Pelvic Ultrasound',
    icon: '📡',
    frequency: 'As advised',
    note: 'For PCOS or fibroid monitoring',
  ),
  CheckupSuggestion(
    title: 'STI Screening',
    icon: '🛡️',
    frequency: 'Yearly',
    note: 'Recommended for all active women',
  ),
  CheckupSuggestion(
    title: 'Blood Pressure Check',
    icon: '💓',
    frequency: 'Yearly',
    note: 'Track cardiovascular health',
  ),
  CheckupSuggestion(
    title: 'Dental Check-up',
    icon: '🦷',
    frequency: 'Every 6 months',
    note: 'Hormones affect gum health',
  ),
  CheckupSuggestion(
    title: 'Eye Exam',
    icon: '👁️',
    frequency: 'Every 2 years',
    note: 'Vision changes with hormones',
  ),
  CheckupSuggestion(
    title: 'Skin Check',
    icon: '🧴',
    frequency: 'Yearly',
    note: 'Dermatologist screening',
  ),
  CheckupSuggestion(
    title: 'Mental Health Check-in',
    icon: '🧠',
    frequency: 'As needed',
    note: 'Therapy or counseling session',
  ),
  CheckupSuggestion(
    title: 'Nutritionist Visit',
    icon: '🥗',
    frequency: 'As needed',
    note: 'For cycle & hormonal nutrition',
  ),
  CheckupSuggestion(
    title: 'Vitamin D Test',
    icon: '☀️',
    frequency: 'Yearly',
    note: 'Deficiency affects cycle health',
  ),
];

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
  int _selectedFilter = 0; // 0=All 1=Upcoming 2=Overdue 3=Done

  // ── Coach-mark tour targets ──
  final GlobalKey _calendarKey = GlobalKey();
  final GlobalKey _summaryKey = GlobalKey();
  final GlobalKey _filtersKey = GlobalKey();
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
        _Glass.pinkDeep,
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
            _Glass.pinkDeep);
        return false;
      }
    } catch (_) {
      _showSnack('Error connecting to FemCycle server',
          _Glass.pinkDeep);
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
            _Glass.pinkDeep);
        await _fetchCheckups(); // resync in case local state drifted
        return false;
      }
    } catch (_) {
      _showSnack('Error connecting to FemCycle server',
          _Glass.pinkDeep);
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
            _Glass.pinkDeep);
        _fetchCheckups();
      }
    } catch (_) {
      _showSnack('Error connecting to FemCycle server',
          _Glass.pinkDeep);
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
          targetKey: _calendarKey,
          title: 'Check-up calendar',
          description: 'Scheduled visits show up on their date here, color-coded by status.',
        ),
        CoachMarkStep(
          targetKey: _summaryKey,
          title: 'At a glance',
          description: 'A quick count of what\'s upcoming, overdue, or already done.',
        ),
        CoachMarkStep(
          targetKey: _filtersKey,
          title: 'Filter your list',
          description: 'Narrow the list below to just Upcoming, Overdue, or Done check-ups.',
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

  List<Checkup> get _filteredCheckups {
    final filters = ['', 'upcoming', 'overdue', 'done'];
    final f = filters[_selectedFilter];
    return _checkups
        .where((c) => f.isEmpty || c.status == f)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

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
      case 'overdue': return _Glass.pink.withOpacity(0.25);
      case 'done': return const Color(0xFF3BAF7E).withOpacity(0.18);
      default: return _Glass.blue.withOpacity(0.25);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'overdue': return _Glass.pinkDeep;
      case 'done': return const Color(0xFF1D9E75);
      default: return _Glass.blueDeep;
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
      _showSnack("Can't mark a future check-up as done yet", _Glass.pinkDeep);
      return;
    }
    setState(() => c.status = 'done');
    _showSnack('Marked as done ✓', const Color(0xFF1D9E75));
    _apiUpdateCheckup(c);
  }

  void _markUpcoming(Checkup c) {
    setState(() => c.status = 'upcoming');
    _showSnack('Restored to upcoming', _Glass.blueDeep);
    _apiUpdateCheckup(c);
  }

  void _delete(Checkup c) {
    setState(() => _checkups.remove(c));
    _showSnack('Deleted "${c.title}"', _Glass.pinkDeep);
    _apiDeleteCheckup(c.id);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: _Glass.body(size: 13, color: Colors.white)),
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
      backgroundColor: _Glass.pageBackground,
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientBackground()),
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
                        KeyedSubtree(key: _calendarKey, child: _buildCalendar()),
                        const SizedBox(height: 12),
                        KeyedSubtree(key: _summaryKey, child: _buildSummaryRow()),
                        const SizedBox(height: 14),
                        KeyedSubtree(key: _filtersKey, child: _buildFilterChips()),
                        const SizedBox(height: 10),
                        _buildCheckupList(),
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
    child: _Glass.card(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Expanded(
          child: Text('Check-up Scheduler',
              style: _Glass.heading(size: 16, weight: FontWeight.w600)),
        ),
        GestureDetector(
          onTap: _startCoachTour,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _Glass.blue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.question_mark_rounded, size: 15, color: _Glass.blueDeep),
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

    return _Glass.card(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        // Month nav
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_monthName(_currentMonth.month)} ${_currentMonth.year}',
                style: _Glass.body(size: 14, weight: FontWeight.w700)),
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
                          style: _Glass.body(size: 10, color: _Glass.textHint)),
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
            Color textColor = _Glass.textDark;
            Color dotColor = Colors.transparent;

            if (isToday) {
              bg = _Glass.blueDeep;
              textColor = Colors.white;
            } else if (isOverdue) {
              bg = _Glass.pink.withOpacity(0.25);
              textColor = _Glass.pinkDeep;
              dotColor = _Glass.pinkDeep;
            } else if (isCheckup) {
              bg = _Glass.blue.withOpacity(0.25);
              textColor = _Glass.blueDeep;
              dotColor = _Glass.blueDeep;
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
                        style: _Glass.body(
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
            _legendDot(_Glass.blueDeep, 'Check-up'),
            const SizedBox(width: 10),
            _legendDot(_Glass.pinkDeep, 'Overdue'),
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
        color: _Glass.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 16, color: _Glass.blueDeep),
    ),
  );

  Widget _legendDot(Color color, String label) => Row(children: [
    Container(width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: _Glass.body(size: 9, color: _Glass.textMuted)),
  ]);

  // ── Summary row ────────────────────────────────────────────────────────────

  Widget _buildSummaryRow() => Row(children: [
    _summaryCard('$_upcomingCount', 'Upcoming', _Glass.blueDeep),
    const SizedBox(width: 8),
    _summaryCard('$_overdueCount', 'Overdue', _Glass.pinkDeep),
    const SizedBox(width: 8),
    _summaryCard('$_doneCount', 'Done', const Color(0xFF1D9E75)),
  ]);

  Widget _summaryCard(String num, String label, Color color) => Expanded(
    child: _Glass.card(
      radius: 14,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(children: [
        Text(num, style: _Glass.heading(size: 22, weight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: _Glass.body(size: 10, color: _Glass.textMuted)),
      ]),
    ),
  );

  // ── Filter chips ───────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    const labels = ['All', 'Upcoming', 'Overdue', 'Done'];
    final colors = [
      _Glass.blueDeep, _Glass.blueDeep, _Glass.pinkDeep, const Color(0xFF1D9E75),
    ];
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final isOn = _selectedFilter == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isOn ? colors[i] : Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isOn ? colors[i] : Colors.white.withOpacity(0.7)),
              ),
              child: Text(labels[i],
                  style: _Glass.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: isOn ? Colors.white : _Glass.textMuted,
                  )),
            ),
          );
        },
      ),
    );
  }

  // ── Checkup list ───────────────────────────────────────────────────────────

  Widget _buildCheckupList() {
    final list = _filteredCheckups;
    if (list.isEmpty) return _buildEmptyState();
    return Column(
      children: list.map((c) => _buildCheckupCard(c)).toList(),
    );
  }

  Widget _buildEmptyState() => _Glass.card(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(children: [
      const Text('📋', style: TextStyle(fontSize: 40)),
      const SizedBox(height: 12),
      Text(
        _selectedFilter == 0
            ? 'No check-ups yet'
            : 'No ${['', 'upcoming', 'overdue', 'done'][_selectedFilter]} check-ups',
        style: _Glass.body(size: 15, color: _Glass.textMuted)),
      const SizedBox(height: 6),
      Text('Tap "Add Check-up" to schedule one',
          style: _Glass.body(size: 12, color: _Glass.textHint)),
    ]),
  );

  Widget _buildCheckupCard(Checkup checkup) {
    final bg = _statusBg(checkup.status);
    final col = _statusColor(checkup.status);
    final label = _statusLabel(checkup.status);

    return Dismissible(
      key: Key('checkup_${checkup.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _Glass.pinkDeep,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
            const SizedBox(height: 2),
            Text('Delete', style: _Glass.body(size: 10, color: Colors.white)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white.withOpacity(0.92),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Delete check-up?',
                style: _Glass.heading(size: 17, weight: FontWeight.w700)),
            content: Text('Remove "${checkup.title}" from your schedule?',
                style: _Glass.body(size: 13, color: _Glass.textMuted)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel', style: _Glass.body(color: _Glass.textMuted)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
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
        ) ?? false;
      },
      onDismissed: (_) => _delete(checkup),
      child: GestureDetector(
        onTap: () => _showCheckupDetailSheet(checkup),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: _Glass.card(
            radius: 14,
            padding: const EdgeInsets.all(12),
            opacity: 0.5,
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: col, width: 3)),
              ),
              padding: const EdgeInsets.only(left: 10),
              child: Row(children: [
                // Date box
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                      color: bg, borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${checkup.date.day}',
                          style: _Glass.heading(
                              size: 16, weight: FontWeight.w700, color: col).copyWith(height: 1)),
                      Text(_shortMonth(checkup.date.month),
                          style: _Glass.body(size: 9, weight: FontWeight.w600, color: col)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(checkup.title,
                              style: _Glass.body(size: 13, weight: FontWeight.w700)),
                        ),
                        if (checkup.isRecurring)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _Glass.blue.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.repeat_rounded, size: 9, color: _Glass.blueDeep),
                              const SizedBox(width: 2),
                              Text(checkup.recurringType[0].toUpperCase() +
                                  checkup.recurringType.substring(1),
                                  style: _Glass.body(size: 8, color: _Glass.blueDeep)),
                            ]),
                          ),
                      ]),
                      const SizedBox(height: 2),
                      Text(
                          checkup.time.isNotEmpty
                              ? '${checkup.time} · ${checkup.notes}'
                              : checkup.notes,
                          style: _Glass.body(size: 10, color: _Glass.textHint)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: bg, borderRadius: BorderRadius.circular(10)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(_statusIcon(checkup.status), size: 10, color: col),
                              const SizedBox(width: 3),
                              Text(label,
                                  style: _Glass.body(size: 9, weight: FontWeight.w600, color: col)),
                            ]),
                          ),
                          // Quick action — only offer "Mark done" once the
                          // appointment date has actually arrived.
                          if (checkup.status != 'done' &&
                              !_isFutureDate(checkup.date))
                            GestureDetector(
                              onTap: () => _markDone(checkup),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3BAF7E).withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.check_rounded, size: 10, color: Color(0xFF1D9E75)),
                                  const SizedBox(width: 3),
                                  Text('Mark done',
                                      style: _Glass.body(
                                          size: 9, weight: FontWeight.w600, color: const Color(0xFF1D9E75))),
                                ]),
                              ),
                            )
                          else if (checkup.status == 'done')
                            GestureDetector(
                              onTap: () => _markUpcoming(checkup),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _Glass.blue.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.undo_rounded, size: 10, color: _Glass.blueDeep),
                                  const SizedBox(width: 3),
                                  Text('Undo',
                                      style: _Glass.body(size: 9, weight: FontWeight.w600, color: _Glass.blueDeep)),
                                ]),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _Glass.textHint),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── Add button ─────────────────────────────────────────────────────────────

  Widget _buildAddButton() => SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton.icon(
      onPressed: () => _showAddEditSheet(null),
      icon: const Icon(Icons.add, color: Colors.white, size: 20),
      label: Text('Add Check-up',
          style: _Glass.body(size: 15, weight: FontWeight.w600, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _Glass.pinkDeep,
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
              color: _Glass.textHint.withOpacity(0.4),
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
                      style: _Glass.heading(size: 18, weight: FontWeight.w700, color: col).copyWith(height: 1)),
                  Text(_shortMonth(c.date.month),
                      style: _Glass.body(size: 10, weight: FontWeight.w600, color: col)),
                ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.title, style: _Glass.heading(size: 16, weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(c.notes, style: _Glass.body(size: 12, color: _Glass.textMuted)),
                ]),
            ),
          ]),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _Glass.pageBackground,
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
                label: Text('Edit', style: _Glass.body(size: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _Glass.blueDeep,
                  side: BorderSide(color: _Glass.blueDeep),
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
                      style: _Glass.body(size: 13, weight: FontWeight.w600, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.status != 'done' ? const Color(0xFF1D9E75) : _Glass.blueDeep,
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
                        style: _Glass.heading(size: 17, weight: FontWeight.w700)),
                    content: Text('Remove "${c.title}" from your schedule?',
                        style: _Glass.body(size: 13, color: _Glass.textMuted)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('Cancel', style: _Glass.body(color: _Glass.textMuted)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
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
                if (confirm == true && mounted) {
                  Navigator.pop(context);
                  _delete(c);
                }
              },
              icon: Icon(Icons.delete_outline_rounded, size: 16, color: _Glass.pinkDeep),
              label: Text('Delete check-up',
                  style: _Glass.body(size: 13, color: _Glass.pinkDeep)),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 8),
        ]),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? color}) =>
      Row(children: [
        Icon(icon, size: 14, color: color ?? _Glass.textMuted),
        const SizedBox(width: 8),
        Text(label, style: _Glass.body(size: 12, color: _Glass.textMuted)),
        const Spacer(),
        Text(value, style: _Glass.body(size: 12, weight: FontWeight.w600, color: color ?? _Glass.textDark)),
      ]);

  // ── Add / Edit sheet ───────────────────────────────────────────────────────

  void _showAddEditSheet(Checkup? existing) {
    final isEdit = existing != null;
    final titleCtrl =
        TextEditingController(text: isEdit ? existing.title : '');
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
                        color: _Glass.textHint.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(isEdit ? 'Edit Check-up' : 'New Check-up',
                      style: _Glass.heading(size: 18, weight: FontWeight.w700)),
                  const SizedBox(height: 16),

                  _label('Appointment Type'),
                  _input(titleCtrl, 'e.g. OB-GYN Consultation'),
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
                            colorScheme: ColorScheme.light(primary: _Glass.blueDeep),
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
                          color: _Glass.pageBackground,
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        Icon(Icons.calendar_today_outlined, size: 16, color: _Glass.blueDeep),
                        const SizedBox(width: 8),
                        Text(_formatDate(selDate), style: _Glass.body(size: 13, color: _Glass.textMuted)),
                        const Spacer(),
                        Text('Change', style: _Glass.body(size: 11, color: _Glass.blueDeep)),
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
                            colorScheme: ColorScheme.light(primary: _Glass.blueDeep),
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
                          color: _Glass.pageBackground,
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        Icon(Icons.access_time_rounded, size: 16, color: _Glass.blueDeep),
                        const SizedBox(width: 8),
                        Text(selTime.format(ctx),
                            style: _Glass.body(size: 13, color: _Glass.textMuted)),
                        const Spacer(),
                        Text('Change', style: _Glass.body(size: 11, color: _Glass.blueDeep)),
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
                              final title = titleCtrl.text.trim();
                              if (title.isEmpty) {
                                _showSnack('Please enter a title', _Glass.pinkDeep);
                                return;
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
                                  _Glass.blueDeep,
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
                        backgroundColor: _Glass.blueDeep,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _Glass.blueDeep.withOpacity(0.5),
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
                              style: _Glass.body(
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

  Widget _recurChip(String label, String value, String current,
      ValueChanged<String> onTap) {
    final isOn = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isOn ? _Glass.blueDeep : _Glass.pageBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isOn ? _Glass.blueDeep : _Glass.textHint.withOpacity(0.4)),
        ),
        child: Text(label,
            style: _Glass.body(
                size: 12, weight: FontWeight.w600, color: isOn ? Colors.white : _Glass.textMuted)),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text, style: _Glass.body(size: 12, color: _Glass.textHint)),
  );

  Widget _input(TextEditingController ctrl, String hint) => TextField(
    controller: ctrl,
    style: _Glass.body(size: 13, color: _Glass.textDark),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: _Glass.body(size: 13, color: _Glass.textHint),
      filled: true,
      fillColor: _Glass.pageBackground,
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
                color: _Glass.textHint.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Text('Suggested Check-ups',
                    style: _Glass.heading(size: 17, weight: FontWeight.w700)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Tap any suggestion to quickly add it to your schedule.',
                style: _Glass.body(size: 12, color: _Glass.textMuted)),
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
                          color: _Glass.pageBackground,
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
                                  style: _Glass.body(size: 13, weight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(s.note,
                                  style: _Glass.body(size: 11, color: _Glass.textMuted)),
                            ]),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: _Glass.blue.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(s.frequency,
                              style: _Glass.body(size: 9, weight: FontWeight.w600, color: _Glass.blueDeep)),
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
        s.frequency == 'Every 2 years';
    String recurType = s.frequency == 'Monthly'
        ? 'monthly'
        : s.frequency == 'Yearly' || s.frequency == 'Every 3 years' ||
                s.frequency == 'Every 2 years'
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
                        color: _Glass.textHint.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 14),

                Row(children: [
                  Text(s.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Text('Add Check-up',
                      style: _Glass.heading(size: 18, weight: FontWeight.w700)),
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
                            colorScheme: ColorScheme.light(primary: _Glass.blueDeep)),
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
                        color: _Glass.pageBackground,
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: _Glass.blueDeep),
                      const SizedBox(width: 8),
                      Text(_formatDate(selDate), style: _Glass.body(size: 13, color: _Glass.textMuted)),
                      const Spacer(),
                      Text('Change', style: _Glass.body(size: 11, color: _Glass.blueDeep)),
                    ]),
                  ),
                ),

                if (recurring) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                        color: _Glass.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      Icon(Icons.repeat_rounded, size: 14, color: _Glass.blueDeep),
                      const SizedBox(width: 8),
                      Text(
                          'Recommended: ${s.frequency} · set to '
                          '${recurType[0].toUpperCase()}${recurType.substring(1)}',
                          style: _Glass.body(size: 11, color: _Glass.blueDeep)),
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
                              _showSnack('Check-up added ✓', _Glass.blueDeep);
                            } else {
                              setSheetState(() => isSaving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Glass.blueDeep,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _Glass.blueDeep.withOpacity(0.5),
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
                            style: _Glass.body(
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
              color: _Glass.textHint.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        Text('Check-ups this day',
            style: _Glass.heading(size: 16, weight: FontWeight.w700)),
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
                  color: _Glass.pageBackground,
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
                      Text(c.title, style: _Glass.body(size: 13, weight: FontWeight.w700)),
                      Text(c.notes, style: _Glass.body(size: 11, color: _Glass.textMuted)),
                    ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: bg, borderRadius: BorderRadius.circular(10)),
                  child: Text(statusLabel(c.status),
                      style: _Glass.body(size: 9, weight: FontWeight.w600, color: col)),
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