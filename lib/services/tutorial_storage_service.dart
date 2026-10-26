import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

/// Tracks, per ACCOUNT and per screen, whether the user has already seen that
/// screen's coach-mark tour — so each tour auto-plays only once (first visit
/// of that account) and can still be replayed manually via the "?" help icon.
class TutorialStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _userIdKey = 'tutorial_user_id';

  static String _keyFor(String userId, String screenId) =>
      'tutorial_seen_${userId}_$screenId';

  /// Screen ids used across the app — keep in sync with each screen's call.
  static const String home = 'home';
  static const String insights = 'insights';
  static const String typicalFlow = 'typical_flow';
  static const String diary = 'diary';
  static const String checkup = 'checkup';
  static const String lifestyle = 'lifestyle';
  static const String profile = 'profile';
  static const String learn = 'learn';

  static const List<String> _allScreens = [
    home, insights, typicalFlow, diary,
    checkup, lifestyle, profile, learn,
  ];

  /// Call right after a successful login or register so tour flags are
  /// stored under the account that just signed in.
  static Future<void> setUser(dynamic id) async {
    if (id == null) return;
    await _storage.write(key: _userIdKey, value: id.toString());
  }

  /// Returns the id of the logged-in user. If none is stored yet (e.g. a
  /// session that was already open before this change), it is fetched once
  /// from the profile endpoint and remembered.
  static Future<String?> _currentUserId() async {
    final stored = await _storage.read(key: _userIdKey);
    if (stored != null && stored.isNotEmpty) return stored;

    final result = await ApiService.getProfile();
    if (result['success'] == true) {
      final user = result['user'];
      if (user is Map && user['id'] != null) {
        final id = user['id'].toString();
        await _storage.write(key: _userIdKey, value: id);
        return id;
      }
    }
    return null;
  }

  static Future<bool> hasSeenTour(String screenId) async {
    final userId = await _currentUserId();
    // If we can't tell who is logged in (e.g. offline), don't auto-play.
    if (userId == null) return true;
    final value = await _storage.read(key: _keyFor(userId, screenId));
    return value == 'true';
  }

  static Future<void> markTourSeen(String screenId) async {
    final userId = await _currentUserId();
    if (userId == null) return;
    await _storage.write(key: _keyFor(userId, screenId), value: 'true');
  }

  /// Clears the "seen" flag for one screen of the current account — handy
  /// for testing.
  static Future<void> resetTour(String screenId) async {
    final userId = await _currentUserId();
    if (userId == null) return;
    await _storage.delete(key: _keyFor(userId, screenId));
  }

  /// Clears every tour flag of the current account ("replay all tours").
  static Future<void> resetAll() async {
    for (final id in _allScreens) {
      await resetTour(id);
    }
  }
}