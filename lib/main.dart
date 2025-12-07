import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  debugPrint('Supabase URL: ${Env.supabaseUrl}');
  debugPrint('Supabase Anon Key: ${Env.supabaseAnonKey}');
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
  runApp(const IngoozApp());
}

class IngoozApp extends StatefulWidget {
  const IngoozApp({super.key});

  @override
  State<IngoozApp> createState() => _IngoozAppState();
}

class _IngoozAppState extends State<IngoozApp> {
  @override
  void initState() {
    super.initState();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        AppRouter.navigatorKey.currentState
            ?.pushNamed('/reset-password');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final initialRoute =
        Supabase.instance.client.auth.currentUser == null ? '/' : '/home';
    return MaterialApp(
      title: 'Ingooz',
      theme: AppTheme.light(),
      navigatorKey: AppRouter.navigatorKey,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: initialRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
