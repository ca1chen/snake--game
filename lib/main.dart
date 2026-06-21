import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart';
import 'app.dart';
import 'utils/logger.dart';

/// 通过 MethodChannel 接收系统分享的文件路径
const _shareChannel = MethodChannel('com.example.firstcc/share');

/// 存储从分享 intent 收到的待导入文件路径
String? pendingImportPath;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 初始化 sherpa_onnx 离线语音识别引擎
  try {
    initBindings();
    Logger.d('App', 'sherpa_onnx bindings initialized');
  } catch (e) {
    Logger.d('App', 'sherpa_onnx init failed: $e');
  }

  Logger.d('App', 'Starting FirstCC...');

  // 检查是否由系统分享启动（在 runApp 之前）
  try {
    final sharedPath = await _shareChannel.invokeMethod<String>('getSharedFile');
    if (sharedPath != null && sharedPath.isNotEmpty) {
      pendingImportPath = sharedPath;
      Logger.d('App', 'Received shared file: $sharedPath');
    }
  } catch (e) {
    // MethodChannel 可能尚未注册（首次启动），忽略错误
    Logger.d('App', 'Share channel not ready: $e');
  }

  runApp(
    const ProviderScope(
      child: FirstCCApp(),
    ),
  );
}
