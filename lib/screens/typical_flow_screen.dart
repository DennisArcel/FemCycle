import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/theme_provider.dart';

class TypicalFlowScreen extends StatefulWidget {
  const TypicalFlowScreen({super.key});

  @override
  State<TypicalFlowScreen> createState() => _TypicalFlowScreenState();
}

class _TypicalFlowScreenState extends State<TypicalFlowScreen> {
  static const String _apiBase = 'https://glutinous-idealist-slit.ngrok-free.dev/api'; // Laravel IP
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  String? _errorMessage;

  // Populated from GET /api/period-logs/predictions — most-recent-first
  List<Map<String, dynamic>> _periods = [];
  double? _avgCycleLength;
  double? _avgPeriodLength;
  int _cyclesLogged = 0;

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
      case 'Light': return const Color(0xFF84B2E9);
      case 'Moderate': return const Color(0xFFE96A8F);
      case 'Heavy': return const Color(0xFFBC6B9C);
      case 'Super Heavy': return const Color(0xFF993556);
      default: return const Color(0xFFAAAAAA);
    }
  }

  Color _flowBg(String? flow) {
    switch (flow) {
      case 'Light': return const Color(0xFFE4E8FE);
      case 'Moderate': return const Color(0xFFFFF0F5);
      case 'Heavy': return const Color(0xFFF5EAF7);
      case 'Super Heavy': return const Color(0xFFFBEAF0);
      default: return const Color(0xFFF0F0F0);
    }
  }

  String _formatRange(DateTime start, DateTime end) {
    if (start.month == end.month && start.year == end.year) {
      return '${_monthShort[start.month - 1]} ${start.day} \u2013 ${_monthShort[end.month - 1]} ${end.day}, ${end.year}';
    }
    return '${_monthShort[start.month - 1]} ${start.day}, ${start.year} \u2013 ${_monthShort[end.month - 1]} ${end.day}, ${end.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = context.cardColor;
    final bgColor = context.bgColor;
    final textColor = context.textPrimary;
    final subColor = context.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF84B2E9)),
                    )
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _periods.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              color: const Color(0xFF84B2E9),
                              onRefresh: _loadData,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSummaryGrid(cardColor),
                                    const SizedBox(height: 16),
                                    Text('Cycle history',
                                        style: TextStyle(
                                            fontFamily: 'Mallanna',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: textColor)),
                                    const SizedBox(height: 10),
                                    ..._periods.map((p) => _buildCycleCard(
                                        p, cardColor, textColor, subColor)),
                                  ],
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
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
                  shape: BoxShape.circle),
              child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          const Text('Typical Flow',
              style: TextStyle(color: Colors.white, fontFamily: 'Mallanna',
                  fontSize: 17, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🩸', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 14),
            const Text(
              'No cycles logged yet',
              style: TextStyle(
                  fontFamily: 'Mallanna', fontSize: 16,
                  fontWeight: FontWeight.w700, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Log your period from the home screen to see your history here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Mallanna', fontSize: 12, color: Color(0xFFAAAAAA)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 44, color: Color(0xFFAAAAAA)),
            const SizedBox(height: 14),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Mallanna', fontSize: 13, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF84B2E9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Try Again', style: TextStyle(fontFamily: 'Mallanna')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(Color cardColor) {
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
            'Avg cycle length', const Color(0xFF84B2E9), cardColor),
        _summaryCard(
            _avgPeriodLength != null ? '${_avgPeriodLength!.round()}' : 'N/A',
            'Avg period days', const Color(0xFFE96A8F), cardColor),
        _summaryCard('$_cyclesLogged',
            'Cycles logged', const Color(0xFFBC6B9C), cardColor),
        _summaryCard(lastPeriodLabel,
            'Last period', const Color(0xFF84B2E9), cardColor),
      ],
    );
  }

  Widget _summaryCard(String value, String label, Color color, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: TextStyle(fontFamily: 'Mallanna', fontSize: 24,
                  fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontFamily: 'Mallanna', fontSize: 10,
                  color: Color(0xFF888888))),
        ],
      ),
    );
  }

  Widget _buildCycleCard(Map<String, dynamic> period, Color cardColor,
      Color textColor, Color subColor) {
    final start = DateTime.parse(period['start']);
    final end = DateTime.parse(period['end']);
    final flow = period['dominant_flow'] as String?;
    final lengthDays = period['length_days'] as int? ?? 0;
    final cycleLengthDays = period['cycle_length_days'] as int?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: const Border(
            left: BorderSide(color: Color(0xFFE96A8F), width: 3)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text('${start.day}',
                  style: const TextStyle(fontFamily: 'Mallanna', fontSize: 20,
                      fontWeight: FontWeight.w700, color: Color(0xFFE96A8F),
                      height: 1)),
              Text(_monthAbbr[start.month - 1],
                  style: const TextStyle(fontFamily: 'Mallanna', fontSize: 9,
                      color: Color(0xFFAAAAAA))),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatRange(start, end),
                    style: TextStyle(fontFamily: 'Mallanna', fontSize: 13,
                        fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 3),
                Text(
                    cycleLengthDays != null
                        ? '$lengthDays days \u00b7 Cycle length: $cycleLengthDays days'
                        : '$lengthDays days \u00b7 Most recent cycle',
                    style: TextStyle(fontFamily: 'Mallanna', fontSize: 10,
                        color: subColor)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: _flowBg(flow),
                borderRadius: BorderRadius.circular(10)),
            child: Text(flow ?? 'N/A',
                style: TextStyle(fontFamily: 'Mallanna', fontSize: 10,
                    fontWeight: FontWeight.w600, color: _flowColor(flow))),
          ),
        ],
      ),
    );
  }
}