import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/diary_screen.dart';
import '../screens/mood_monitoring_screen.dart';
import '../screens/checkup_screen.dart';
import '../screens/educational_screen.dart';
import '../screens/lifestyle_screen.dart';

// Shared bottom navigation bar used by Home, Diary, Mood, Checkup, Learn,
// and Lifestyle. Each screen declares its OWN fixed index (a constant, not
// shared mutable state) — that's what makes the highlight always correct:
// there's no cross-screen state to fall out of sync.
//
// Uses pushReplacement (swap) instead of push (stack), so tapping between
// tabs never builds up a deep back-stack, and every screen always has this
// same bar rather than losing it entirely once you leave Home.
//
// Tab switches use a zero-duration PageRouteBuilder instead of the default
// MaterialPageRoute slide/fade, so switching tabs feels instant rather than
// animated.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final VoidCallback? onAddPressed;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    this.onAddPressed,
  });

  // Shared no-transition route builder used by both _go() and _goToAddSheet().
  Route _noTransitionRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => screen,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  void _go(BuildContext context, int index) {
    if (index == currentIndex) return; // already here — no-op, avoids a pointless rebuild

    late Widget screen;
    switch (index) {
      case 0:
        screen = const HomeScreen();
        break;
      case 1:
        screen = const DiaryScreen();
        break;
      case 2:
        screen = const MoodMonitoringScreen();
        break;
      case 3:
        screen = const CheckupScreen();
        break;
      case 4:
        screen = const EducationalScreen();
        break;
      case 5:
        screen = const LifestyleScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(context, _noTransitionRoute(screen));
  }

  // Tapping "+" from any tab jumps to Home with the add-period sheet already
  // open, via HomeScreen's autoOpenAddSheet flag — see home_screen.dart.
  void _goToAddSheet(BuildContext context) {
  // If we're already on Home, use HomeScreen's own Add Cycle function.
  if (currentIndex == 0 && onAddPressed != null) {
    onAddPressed!();
    return;
  }

    // From other screens, go to Home and automatically open Add Cycle.
    Navigator.pushReplacement(
      context,
      _noTransitionRoute(const HomeScreen(autoOpenAddSheet: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(context, 0, Icons.calendar_month_outlined, 'Cycle'),
            _navItem(context, 1, Icons.book_outlined, 'Diary'),
            _navItem(context, 2, Icons.sentiment_satisfied_outlined, 'Insights'),
            _navItem(context, 3, Icons.medical_services_outlined, 'Check-up'),
            _navItem(context, 4, Icons.menu_book_outlined, 'Learn'),
            _navItem(context, 5, Icons.self_improvement_outlined, 'Lifestyle'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index, IconData icon, String label) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => _go(context, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isActive ? const Color(0xFF84B2E9) : const Color(0xFFAAAAAA),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontFamily: 'Mallanna',
              color: isActive ? const Color(0xFF84B2E9) : const Color(0xFFAAAAAA),
            ),
          ),
        ],
      ),
    );
  }
}