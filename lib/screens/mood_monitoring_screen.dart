import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/coach_mark_overlay.dart';
import '../services/tutorial_storage_service.dart';

// ── Glass design tokens — shared look, same as home_screen.dart ───────────
class _Glass {
  static const blue = Color(0xFF84B2E9);
  static const blueDeep = Color(0xFF4A7FC9);
  static const pink = Color(0xFFE96A8F);
  static const pinkDeep = Color(0xFFC94A6D);
  static const purple = Color(0xFFBC6B9C);
  static const green = Color(0xFF4CAF7D);
  static const ink = Color(0xFF33303B);
  static const inkSoft = Color(0xFF6B6775);
  static const textHint = Color(0xFFA6A0B4);

  static TextStyle display({double size = 15, FontWeight w = FontWeight.w700, Color? color}) =>
      GoogleFonts.quicksand(fontSize: size, fontWeight: w, color: color ?? ink);
  static TextStyle body({double size = 13, FontWeight w = FontWeight.w400, Color? color}) =>
      GoogleFonts.nunito(fontSize: size, fontWeight: w, color: color ?? inkSoft);

  static BoxDecoration card({double radius = 20, Color? borderColor}) => BoxDecoration(
        color: Colors.white.withOpacity(0.42),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? Colors.white.withOpacity(0.55), width: borderColor != null ? 1.5 : 1),
        boxShadow: [
          BoxShadow(color: const Color(0xFF503C78).withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      );

  static Widget glassCard({required Widget child, EdgeInsets? padding, double radius = 20, Color? borderColor}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding ?? const EdgeInsets.all(14),
          decoration: card(radius: radius, borderColor: borderColor),
          child: child,
        ),
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEEF2FB), Color(0xFFF7EEF6), Color(0xFFFDEFF3)],
              ),
            ),
          ),
          Positioned(top: -100, left: -80, child: _blob(220, _Glass.blue.withOpacity(0.35))),
          Positioned(bottom: -120, right: -60, child: _blob(200, _Glass.pink.withOpacity(0.30))),
          Positioned(top: 260, right: -40, child: _blob(160, _Glass.purple.withOpacity(0.25))),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ),
    );
  }
}

// ── Cycle entry model ───────────────────────────────────────────────────────
class CycleEntry {
  final String flow;
  final String energy;
  final String mood;
  CycleEntry({required this.flow, required this.energy, required this.mood});
}

class MoodMonitoringScreen extends StatefulWidget {
  // Optional — if not provided (e.g. reached via bottom nav), this screen
  // fetches its own data instead of relying on being handed it.
  final Map<DateTime, CycleEntry>? cycleEntries;

  const MoodMonitoringScreen({super.key, this.cycleEntries});

  @override
  State<MoodMonitoringScreen> createState() => _MoodMonitoringScreenState();
}

class _MoodMonitoringScreenState extends State<MoodMonitoringScreen> {
  final DateTime _today = DateTime.now();
  late DateTime _currentMonth;

  Map<DateTime, CycleEntry> _ownCycleEntries = {};
  bool _isLoadingEntries = true;

  // ── Coach-mark tour targets ──
  final GlobalKey _summaryGridKey = GlobalKey();
  final GlobalKey _healthCardKey = GlobalKey();
  final GlobalKey _breakdownKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(_today.year, _today.month);
    if (widget.cycleEntries != null && widget.cycleEntries!.isNotEmpty) {
      _ownCycleEntries = widget.cycleEntries!;
      _isLoadingEntries = false;
    } else {
      _fetchCycleEntries();
    }
    _fetchPredictions();
    _maybeShowCoachTour();
  }

  Future<void> _maybeShowCoachTour() async {
    final seen = await TutorialStorageService.hasSeenTour(TutorialStorageService.insights);
    if (seen || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCoachTour());
  }

  void _startCoachTour() {
    showCoachMarkTour(
      context: context,
      steps: [
        CoachMarkStep(
          targetKey: _summaryGridKey,
          title: 'Your month at a glance',
          description: 'Dominant mood and energy, period symptoms, PCOS detection, and your next predicted period — all in one grid.',
        ),
        CoachMarkStep(
          targetKey: _healthCardKey,
          title: 'PCOS Detection',
          description: 'A non-diagnostic pattern check based on your cycle history and Health Profile answers — not a diagnosis, just something worth discussing with a doctor if it applies to you.',
        ),
        CoachMarkStep(
          targetKey: _breakdownKey,
          title: 'Daily log',
          description: 'Every day you\'ve logged this month, broken down by flow, mood, and energy.',
        ),
      ],
    ).then((_) => TutorialStorageService.markTourSeen(TutorialStorageService.insights));
  }

  static const String _apiBase = 'https://femcycleapp-production.up.railway.app/api';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isLoadingPredictions = true;
  Map<String, dynamic>? _predictions;

  Future<Map<String, String>> _getHeaders() async {
    String? token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  Future<void> _fetchCycleEntries() async {
    setState(() => _isLoadingEntries = true);
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$_apiBase/period-logs'), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final Map<DateTime, CycleEntry> loaded = {};
        for (final row in data) {
          final d = DateTime.parse(row['date']);
          final key = DateTime(d.year, d.month, d.day);
          loaded[key] = CycleEntry(
            flow: row['flow'] ?? 'Moderate',
            energy: row['energy'] ?? 'Energetic',
            mood: row['mood'] ?? 'Happy',
          );
        }
        if (!mounted) return;
        setState(() {
          _ownCycleEntries = loaded;
          _isLoadingEntries = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoadingEntries = false);
      }
    } catch (e) {
      debugPrint('Error fetching cycle entries: $e');
      if (!mounted) return;
      setState(() => _isLoadingEntries = false);
    }
  }

  Future<void> _fetchPredictions() async {
    setState(() => _isLoadingPredictions = true);
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$_apiBase/period-logs/predictions'), headers: headers);
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _predictions = json.decode(response.body);
          _isLoadingPredictions = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoadingPredictions = false);
      }
    } catch (e) {
      debugPrint('Error fetching predictions: $e');
      if (!mounted) return;
      setState(() => _isLoadingPredictions = false);
    }
  }

  Map<DateTime, CycleEntry> get _thisMonthEntries => {
        for (final e in _ownCycleEntries.entries)
          if (e.key.year == _currentMonth.year && e.key.month == _currentMonth.month) e.key: e.value,
      };

  String get _dominantMood {
    if (_thisMonthEntries.isEmpty) return '—';
    final freq = <String, int>{};
    for (final e in _thisMonthEntries.values) {
      freq[e.mood] = (freq[e.mood] ?? 0) + 1;
    }
    return freq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  String get _dominantEnergy {
    if (_thisMonthEntries.isEmpty) return '—';
    final freq = <String, int>{};
    for (final e in _thisMonthEntries.values) {
      freq[e.energy] = (freq[e.energy] ?? 0) + 1;
    }
    return freq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  String get _dominantFlow {
    if (_thisMonthEntries.isEmpty) return '—';
    final freq = <String, int>{};
    for (final e in _thisMonthEntries.values) {
      freq[e.flow] = (freq[e.flow] ?? 0) + 1;
    }
    return freq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  Map<String, dynamic> get _cycleHealthSignals =>
      _predictions?['cycle_health_signals'] as Map<String, dynamic>? ?? {'level': 'insufficient_data', 'notes': <String>[]};

  // pillar_a_present / pillar_b_present are true / false / null (null =
  // not enough data or not answered yet). These drive the pattern meter
  // below, not just the raw symptom count — a percentage based on symptoms
  // alone would silently drop the cycle-data half of the signal.
  bool get _pillarAPresent => _cycleHealthSignals['pillar_a_present'] == true;
  bool get _pillarBPresent => _cycleHealthSignals['pillar_b_present'] == true;
  int get _patternCount => (_pillarAPresent ? 1 : 0) + (_pillarBPresent ? 1 : 0);
  // A percentage derived directly from the same 2-pillar count above (0%,
  // 50%, or 100%) — never a fabricated or clinically-calibrated risk score.
  // Labeled "pattern match" everywhere it's shown, not "risk", since this
  // is a simple screening-criteria count, not a diagnostic probability.
  String get _patternMatchLabel => '$_patternCount of 2 patterns';
  bool get _showPatternMeter =>
    _cycleHealthSignals['level'] == 'monitor' || _cycleHealthSignals['level'] == 'signs_present';

  String get _cycleHealthLevel {
    switch (_cycleHealthSignals['level']) {
      case 'signs_present': return 'Signs present';
      case 'monitor': return 'Worth monitoring';
      case 'symptoms_only': return 'Symptoms noted';
      case 'none': return 'None noted';
      default: return 'Not enough data yet';
    }
  }

  Color get _cycleHealthColor {
  switch (_cycleHealthSignals['level']) {
    case 'signs_present': return _Glass.pink;
    case 'monitor': return _Glass.purple;
    case 'symptoms_only': return _Glass.blue;
    case 'none': return _Glass.green;
    default: return const Color(0xFFAAAAAA);
  }
}

  IconData get _cycleHealthIcon {
  switch (_cycleHealthSignals['level']) {
    case 'signs_present': return Icons.favorite_border;
    case 'monitor': return Icons.visibility_outlined;
    case 'symptoms_only': return Icons.info_outline;
    case 'none': return Icons.check_circle_outline;
    default: return Icons.hourglass_empty;
  }
}

  List<String> get _cycleHealthNotes {
    final raw = _cycleHealthSignals['notes'] as List<dynamic>? ?? [];
    return raw.map((s) => s.toString()).toList();
  }

  String get _nextPeriodLabel {
    final range = _predictions?['next_predicted_range'] as Map<String, dynamic>?;
    if (range == null || range['earliest'] == null || range['latest'] == null) return 'Not enough data';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final earliest = DateTime.parse(range['earliest']);
    final latest = DateTime.parse(range['latest']);
    if (earliest.month == latest.month) {
      return '${months[earliest.month - 1]} ${earliest.day}\u2013${latest.day}';
    }
    return '${months[earliest.month - 1]} ${earliest.day} \u2013 ${months[latest.month - 1]} ${latest.day}';
  }

  String get _nextPeriodConfidenceLabel {
    switch (_predictions?['confidence']) {
      case 'high': return 'High confidence';
      case 'medium': return 'Medium confidence';
      case 'low': return 'Low confidence';
      default: return 'Not enough data yet';
    }
  }

  String? get _predictionNote => _predictions?['prediction_note'] as String?;

  String get _monthLabel {
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${months[_currentMonth.month - 1]} ${_currentMonth.year}';
  }

  Color _moodColor(String mood) {
    switch (mood) {
      case 'Happy': return _Glass.blueDeep;
      case 'Sad': return _Glass.purple;
      case 'Irritable': return _Glass.purple;
      case 'Cry': return _Glass.pink;
      case 'Calm': return _Glass.blueDeep;
      case 'Anxious': return _Glass.pink;
      case 'Tired': return _Glass.inkSoft;
      case 'Energetic': return _Glass.blue;
      default: return const Color(0xFFAAAAAA);
    }
  }

  Widget _moodDot(String mood, {double size = 9}) {
    return Container(width: size, height: size, decoration: BoxDecoration(color: _moodColor(mood), shape: BoxShape.circle));
  }

  IconData _energyIcon(String e) {
    switch (e) {
      case 'Exhausted': return Icons.airline_seat_flat;
      case 'Tired': return Icons.accessibility;
      case 'Energetic': return Icons.directions_walk;
      case 'Fully Energetic': return Icons.directions_run;
      default: return Icons.bolt;
    }
  }

  Color _flowColor(String f) {
    switch (f) {
      case 'Light': return _Glass.blue;
      case 'Moderate': return _Glass.pink;
      case 'Heavy': return _Glass.purple;
      case 'Super Heavy': return const Color(0xFF993556);
      default: return _Glass.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _AmbientBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMonthNav(),
                        const SizedBox(height: 16),
                        KeyedSubtree(key: _summaryGridKey, child: _buildSummaryGrid()),
                        const SizedBox(height: 16),
                        KeyedSubtree(key: _healthCardKey, child: _buildCycleHealthCard()),
                        const SizedBox(height: 16),
                        KeyedSubtree(key: _breakdownKey, child: _buildMonthlyBreakdown()),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: _Glass.glassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text('Insights', style: _Glass.display(size: 15)),
            if (_isLoadingEntries) ...[
              const SizedBox(width: 10),
              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _Glass.blue)),
            ],
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
                child: const Icon(Icons.question_mark_rounded, size: 15, color: _Glass.blueDeep),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1)),
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: _Glass.blue.withOpacity(0.14), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.chevron_left, size: 18, color: _Glass.blueDeep),
          ),
        ),
        Text(_monthLabel, style: _Glass.display(size: 15)),
        GestureDetector(
          onTap: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1)),
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: _Glass.blue.withOpacity(0.14), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.chevron_right, size: 18, color: _Glass.blueDeep),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        _summaryCard(
          title: 'Emotion & Energy',
          child: _thisMonthEntries.isEmpty
              ? _emptyChip()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(children: [
                      _moodDot(_dominantMood),
                      const SizedBox(width: 8),
                      Flexible(child: Text(_dominantMood, style: _Glass.display(size: 13, color: _Glass.ink), overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(_energyIcon(_dominantEnergy), size: 16, color: _Glass.blue),
                      const SizedBox(width: 6),
                      Flexible(child: Text(_dominantEnergy, style: _Glass.display(size: 13, color: _Glass.ink), overflow: TextOverflow.ellipsis)),
                    ]),
                  ],
                ),
        ),
        _summaryCard(
          title: 'Period Symptoms',
          child: _thisMonthEntries.isEmpty
              ? _emptyChip()
              : Row(children: [
                  Icon(Icons.water_drop, color: _flowColor(_dominantFlow), size: 22),
                  const SizedBox(width: 8),
                  Flexible(child: Text(_dominantFlow, style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w700, color: _flowColor(_dominantFlow)), overflow: TextOverflow.ellipsis)),
                ]),
        ),
        _summaryCard(
          title: 'PCOS Detection',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_cycleHealthIcon, size: 26, color: _cycleHealthColor),
              const SizedBox(height: 6),
             Row(
                children: [
                  Text(_cycleHealthLevel, style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w700, color: _cycleHealthColor)),
                ],
              ),
              if (_showPatternMeter) ...[
                const SizedBox(height: 2),
                Text(_patternMatchLabel, style: _Glass.body(size: 9.5, color: _Glass.inkSoft)),
              ],
            ],
          ),
        ),
        _summaryCard(
          title: 'Next Period',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 18, color: _Glass.blue),
              const SizedBox(height: 6),
              Text(_nextPeriodLabel, style: _Glass.display(size: 14, color: _Glass.ink)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_nextPeriodConfidenceLabel, style: _Glass.body(size: 10)),
                  if (_predictionNote != null) ...[
                    const SizedBox(width: 4),
                    Tooltip(
                      message: _predictionNote!,
                      triggerMode: TooltipTriggerMode.tap,
                      child: const Icon(Icons.info_outline, size: 12, color: Color(0xFFAAAAAA)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({required String title, required Widget child}) {
    return _Glass.glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.quicksand(fontSize: 11, fontWeight: FontWeight.w700, color: _Glass.inkSoft)),
          const SizedBox(height: 8),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _emptyChip() => Text('No data yet', style: _Glass.body(size: 12, color: const Color(0xFFBBBBBB)));

  // ── Pattern meter — "X of 2 patterns detected" ────────────────────────────
  // Mirrors the meter on the Home banner. Deliberately built from BOTH
  // pillars (cycle regularity from logs + symptom signs from the Health
  // Profile) rather than a symptom-only percentage, so it never
  // misrepresents itself as a calibrated risk score or drops the
  // logged-cycle-data half of the signal.
  Widget _buildPatternMeter() {
    final accent = _cycleHealthColor;

    Widget segment(bool filled) => Expanded(
          child: Container(
            height: 6,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: filled ? accent : accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );

    Widget row(String label, bool present) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                present ? Icons.error_outline : Icons.check_circle_outline,
                size: 13,
                color: present ? accent : _Glass.textHint,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: _Glass.body(
                    size: 11.5,
                    w: present ? FontWeight.w600 : FontWeight.normal,
                    color: present ? _Glass.ink : _Glass.inkSoft,
                  ),
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              segment(_patternCount >= 1),
              segment(_patternCount >= 2),
              const SizedBox(width: 4),
             Text(
                _patternMatchLabel,
                style: GoogleFonts.quicksand(fontSize: 11, fontWeight: FontWeight.w700, color: accent),
              ),
            ],
          ),
          row('Irregular cycle pattern (from your logs)', _pillarAPresent),
          row('Symptom signs (from Health Profile)', _pillarBPresent),
        ],
      ),
    );
  }

  Widget _buildCycleHealthCard() {
    final notes = _cycleHealthNotes;
    return _Glass.glassCard(
      padding: const EdgeInsets.all(16),
      borderColor: _cycleHealthColor.withOpacity(0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: _cycleHealthColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(_cycleHealthIcon, color: _cycleHealthColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text('PCOS Detection', style: _Glass.display(size: 15)),
              if (_isLoadingPredictions) ...[
                const SizedBox(width: 8),
                SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: _Glass.blue)),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _cycleHealthColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  _showPatternMeter
                      ? '$_cycleHealthLevel • $_patternMatchLabel'
                      : _cycleHealthLevel,
                  style: GoogleFonts.quicksand(fontSize: 11, fontWeight: FontWeight.w700, color: _cycleHealthColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(10)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 14, color: Color(0xFFAAAAAA)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Based on your cycle history and health profile answers. '
                    'This is not a diagnosis — just a pattern worth discussing '
                    'with a doctor if it applies to you.',
                    style: _Glass.body(size: 11, color: _Glass.inkSoft),
                  ),
                ),
              ],
            ),
          ),
          if (_showPatternMeter) ...[
            const SizedBox(height: 12),
            _buildPatternMeter(),
          ],
          const SizedBox(height: 12),
          if (notes.isEmpty) ...[
            Row(children: [
              const Icon(Icons.check_circle_outline, size: 16, color: _Glass.green),
              const SizedBox(width: 6),
              Text('Nothing notable from your logs right now.', style: GoogleFonts.nunito(fontSize: 12, color: _Glass.green, fontWeight: FontWeight.w600)),
            ]),
          ] else ...[
            Text('From your logs:', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: _Glass.inkSoft)),
            const SizedBox(height: 8),
            ...notes.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(margin: const EdgeInsets.only(top: 5), width: 5, height: 5, decoration: BoxDecoration(color: _cycleHealthColor, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(s, style: _Glass.body(size: 12, color: _Glass.inkSoft))),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyBreakdown() {
    if (_thisMonthEntries.isEmpty) {
      return _Glass.glassCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_note_outlined, size: 36, color: _Glass.inkSoft.withOpacity(0.5)),
              const SizedBox(height: 10),
              Text('No cycle entries this month', style: _Glass.body(size: 14, color: _Glass.inkSoft)),
              const SizedBox(height: 4),
              Text('Log your cycle from the home screen', style: _Glass.body(size: 12, color: const Color(0xFFBBBBBB))),
            ],
          ),
        ),
      );
    }

    final sorted = _thisMonthEntries.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daily Log — $_monthLabel', style: GoogleFonts.quicksand(fontSize: 13, fontWeight: FontWeight.w700, color: _Glass.ink)),
        const SizedBox(height: 8),
        ...sorted.map((entry) {
          final d = entry.key;
          final e = entry.value;
          final label = '${months[d.month - 1]} ${d.day}';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.38),
                    borderRadius: BorderRadius.circular(12),
                    border: Border(left: BorderSide(color: _flowColor(e.flow), width: 3)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 44, child: Text(label, style: GoogleFonts.quicksand(fontSize: 11, fontWeight: FontWeight.w700, color: _flowColor(e.flow)))),
                      const SizedBox(width: 10),
                      Icon(Icons.water_drop, size: 14, color: _flowColor(e.flow)),
                      const SizedBox(width: 4),
                      Text(e.flow, style: _Glass.body(size: 12, color: _Glass.inkSoft)),
                      const SizedBox(width: 12),
                      _moodDot(e.mood, size: 8),
                      const SizedBox(width: 5),
                      Expanded(child: Text(e.mood, style: _Glass.body(size: 12, color: _Glass.inkSoft), overflow: TextOverflow.ellipsis)),
                      Icon(_energyIcon(e.energy), size: 14, color: _Glass.blue),
                      const SizedBox(width: 4),
                      Text(e.energy, style: _Glass.body(size: 11, color: const Color(0xFFAAAAAA))),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}