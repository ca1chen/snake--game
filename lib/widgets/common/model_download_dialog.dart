import 'package:flutter/material.dart';
import '../../services/speech_service.dart';
import '../../utils/app_strings.dart';

/// 语音识别模型下载对话框（公共组件）
class ModelDownloadDialog extends StatefulWidget {
  final SpeechService speech;

  const ModelDownloadDialog({super.key, required this.speech});

  @override
  State<ModelDownloadDialog> createState() => _ModelDownloadDialogState();
}

class _ModelDownloadDialogState extends State<ModelDownloadDialog> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.speech.modelDownloadProgress.listen((progress) {
      if (!mounted) return;
      if (progress >= 1.0) {
        // 完成，关闭对话框
        Navigator.of(context).pop();
      } else {
        setState(() {
          _downloading = true;
          _progress = progress;
        });
      }
    }).onError((error) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _error = error.toString();
        });
      }
    });
  }

  Future<void> _startDownload() async {
    setState(() {
      _downloading = true;
      _error = null;
    });
    final ok = await widget.speech.downloadModel();
    if (!ok && mounted) {
      setState(() {
        _downloading = false;
        _error = AppStrings.modelDownloadFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text(AppStrings.modelDownloadTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.modelDownloadDesc, style: theme.textTheme.bodyMedium),
          if (_downloading) ...[
            const SizedBox(height: 20),
            LinearProgressIndicator(value: _progress > 0 ? _progress : null),
            const SizedBox(height: 8),
            Text(
              _progress > 0
                  ? '${(_progress * 100).toStringAsFixed(0)}%'
                  : AppStrings.modelDownloading,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
            ),
          ],
        ],
      ),
      actions: [
        if (!_downloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
        if (!_downloading)
          FilledButton(
            onPressed: _startDownload,
            child: const Text(AppStrings.modelDownloadStart),
          ),
      ],
    );
  }
}
