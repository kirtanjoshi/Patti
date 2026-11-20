import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class DeepLinkData {
  final String? roomCode;
  final String? friendCode;

  const DeepLinkData({this.roomCode, this.friendCode});

  bool get hasRoomCode => roomCode != null && roomCode!.isNotEmpty;
  bool get hasFriendCode => friendCode != null && friendCode!.isNotEmpty;
}

class DeepLinkService {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  final _deepLinkController = StreamController<DeepLinkData>.broadcast();
  Stream<DeepLinkData> get deepLinkStream => _deepLinkController.stream;

  DeepLinkService() {
    _appLinks = AppLinks();
  }

  Future<void> init() async {
    try {
      // 1. Check for initial link if app was launched via deep link
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }

      // 2. Listen to incoming deep links while app is running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (uri) => _handleUri(uri),
        onError: (err) => debugPrint('Deep link error: $err'),
      );
    } catch (e) {
      debugPrint('DeepLinkService initialization error: $e');
    }
  }

  void _handleUri(Uri uri) {
    debugPrint('Received Deep Link: $uri');
    String? roomCode;
    String? friendCode;

    // Cases:
    // 1. patii://room/7X8K2M  or  https://patii.app/r/7X8K2M
    // 2. patii://friend/PT-K8M2  or  https://patii.app/f/PT-K8M2
    if (uri.scheme == 'patii') {
      if (uri.host == 'room' || uri.pathSegments.contains('room')) {
        roomCode = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : uri.host;
      } else if (uri.host == 'friend' || uri.pathSegments.contains('friend')) {
        friendCode = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : uri.host;
      }
    } else if (uri.host.contains('patii.app') || uri.host.contains('localhost')) {
      if (uri.pathSegments.contains('r')) {
        final idx = uri.pathSegments.indexOf('r');
        if (idx + 1 < uri.pathSegments.length) {
          roomCode = uri.pathSegments[idx + 1];
        }
      } else if (uri.pathSegments.contains('f')) {
        final idx = uri.pathSegments.indexOf('f');
        if (idx + 1 < uri.pathSegments.length) {
          friendCode = uri.pathSegments[idx + 1];
        }
      }
    }

    if (roomCode != null || friendCode != null) {
      _deepLinkController.add(DeepLinkData(
        roomCode: roomCode?.toUpperCase(),
        friendCode: friendCode?.toUpperCase(),
      ));
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
    _deepLinkController.close();
  }
}
