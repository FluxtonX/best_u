import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:best_u/view/auth_screens/reset_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PasswordResetLinkService {
  PasswordResetLinkService._();

  static final PasswordResetLinkService instance = PasswordResetLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  GlobalKey<NavigatorState>? _navigatorKey;
  String? _pendingResetCode;

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;

    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleUri(initialLink);
      }
    } catch (_) {
      // Link handling should never block app startup.
    }

    _subscription ??= _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (error) {
        if (error is MissingPluginException) return;
        debugPrint('Password reset link listener error: $error');
      },
    );
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _handleUri(Uri uri) {
    final resetCode = _extractPasswordResetCode(uri);
    if (resetCode == null) return;

    _openResetScreen(resetCode);
  }

  void _openResetScreen(String resetCode) {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      _pendingResetCode = resetCode;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final pendingCode = _pendingResetCode;
        if (pendingCode == null) return;
        _pendingResetCode = null;
        _openResetScreen(pendingCode);
      });
      return;
    }

    navigator.push(
      MaterialPageRoute(
        builder: (_) => ResetScreen(oobCode: resetCode),
      ),
    );
  }

  String? _extractPasswordResetCode(Uri uri) {
    final mode = uri.queryParameters['mode'];
    final code = uri.queryParameters['oobCode'];
    if (mode == 'resetPassword' && code != null && code.isNotEmpty) {
      return code;
    }

    final nestedLink = uri.queryParameters['link'];
    if (nestedLink == null || nestedLink.isEmpty) return null;

    return _extractPasswordResetCode(Uri.parse(Uri.decodeFull(nestedLink)));
  }
}
