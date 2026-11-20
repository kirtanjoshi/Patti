import 'package:flutter/foundation.dart';

/// Centralized API and Network Constants for the Patii mobile application.
class ApiConst {
  ApiConst._();

  /// Primary Production Render Backend URL
  static const String productionBaseUrl = 'https://patti-ntpv.onrender.com';

  /// Local Development Fallbacks
  static const String localWebOrIosUrl = 'http://localhost:4000';
  static const String localAndroidEmulatorUrl = 'http://10.0.2.2:4000';

  /// Active Base URL. Defaults to the Render production server,
  /// but can be overridden at runtime or via --dart-define=API_BASE_URL=...
  static String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: productionBaseUrl,
  );

  /// Helper to toggle local dev server if needed
  static void useLocalDev() {
    baseUrl = kIsWeb || defaultTargetPlatform != TargetPlatform.android
        ? localWebOrIosUrl
        : localAndroidEmulatorUrl;
  }

  /// Helper to restore production Render server
  static void useProduction() {
    baseUrl = productionBaseUrl;
  }

  // ==========================================
  // Socket.IO Real-Time Table & Gateway URLs
  // ==========================================
  static String get socketUrl => baseUrl;

  // ==========================================
  // Google OAuth Credentials & Deep Linking
  // ==========================================
  static const String googleWebClientId =
      '535204897241-8ee666l35silo6e464330nl5oirgb11g.apps.googleusercontent.com';

  static const String deepLinkScheme = 'patii';
  static const String deepLinkDomain = 'patii.app';

  // ==========================================
  // Authentication Endpoints
  // ==========================================
  static String get authGuest => '$baseUrl/auth/guest';
  static String get authGoogle => '$baseUrl/auth/google';
  static String get authMe => '$baseUrl/auth/me';
  static String get authRefresh => '$baseUrl/auth/refresh';

  // ==========================================
  // Social & Friends Endpoints
  // ==========================================
  static String get friends => '$baseUrl/social/friends';
  static String get friendRequest => '$baseUrl/social/friends/request';
  static String get friendAccept => '$baseUrl/social/friends/accept';
  static String get friendDecline => '$baseUrl/social/friends/decline';
  static String get friendConnect => '$baseUrl/social/friends/connect';

  // ==========================================
  // Nearby Discovery Radar Endpoints
  // ==========================================
  static String get nearbyLocation => '$baseUrl/social/nearby/location';
  static String get nearbyVisibility => '$baseUrl/social/nearby/visibility';

  static Uri nearbyPlayersUri({
    required double radiusKm,
    required double lat,
    required double lon,
  }) {
    return Uri.parse(
      '$baseUrl/social/nearby?radiusKm=$radiusKm&lat=$lat&lon=$lon',
    );
  }

  // ==========================================
  // Private Rooms & Table Endpoints
  // ==========================================
  static String get rooms => '$baseUrl/rooms';
  static String roomByCode(String code) => '$baseUrl/rooms/$code';

  // ==========================================
  // Health & Monitoring Endpoints
  // ==========================================
  static String get health => '$baseUrl/health';
  static String get healthPing => '$baseUrl/health/ping';
}
