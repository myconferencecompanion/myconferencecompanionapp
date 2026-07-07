import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nse_mobile/config/event_config.dart';
import 'package:nse_mobile/core/auth_provider.dart';
import 'package:nse_mobile/router/app_router.dart';
import 'package:nse_mobile/theme/app_theme.dart';

class NseApp extends ConsumerStatefulWidget {
  const NseApp({super.key});

  @override
  ConsumerState<NseApp> createState() => _NseAppState();
}

class _NseAppState extends ConsumerState<NseApp> {
  late final router = createAppRouter(ref);

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (prev, next) => router.refresh());
    return MaterialApp.router(
      title: EventConfig.shortName,
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
