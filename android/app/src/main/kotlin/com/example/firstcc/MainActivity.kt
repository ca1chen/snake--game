package com.example.firstcc

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.firstcc/share"
    private var pendingShareUri: Uri? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getSharedFile") {
                    pendingShareUri?.let { uri ->
                        val path = copyToTemp(uri)
                        pendingShareUri = null
                        if (path != null) {
                            result.success(path)
                        } else {
                            result.error("COPY_FAILED", "无法复制文件", null)
                        }
                    } ?: result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleShareIntent(intent)
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        handleShareIntent(intent)
    }

    private fun handleShareIntent(intent: Intent?) {
        if (intent == null) return
        if (Intent.ACTION_SEND == intent.action || Intent.ACTION_VIEW == intent.action) {
            val uri: Uri? = intent.getParcelableExtra(Intent.EXTRA_STREAM) ?: intent.data
            if (uri != null) {
                pendingShareUri = uri
            }
        }
    }

    private fun copyToTemp(uri: Uri): String? {
        return try {
            val inputStream = contentResolver.openInputStream(uri) ?: return null
            val ext = if (uri.toString().endsWith(".xls")) ".xls" else ".html"
            val tempFile = File.createTempFile("course_import", ext, cacheDir)
            FileOutputStream(tempFile).use { output ->
                inputStream.copyTo(output)
            }
            inputStream.close()
            tempFile.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}
