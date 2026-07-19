import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

class Checkup {
  final int id;
  final String title;
  final String notes;
  final DateTime date;
  String status; // 'upcoming' | 'done' | 'overdue'
  final bool isRecurring;
  final String recurringType; // 'monthly' | 'quarterly' | 'yearly' | 'none'
  final String type; // icon key

  Checkup({
    required this.id,
    required this.title,
    required this.notes,
    required this.date,
    this.status = 'upcoming',
    this.isRecurring = false,
    this.recurringType = 'none',
    this.type = 'general',
  });

  Checkup copyWith({
    String? title,
    String? notes,
    DateTime? date,
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

  List<Checkup> _checkups = [
  ];

  bool _isLoading = true;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String apiUrl = 'http://127.0.0.1:8000/api/checkups'; // Laravel IP

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
      final response = await http.get(Uri.parse(apiUrl), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _checkups = data.map((json) => Checkup.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error connecting to FemCycle server')),
      );
    }
  }

  Future<void> _apiCreateCheckup(Checkup newCheckup) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(Uri.parse(apiUrl),
          headers: headers, body: json.encode(newCheckup.toJson()));
      if (response.statusCode == 201 || response.statusCode == 200) {
        _fetchCheckups();
      } else {
        _showSnack('Failed to save check-up (${response.statusCode})',
            const Color(0xFFE24B4A));
      }
    } catch (_) {
      _showSnack('Error connecting to FemCycle server',
          const Color(0xFFE24B4A));
    }
  }

  Future<void> _apiUpdateCheckup(Checkup updatedCheckup) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
          Uri.parse('$apiUrl/${updatedCheckup.id}'),
          headers: headers, body: json.encode(updatedCheckup.toJson()));
      if (response.statusCode == 200) {
        _fetchCheckups();
      } else {
        _showSnack('Failed to update check-up (${response.statusCode})',
            const Color(0xFFE24B4A));
        _fetchCheckups(); // resync in case local state drifted
      }
    } catch (_) {
      _showSnack('Error connecting to FemCycle server',
          const Color(0xFFE24B4A));
    }
  }

  Future<void> _apiDeleteCheckup(int id) async {
    try {
      final headers = await _getHeaders();
      final response =
          await http.delete(Uri.parse('$apiUrl/$id'), headers: headers);
      if (response.statusCode == 200 || response.statusCode == 204) {
        _fetchCheckups();
      } else {
        _showSnack('Failed to delete check-up (${response.statusCode})',
            const Color(0xFFE24B4A));
        _fetchCheckups();
      }
    } catch (_) {
      _showSnack('Error connecting to FemCycle server',
          const Color(0xFFE24B4A));
    }
  }

  @override
  void initState() {
  super.initState();
  _fetchCheckups();
    _currentMonth = DateTime(_today.year, _today.month);
    _autoMarkOverdue();
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

  static const List<int> _periodDays = [1, 2, 3, 4, 5];

  // ── Status colors ──────────────────────────────────────────────────────────

  Color _statusBg(String s) {
    switch (s) {
      case 'overdue': return const Color(0xFFFCEBEB);
      case 'done': return const Color(0xFFE1F5EE);
      default: return const Color(0xFFE4E8FE);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'overdue': return const Color(0xFFE24B4A);
      case 'done': return const Color(0xFF1D9E75);
      default: return const Color(0xFF185FA5);
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

  void _markDone(Checkup c) {
    setState(() => c.status = 'done');
    _showSnack('Marked as done ✓', const Color(0xFF1D9E75));
    _apiUpdateCheckup(c);
  }

  void _markUpcoming(Checkup c) {
    setState(() => c.status = 'upcoming');
    _showSnack('Restored to upcoming', const Color(0xFF84B2E9));
    _apiUpdateCheckup(c);
  }

  void _delete(Checkup c) {
    setState(() => _checkups.remove(c));
    _showSnack('Deleted "${c.title}"', const Color(0xFFE24B4A));
    _apiDeleteCheckup(c.id);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'Mallanna', fontSize: 13)),
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
      backgroundColor: const Color(0xFFFBF7F1),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCalendar(),
                    const SizedBox(height: 12),
                    _buildSummaryRow(),
                    const SizedBox(height: 14),
                    _buildFilterChips(),
                    const SizedBox(height: 10),
                    _buildCheckupList(),
                    const SizedBox(height: 14),
                    _buildAddButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar() => Container(
    color: const Color(0xFF84B2E9),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
        ),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Text('Check-up Scheduler',
          style: TextStyle(color: Colors.white, fontFamily: 'Mallanna',
              fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      GestureDetector(
        onTap: _showSuggestionsSheet,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.22),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: const Row(children: [
            Icon(Icons.lightbulb_outline_rounded,
                color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text('Suggest',
              style: TextStyle(fontFamily: 'Mallanna', fontSize: 12,
                  color: Colors.white, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ]),
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        // Month nav
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_monthName(_currentMonth.month)} ${_currentMonth.year}',
              style: const TextStyle(fontFamily: 'Mallanna', fontSize: 14,
                  fontWeight: FontWeight.w700, color: Color(0xFF333333))),
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
                        style: const TextStyle(fontSize: 10,
                            color: Color(0xFFAAAAAA),
                            fontWeight: FontWeight.w500)),
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
            final isPeriod = _periodDays.contains(day);
            final isOverdue = overdueDays.contains(day);
            final isCheckup = upcomingDays.contains(day);
            final isDone = doneDays.contains(day);

            Color bg = Colors.transparent;
            Color textColor = const Color(0xFF444444);
            Color dotColor = Colors.transparent;

            if (isToday) {
              bg = const Color(0xFF84B2E9);
              textColor = Colors.white;
            } else if (isOverdue) {
              bg = const Color(0xFFFCEBEB);
              textColor = const Color(0xFFE24B4A);
              dotColor = const Color(0xFFE24B4A);
            } else if (isCheckup) {
              bg = const Color(0xFFE4E8FE);
              textColor = const Color(0xFF185FA5);
              dotColor = const Color(0xFF84B2E9);
            } else if (isDone) {
              bg = const Color(0xFFE1F5EE);
              textColor = const Color(0xFF0F6E56);
              dotColor = const Color(0xFF1D9E75);
            } else if (isPeriod) {
              bg = const Color(0xFFFFEEF3);
              textColor = const Color(0xFFBC6B9C);
              dotColor = const Color(0xFFE96A8F);
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
                      style: TextStyle(fontSize: 11, color: textColor,
                          fontWeight: isToday
                              ? FontWeight.w700 : FontWeight.normal)),
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
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        const SizedBox(height: 8),

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendDot(const Color(0xFFE96A8F), 'Period'),
            const SizedBox(width: 10),
            _legendDot(const Color(0xFF84B2E9), 'Check-up'),
            const SizedBox(width: 10),
            _legendDot(const Color(0xFFE24B4A), 'Overdue'),
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
        color: const Color(0xFFE4E8FE),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 16, color: const Color(0xFF84B2E9)),
    ),
  );

  Widget _legendDot(Color color, String label) => Row(children: [
    Container(width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label,
      style: const TextStyle(fontSize: 9, color: Color(0xFF888888),
          fontFamily: 'Mallanna')),
  ]);

  // ── Summary row ────────────────────────────────────────────────────────────

  Widget _buildSummaryRow() => Row(children: [
    _summaryCard('$_upcomingCount', 'Upcoming', const Color(0xFF84B2E9)),
    const SizedBox(width: 8),
    _summaryCard('$_overdueCount', 'Overdue', const Color(0xFFE24B4A)),
    const SizedBox(width: 8),
    _summaryCard('$_doneCount', 'Done', const Color(0xFF1D9E75)),
  ]);

  Widget _summaryCard(String num, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(num,
          style: TextStyle(fontFamily: 'Mallanna', fontSize: 22,
              fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label,
          style: const TextStyle(fontFamily: 'Mallanna', fontSize: 10,
              color: Color(0xFF888888))),
      ]),
    ),
  );

  // ── Filter chips ───────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    const labels = ['All', 'Upcoming', 'Overdue', 'Done'];
    const colors = [
      Color(0xFF84B2E9), Color(0xFF84B2E9),
      Color(0xFFE24B4A), Color(0xFF1D9E75),
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
                color: isOn ? colors[i] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isOn ? colors[i] : const Color(0xFFDDE2F0)),
              ),
              child: Text(labels[i],
                style: TextStyle(
                  fontFamily: 'Mallanna', fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isOn ? Colors.white : const Color(0xFF888888))),
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

  Widget _buildEmptyState() => Container(
    padding: const EdgeInsets.symmetric(vertical: 40),
    alignment: Alignment.center,
    child: Column(children: [
      const Text('📋', style: TextStyle(fontSize: 40)),
      const SizedBox(height: 12),
      Text(
        _selectedFilter == 0
            ? 'No check-ups yet'
            : 'No ${['', 'upcoming', 'overdue', 'done'][_selectedFilter]} check-ups',
        style: const TextStyle(fontFamily: 'Mallanna', fontSize: 15,
            color: Color(0xFF888888))),
      const SizedBox(height: 6),
      const Text('Tap "Add Check-up" to schedule one',
        style: TextStyle(fontFamily: 'Mallanna', fontSize: 12,
            color: Color(0xFFAAAAAA))),
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
          color: const Color(0xFFE24B4A),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
            SizedBox(height: 2),
            Text('Delete', style: TextStyle(fontFamily: 'Mallanna',
                fontSize: 10, color: Colors.white)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete check-up?',
              style: TextStyle(fontFamily: 'Mallanna',
                  fontWeight: FontWeight.w700)),
            content: Text('Remove "${checkup.title}" from your schedule?',
              style: const TextStyle(fontFamily: 'Mallanna',
                  color: Color(0xFF666666))),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                  style: TextStyle(fontFamily: 'Mallanna',
                      color: Color(0xFF888888))),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE24B4A),
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
        ) ?? false;
      },
      onDismissed: (_) => _delete(checkup),
      child: GestureDetector(
        onTap: () => _showCheckupDetailSheet(checkup),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(color: col, width: 3),
            ),
          ),
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
                    style: TextStyle(fontFamily: 'Mallanna', fontSize: 16,
                        fontWeight: FontWeight.w700, color: col, height: 1)),
                  Text(_shortMonth(checkup.date.month),
                    style: TextStyle(fontFamily: 'Mallanna', fontSize: 9,
                        fontWeight: FontWeight.w600, color: col)),
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
                        style: const TextStyle(fontFamily: 'Mallanna',
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: Color(0xFF333333))),
                    ),
                    if (checkup.isRecurring)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE4E8FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.repeat_rounded,
                              size: 9, color: Color(0xFF84B2E9)),
                          const SizedBox(width: 2),
                          Text(checkup.recurringType[0].toUpperCase() +
                              checkup.recurringType.substring(1),
                            style: const TextStyle(fontFamily: 'Mallanna',
                                fontSize: 8, color: Color(0xFF185FA5))),
                        ]),
                      ),
                  ]),
                  const SizedBox(height: 2),
                  Text(checkup.notes,
                    style: const TextStyle(fontFamily: 'Mallanna',
                        fontSize: 10, color: Color(0xFFAAAAAA))),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: bg, borderRadius: BorderRadius.circular(10)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_statusIcon(checkup.status),
                              size: 10, color: col),
                          const SizedBox(width: 3),
                          Text(label,
                            style: TextStyle(fontFamily: 'Mallanna',
                                fontSize: 9, fontWeight: FontWeight.w600,
                                color: col)),
                        ]),
                      ),
                      // Quick action
                      if (checkup.status != 'done')
                        GestureDetector(
                          onTap: () => _markDone(checkup),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE1F5EE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                                mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.check_rounded,
                                  size: 10, color: Color(0xFF1D9E75)),
                              SizedBox(width: 3),
                              Text('Mark done',
                                style: TextStyle(fontFamily: 'Mallanna',
                                    fontSize: 9, fontWeight: FontWeight.w600,
                                    color: Color(0xFF1D9E75))),
                            ]),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () => _markUpcoming(checkup),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE4E8FE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                                mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.undo_rounded,
                                  size: 10, color: Color(0xFF185FA5)),
                              SizedBox(width: 3),
                              Text('Undo',
                                style: TextStyle(fontFamily: 'Mallanna',
                                    fontSize: 9, fontWeight: FontWeight.w600,
                                    color: Color(0xFF185FA5))),
                            ]),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: Color(0xFFCCCCCC)),
          ]),
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
      label: const Text('Add Check-up',
        style: TextStyle(fontFamily: 'Mallanna', fontSize: 15,
            fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE96A8F),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
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
                    style: TextStyle(fontFamily: 'Mallanna', fontSize: 18,
                        fontWeight: FontWeight.w700, color: col, height: 1)),
                  Text(_shortMonth(c.date.month),
                    style: TextStyle(fontFamily: 'Mallanna', fontSize: 10,
                        fontWeight: FontWeight.w600, color: col)),
                ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.title,
                    style: const TextStyle(fontFamily: 'Mallanna',
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 3),
                  Text(c.notes,
                    style: const TextStyle(fontFamily: 'Mallanna',
                        fontSize: 12, color: Color(0xFF888888))),
                ]),
            ),
          ]),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _detailRow(Icons.calendar_today_rounded,
                  'Date', _formatDate(c.date)),
              const SizedBox(height: 8),
              _detailRow(_statusIcon(c.status),
                  'Status', _statusLabel(c.status), color: col),
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
                label: const Text('Edit',
                  style: TextStyle(fontFamily: 'Mallanna', fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF84B2E9),
                  side: const BorderSide(color: Color(0xFF84B2E9)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
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
                  c.status != 'done'
                      ? Icons.check_circle_outline_rounded
                      : Icons.undo_rounded,
                  size: 16,
                ),
                label: Text(c.status != 'done' ? 'Mark done' : 'Undo',
                  style: const TextStyle(fontFamily: 'Mallanna',
                      fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.status != 'done'
                      ? const Color(0xFF1D9E75)
                      : const Color(0xFF84B2E9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Text('Delete check-up?',
                      style: TextStyle(fontFamily: 'Mallanna',
                          fontWeight: FontWeight.w700)),
                    content: Text('Remove "${c.title}" from your schedule?',
                      style: const TextStyle(fontFamily: 'Mallanna',
                          color: Color(0xFF666666))),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel',
                          style: TextStyle(fontFamily: 'Mallanna',
                              color: Color(0xFF888888))),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE24B4A),
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
                if (confirm == true && mounted) {
                  Navigator.pop(context);
                  _delete(c);
                }
              },
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 16, color: Color(0xFFE24B4A)),
              label: const Text('Delete check-up',
                style: TextStyle(fontFamily: 'Mallanna', fontSize: 13,
                    color: Color(0xFFE24B4A))),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 8),
        ]),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      {Color color = const Color(0xFF555555)}) =>
      Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text(label,
          style: const TextStyle(fontFamily: 'Mallanna', fontSize: 12,
              color: Color(0xFF888888))),
        const Spacer(),
        Text(value,
          style: TextStyle(fontFamily: 'Mallanna', fontSize: 12,
              fontWeight: FontWeight.w600, color: color)),
      ]);

  // ── Add / Edit sheet ───────────────────────────────────────────────────────

  void _showAddEditSheet(Checkup? existing) {
    final isEdit = existing != null;
    final titleCtrl =
        TextEditingController(text: isEdit ? existing.title : '');
    final notesCtrl =
        TextEditingController(text: isEdit ? existing.notes : '');
    DateTime selDate = isEdit ? existing.date : DateTime.now();
    bool recurring = isEdit ? existing.isRecurring : false;
    String recurType = isEdit ? existing.recurringType : 'none';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                        color: const Color(0xFFDDDDDD),
                        borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(isEdit ? 'Edit Check-up' : 'New Check-up',
                    style: const TextStyle(fontFamily: 'Mallanna',
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: Color(0xFF333333))),
                  const SizedBox(height: 16),

                  _label('Title'),
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
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF84B2E9)),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 16, color: Color(0xFF84B2E9)),
                        const SizedBox(width: 8),
                        Text(_formatDate(selDate),
                          style: const TextStyle(fontFamily: 'Mallanna',
                              fontSize: 13, color: Color(0xFF555555))),
                        const Spacer(),
                        const Text('Change',
                          style: TextStyle(fontFamily: 'Mallanna',
                              fontSize: 11, color: Color(0xFF84B2E9))),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Recurring toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.repeat_rounded,
                          size: 16, color: Color(0xFF84B2E9)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Recurring reminder',
                          style: TextStyle(fontFamily: 'Mallanna',
                              fontSize: 13, color: Color(0xFF555555))),
                      ),
                      Switch(
                        value: recurring,
                        onChanged: (v) =>
                            setSheetState(() {
                              recurring = v;
                              if (!v) recurType = 'none';
                            }),
                        activeColor: Colors.white,
                        activeTrackColor: const Color(0xFF84B2E9),
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: const Color(0xFFDDDDDD),
                      ),
                    ]),
                  ),

                  if (recurring) ...[
                    const SizedBox(height: 10),
                    _label('Repeat frequency'),
                    const SizedBox(height: 6),
                    Row(children: [
                      _recurChip('Monthly', 'monthly', recurType,
                              (v) => setSheetState(() => recurType = v)),
                      const SizedBox(width: 6),
                      _recurChip('Quarterly', 'quarterly', recurType,
                              (v) => setSheetState(() => recurType = v)),
                      const SizedBox(width: 6),
                      _recurChip('Yearly', 'yearly', recurType,
                              (v) => setSheetState(() => recurType = v)),
                    ]),
                  ],

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final title = titleCtrl.text.trim();
                        if (title.isEmpty) {
                          _showSnack('Please enter a title',
                              const Color(0xFFE24B4A));
                          return;
                        }
                        if (isEdit) {
                          final updated = existing.copyWith(
                            title: title,
                            notes: notesCtrl.text.trim().isEmpty
                                ? 'Reminder'
                                : notesCtrl.text.trim(),
                            date: selDate,
                            isRecurring: recurring,
                            recurringType:
                                recurring ? recurType : 'none',
                          );
                          _apiUpdateCheckup(updated);
                        } else {
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
                          _apiCreateCheckup(newCheckup);
                        }
                        Navigator.pop(ctx);
                        _showSnack(
                          isEdit
                              ? 'Check-up updated ✓'
                              : 'Check-up added ✓',
                          const Color(0xFF84B2E9),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF84B2E9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(isEdit ? 'Save Changes' : 'Save',
                        style: const TextStyle(fontFamily: 'Mallanna',
                            fontSize: 15, fontWeight: FontWeight.w600)),
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
          color: isOn ? const Color(0xFF84B2E9) : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOn
                ? const Color(0xFF84B2E9)
                : const Color(0xFFDDDDDD)),
        ),
        child: Text(label,
          style: TextStyle(fontFamily: 'Mallanna', fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isOn ? Colors.white : const Color(0xFF888888))),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text,
      style: const TextStyle(fontFamily: 'Mallanna', fontSize: 12,
          color: Color(0xFF888888))),
  );

  Widget _input(TextEditingController ctrl, String hint) => TextField(
    controller: ctrl,
    style: const TextStyle(fontFamily: 'Mallanna', fontSize: 13,
        color: Color(0xFF555555)),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontFamily: 'Mallanna', fontSize: 13,
          color: Color(0xFFCCCCCC)),
      filled: true,
      fillColor: const Color(0xFFF5F6FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 10),
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            const SizedBox(height: 10),
            Container(width: 36, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Text('Suggested Check-ups',
                  style: TextStyle(fontFamily: 'Mallanna', fontSize: 17,
                      fontWeight: FontWeight.w700, color: Color(0xFF333333))),
              ]),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Tap any suggestion to quickly add it to your schedule.',
                style: TextStyle(fontFamily: 'Mallanna', fontSize: 12,
                    color: Color(0xFF888888))),
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
                        color: const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(14)),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12)),
                          alignment: Alignment.center,
                          child: Text(s.icon,
                            style: const TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.title,
                                style: const TextStyle(
                                    fontFamily: 'Mallanna', fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF333333))),
                              const SizedBox(height: 2),
                              Text(s.note,
                                style: const TextStyle(
                                    fontFamily: 'Mallanna', fontSize: 11,
                                    color: Color(0xFF888888))),
                            ]),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4E8FE),
                            borderRadius: BorderRadius.circular(10)),
                          child: Text(s.frequency,
                            style: const TextStyle(
                                fontFamily: 'Mallanna', fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF185FA5))),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 14),

                Row(children: [
                  Text(s.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  const Text('Add Check-up',
                    style: TextStyle(fontFamily: 'Mallanna', fontSize: 18,
                        fontWeight: FontWeight.w700, color: Color(0xFF333333))),
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
                          colorScheme: const ColorScheme.light(
                              primary: Color(0xFF84B2E9))),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setSheetState(() => selDate = picked);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: Color(0xFF84B2E9)),
                      const SizedBox(width: 8),
                      Text(_formatDate(selDate),
                        style: const TextStyle(fontFamily: 'Mallanna',
                            fontSize: 13, color: Color(0xFF555555))),
                      const Spacer(),
                      const Text('Change',
                        style: TextStyle(fontFamily: 'Mallanna',
                            fontSize: 11, color: Color(0xFF84B2E9))),
                    ]),
                  ),
                ),

                if (recurring) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4E8FE),
                      borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.repeat_rounded,
                          size: 14, color: Color(0xFF84B2E9)),
                      const SizedBox(width: 8),
                      Text(
                        'Recommended: ${s.frequency} · set to '
                        '${recurType[0].toUpperCase()}${recurType.substring(1)}',
                        style: const TextStyle(fontFamily: 'Mallanna',
                            fontSize: 11, color: Color(0xFF185FA5))),
                    ]),
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) return;
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
                      _apiCreateCheckup(newCheckup);
                      Navigator.pop(ctx);
                      _showSnack('Check-up added ✓',
                          const Color(0xFF84B2E9));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF84B2E9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Save',
                      style: TextStyle(fontFamily: 'Mallanna',
                          fontSize: 15, fontWeight: FontWeight.w600)),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFDDDDDD),
            borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        const Text('Check-ups this day',
          style: TextStyle(fontFamily: 'Mallanna', fontSize: 16,
              fontWeight: FontWeight.w700, color: Color(0xFF333333))),
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
                color: const Color(0xFFF5F6FA),
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
                      Text(c.title,
                        style: const TextStyle(fontFamily: 'Mallanna',
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: Color(0xFF333333))),
                      Text(c.notes,
                        style: const TextStyle(fontFamily: 'Mallanna',
                            fontSize: 11, color: Color(0xFF888888))),
                    ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(10)),
                  child: Text(statusLabel(c.status),
                    style: TextStyle(fontFamily: 'Mallanna', fontSize: 9,
                        fontWeight: FontWeight.w600, color: col)),
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