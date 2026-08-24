import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run root application wrapped in Riverpod ProviderScope
  runApp(
    const ProviderScope(
      child: KiranaApp(),
    ),
  );
}
