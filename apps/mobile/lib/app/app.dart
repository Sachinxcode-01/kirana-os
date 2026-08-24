import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/network/connectivity_status.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/connectivity_banner.dart';
import 'app_providers.dart';
import 'router.dart';

/// Root application widget for KiranaOS.
class KiranaApp extends ConsumerWidget {
  const KiranaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final connectivityAsync = ref.watch(connectivityStatusStreamProvider);
    final connectivityStatus =
        connectivityAsync.valueOrNull ?? ConnectivityStatus.online;

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: KiranaTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        return Column(
          children: [
            ConnectivityBanner(status: connectivityStatus),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
    );
  }
}
