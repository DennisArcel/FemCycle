import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/theme_provider.dart';

// ── Sample cycle data (in real app, passed in or fetched from API) ────────────
// This mirrors the _CycleEntry map from home_screen.dart
class CycleEntry {
  final String flow;
  final String energy;
  final String mood;
  CycleEntry({required this.flow, required this.energy, required this.mood});
}

class MoodMonitoringScreen extends StatefulWidget {
  // Accept cycle entries from HomeScreen so data is consistent
  final Map<DateTime, CycleEntry> cycleEntries;

  const MoodMonitoringScreen({super.key, required this.cycleEntries});

  @override
  State<MoodMonitoringScreen> createState() => _MoodMonitoringScreenState();
}

class _MoodMonitoringScreenState extends State<MoodMonitoringScreen> {
  final DateTime _today = DateTime.now();
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(_today.year, _today.month);
    _fetchPredictions();
  }

  // ── Predictions API — same endpoint the home screen uses ─────────────────
  static const String _apiBase = 'http://127.0.0.1:8000/api/period-logs'; // Laravel IP
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isLoadingPredictions = true;
  Map<String, dynamic>? _predictions; // raw response from /predictions

  Future<Map<String, String>> _getHeaders() async {
    String? token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  Future<void> _fetchPredictions() async {
    setState(() => _isLoadingPredictions = true);
    try {
      final headers = await _getHeaders();
      final response =
          await http.get(Uri.parse('$_apiBase/predictions'), headers: headers);
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

  // ── Derived data for this month ───────────────────────────────────────────

  Map<DateTime, CycleEntry> get _thisMonthEntries => {
        for (final e in widget.cycleEntries.entries)
          if (e.key.year == _currentMonth.year &&
              e.key.month == _currentMonth.month)
            e.key: e.value,
      };

  // Most frequent mood this month
  String get _dominantMood {
    if (_thisMonthEntries.isEmpty) return '—';
    final freq = <String, int>{};
    for (final e in _thisMonthEntries.values) {
      freq[e.mood] = (freq[e.mood] ?? 0) + 1;
    }
    return freq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  // Most frequent energy this month
  String get _dominantEnergy {
    if (_thisMonthEntries.isEmpty) return '—';
    final freq = <String, int>{};
    for (final e in _thisMonthEntries.values) {
      freq[e.energy] = (freq[e.energy] ?? 0) + 1;
    }
    return freq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  // Most frequent flow (Period Symptoms)
  String get _dominantFlow {
    if (_thisMonthEntries.isEmpty) return '—';
    final freq = <String, int>{};
    for (final e in _thisMonthEntries.values) {
      freq[e.flow] = (freq[e.flow] ?? 0) + 1;
    }
    return freq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  // Period days count this month
  int get _periodDaysCount => _thisMonthEntries.length;

  // ── PCOS risk — now sourced from the server, which looks at ALL logged
  // history (irregularity across cycles + flow heaviness), not just this
  // month. Falls back to a neutral "not enough data" state while loading
  // or if the request hasn't returned yet.
  Map<String, dynamic> get _pcosRiskData =>
      _predictions?['pcos_risk'] as Map<String, dynamic>? ??
      {'level': 'insufficient_data', 'score': 0, 'symptoms': <String>[]};

  String get _pcosRisk {
    switch (_pcosRiskData['level']) {
      case 'high':     return 'High';
      case 'moderate': return 'Moderate';
      case 'low':      return 'Low';
      case 'none':     return 'None';
      default:         return 'Not enough data';
    }
  }

  // Real score out of the max possible (3 + 2 + 1 = 6), not a fixed guess —
  // '—' while there isn't enough history to score at all.
  String get _pcosRiskPercent {
    if (_pcosRiskData['level'] == 'insufficient_data') return '—';
    final score = (_pcosRiskData['score'] as num?) ?? 0;
    return '${(score / 6 * 100).round()}%';
  }

  Color get _pcosRiskColor {
    switch (_pcosRiskData['level']) {
      case 'high':     return const Color(0xFFE96A8F);
      case 'moderate': return const Color(0xFFBC6B9C);
      case 'low':      return const Color(0xFF84B2E9);
      case 'none':     return const Color(0xFF4CAF7D);
      default:         return const Color(0xFFAAAAAA);
    }
  }

  List<String> get _pcosSymptoms {
    final raw = _pcosRiskData['symptoms'] as List<dynamic>? ?? [];
    return raw.map((s) => s.toString()).toList();
  }

  // ── Next period prediction — real weighted average + confidence range
  // from the server, instead of a naive fixed +23-day guess.
  String get _nextPeriodLabel {
    final range = _predictions?['next_predicted_range'] as Map<String, dynamic>?;
    if (range == null || range['earliest'] == null || range['latest'] == null) {
      return 'Not enough data';
    }
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    final earliest = DateTime.parse(range['earliest']);
    final latest = DateTime.parse(range['latest']);
    if (earliest.month == latest.month) {
      return '${months[earliest.month - 1]} ${earliest.day}\u2013${latest.day}';
    }
    return '${months[earliest.month - 1]} ${earliest.day} \u2013 ${months[latest.month - 1]} ${latest.day}';
  }

  String get _nextPeriodConfidenceLabel {
    switch (_predictions?['confidence']) {
      case 'high':   return 'High confidence';
      case 'medium': return 'Medium confidence';
      case 'low':    return 'Low confidence';
      default:       return 'Not enough data yet';
    }
  }

  // ── Month name helper ─────────────────────────────────────────────────────
  String get _monthLabel {
    const months = ['January','February','March','April','May','June',
        'July','August','September','October','November','December'];
    return '${months[_currentMonth.month - 1]} ${_currentMonth.year}';
  }

  // ── Mood/Energy icon & color ──────────────────────────────────────────────
  String _moodEmoji(String mood) {
    switch (mood) {
      case 'Happy':     return '😊';
      case 'Sad':       return '😔';
      case 'Irritable': return '😤';
      case 'Cry':       return '😢';
      case 'Calm':      return '🌸';
      case 'Anxious':   return '😰';
      case 'Tired':     return '😴';
      case 'Energetic': return '⚡';
      default:          return '😐';
    }
  }

  IconData _energyIcon(String e) {
    switch (e) {
      case 'Exhausted':       return Icons.airline_seat_flat;
      case 'Tired':           return Icons.accessibility;
      case 'Energetic':       return Icons.directions_walk;
      case 'Fully Energetic': return Icons.directions_run;
      default:                return Icons.bolt;
    }
  }

  Color _flowColor(String f) {
    switch (f) {
      case 'Light':       return const Color(0xFF84B2E9);
      case 'Moderate':    return const Color(0xFFE96A8F);
      case 'Heavy':       return const Color(0xFFBC6B9C);
      case 'Super Heavy': return const Color(0xFF993556);
      default:            return const Color(0xFF84B2E9);
    }
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
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month navigation
                    _buildMonthNav(),
                    const SizedBox(height: 16),

                    // 4 summary cards
                    _buildSummaryGrid(),
                    const SizedBox(height: 16),

                    // PCOS detection card
                    _buildPcosCard(),
                    const SizedBox(height: 16),

                    // Monthly log breakdown
                    _buildMonthlyBreakdown(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      color: const Color(0xFF84B2E9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_left,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Mood Logging',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Mallanna',
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Month navigation ──────────────────────────────────────────────────────
  Widget _buildMonthNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => setState(() => _currentMonth =
              DateTime(_currentMonth.year, _currentMonth.month - 1)),
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chevron_left,
                size: 18, color: Color(0xFF84B2E9)),
          ),
        ),
        Text(
          _monthLabel,
          style: TextStyle(
            fontFamily: 'Mallanna',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _currentMonth =
              DateTime(_currentMonth.year, _currentMonth.month + 1)),
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chevron_right,
                size: 18, color: Color(0xFF84B2E9)),
          ),
        ),
      ],
    );
  }

  // ── 4 summary cards grid ──────────────────────────────────────────────────
  Widget _buildSummaryGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        // Emotion & Energy
        _summaryCard(
          title: 'Emotion & Energy',
          child: _thisMonthEntries.isEmpty
              ? _emptyChip()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(children: [
                      Text(_moodEmoji(_dominantMood),
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _dominantMood,
                          style: const TextStyle(
                            fontFamily: 'Mallanna',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(_energyIcon(_dominantEnergy),
                          size: 16, color: const Color(0xFF84B2E9)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _dominantEnergy,
                          style: const TextStyle(
                            fontFamily: 'Mallanna',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  ],
                ),
        ),

        // Period Symptoms
        _summaryCard(
          title: 'Period Symptoms',
          child: _thisMonthEntries.isEmpty
              ? _emptyChip()
              : Row(
                  children: [
                    Icon(Icons.water_drop,
                        color: _flowColor(_dominantFlow), size: 22),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _dominantFlow,
                        style: TextStyle(
                          fontFamily: 'Mallanna',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _flowColor(_dominantFlow),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),

        // PCOS Risk %
        _summaryCard(
          title: 'PCOS Risk',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _pcosRiskPercent,
                style: TextStyle(
                  fontFamily: 'Mallanna',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _pcosRiskColor,
                ),
              ),
              Text(
                _pcosRisk,
                style: TextStyle(
                  fontFamily: 'Mallanna',
                  fontSize: 11,
                  color: _pcosRiskColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Next Period Prediction
        _summaryCard(
          title: 'Next Period',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today,
                  size: 18, color: Color(0xFF84B2E9)),
              const SizedBox(height: 6),
              Text(
                _nextPeriodLabel,
                style: const TextStyle(
                  fontFamily: 'Mallanna',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
              Text(
                _nextPeriodConfidenceLabel,
                style: const TextStyle(
                  fontFamily: 'Mallanna',
                  fontSize: 10,
                  color: Color(0xFFAAAAAA),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Mallanna',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _emptyChip() {
    return const Text(
      'No data yet',
      style: TextStyle(
        fontFamily: 'Mallanna',
        fontSize: 12,
        color: Color(0xFFBBBBBB),
      ),
    );
  }

  // ── PCOS detection card ───────────────────────────────────────────────────
  Widget _buildPcosCard() {
    final symptoms = _pcosSymptoms;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _pcosRiskColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _pcosRiskColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.monitor_heart_outlined,
                    color: _pcosRiskColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'PCOS Detection',
                style: TextStyle(
                  fontFamily: 'Mallanna',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
              if (_isLoadingPredictions) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF84B2E9),
                  ),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _pcosRiskColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_pcosRisk} Risk',
                  style: TextStyle(
                    fontFamily: 'Mallanna',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _pcosRiskColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Info note
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    size: 14, color: Color(0xFFAAAAAA)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Based on your logged period symptoms only. This is not a medical diagnosis. Please consult a doctor for proper evaluation.',
                    style: TextStyle(
                      fontFamily: 'Mallanna',
                      fontSize: 11,
                      color: Color(0xFF888888),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (symptoms.isEmpty) ...[
            Row(
              children: const [
                Icon(Icons.check_circle_outline,
                    size: 16, color: Color(0xFF4CAF7D)),
                SizedBox(width: 6),
                Text(
                  'No period-related PCOS symptoms detected.',
                  style: TextStyle(
                    fontFamily: 'Mallanna',
                    fontSize: 12,
                    color: Color(0xFF4CAF7D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ] else ...[
            const Text(
              'Detected from your logs:',
              style: TextStyle(
                fontFamily: 'Mallanna',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 8),
            ...symptoms.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 14, color: _pcosRiskColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s,
                          style: const TextStyle(
                            fontFamily: 'Mallanna',
                            fontSize: 12,
                            color: Color(0xFF555555),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  // ── Monthly log breakdown ─────────────────────────────────────────────────
  Widget _buildMonthlyBreakdown() {
    if (_thisMonthEntries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            children: [
              Text('📋', style: TextStyle(fontSize: 36)),
              SizedBox(height: 10),
              Text(
                'No cycle entries this month',
                style: TextStyle(
                  fontFamily: 'Mallanna',
                  fontSize: 14,
                  color: Color(0xFF888888),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Log your cycle from the home screen',
                style: TextStyle(
                  fontFamily: 'Mallanna',
                  fontSize: 12,
                  color: Color(0xFFBBBBBB),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sorted = _thisMonthEntries.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Log — $_monthLabel',
          style: TextStyle(
            fontFamily: 'Mallanna',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...sorted.map((entry) {
          final d = entry.key;
          final e = entry.value;
          final label = '${months[d.month - 1]} ${d.day}';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(
                    color: _flowColor(e.flow), width: 3),
              ),
            ),
            child: Row(
              children: [
                // Date
                SizedBox(
                  width: 44,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Mallanna',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _flowColor(e.flow),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Flow
                Icon(Icons.water_drop,
                    size: 14, color: _flowColor(e.flow)),
                const SizedBox(width: 4),
                Text(
                  e.flow,
                  style: const TextStyle(
                    fontFamily: 'Mallanna',
                    fontSize: 12,
                    color: Color(0xFF555555),
                  ),
                ),
                const SizedBox(width: 12),
                // Mood
                Text(_moodEmoji(e.mood),
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    e.mood,
                    style: const TextStyle(
                      fontFamily: 'Mallanna',
                      fontSize: 12,
                      color: Color(0xFF555555),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Energy
                Icon(_energyIcon(e.energy),
                    size: 14, color: const Color(0xFF84B2E9)),
                const SizedBox(width: 4),
                Text(
                  e.energy,
                  style: const TextStyle(
                    fontFamily: 'Mallanna',
                    fontSize: 11,
                    color: Color(0xFFAAAAAA),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}