import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'educational_screen.dart';
import 'lifestyle_screen.dart';
import 'profile_screen.dart';
import 'diary_screen.dart';
import 'mood_monitoring_screen.dart';
import 'checkup_screen.dart';
import '../theme/theme_provider.dart';
import '../services/api_service.dart'; // Imported your API service

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Holds one logged cycle entry per date
class _CycleEntry {
  int? id; // server-assigned id — null until saved once
  String flow;
  String energy;
  String mood;
  _CycleEntry({this.id, required this.flow, required this.energy, this.mood = 'Happy'});
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNav = 0;
  int _selectedPeriod = 0;
  int _selectedMood = -1;
  int _selectedEnergy = -1;

  // ── PROFILE STATE VARIABLES ──
  String _firstName = 'User';
  bool _isLoadingProfile = true;

  final DateTime _today = DateTime.now();
  DateTime _currentMonth = DateTime.now();

  // key = DateTime(year, month, day)  value = entry — populated from the API
  final Map<DateTime, _CycleEntry> _cycleEntries = {};
  bool _isLoadingCycles = true;

  // ── Prediction state — populated from GET /api/period-logs/predictions ────
  double? _avgCycleLength; // falls back to _assumedCycleLength until loaded
  String _confidence = 'insufficient_data';
  Map<String, dynamic>? _nextPredictedRange; // {earliest, latest}
  bool _isIrregular = false;
  Map<String, dynamic>? _pcosRisk;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _fetchPeriodLogs();
    _fetchPredictions();
  }

  Future<void> _loadProfile() async {
    try {
      final result = await ApiService.getProfile();
      if (mounted && result['success'] == true) {
        final user = result['user'];
        setState(() {
          _firstName = user['first_name'] ?? 'User';
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading home profile: $e');
    }
  }

  // ── Period-logs API ────────────────────────────────────────────────────────
  static const String _apiBase = 'https://glutinous-idealist-slit.ngrok-free.dev/api'; // Laravel IP
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    String? token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  Future<void> _fetchPeriodLogs() async {
    setState(() => _isLoadingCycles = true);
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(_apiBase), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final Map<DateTime, _CycleEntry> loaded = {};
        for (final row in data) {
          // 'date' comes back as a full ISO string (e.g. 2026-07-11T00:00:00.000000Z)
          final d = DateTime.parse(row['date']);
          final key = DateTime(d.year, d.month, d.day);
          loaded[key] = _CycleEntry(
            id: row['id'],
            flow: row['flow'] ?? 'Moderate',
            energy: row['energy'] ?? 'Energetic',
            mood: row['mood'] ?? 'Happy',
          );
        }
        if (!mounted) return;
        setState(() {
          _cycleEntries
            ..clear()
            ..addAll(loaded);
          _isLoadingCycles = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoadingCycles = false);
      }
    } catch (e) {
      debugPrint('Error fetching period logs: $e');
      if (!mounted) return;
      setState(() => _isLoadingCycles = false);
    }
  }

  Future<void> _fetchPredictions() async {
    try {
      final headers = await _getHeaders();
      final response =
          await http.get(Uri.parse('$_apiBase/predictions'), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          _avgCycleLength = (data['average_cycle_length'] as num?)?.toDouble();
          _confidence = data['confidence'] ?? 'insufficient_data';
          _nextPredictedRange = data['next_predicted_range'];
          _isIrregular = data['is_irregular'] ?? false;
          _pcosRisk = data['pcos_risk'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching predictions: $e');
    }
  }

  // Creates a new log, or updates one if this date already has a server id.
  Future<bool> _savePeriodLog(DateTime day, String flow, String energy,
      {String mood = 'Happy'}) async {
    try {
      final headers = await _getHeaders();
      final existingId = _cycleEntries[DateTime(day.year, day.month, day.day)]?.id;
      final body = json.encode({
        'date': DateTime(day.year, day.month, day.day).toIso8601String().split('T')[0],
        'flow': flow,
        'energy': energy,
        'mood': mood,
      });

      final response = existingId != null
          ? await http.put(Uri.parse('$_apiBase/$existingId'), headers: headers, body: body)
          : await http.post(Uri.parse(_apiBase), headers: headers, body: body);

      final ok = response.statusCode == 200 || response.statusCode == 201;
      if (ok) {
        await _fetchPeriodLogs();
        await _fetchPredictions(); // stats shift with every add/edit
      }
      return ok;
    } catch (e) {
      debugPrint('Error saving period log: $e');
      return false;
    }
  }

  Future<bool> _deletePeriodLog(DateTime day) async {
    try {
      final id = _cycleEntries[DateTime(day.year, day.month, day.day)]?.id;
      if (id == null) return false;
      final headers = await _getHeaders();
      final response =
          await http.delete(Uri.parse('$_apiBase/$id'), headers: headers);
      final ok = response.statusCode == 200 || response.statusCode == 204;
      if (ok) {
        await _fetchPeriodLogs();
        await _fetchPredictions();
      }
      return ok;
    } catch (e) {
      debugPrint('Error deleting period log: $e');
      return false;
    }
  }

  // Derived — days with logged entries this month
  List<int> get _periodDays => _cycleEntries.entries
      .where((e) =>
          e.key.year == _currentMonth.year &&
          e.key.month == _currentMonth.month)
      .map((e) => e.key.day)
      .toList();

  // Predicted days this month, derived from the API's next_predicted_range
  List<int> get _predictedDays {
    final range = _nextPredictedRange;
    if (range == null || range['earliest'] == null || range['latest'] == null) {
      return [];
    }
    final earliest = DateTime.parse(range['earliest']);
    final latest = DateTime.parse(range['latest']);
    final days = <int>[];
    for (var d = earliest; !d.isAfter(latest); d = d.add(const Duration(days: 1))) {
      if (d.year == _currentMonth.year && d.month == _currentMonth.month) {
        days.add(d.day);
      }
    }
    return days;
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  // ── Phase ring calculations ──────────────────────────────────────────────
  // 28 is only a placeholder until real history is loaded — once
  // _avgCycleLength comes back from the predictions endpoint, that real,
  // personalized number takes over everywhere below.
  static const int _assumedCycleLength = 28;
  static const int _assumedPeriodLength = 5;

  double get _effectiveCycleLength => _avgCycleLength ?? _assumedCycleLength.toDouble();

  DateTime? get _mostRecentPeriodStart {
    final loggedDates = _cycleEntries.keys
        .where((d) => !d.isAfter(_today))
        .toList()
      ..sort();
    if (loggedDates.isEmpty) return null;

    // Walk backwards to find the start of the most recent consecutive streak
    DateTime start = loggedDates.last;
    for (int i = loggedDates.length - 1; i > 0; i--) {
      final curr = loggedDates[i];
      final prev = loggedDates[i - 1];
      if (curr.difference(prev).inDays <= 2) {
        start = prev;
      } else {
        break;
      }
    }
    return start;
  }

  int get _cycleDay {
    final start = _mostRecentPeriodStart;
    if (start == null) return 1;
    final diff = _today.difference(start).inDays % _effectiveCycleLength.round();
    return diff + 1;
  }

  String get _currentPhaseLabel {
    final day = _cycleDay;
    if (day <= _assumedPeriodLength) return 'Menstrual phase';
    if (day <= 13) return 'Follicular phase';
    if (day <= 16) return 'Ovulation phase';
    return 'Luteal phase';
  }

  String get _phaseInsight {
    final day = _cycleDay;
    if (day <= _assumedPeriodLength) {
      return 'Energy is naturally lower right now — gentle movement and extra rest support your body best today.';
    } else if (day <= 13) {
      return 'Energy is building back up — a good window to ease into more active workouts.';
    } else if (day <= 16) {
      return 'Energy and confidence typically peak today — a good window for that harder workout.';
    }
    return 'Energy may dip and PMS symptoms can appear — be gentle with yourself and prioritize rest.';
  }

  // ── Phase ring widget ─────────────────────────────────────────────────────
  Widget _buildPhaseRingCard() {
    final day = _cycleDay;
    final phase = _currentPhaseLabel;
    final progress = (day / _effectiveCycleLength).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 168,
            height: 168,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(168, 168),
                  painter: _PhaseRingPainter(progress: progress),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontFamily: 'Mallanna',
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'days into cycle',
                      style: TextStyle(
                        fontFamily: 'Mallanna',
                        fontSize: 10.5,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE96A8F),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  phase,
                  style: const TextStyle(
                    fontFamily: 'Mallanna',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF84B2E9).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome,
                    size: 15, color: Color(0xFFE96A8F)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _phaseInsight,
                    style: TextStyle(
                      fontFamily: 'Mallanna',
                      fontSize: 11.5,
                      color: context.textSecondary,
                      height: 1.4,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPhaseRingCard(),
                    _buildCalendar(),
                    _buildLogSection(),
                  ],
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      color: const Color(0xFF84B2E9),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          // Avatar — tap to open Profile
          GestureDetector(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFE96A8F),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _firstName.isNotEmpty ? _firstName[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: context.cardColor,
                  fontFamily: 'Mallanna',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Greeting
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $_firstName!',
                style: TextStyle(
                  color: context.cardColor,
                  fontFamily: 'Mallanna',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                'Track your cycle today',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Mallanna',
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Notification bell
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ── Calendar ──────────────────────────────────────────────────────────────
  Widget _buildCalendar() {
    final monthName = _monthName(_currentMonth.month);
    final year = _currentMonth.year;
    final daysInMonth =
        DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Month header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$monthName $year',
                style: TextStyle(
                  fontFamily: 'Mallanna',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
              ),
              Row(
                children: [
                  _calNavBtn(Icons.chevron_left, _previousMonth),
                  const SizedBox(width: 4),
                  _calNavBtn(Icons.chevron_right, _nextMonth),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Day labels
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFAAAAAA),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          // Day grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.1,
            ),
            itemCount: firstWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstWeekday) return const SizedBox();
              final day = index - firstWeekday + 1;
              final isToday = _currentMonth.year == _today.year &&
                  _currentMonth.month == _today.month &&
                  day == _today.day;
              final isPeriod = _periodDays.contains(day);
              final isPredicted = _predictedDays.contains(day);

              Color bg = Colors.transparent;
              Color textColor = const Color(0xFF444444);

              if (isToday) {
                bg = const Color(0xFF84B2E9);
                textColor = Colors.white;
              } else if (isPeriod) {
                bg = const Color(0xFFFFEEF3);
                textColor = const Color(0xFFBC6B9C);
              } else if (isPredicted) {
                bg = const Color(0xFFE4E8FE);
                textColor = const Color(0xFF84B2E9);
              }

              return GestureDetector(
                onTap: () {
                  final tapped = DateTime(
                      _currentMonth.year, _currentMonth.month, day);
                  if (_cycleEntries.containsKey(tapped)) {
                    _showUpdateDeleteSheet(tapped);
                  } else {
                    _showAddCycleForDay(tapped);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor,
                      fontWeight:
                          isToday ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          // Legend
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(const Color(0xFFE96A8F), 'Period'),
              const SizedBox(width: 16),
              _legendItem(const Color(0xFF84B2E9), 'Today'),
              const SizedBox(width: 16),
              _legendItem(const Color(0xFFE4E8FE),
                  'Predicted', border: const Color(0xFF84B2E9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calNavBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: const Color(0xFFE4E8FE),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF84B2E9)),
      ),
    );
  }

  Widget _legendItem(Color color, String label, {Color? border}) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: border != null
                ? Border.all(color: border, width: 1)
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF888888),
            fontFamily: 'Mallanna',
          ),
        ),
      ],
    );
  }

  // ── Log Section ───────────────────────────────────────────────────────────
  Widget _buildLogSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period
          _sectionLabel('Period flow'),
          const SizedBox(height: 8),
          Row(
            children: [
              _periodBtn(0, 'Light', 0.35),
              _periodBtn(1, 'Moderate', 0.60),
              _periodBtn(2, 'Heavy', 0.85),
              _periodBtn(3, 'Super\nheavy', 1.0),
            ],
          ),
          const SizedBox(height: 14),

          // Mood
          _sectionLabel('Mood'),
          const SizedBox(height: 8),
          Row(
            children: [
              _moodBtn(0, 'Happy', _happyFace()),
              _moodBtn(1, 'Depressed', _depressedFace()),
              _moodBtn(2, 'Sad', _sadFace()),
              _moodBtn(3, 'Cry', _cryFace()),
            ],
          ),
          const SizedBox(height: 14),

          // Energy
          _sectionLabel('Energy'),
          const SizedBox(height: 8),
          Row(
            children: [
              _energyBtn(0, 'Exhausted', Icons.airline_seat_flat),
              _energyBtn(1, 'Tired', Icons.accessibility),
              _energyBtn(2, 'Energetic', Icons.directions_walk),
              _energyBtn(3, 'Fully\nenergetic', Icons.directions_run),
            ],
          ),
          const SizedBox(height: 20),

          // Save
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF84B2E9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  fontFamily: 'Mallanna',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Mallanna',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: context.textSecondary,
      ),
    );
  }

  Widget _periodBtn(int index, String label, double opacity) {
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE4E8FE) : context.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF84B2E9) : context.dividerColor,
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.water_drop,
                color: const Color(0xFF84B2E9).withOpacity(opacity),
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontFamily: 'Mallanna',
                  color: isSelected
                      ? const Color(0xFF185FA5)
                      : const Color(0xFF555555),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moodBtn(int index, String label, Widget face) {
    final isSelected = _selectedMood == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMood = index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF5EAF7) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFBC6B9C)
                  : const Color(0xFFE0E4F0),
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            children: [
              face,
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontFamily: 'Mallanna',
                  color: isSelected
                      ? const Color(0xFF72243E)
                      : const Color(0xFF555555),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _energyBtn(int index, String label, IconData icon) {
    final isSelected = _selectedEnergy == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedEnergy = index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE4E8FE) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF84B2E9)
                  : const Color(0xFFE0E4F0),
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: const Color(0xFF84B2E9),
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontFamily: 'Mallanna',
                  color: isSelected
                      ? const Color(0xFF185FA5)
                      : const Color(0xFF555555),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mood Face Widgets ─────────────────────────────────────────────────────
  Widget _happyFace() => _buildFace(mouthPath: 'happy');
  Widget _depressedFace() => _buildFace(mouthPath: 'flat');
  Widget _sadFace() => _buildFace(mouthPath: 'sad');
  Widget _cryFace() => _buildFace(mouthPath: 'sad', hasTears: true);

  Widget _buildFace({required String mouthPath, bool hasTears = false}) {
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(
        painter: _FacePainter(mouth: mouthPath, tears: hasTears),
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      color: context.cardColor,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.calendar_month_outlined, 'Cycle'),
          _navItem(1, Icons.book_outlined, 'Diary'),
          _navItem(2, Icons.sentiment_satisfied_outlined, 'Mood'),
          GestureDetector(
            onTap: _showAddPeriodSheet,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFE96A8F),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33E96A8F),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 26),
            ),
          ),
          _navItem(3, Icons.medical_services_outlined, 'Check-up'),
          _navItem(4, Icons.menu_book_outlined, 'Learn'),
          _navItem(5, Icons.self_improvement_outlined, 'Lifestyle'),
        ],
      ),
    );
  }

  void _onNavTap(int index) {
    switch (index) {
      case 1:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const DiaryScreen()));
        break;
      case 2:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => MoodMonitoringScreen(
              cycleEntries: _cycleEntries.map((date, entry) => MapEntry(
                date,
                CycleEntry(
                  flow: entry.flow,
                  energy: entry.energy,
                  mood: 'Happy',
                ),
              )),
            )));
        break;
      case 3:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CheckupScreen()));
        break;
      case 4:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const EducationalScreen()));
        break;
      case 5:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const LifestyleScreen()));
        break;
      default:
        setState(() => _selectedNav = index);
    }
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isActive = _selectedNav == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isActive
                ? const Color(0xFF84B2E9)
                : const Color(0xFFAAAAAA),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontFamily: 'Mallanna',
              color: isActive
                  ? const Color(0xFF84B2E9)
                  : const Color(0xFFAAAAAA),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Color _flowColor(String f) {
    switch (f) {
      case 'Light':  return const Color(0xFF84B2E9);
      case 'Moderate': return const Color(0xFFE96A8F);
      case 'Heavy':  return const Color(0xFFBC6B9C);
      default:       return const Color(0xFF993556);
    }
  }

  Color _energyColor(String e) {
    switch (e) {
      case 'Exhausted':     return const Color(0xFFE96A8F);
      case 'Tired':         return const Color(0xFFBC6B9C);
      case 'Energetic':     return const Color(0xFF84B2E9);
      default:              return const Color(0xFF4CAF7D);
    }
  }

  IconData _energyIcon(String e) {
    switch (e) {
      case 'Exhausted':     return Icons.airline_seat_flat;
      case 'Tired':         return Icons.accessibility;
      case 'Energetic':     return Icons.directions_walk;
      default:              return Icons.directions_run;
    }
  }

  // ── Add Cycle — called from + button ──────────────────────────────────────
  void _showAddPeriodSheet() {
    DateTime sheetMonth = DateTime(_today.year, _today.month);
    DateTime? pickedDay;
    String selectedFlow = 'Moderate';
    String selectedEnergy = 'Energetic';
    const flows = ['Light', 'Moderate', 'Heavy', 'Super Heavy'];
    const energies = ['Exhausted', 'Tired', 'Energetic', 'Fully Energetic'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final daysInMonth = DateUtils.getDaysInMonth(
              sheetMonth.year, sheetMonth.month);
          final firstWeekday =
              DateTime(sheetMonth.year, sheetMonth.month, 1).weekday % 7;
          const monthNames = [
            'January','February','March','April','May','June',
            'July','August','September','October','November','December'
          ];

          return _buildCycleSheet(
            ctx: ctx,
            setSheet: setSheet,
            title: 'Add Cycle',
            titleIcon: Icons.add_circle_outline,
            sheetMonth: sheetMonth,
            daysInMonth: daysInMonth,
            firstWeekday: firstWeekday,
            monthNames: monthNames,
            pickedDay: pickedDay,
            selectedFlow: selectedFlow,
            selectedEnergy: selectedEnergy,
            flows: flows,
            energies: energies,
            onPrevMonth: () => setSheet(() =>
                sheetMonth = DateTime(sheetMonth.year, sheetMonth.month - 1)),
            onNextMonth: () => setSheet(() =>
                sheetMonth = DateTime(sheetMonth.year, sheetMonth.month + 1)),
            onDayTap: (d) => setSheet(() => pickedDay = d),
            onFlowTap: (f) => setSheet(() => selectedFlow = f),
            onEnergyTap: (e) => setSheet(() => selectedEnergy = e),
            saveLabel: 'Save Cycle',
            canSave: pickedDay != null,
            onSave: () async {
              if (pickedDay == null) return;
              final saved = await _savePeriodLog(
                  pickedDay!, selectedFlow, selectedEnergy);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(saved
                    ? 'Cycle entry saved!'
                    : 'Could not save — check your connection.'),
                backgroundColor: saved
                    ? const Color(0xFFE96A8F)
                    : const Color(0xFFE24B4A),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ));
            },
          );
        },
      ),
    );
  }

  // ── Add Cycle — called from calendar tap on an unlogged day ──────────────
  void _showAddCycleForDay(DateTime day) {
    String selectedFlow = 'Moderate';
    String selectedEnergy = 'Energetic';
    const flows = ['Light', 'Moderate', 'Heavy', 'Super Heavy'];
    const energies = ['Exhausted', 'Tired', 'Energetic', 'Fully Energetic'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          const monthNames = [
            'January','February','March','April','May','June',
            'July','August','September','October','November','December'
          ];
          final label =
              '${monthNames[day.month - 1]} ${day.day}, ${day.year}';

          return _buildCycleSheet(
            ctx: ctx,
            setSheet: setSheet,
            title: 'Add Cycle',
            titleIcon: Icons.add_circle_outline,
            sheetMonth: DateTime(day.year, day.month),
            daysInMonth: DateUtils.getDaysInMonth(day.year, day.month),
            firstWeekday: DateTime(day.year, day.month, 1).weekday % 7,
            monthNames: monthNames,
            pickedDay: day,
            selectedFlow: selectedFlow,
            selectedEnergy: selectedEnergy,
            flows: flows,
            energies: energies,
            fixedDay: true,
            fixedDayLabel: label,
            onPrevMonth: () {},
            onNextMonth: () {},
            onDayTap: (_) {},
            onFlowTap: (f) => setSheet(() => selectedFlow = f),
            onEnergyTap: (e) => setSheet(() => selectedEnergy = e),
            saveLabel: 'Save Cycle',
            canSave: true,
            onSave: () async {
              final saved = await _savePeriodLog(day, selectedFlow, selectedEnergy);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(saved
                    ? 'Cycle entry saved!'
                    : 'Could not save — check your connection.'),
                backgroundColor: saved
                    ? const Color(0xFFE96A8F)
                    : const Color(0xFFE24B4A),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ));
            },
          );
        },
      ),
    );
  }

  // ── Update / Delete — called from calendar tap on a logged day ────────────
  void _showUpdateDeleteSheet(DateTime day) {
    final existing = _cycleEntries[day]!;
    String selectedFlow = existing.flow;
    String selectedEnergy = existing.energy;
    const flows = ['Light', 'Moderate', 'Heavy', 'Super Heavy'];
    const energies = ['Exhausted', 'Tired', 'Energetic', 'Fully Energetic'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          const monthNames = [
            'January','February','March','April','May','June',
            'July','August','September','October','November','December'
          ];
          final label =
              '${monthNames[day.month - 1]} ${day.day}, ${day.year}';

          return _buildCycleSheet(
            ctx: ctx,
            setSheet: setSheet,
            title: 'Update Cycle',
            titleIcon: Icons.edit_outlined,
            sheetMonth: DateTime(day.year, day.month),
            daysInMonth: DateUtils.getDaysInMonth(day.year, day.month),
            firstWeekday: DateTime(day.year, day.month, 1).weekday % 7,
            monthNames: monthNames,
            pickedDay: day,
            selectedFlow: selectedFlow,
            selectedEnergy: selectedEnergy,
            flows: flows,
            energies: energies,
            fixedDay: true,
            fixedDayLabel: label,
            onPrevMonth: () {},
            onNextMonth: () {},
            onDayTap: (_) {},
            onFlowTap: (f) => setSheet(() => selectedFlow = f),
            onEnergyTap: (e) => setSheet(() => selectedEnergy = e),
            saveLabel: 'Update Cycle',
            canSave: true,
            onSave: () async {
              final saved = await _savePeriodLog(day, selectedFlow, selectedEnergy);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(saved
                    ? 'Cycle entry updated!'
                    : 'Could not update — check your connection.'),
                backgroundColor: saved
                    ? const Color(0xFF84B2E9)
                    : const Color(0xFFE24B4A),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ));
            },
            onDelete: () {
              Navigator.pop(ctx);
              _confirmDelete(day);
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(DateTime day) {
    const monthNames = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    final label = '${monthNames[day.month - 1]} ${day.day}, ${day.year}';

    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Entry',
            style: TextStyle(
                fontFamily: 'Mallanna', fontWeight: FontWeight.w700)),
        content: Text(
          'Delete the cycle entry for $label? This cannot be undone.',
          style: const TextStyle(
              fontFamily: 'Mallanna', color: Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Cancel',
                style: TextStyle(
                    fontFamily: 'Mallanna', color: Color(0xFF888888))),
          ),
          ElevatedButton(
            onPressed: () async {
              final deleted = await _deletePeriodLog(day);
              Navigator.pop(dCtx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(deleted
                    ? 'Cycle entry deleted.'
                    : 'Could not delete — check your connection.'),
                backgroundColor: deleted
                    ? const Color(0xFFE96A8F)
                    : const Color(0xFFE24B4A),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ));
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

  // ── Shared sheet builder ──────────────────────────────────────────────────
  Widget _buildCycleSheet({
    required BuildContext ctx,
    required StateSetter setSheet,
    required String title,
    required IconData titleIcon,
    required DateTime sheetMonth,
    required int daysInMonth,
    required int firstWeekday,
    required List<String> monthNames,
    required DateTime? pickedDay,
    required String selectedFlow,
    required String selectedEnergy,
    required List<String> flows,
    required List<String> energies,
    bool fixedDay = false,
    String? fixedDayLabel,
    required VoidCallback onPrevMonth,
    required VoidCallback onNextMonth,
    required ValueChanged<DateTime> onDayTap,
    required ValueChanged<String> onFlowTap,
    required ValueChanged<String> onEnergyTap,
    required String saveLabel,
    required bool canSave,
    required VoidCallback onSave,
    VoidCallback? onDelete,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEF3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(titleIcon,
                      color: const Color(0xFFE96A8F), size: 18),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                      fontFamily: 'Mallanna',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    )),
                const Spacer(),
                if (onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEEF3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline,
                              color: Color(0xFFE96A8F), size: 15),
                          SizedBox(width: 4),
                          Text('Delete',
                              style: TextStyle(
                                fontFamily: 'Mallanna',
                                fontSize: 12,
                                color: Color(0xFFE96A8F),
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            if (fixedDay && fixedDayLabel != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEF3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE96A8F)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 13, color: Color(0xFFE96A8F)),
                    const SizedBox(width: 6),
                    Text(fixedDayLabel,
                        style: const TextStyle(
                          fontFamily: 'Mallanna',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE96A8F),
                        )),
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: pickedDay != null
                      ? const Color(0xFFFFEEF3)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: pickedDay != null
                        ? const Color(0xFFE96A8F)
                        : const Color(0xFFEEEEEE),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.water_drop,
                        size: 13,
                        color: pickedDay != null
                            ? const Color(0xFFE96A8F)
                            : const Color(0xFFBBBBBB)),
                    const SizedBox(width: 6),
                    Text(
                      pickedDay != null
                          ? '${monthNames[pickedDay!.month - 1]} ${pickedDay!.day}  •  tap again to change'
                          : 'Tap a day to select',
                      style: TextStyle(
                        fontFamily: 'Mallanna',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: pickedDay != null
                            ? const Color(0xFFE96A8F)
                            : const Color(0xFFBBBBBB),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.bgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: onPrevMonth,
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.chevron_left,
                                size: 18, color: Color(0xFF84B2E9)),
                          ),
                        ),
                        Text(
                          '${monthNames[sheetMonth.month - 1]} ${sheetMonth.year}',
                          style: TextStyle(
                            fontFamily: 'Mallanna',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: onNextMonth,
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.chevron_right,
                                size: 18, color: Color(0xFF84B2E9)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: ['S','M','T','W','T','F','S']
                          .map((d) => Expanded(
                                child: Center(
                                  child: Text(d,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFFAAAAAA),
                                        fontWeight: FontWeight.w600,
                                      )),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 6),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: firstWeekday + daysInMonth,
                      itemBuilder: (_, index) {
                        if (index < firstWeekday) return const SizedBox();
                        final day = index - firstWeekday + 1;
                        final d = DateTime(
                            sheetMonth.year, sheetMonth.month, day);
                        final isPicked = pickedDay != null &&
                            d.year == pickedDay!.year &&
                            d.month == pickedDay!.month &&
                            d.day == pickedDay!.day;
                        final isToday = d.year == _today.year &&
                            d.month == _today.month &&
                            d.day == _today.day;
                        final isLogged = _cycleEntries.containsKey(d);

                        Color bg;
                        Color txt;
                        if (isPicked) {
                          bg = const Color(0xFFE96A8F);
                          txt = Colors.white;
                        } else if (isLogged) {
                          bg = const Color(0xFFFFEEF3);
                          txt = const Color(0xFFE96A8F);
                        } else if (isToday) {
                          bg = const Color(0xFF84B2E9).withOpacity(0.2);
                          txt = const Color(0xFF84B2E9);
                        } else {
                          bg = Colors.transparent;
                          txt = context.textPrimary;
                        }

                        return GestureDetector(
                          onTap: () => onDayTap(d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                                color: bg, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text('$day',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isPicked
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  color: txt,
                                )),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            _sheetSectionLabel('Period Flow'),
            const SizedBox(height: 8),
            Row(
              children: flows.map((f) {
                final sel = selectedFlow == f;
                final fc = _flowColor(f);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onFlowTap(f),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? fc.withOpacity(0.12)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? fc : const Color(0xFFEEEEEE),
                          width: sel ? 1.5 : 0.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.water_drop, size: 18, color: fc),
                          const SizedBox(height: 3),
                          Text(f,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Mallanna',
                                fontSize: 9,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: fc,
                              )),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            _sheetSectionLabel('Energy Level'),
            const SizedBox(height: 8),
            Row(
              children: energies.map((e) {
                final sel = selectedEnergy == e;
                final ec = _energyColor(e);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onEnergyTap(e),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? ec.withOpacity(0.12)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? ec : const Color(0xFFEEEEEE),
                          width: sel ? 1.5 : 0.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(_energyIcon(e), size: 18, color: ec),
                          const SizedBox(height: 3),
                          Text(e,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Mallanna',
                                fontSize: 9,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: ec,
                              )),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: canSave ? onSave : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE96A8F),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFFE96A8F).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(saveLabel,
                    style: const TextStyle(
                      fontFamily: 'Mallanna',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetSectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'Mallanna',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF888888),
        ),
      );

  // ── Save Handler ──────────────────────────────────────────────────────────
  // Maps the index-based selections from the Period/Mood/Energy panel to the
  // same string values used everywhere else in the app, and actually saves
  // them for today — this used to just show a toast and save nothing at all.
  static const List<String> _logFlowOptions = ['Light', 'Moderate', 'Heavy', 'Super Heavy'];
  static const List<String> _logMoodOptions = ['Happy', 'Depressed', 'Sad', 'Cry'];
  static const List<String> _logEnergyOptions = ['Exhausted', 'Tired', 'Energetic', 'Fully Energetic'];

  void _handleSave() async {
    if (_selectedEnergy == -1) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Pick an energy level first.'),
        backgroundColor: const Color(0xFFE24B4A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    final flow = _logFlowOptions[_selectedPeriod];
    final energy = _logEnergyOptions[_selectedEnergy];
    final mood = _selectedMood == -1 ? 'Happy' : _logMoodOptions[_selectedMood];

    final saved = await _savePeriodLog(_today, flow, energy, mood: mood);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved
            ? 'Cycle log saved!'
            : 'Could not save — check your connection.'),
        backgroundColor: saved
            ? const Color(0xFF84B2E9)
            : const Color(0xFFE24B4A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

// ── Phase Ring Painter ────────────────────────────────────────────────────────
class _PhaseRingPainter extends CustomPainter {
  final double progress;

  _PhaseRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;
    const strokeWidth = 13.0;

    final trackPaint = Paint()
      ..color = const Color(0xFFE4E8FE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final bluePaint = Paint()
      ..color = const Color(0xFF84B2E9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * 3.14159265 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159265 / 2,
      sweepAngle,
      false,
      bluePaint,
    );

    final pinkPaint = Paint()
      ..color = const Color(0xFFE96A8F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const fertileStart = 12 / 28;
    const fertileEnd = 16 / 28;
    final fertileStartAngle =
        (-3.14159265 / 2) + (2 * 3.14159265 * fertileStart);
    final fertileSweep =
        2 * 3.14159265 * (fertileEnd - fertileStart);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      fertileStartAngle,
      fertileSweep,
      false,
      pinkPaint,
    );
  }

  @override
  bool shouldRepaint(_PhaseRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ── Face Painter ─────────────────────────────────────────────────────────────
class _FacePainter extends CustomPainter {
  final String mouth;
  final bool tears;

  _FacePainter({required this.mouth, this.tears = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBC6B9C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1;

    canvas.drawCircle(Offset(cx, cy), r, paint);

    final eyePaint = Paint()
      ..color = const Color(0xFFBC6B9C)
      ..style = PaintingStyle.fill;

    if (mouth == 'sad') {
      final xPaint = Paint()
        ..color = const Color(0xFFBC6B9C)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
          Offset(cx - 6, cy - 5), Offset(cx - 3, cy - 2), xPaint);
      canvas.drawLine(
          Offset(cx - 3, cy - 5), Offset(cx - 6, cy - 2), xPaint);
      canvas.drawLine(
          Offset(cx + 3, cy - 5), Offset(cx + 6, cy - 2), xPaint);
      canvas.drawLine(
          Offset(cx + 6, cy - 5), Offset(cx + 3, cy - 2), xPaint);
    } else {
      canvas.drawCircle(Offset(cx - 4.5, cy - 3), 1.5, eyePaint);
      canvas.drawCircle(Offset(cx + 4.5, cy - 3), 1.5, eyePaint);
    }

    final mouthPath = Path();
    if (mouth == 'happy') {
      mouthPath.moveTo(cx - 5, cy + 2);
      mouthPath.quadraticBezierTo(cx, cy + 7, cx + 5, cy + 2);
    } else if (mouth == 'flat') {
      mouthPath.moveTo(cx - 5, cy + 4);
      mouthPath.quadraticBezierTo(cx, cy + 2, cx + 5, cy + 4);
    } else {
      mouthPath.moveTo(cx - 5, cy + 5);
      mouthPath.quadraticBezierTo(cx, cy + 1, cx + 5, cy + 5);
    }
    canvas.drawPath(mouthPath, paint);

    if (tears) {
      final tearPaint = Paint()
        ..color = const Color(0xFF84B2E9)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx - 6, cy + 1), width: 3, height: 5),
          tearPaint);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx + 6, cy + 1), width: 3, height: 5),
          tearPaint);
    }
  }

  @override
  bool shouldRepaint(_FacePainter oldDelegate) =>
      oldDelegate.mouth != mouth || oldDelegate.tears != tears;
}