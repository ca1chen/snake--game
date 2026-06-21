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

  // 强制竖屏
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  Logger.d('App', 'Starting FirstCC...');

  runApp(
    const ProviderScope(
      child: FirstCCApp(),
    ),
  );
}
