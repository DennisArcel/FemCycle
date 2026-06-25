import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // ─────────────────────────────────────────────────────────────────────
  // BASE URL CONFIG
  // - Web / iOS simulator / Windows desktop  -> 127.0.0.1
  // - Android emulator                       -> 10.0.2.2
  // - Physical phone (same WiFi as your PC)  -> your PC's local IP (e.g. 192.168.1.X)
  // Just change this one line depending on what you're testing on.
  // ─────────────────────────────────────────────────────────────────────
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  // ── Token helpers ────────────────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── LOGIN ────────────────────────────────────────────────────────────
  // Returns a Map with 'success' (bool) and either 'data' or 'message'.
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => http.Response('{"message":"Request timed out. Please check your connection."}', 408),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save token for future authenticated requests
        await saveToken(body['token']);
        return {'success': true, 'data': body};
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Login failed. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Could not connect to server. Check your connection.',
      };
    }
  }

  // ── REGISTER ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String firstName,
    String? middleName,
    required String lastName,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'first_name': firstName,
          'middle_name': middleName,
          'last_name': lastName,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => http.Response('{"message":"Request timed out. Please check your connection."}', 408),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 201) {
        await saveToken(body['token']);
        return {'success': true, 'data': body};
      } else {
        // Laravel validation errors come back as { errors: { field: [msg] } }
        String message = body['message'] ?? 'Registration failed. Please try again.';
        if (body['errors'] != null) {
          final errors = body['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            message = firstError.first.toString();
          }
        }
        return {'success': false, 'message': message};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Could not connect to server. Check your connection.',
      };
    }
  }

  // ── FORGOT PASSWORD: SEND OTP ───────────────────────────────────────
  static Future<Map<String, dynamic>> sendOtp({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email}),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => http.Response('{"message":"Request timed out. Please check your connection."}', 408),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message']};
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Could not send OTP. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Could not connect to server. Check your connection.',
      };
    }
  }

  // ── FORGOT PASSWORD: VERIFY OTP ─────────────────────────────────────
  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email, 'otp': otp}),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => http.Response('{"message":"Request timed out. Please check your connection."}', 408),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message']};
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Invalid or expired OTP.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Could not connect to server. Check your connection.',
      };
    }
  }

  // ── FORGOT PASSWORD: RESET PASSWORD ─────────────────────────────────
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => http.Response('{"message":"Request timed out. Please check your connection."}', 408),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message']};
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Could not reset password.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Could not connect to server. Check your connection.',
      };
    }
  }

  // ── LOGOUT ───────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: await _authHeaders(),
      ).timeout(const Duration(seconds: 10));

      await deleteToken();

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        // Even if server call fails, we've already cleared local token
        return {'success': true};
      }
    } catch (e) {
      await deleteToken();
      return {'success': true};
    }
  }
}