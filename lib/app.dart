import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import 'router/app_router.dart';
import 'providers/theme_provider.dart';
import 'pages/splash_page.dart';

/// App 根组件
class FirstCCApp extends ConsumerWidget {
  const FirstCCApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'FirstCC',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,

      // GoRouter
      routerConfig: appRouter,

      // 启动页包裹
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return SplashPage(child: child);
      },
    );
  }
}
