import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';

class TypicalFlowScreen extends StatelessWidget {
  const TypicalFlowScreen({super.key});

  final List<Map<String, dynamic>> _cycles = const [
    {
      'day': 1, 'month': 'JAN', 'year': 2026,
      'range': 'Jan 1 – Jan 5, 2026',
      'days': 5, 'cycleLength': 28, 'flow': 'Medium',
    },
    {
      'day': 4, 'month': 'DEC', 'year': 2025,
      'range': 'Dec 4 – Dec 8, 2025',
      'days': 5, 'cycleLength': 29, 'flow': 'Light',
    },
    {
      'day': 5, 'month': 'NOV', 'year': 2025,
      'range': 'Nov 5 – Nov 10, 2025',
      'days': 6, 'cycleLength': 27, 'flow': 'Heavy',
    },
  ];

  double get _avgCycleLength {
    final total = _cycles.fold<int>(
        0, (sum, c) => sum + (c['cycleLength'] as int));
    return total / _cycles.length;
  }

  double get _avgPeriodDays {
    final total = _cycles.fold<int>(0, (sum, c) => sum + (c['days'] as int));
    return total / _cycles.length;
  }

  Color _flowColor(String flow) {
    switch (flow) {
      case 'Light': return const Color(0xFF84B2E9);
      case 'Medium': return const Color(0xFFE96A8F);
      case 'Heavy': return const Color(0xFFBC6B9C);
      case 'Super Heavy': return const Color(0xFF993556);
      default: return const Color(0xFF84B2E9);
    }
  }

  Color _flowBg(String flow) {
    switch (flow) {
      case 'Light': return const Color(0xFFE4E8FE);
      case 'Medium': return const Color(0xFFFFF0F5);
      case 'Heavy': return const Color(0xFFF5EAF7);
      case 'Super Heavy': return const Color(0xFFFBEAF0);
      default: return const Color(0xFFE4E8FE);
    }
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary cards
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.8,
                      children: [
                        _summaryCard('${_avgCycleLength.round()}',
                            'Avg cycle length', const Color(0xFF84B2E9), cardColor),
                        _summaryCard('${_avgPeriodDays.round()}',
                            'Avg period days', const Color(0xFFE96A8F), cardColor),
                        _summaryCard('${_cycles.length}',
                            'Cycles logged', const Color(0xFFBC6B9C), cardColor),
                        _summaryCard('Jan 1',
                            'Last period', const Color(0xFF84B2E9), cardColor),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text('Cycle history',
                        style: TextStyle(fontFamily: 'Mallanna', fontSize: 13,
                            fontWeight: FontWeight.w700, color: textColor)),
                    const SizedBox(height: 10),

                    ..._cycles.map((c) => _buildCycleCard(
                        c, cardColor, textColor, subColor)),
                  ],
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

  Widget _buildCycleCard(Map<String, dynamic> cycle, Color cardColor,
      Color textColor, Color subColor) {
    final flow = cycle['flow'] as String;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border(
            left: BorderSide(color: const Color(0xFFE96A8F), width: 3)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text('${cycle['day']}',
                  style: const TextStyle(fontFamily: 'Mallanna', fontSize: 20,
                      fontWeight: FontWeight.w700, color: Color(0xFFE96A8F),
                      height: 1)),
              Text(cycle['month'] as String,
                  style: const TextStyle(fontFamily: 'Mallanna', fontSize: 9,
                      color: Color(0xFFAAAAAA))),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cycle['range'] as String,
                    style: TextStyle(fontFamily: 'Mallanna', fontSize: 13,
                        fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 3),
                Text(
                    '${cycle['days']} days · Cycle length: ${cycle['cycleLength']} days',
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
            child: Text(flow,
                style: TextStyle(fontFamily: 'Mallanna', fontSize: 10,
                    fontWeight: FontWeight.w600, color: _flowColor(flow))),
          ),
        ],
      ),
    );
  }
}