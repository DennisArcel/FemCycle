import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tracks, per screen, whether the user has already seen that screen's
/// coach-mark tour — so each tour auto-plays only once (first visit) and can
/// still be replayed manually via the "?" help icon.
class TutorialStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static String _keyFor(String screenId) => 'tutorial_seen_$screenId';

  /// Screen ids used across the app — keep in sync with each screen's call.
  static const String home = 'home';
  static const String insights = 'insights';
  static const String typicalFlow = 'typical_flow';
  static const String diary = 'diary';
  static const String checkup = 'checkup';
  static const String lifestyle = 'lifestyle';
  static const String profile = 'profile';
  static const String learn = 'learn';

  static Future<bool> hasSeenTour(String screenId) async {
    final value = await _storage.read(key: _keyFor(screenId));
    return value == 'true';
  }

  static Future<void> markTourSeen(String screenId) async {
    await _storage.write(key: _keyFor(screenId), value: 'true');
  }

  /// Clears the "seen" flag for one screen — handy for testing, or if you
  /// want a "replay all tours" option in settings later.
  static Future<void> resetTour(String screenId) async {
    await _storage.delete(key: _keyFor(screenId));
  }
}