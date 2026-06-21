import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 离线语音模型下载服务（移动端）
class ModelDownloadService {
  static final ModelDownloadService _instance = ModelDownloadService._();
  factory ModelDownloadService() => _instance;
  ModelDownloadService._();

  static const String _modelUrl =
      'https://hf-mirror.com/csukuangfj/'
      'sherpa-onnx-paraformer-zh-small-2024-03-09/resolve/main/model.int8.onnx';

  static const String _tokensUrl =
      'https://hf-mirror.com/csukuangfj/'
      'sherpa-onnx-paraformer-zh-small-2024-03-09/resolve/main/tokens.txt';

  static const String _modelSubDir = 'sherpa_onnx/paraformer-zh-small';

  final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  Stream<double> get onProgress => _progressController.stream;

  Future<bool> isModelDownloaded() async {
    final dir = await _modelDir;
    return File(p.join(dir.path, 'model.int8.onnx')).existsSync() &&
        File(p.join(dir.path, 'tokens.txt')).existsSync();
  }

  Future<Directory> get _modelDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, _modelSubDir));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<String> get modelPath async {
    final dir = await _modelDir;
    return p.join(dir.path, 'model.int8.onnx');
  }

  Future<String> get tokensPath async {
    final dir = await _modelDir;
    return p.join(dir.path, 'tokens.txt');
  }

  Future<bool> _downloadFile(String url, File outputFile) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);
      if (response.statusCode != 200) return false;
      final sink = outputFile.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
      }
      await sink.close();
      return true;
    } finally {
      client.close();
    }
  }

  Future<bool> downloadModel() async {
    final dir = await _modelDir;
    try {
      final tokensFile = File(p.join(dir.path, 'tokens.txt'));
      final tokensOk = await _downloadFile(_tokensUrl, tokensFile);
      if (!tokensOk) {
        _progressController.addError('下载 tokens.txt 失败');
        return false;
      }

      _progressController.add(0.0);

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(_modelUrl));
      final response = await client.send(request);
      if (response.statusCode != 200) {
        _progressController.addError('下载模型失败：HTTP ${response.statusCode}');
        client.close();
        return false;
      }

      final totalBytes = response.contentLength ?? -1;
      var downloadedBytes = 0;
      final modelFile = File(p.join(dir.path, 'model.int8.onnx'));
      final sink = modelFile.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        if (totalBytes > 0) {
          _progressController.add(downloadedBytes / totalBytes);
        }
      }
      await sink.close();
      client.close();

      final modelOk =
          modelFile.existsSync() && modelFile.lengthSync() > 1000000;
      final tokensFileOk =
          tokensFile.existsSync() && tokensFile.lengthSync() > 100;
      if (!modelOk || !tokensFileOk) {
        _progressController.addError('下载的文件不完整');
        return false;
      }

      _progressController.add(1.0);
      return true;
    } catch (e) {
      _progressController.addError('下载失败: $e');
      return false;
    }
  }

  void dispose() => _progressController.close();
}
