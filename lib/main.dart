import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

bool _isExpiredLinkUri(Uri uri) {
  final raw = uri.toString();
  return raw.contains('error=access_denied') ||
      raw.contains('error_code=otp_expired') ||
      raw.contains('otp_expired') ||
      raw.contains('Email+link+is+invalid');
}

String? _expiredReasonFromRaw(String raw) {
  if (raw.contains('type=recovery') || raw.contains('reset-password')) {
    return 'recovery';
  }
  if (raw.contains('type=signup') || raw.contains('email-confirm')) {
    return 'signup';
  }
  if (raw.contains('type=magiclink') || raw.contains('email-change-confirm')) {
    return 'email_change';
  }
  return null;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const IngoozApp());
}

class IngoozApp extends StatefulWidget {
  const IngoozApp({super.key});

  @override
  State<IngoozApp> createState() => _IngoozAppState();
}

class _IngoozAppState extends State<IngoozApp> {
  bool _recoveryPending = false;
  String? _pendingExpiredReason;
  Timer? _recoveryFallbackTimer;
  StreamSubscription<Uri>? _linkSub;
  StreamSubscription<AuthState>? _authSub;

  void _pushRoute(String route, {bool replaceAll = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nav = AppRouter.navigatorKey.currentState;
      if (nav == null) return;
      if (replaceAll) {
        nav.pushNamedAndRemoveUntil(route, (r) => false);
      } else {
        nav.pushNamed(route);
      }
    });
  }

  void _handleRecoveryStart() {
    _recoveryPending = true;
    _recoveryFallbackTimer?.cancel();
    _recoveryFallbackTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!_recoveryPending || !mounted) return;
      _recoveryPending = false;
      _pushRoute('/email-link-expired?reason=recovery', replaceAll: true);
    });
  }

Future<void> _handleIncomingUri(Uri uri) async {
    final raw = uri.toString();
    final queryParams = <String, String>{...uri.queryParameters};
    final fragment = uri.fragment;
    if (fragment.isNotEmpty) {
      final fragmentUri = Uri.tryParse('?$fragment');
      if (fragmentUri != null) {
        queryParams.addAll(fragmentUri.queryParameters);
      }
    }

    final isRecoveryLink =
        raw.contains('type=recovery') || raw.contains('reset-password');
    final isSignupLink =
        queryParams['type'] == 'signup' ||
        raw.contains('type=signup') ||
        raw.contains('email-confirm');
    final isEmailChangeLink =
        queryParams['type'] == 'magiclink' ||
        raw.contains('type=magiclink') ||
        raw.contains('email-change-confirm');
    _pendingExpiredReason = _expiredReasonFromRaw(raw);

    if (_isExpiredLinkUri(uri)) {
      _recoveryPending = false;
      _recoveryFallbackTimer?.cancel();
      final route = _pendingExpiredReason == null
          ? '/email-link-expired'
          : '/email-link-expired?reason=$_pendingExpiredReason';
      _pushRoute(route, replaceAll: true);
      return;
    }

    if (isRecoveryLink) {
      _handleRecoveryStart();
      return;
    }

    if (isSignupLink) {
      _recoveryPending = false;
      _pendingExpiredReason = null;
      _recoveryFallbackTimer?.cancel();
      _pushRoute('/email-confirmed', replaceAll: true);
      return;
    }

    if (isEmailChangeLink) {
      _recoveryPending = false;
      _pendingExpiredReason = null;
      _recoveryFallbackTimer?.cancel();
      // Передаём исходный URI в роутер, чтобы он достал request_id/confirm_token.
      _pushRoute(raw, replaceAll: true);
    }
  }

  @override
  void initState() {
    super.initState();

    final appLinks = AppLinks();

    // Handle initial deep link on cold start.
    appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleIncomingUri(uri);
      }
    });

    // Handle deep links while app is running.
    _linkSub = appLinks.uriLinkStream.listen((uri) {
      _handleIncomingUri(uri);
    });

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        final event = data.event;

        if (event == AuthChangeEvent.passwordRecovery) {
          _recoveryPending = false;
          _pendingExpiredReason = null;
          _recoveryFallbackTimer?.cancel();
          _pushRoute('/reset-password', replaceAll: true);
          return;
        }

        // iOS sometimes emits initialSession/signedIn instead of passwordRecovery.
        if (_recoveryPending &&
            (event == AuthChangeEvent.signedIn ||
                event == AuthChangeEvent.initialSession)) {
          _recoveryPending = false;
          _pendingExpiredReason = null;
          _recoveryFallbackTimer?.cancel();
          _pushRoute('/reset-password', replaceAll: true);
          return;
        }

      },
      onError: (error) {
        if (error is AuthException &&
            (error.statusCode == 'otp_expired' ||
                error.statusCode == 'access_denied' ||
                error.message.contains('expired') ||
                error.message.contains('invalid'))) {
          _recoveryPending = false;
          _recoveryFallbackTimer?.cancel();
          final route = _pendingExpiredReason == null
              ? '/email-link-expired'
              : '/email-link-expired?reason=$_pendingExpiredReason';
          _pushRoute(route, replaceAll: true);
        }
      },
    );
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _authSub?.cancel();
    _recoveryFallbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final initialRoute = currentUser == null ? '/' : '/home';

    return MaterialApp(
      title: 'Ingooz',
      theme: AppTheme.light(),
      locale: const Locale('ru', 'RU'),
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorKey: AppRouter.navigatorKey,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: initialRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
