import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'utils/logger.dart';

/// 存储从分享 intent 收到的待导入文件路径（Android 专用，Web 永远 null）
String? pendingImportPath;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 强制竖屏（Web 端由 index.html 中 JS 处理）
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  } catch (_) {
    // Web 端可能不支持此 API
  }

  Logger.d('App', 'Starting FirstCC...');

  runApp(
    const ProviderScope(
      child: FirstCCApp(),
    ),
  );
}
