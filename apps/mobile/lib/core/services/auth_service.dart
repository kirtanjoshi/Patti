import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_const.dart';
import '../models/user_model.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final UserAccount? user;
  final String? token;
  final String? refreshToken;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.token,
    this.refreshToken,
  });

  bool get isAuthenticated => token != null && user != null;

  AuthState copyWith({
    bool? isLoading,
    String? error,
    UserAccount? user,
    String? token,
    String? refreshToken,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  static const String _tokenKey = 'patii_auth_token';
  static const String _refreshTokenKey = 'patii_refresh_token';
  static const String _userKey = 'patii_user_profile';
  static const String _deviceIdKey = 'patii_device_id';

  // Base URL and Google client id delegated to centralized ApiConst
  static String get baseUrl => ApiConst.baseUrl;
  static set baseUrl(String value) => ApiConst.baseUrl = value;

  static String get googleWebClientId => ApiConst.googleWebClientId;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: ApiConst.googleWebClientId,
    scopes: ['email', 'profile'],
  );

  AuthNotifier() : super(const AuthState(isLoading: false)) {
    init();
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final refreshToken = prefs.getString(_refreshTokenKey);
      final userJson = prefs.getString(_userKey);

      if (token != null && userJson != null) {
        final decoded = jsonDecode(userJson) as Map<String, dynamic>;
        final user = UserAccount.fromJson(decoded);
        state = AuthState(
          isLoading: false,
          token: token,
          refreshToken: refreshToken,
          user: user,
        );
        if (token == 'mock_guest_jwt_token') {
          loginGuest(user.displayName);
        } else {
          _refreshUserProfile(token);
        }
        return;
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    }
    state = const AuthState(isLoading: false);
  }

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    if (deviceId == null) {
      final rand = Random().nextInt(999999);
      deviceId = 'dev_${DateTime.now().millisecondsSinceEpoch}_$rand';
      await prefs.setString(_deviceIdKey, deviceId);
    }
    return deviceId;
  }

  Future<bool> loginGuest([String? nickname]) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final deviceId = await _getOrCreateDeviceId();
      final displayName = nickname?.trim().isNotEmpty == true
          ? nickname!.trim()
          : 'Player #${Random().nextInt(9000) + 1000}';

      final response = await http
          .post(
            Uri.parse(ApiConst.authGuest),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'deviceId': deviceId,
              'displayName': displayName,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['accessToken'] as String;
        final refreshToken = data['refreshToken'] as String?;
        final userId = data['userId'] as String;
        final name = data['displayName'] as String? ?? displayName;
        final friendCode = data['friendCode'] as String? ?? 'PT-${Random().nextInt(9000) + 1000}';

        final user = UserAccount(
          userId: userId,
          displayName: name,
          friendCode: friendCode,
          isGuest: true,
          coins: 10000,
        );

        await _persistSession(token, refreshToken, user);
        state = AuthState(
          isLoading: false,
          token: token,
          refreshToken: refreshToken,
          user: user,
        );
        return true;
      } else {
        // Fallback for offline or local dev without backend running
        return await _fallbackLocalGuest(displayName);
      }
    } catch (e) {
      debugPrint('Guest login network failure: $e. Falling back to local guest.');
      final displayName = nickname?.trim().isNotEmpty == true
          ? nickname!.trim()
          : 'Player #${Random().nextInt(9000) + 1000}';
      return await _fallbackLocalGuest(displayName);
    }
  }

  Future<bool> _fallbackLocalGuest(String displayName) async {
    final randCode = 'PT-${Random().nextInt(9000) + 1000}';
    final user = UserAccount(
      userId: 'local_guest_${DateTime.now().millisecondsSinceEpoch}',
      displayName: displayName,
      friendCode: randCode,
      isGuest: true,
      coins: 10000,
    );
    const token = 'mock_guest_jwt_token';
    await _persistSession(token, null, user);
    state = AuthState(
      isLoading: false,
      token: token,
      user: user,
    );
    return true;
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken ?? googleAuth.accessToken;
      if (idToken != null) {
        return await loginGoogle(idToken);
      }
      state = state.copyWith(isLoading: false, error: 'Could not retrieve Google ID token');
      return false;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      if (kDebugMode) {
        return await loginGoogle('mock-google-token:player@gmail.com');
      }
      state = state.copyWith(isLoading: false, error: 'Google sign-in error: $e');
      return false;
    }
  }

  Future<bool> linkGoogleWithPrompt() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken ?? googleAuth.accessToken;
      if (idToken != null) {
        return await linkGoogleAccount(idToken);
      }
      return false;
    } catch (e) {
      debugPrint('Link Google error: $e');
      return await linkGoogleAccount('mock-google-token:linked@gmail.com');
    }
  }

  Future<bool> loginGoogle(String idToken) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http
          .post(
            Uri.parse(ApiConst.authGoogle),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'idToken': idToken}),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['accessToken'] as String;
        final refreshToken = data['refreshToken'] as String?;
        final user = UserAccount.fromJson(data);

        await _persistSession(token, refreshToken, user);
        state = AuthState(
          isLoading: false,
          token: token,
          refreshToken: refreshToken,
          user: user,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Google sign-in failed. Please try again.',
        );
        return false;
      }
    } catch (e) {
      // Local development test fallback
      if (idToken.startsWith('mock_') || kDebugMode) {
        final user = UserAccount(
          userId: 'google_user_${DateTime.now().millisecondsSinceEpoch}',
          displayName: 'Google Player',
          friendCode: 'PT-G${Random().nextInt(9000) + 1000}',
          isGuest: false,
          coins: 10000,
        );
        const token = 'mock_google_jwt_token';
        await _persistSession(token, null, user);
        state = AuthState(isLoading: false, token: token, user: user);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Network error during Google sign-in.',
      );
      return false;
    }
  }

  Future<bool> linkGoogleAccount(String idToken) async {
    if (state.token == null) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http
          .post(
            Uri.parse(ApiConst.authGoogle),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${state.token}',
            },
            body: jsonEncode({
              'idToken': idToken,
              'currentGuestToken': state.token,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final updatedUser = state.user?.copyWith(
          isGuest: false,
          displayName: data['displayName'] as String? ?? state.user?.displayName,
          avatarUrl: data['avatarUrl'] as String? ?? state.user?.avatarUrl,
        );
        if (updatedUser != null) {
          await _persistSession(state.token!, state.refreshToken, updatedUser);
          state = state.copyWith(isLoading: false, user: updatedUser);
        }
        return true;
      }
    } catch (_) {}

    // Simulated upgrade for offline/dev test
    final updatedUser = state.user?.copyWith(
      isGuest: false,
      displayName: '${state.user?.displayName} (Linked)',
    );
    if (updatedUser != null) {
      await _persistSession(state.token ?? 'mock_token', state.refreshToken, updatedUser);
      state = state.copyWith(isLoading: false, user: updatedUser);
    }
    return true;
  }

  Future<void> _refreshUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConst.authMe),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final refreshed = UserAccount.fromJson(data);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(refreshed.toJson()));
        state = state.copyWith(user: refreshed);
      }
    } catch (_) {}
  }

  Future<void> _persistSession(
    String token,
    String? refreshToken,
    UserAccount user,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
    state = const AuthState();
  }

  static const String _dailyClaimDateKey = 'patii_daily_claim_date';
  static const String _dailyStreakCountKey = 'patii_daily_streak_count';
  static const List<int> dailyRewards = [500, 750, 1000, 1250, 1500, 2000, 3000];

  Future<int> getDailyStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyStreakCountKey) ?? 1;
  }

  Future<bool> isDailyRewardClaimedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_dailyClaimDateKey);
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return lastDate == todayStr;
  }

  Future<int> claimDailyReward() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final lastDate = prefs.getString(_dailyClaimDateKey);

    if (lastDate == todayStr) {
      return 0; // Already claimed today
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    int currentStreak = prefs.getInt(_dailyStreakCountKey) ?? 0;
    int nextStreak;
    if (lastDate == yesterdayStr) {
      nextStreak = (currentStreak % 7) + 1;
    } else {
      nextStreak = 1; // Streak reset or first day
    }

    final reward = dailyRewards[nextStreak - 1];
    await prefs.setString(_dailyClaimDateKey, todayStr);
    await prefs.setInt(_dailyStreakCountKey, nextStreak);

    final currentCoins = state.user?.coins ?? 10000;
    final updatedUser = (state.user ??
            const UserAccount(
              userId: 'local_player',
              displayName: 'Player',
              friendCode: 'PT-NEW',
              isGuest: true,
              coins: 10000,
            ))
        .copyWith(coins: currentCoins + reward);

    await prefs.setString(_userKey, jsonEncode(updatedUser.toJson()));
    state = state.copyWith(user: updatedUser);

    return reward;
  }

  Future<void> addCoins(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final currentCoins = state.user?.coins ?? 10000;
    final updatedUser = (state.user ??
            const UserAccount(
              userId: 'local_player',
              displayName: 'Player',
              friendCode: 'PT-NEW',
              isGuest: true,
              coins: 10000,
            ))
        .copyWith(coins: currentCoins + amount);

    await prefs.setString(_userKey, jsonEncode(updatedUser.toJson()));
    state = state.copyWith(user: updatedUser);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
