import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'educational_screen.dart';
import 'lifestyle_screen.dart';
import 'profile_screen.dart';
import 'diary_screen.dart';
import 'mood_monitoring_screen.dart';
import 'checkup_screen.dart';
import '../theme/theme_provider.dart';
import '../services/api_service.dart'; // Imported your API service
import 'health_profile_screen.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/coach_mark_overlay.dart';
import '../services/tutorial_storage_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HomeScreen extends StatefulWidget {
  final bool autoOpenAddSheet;
  const HomeScreen({super.key, this.autoOpenAddSheet = false});

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

  // ── Coach-mark tour targets ──
  final GlobalKey _avatarKey = GlobalKey();
  final GlobalKey _calendarKey = GlobalKey();
  final GlobalKey _addCycleKey = GlobalKey();

  final FlutterLocalNotificationsPlugin _testNotifications =
    FlutterLocalNotificationsPlugin();

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
  Map<String, dynamic>? _cycleHealthSignals;
  bool _healthBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _fetchPeriodLogs();
    _fetchPredictions();
    if (widget.autoOpenAddSheet) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showAddPeriodSheet());
    }
    _maybeShowCoachTour();
  }

  Future<void> _maybeShowCoachTour() async {
    final seen = await TutorialStorageService.hasSeenTour(TutorialStorageService.home);
    if (seen || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCoachTour());
  }

  void _startCoachTour() {
    showCoachMarkTour(
      context: context,
      steps: [
        CoachMarkStep(
          targetKey: _avatarKey,
          title: 'Your profile',
          description: 'Tap your avatar anytime to view or edit your profile and settings.',
          isCircle: true,
          highlightPadding: const EdgeInsets.all(4),
        ),
        CoachMarkStep(
          targetKey: _calendarKey,
          title: 'Your cycle calendar',
          description:
              'Logged days, today, and your predicted period all show up here at a glance. Tap any day to log or edit it.',
        ),
        CoachMarkStep(
          targetKey: _addCycleKey,
          title: 'Log a new day',
          description: 'Tap here to record flow, energy, and mood for today or any past date.',
        ),
      ],
    ).then((_) => TutorialStorageService.markTourSeen(TutorialStorageService.home));
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
  static const String _apiBase = 'https://femcycleapp-production.up.railway.app/api/period-logs'; // Laravel IP
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
          _cycleHealthSignals = data['cycle_health_signals'];
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

  // ── Health profile reminder banner ────────────────────────────────────────
  // Just a nudge to go fill out / answer the Health Profile symptoms
  // questionnaire — not tied to any prediction data. Shows until the user
  // dismisses it (or you wire in a real "already completed" check from the
  // backend) and taps through to HealthProfileScreen.
  Widget _buildHealthProfileBanner() {
    if (_healthBannerDismissed) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HealthProfileScreen()),
          );
        },
        child: _Glass.card(
          radius: 20,
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFC6ACFF).withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.health_and_safety_outlined,
                    color: _Glass.purpleDeep, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Don't forget to complete your health profile!",
                      style: _Glass.heading(size: 13.5, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A few quick questions about your symptoms helps us '
                      'personalize your insights.',
                      style: _Glass.body(size: 11.5, color: _Glass.textMuted)
                          .copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Complete it now',
                          style: _Glass.body(
                              size: 11.5, weight: FontWeight.w700, color: _Glass.blueDeep),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 12, color: _Glass.blueDeep),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _healthBannerDismissed = true),
                child: Icon(Icons.close, size: 16, color: _Glass.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Phase ring widget ─────────────────────────────────────────────────────
  Widget _buildPhaseRingCard() {
    final day = _cycleDay;
    final phase = _currentPhaseLabel;
    final progress = (day / _effectiveCycleLength).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: _Glass.card(
        radius: 22,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
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
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_Glass.pinkDeep, _Glass.purpleDeep]),
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
                    style: _Glass.body(size: 11.5, weight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _Glass.blue.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome, size: 15, color: _Glass.pinkDeep),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _phaseInsight,
                      style: _Glass.body(size: 11.5, color: _Glass.textMuted).copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                    child: Column(
                    children: [
                      _buildHealthProfileBanner(),
                      KeyedSubtree(key: _calendarKey, child: _buildCalendar()),
                      KeyedSubtree(key: _addCycleKey, child: _buildAddCycleButton()),
                    ],
                  ),
                  ),
                ),
               AppBottomNav(
                  currentIndex: 2,
                  onAddPressed: _showAddPeriodSheet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: _Glass.card(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Avatar — tap to open Profile
            GestureDetector(
              key: _avatarKey,
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_Glass.pinkDeep, _Glass.purpleDeep]),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _firstName.isNotEmpty ? _firstName[0].toUpperCase() : 'U',
                  style: _Glass.body(size: 16, weight: FontWeight.w600, color: Colors.white),
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
                  style: _Glass.heading(size: 14, weight: FontWeight.w600),
                ),
                Text(
                  'Track your cycle today',
                  style: _Glass.body(size: 11, color: _Glass.textMuted),
                ),
              ],
            ),
            const Spacer(),
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
          ],
        ),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: _Glass.card(
        radius: 18,
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // Month header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$monthName $year',
                  style: _Glass.body(size: 14, weight: FontWeight.w700),
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
                          style: _Glass.body(size: 10, weight: FontWeight.w500, color: _Glass.textHint),
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
                Color textColor = _Glass.textDark;

                if (isToday) {
                  bg = _Glass.blueDeep;
                  textColor = Colors.white;
                } else if (isPeriod) {
                  bg = _Glass.pink.withOpacity(0.25);
                  textColor = _Glass.pinkDeep;
                } else if (isPredicted) {
                  bg = _Glass.blue.withOpacity(0.22);
                  textColor = _Glass.blueDeep;
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
                      style: _Glass.body(
                        size: 11,
                        color: textColor,
                        weight: isToday ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            // Legend
            Divider(height: 1, color: Colors.white.withOpacity(0.6)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendItem(_Glass.pinkDeep, 'Period'),
                const SizedBox(width: 16),
                _legendItem(_Glass.blueDeep, 'Today'),
                const SizedBox(width: 16),
                _legendItem(_Glass.blue.withOpacity(0.3),
                    'Predicted', border: _Glass.blueDeep),
              ],
            ),
          ],
        ),
      ),
    );
  }

    Widget _buildAddCycleButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _showAddPeriodSheet,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'Add Cycle',
            style: _Glass.heading(size: 15, weight: FontWeight.w600, color: Colors.white),
          ),
          style: _Glass.primaryButtonStyle(),
        ),
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
          color: _Glass.blue.withOpacity(0.25),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: _Glass.blueDeep),
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
          style: _Glass.body(size: 10, color: _Glass.textMuted),
        ),
      ],
    );
  }

  // ── Log Section ───────────────────────────────────────────────────────────
  Widget _buildLogSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: _Glass.card(
        radius: 20,
        padding: const EdgeInsets.all(16),
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
                style: _Glass.primaryButtonStyle(),
                child: Text(
                  'Save',
                  style: _Glass.heading(size: 16, weight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: _Glass.body(size: 13, weight: FontWeight.w700, color: _Glass.textMuted),
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
            color: isSelected ? _Glass.blue.withOpacity(0.25) : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _Glass.blueDeep : Colors.white.withOpacity(0.6),
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.water_drop,
                color: _Glass.blueDeep.withOpacity(opacity),
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: _Glass.body(
                  size: 9,
                  color: isSelected ? _Glass.blueDeep : _Glass.textMuted,
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
            color: isSelected ? _Glass.purple.withOpacity(0.25) : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _Glass.purpleDeep : Colors.white.withOpacity(0.6),
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
                style: _Glass.body(
                  size: 9,
                  color: isSelected ? _Glass.purpleDeep : _Glass.textMuted,
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
            color: isSelected ? _Glass.blue.withOpacity(0.25) : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _Glass.blueDeep : Colors.white.withOpacity(0.6),
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: _Glass.blueDeep,
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: _Glass.body(
                  size: 9,
                  color: isSelected ? _Glass.blueDeep : _Glass.textMuted,
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

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Color _flowColor(String f) {
    switch (f) {
      case 'Light':  return _Glass.blueDeep;
      case 'Moderate': return _Glass.pinkDeep;
      case 'Heavy':  return _Glass.purpleDeep;
      default:       return const Color(0xFF8A2E4E);
    }
  }

  Color _energyColor(String e) {
    switch (e) {
      case 'Exhausted':     return _Glass.pinkDeep;
      case 'Tired':         return _Glass.purpleDeep;
      case 'Energetic':     return _Glass.blueDeep;
      default:              return const Color(0xFF3BAF7E);
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
                    : 'Could not save — check your connection.',
                    style: _Glass.body(color: Colors.white)),
                backgroundColor: saved ? _Glass.pinkDeep : const Color(0xFFE24B4A),
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
                    : 'Could not save — check your connection.',
                    style: _Glass.body(color: Colors.white)),
                backgroundColor: saved ? _Glass.pinkDeep : const Color(0xFFE24B4A),
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
                    : 'Could not update — check your connection.',
                    style: _Glass.body(color: Colors.white)),
                backgroundColor: saved ? _Glass.blueDeep : const Color(0xFFE24B4A),
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
        backgroundColor: Colors.white.withOpacity(0.92),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Entry',
            style: _Glass.heading(size: 17, weight: FontWeight.w700)),
        content: Text(
          'Delete the cycle entry for $label? This cannot be undone.',
          style: _Glass.body(size: 14, color: _Glass.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text('Cancel', style: _Glass.body(color: _Glass.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final deleted = await _deletePeriodLog(day);
              Navigator.pop(dCtx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(deleted
                    ? 'Cycle entry deleted.'
                    : 'Could not delete — check your connection.',
                    style: _Glass.body(color: Colors.white)),
                backgroundColor: deleted ? _Glass.pinkDeep : const Color(0xFFE24B4A),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _Glass.pinkDeep,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text('Delete', style: _Glass.body(color: Colors.white)),
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
        color: Colors.white.withOpacity(0.96),
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
                  color: _Glass.textHint.withOpacity(0.4),
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
                    color: _Glass.pink.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(titleIcon, color: _Glass.pinkDeep, size: 18),
                ),
                const SizedBox(width: 10),
                Text(title, style: _Glass.heading(size: 17, weight: FontWeight.w700)),
                const Spacer(),
                if (onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _Glass.pink.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: _Glass.pinkDeep, size: 15),
                          const SizedBox(width: 4),
                          Text('Delete',
                              style: _Glass.body(
                                  size: 12, weight: FontWeight.w600, color: _Glass.pinkDeep)),
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
                  color: _Glass.pink.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _Glass.pinkDeep),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 13, color: _Glass.pinkDeep),
                    const SizedBox(width: 6),
                    Text(fixedDayLabel,
                        style: _Glass.body(
                            size: 13, weight: FontWeight.w600, color: _Glass.pinkDeep)),
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
                      ? _Glass.pink.withOpacity(0.18)
                      : _Glass.pageBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: pickedDay != null ? _Glass.pinkDeep : _Glass.textHint.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.water_drop,
                        size: 13,
                        color: pickedDay != null ? _Glass.pinkDeep : _Glass.textHint),
                    const SizedBox(width: 6),
                    Text(
                      pickedDay != null
                          ? '${monthNames[pickedDay!.month - 1]} ${pickedDay!.day}  •  tap again to change'
                          : 'Tap a day to select',
                      style: _Glass.body(
                        size: 13,
                        weight: FontWeight.w600,
                        color: pickedDay != null ? _Glass.pinkDeep : _Glass.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _Glass.pageBackground,
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.chevron_left, size: 18, color: _Glass.blueDeep),
                          ),
                        ),
                        Text(
                          '${monthNames[sheetMonth.month - 1]} ${sheetMonth.year}',
                          style: _Glass.body(size: 14, weight: FontWeight.w700),
                        ),
                        GestureDetector(
                          onTap: onNextMonth,
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.chevron_right, size: 18, color: _Glass.blueDeep),
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
                                      style: _Glass.body(
                                          size: 10, weight: FontWeight.w600, color: _Glass.textHint)),
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
                          bg = _Glass.pinkDeep;
                          txt = Colors.white;
                        } else if (isLogged) {
                          bg = _Glass.pink.withOpacity(0.2);
                          txt = _Glass.pinkDeep;
                        } else if (isToday) {
                          bg = _Glass.blueDeep.withOpacity(0.2);
                          txt = _Glass.blueDeep;
                        } else {
                          bg = Colors.transparent;
                          txt = _Glass.textDark;
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
                                style: _Glass.body(
                                  size: 11,
                                  weight: isPicked ? FontWeight.w700 : FontWeight.normal,
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
                        color: sel ? fc.withOpacity(0.15) : _Glass.pageBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? fc : _Glass.textHint.withOpacity(0.25),
                          width: sel ? 1.5 : 0.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.water_drop, size: 18, color: fc),
                          const SizedBox(height: 3),
                          Text(f,
                              textAlign: TextAlign.center,
                              style: _Glass.body(
                                size: 9,
                                weight: sel ? FontWeight.w700 : FontWeight.normal,
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
                        color: sel ? ec.withOpacity(0.15) : _Glass.pageBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? ec : _Glass.textHint.withOpacity(0.25),
                          width: sel ? 1.5 : 0.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(_energyIcon(e), size: 18, color: ec),
                          const SizedBox(height: 3),
                          Text(e,
                              textAlign: TextAlign.center,
                              style: _Glass.body(
                                size: 9,
                                weight: sel ? FontWeight.w700 : FontWeight.normal,
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
                  backgroundColor: _Glass.pinkDeep,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _Glass.pinkDeep.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(saveLabel,
                    style: _Glass.heading(size: 16, weight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetSectionLabel(String text) => Text(
        text,
        style: _Glass.body(size: 12, weight: FontWeight.w600, color: _Glass.textMuted),
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
        backgroundColor: saved ? _Glass.blueDeep : const Color(0xFFE24B4A),
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
      ..color = _Glass.blue.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final bluePaint = Paint()
      ..color = _Glass.blueDeep
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
      ..color = _Glass.pinkDeep
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
      ..color = _Glass.purpleDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1;

    canvas.drawCircle(Offset(cx, cy), r, paint);

    final eyePaint = Paint()
      ..color = _Glass.purpleDeep
      ..style = PaintingStyle.fill;

    if (mouth == 'sad') {
      final xPaint = Paint()
        ..color = _Glass.purpleDeep
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
        ..color = _Glass.blueDeep
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

  static ButtonStyle primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: blueDeep,
      foregroundColor: Colors.white,
      disabledBackgroundColor: blueDeep.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
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