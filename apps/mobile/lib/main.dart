import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'app/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.dev();

  try {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabaseAnonKey,
      debug: config.enableDebugLogging,
    );
  } catch (e) {
    debugPrint('Supabase initialization notice: $e');
  }

  // Run root application wrapped in Riverpod ProviderScope
  runApp(
    const ProviderScope(
      child: KiranaApp(),
    ),
  );
}
