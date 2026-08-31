import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/theme_provider.dart';
import '../widgets/coach_mark_overlay.dart';
import '../services/tutorial_storage_service.dart';

class TypicalFlowScreen extends StatefulWidget {
  const TypicalFlowScreen({super.key});

  @override
  State<TypicalFlowScreen> createState() => _TypicalFlowScreenState();
}

class _TypicalFlowScreenState extends State<TypicalFlowScreen> {
  static const String _apiBase = 'https://femcycleapp-production.up.railway.app/api'; // Laravel IP
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  String? _errorMessage;

  // Populated from GET /api/period-logs/predictions — most-recent-first
  List<Map<String, dynamic>> _periods = [];
  double? _avgCycleLength;
  double? _avgPeriodLength;
  int _cyclesLogged = 0;

  // ── Coach-mark tour targets ──
  final GlobalKey _summaryGridKey = GlobalKey();
  final GlobalKey _historyKey = GlobalKey();

  static const List<String> _monthAbbr = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];
  static const List<String> _monthShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<Map<String, String>> _getHeaders() async {
    String? token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_apiBase/predictions'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          _periods = List<Map<String, dynamic>>.from(data['periods'] ?? []);
          _avgCycleLength = (data['average_cycle_length'] as num?)?.toDouble();
          _avgPeriodLength = (data['average_period_length'] as num?)?.toDouble();
          _cyclesLogged = data['cycles_logged'] ?? 0;
          _isLoading = false;
        });
        _maybeShowCoachTour();
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Could not load your cycle history.';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading typical flow data: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load your cycle history.';
        _isLoading = false;
      });
    }
  }

  Color _flowColor(String? flow) {
    switch (flow) {
      case 'Light': return _Glass.blueDeep;
      case 'Moderate': return _Glass.pinkDeep;
      case 'Heavy': return const Color(0xFFA865C0);
      case 'Super Heavy': return const Color(0xFF7A2E4C);
      default: return _Glass.textHint;
    }
  }

  Color _flowBg(String? flow) {
    switch (flow) {
      case 'Light': return _Glass.blue.withOpacity(0.25);
      case 'Moderate': return _Glass.pink.withOpacity(0.25);
      case 'Heavy': return _Glass.purple.withOpacity(0.25);
      case 'Super Heavy': return const Color(0xFFE0679A).withOpacity(0.2);
      default: return Colors.white.withOpacity(0.4);
    }
  }

  String _formatRange(DateTime start, DateTime end) {
    if (start.month == end.month && start.year == end.year) {
      return '${_monthShort[start.month - 1]} ${start.day} \u2013 ${_monthShort[end.month - 1]} ${end.day}, ${end.year}';
    }
    return '${_monthShort[start.month - 1]} ${start.day}, ${start.year} \u2013 ${_monthShort[end.month - 1]} ${end.day}, ${end.year}';
  }

  Future<void> _maybeShowCoachTour() async {
    final seen = await TutorialStorageService.hasSeenTour(TutorialStorageService.typicalFlow);
    if (seen || !mounted || _periods.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCoachTour());
  }

  void _startCoachTour() {
    if (_periods.isEmpty) return;
    showCoachMarkTour(
      context: context,
      steps: [
        CoachMarkStep(
          targetKey: _summaryGridKey,
          title: 'Your averages',
          description: 'Your average cycle length, period length, and total cycles logged, all in one place.',
        ),
        CoachMarkStep(
          targetKey: _historyKey,
          title: 'Cycle history',
          description: 'Every past cycle you\'ve logged, with its dates and dominant flow.',
        ),
      ],
    ).then((_) => TutorialStorageService.markTourSeen(TutorialStorageService.typicalFlow));
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
                _buildTopBar(context),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: _Glass.blueDeep),
                        )
                      : _errorMessage != null
                          ? _buildErrorState()
                          : _periods.isEmpty
                              ? _buildEmptyState()
                              : RefreshIndicator(
                                  color: _Glass.blueDeep,
                                  onRefresh: _loadData,
                                  child: SingleChildScrollView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        KeyedSubtree(key: _summaryGridKey, child: _buildSummaryGrid()),
                                        const SizedBox(height: 16),
                                        Text('Cycle history',
                                            style: _Glass.body(
                                                size: 13, weight: FontWeight.w700)),
                                        const SizedBox(height: 10),
                                        KeyedSubtree(
                                          key: _historyKey,
                                          child: Column(
                                            children: _periods.map((p) => _buildCycleCard(p)).toList(),
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

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: _Glass.card(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
                child: Icon(Icons.chevron_left, color: _Glass.textDark, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Text('Typical Flow', style: _Glass.heading(size: 18, weight: FontWeight.w600)),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _Glass.card(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🩸', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 14),
              Text('No cycles logged yet',
                  style: _Glass.heading(size: 16, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'Log your period from the home screen to see your history here.',
                textAlign: TextAlign.center,
                style: _Glass.body(size: 12, color: _Glass.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _Glass.card(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 44, color: _Glass.textHint),
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: _Glass.body(size: 13, color: _Glass.textMuted),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: _Glass.primaryButtonStyle(),
                child: Text('Try Again', style: _Glass.body(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    final lastPeriodStart = DateTime.parse(_periods.first['start']);
    final lastPeriodLabel =
        '${_monthShort[lastPeriodStart.month - 1]} ${lastPeriodStart.day}';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: [
        _summaryCard(
            _avgCycleLength != null ? '${_avgCycleLength!.round()}' : 'N/A',
            'Avg cycle length', _Glass.blueDeep),
        _summaryCard(
            _avgPeriodLength != null ? '${_avgPeriodLength!.round()}' : 'N/A',
            'Avg period days', _Glass.pinkDeep),
        _summaryCard('$_cyclesLogged', 'Cycles logged', const Color(0xFFA865C0)),
        _summaryCard(lastPeriodLabel, 'Last period', _Glass.blueDeep),
      ],
    );
  }

  Widget _summaryCard(String value, String label, Color color) {
    return _Glass.card(
      radius: 14,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: _Glass.heading(size: 24, weight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: _Glass.body(size: 10, color: _Glass.textMuted)),
        ],
      ),
    );
  }

  Widget _buildCycleCard(Map<String, dynamic> period) {
    final start = DateTime.parse(period['start']);
    final end = DateTime.parse(period['end']);
    final flow = period['dominant_flow'] as String?;
    final lengthDays = period['length_days'] as int? ?? 0;
    final cycleLengthDays = period['cycle_length_days'] as int?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: _Glass.card(
        radius: 14,
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
              border: Border(left: BorderSide(color: _Glass.pinkDeep, width: 3))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Column(
                  children: [
                    Text('${start.day}',
                        style: _Glass.heading(
                          size: 20,
                          weight: FontWeight.w700,
                          color: _Glass.pinkDeep,
                        ).copyWith(height: 1)),
                    Text(_monthAbbr[start.month - 1],
                        style: _Glass.body(size: 9, color: _Glass.textHint)),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatRange(start, end),
                          style: _Glass.body(size: 13, weight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(
                          cycleLengthDays != null
                              ? '$lengthDays days \u00b7 Cycle length: $cycleLengthDays days'
                              : '$lengthDays days \u00b7 Most recent cycle',
                          style: _Glass.body(size: 10, color: _Glass.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: _flowBg(flow), borderRadius: BorderRadius.circular(10)),
                  child: Text(flow ?? 'N/A',
                      style: _Glass.body(
                          size: 10, weight: FontWeight.w600, color: _flowColor(flow))),
                ),
              ],
            ),
          ),
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