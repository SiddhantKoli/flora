package com.example.flora

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val backupChannel = "flora/backup_document"
    private val createRequest = 8401
    private val openRequest = 8402
    private var pendingResult: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, backupChannel)
            .setMethodCallHandler { call, result ->
                if (pendingResult != null) {
                    result.error("busy", "A document picker is already open.", null)
                    return@setMethodCallHandler
                }
                when (call.method) {
                    "save" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        if (bytes == null) {
                            result.error("invalid", "No backup data was provided.", null)
                            return@setMethodCallHandler
                        }
                        pendingResult = result
                        pendingBytes = bytes
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "application/json"
                            putExtra(Intent.EXTRA_TITLE, "flora-backup.json")
                        }
                        startActivityForResult(intent, createRequest)
                    }
                    "open" -> {
                        pendingResult = result
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "*/*"
                            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf(
                                "application/json", "text/plain", "application/octet-stream"))
                        }
                        startActivityForResult(intent, openRequest)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Android activity result API is used for the document picker")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != createRequest && requestCode != openRequest) return
        val result = pendingResult ?: return
        try {
            val uri = if (resultCode == Activity.RESULT_OK) data?.data else null
            if (uri == null) {
                result.success(null)
            } else if (requestCode == createRequest) {
                contentResolver.openOutputStream(uri)?.use { stream ->
                    stream.write(pendingBytes ?: error("Backup data was lost."))
                    stream.flush()
                } ?: error("Could not open the selected document.")
                result.success(true)
            } else {
                val bytes = ByteArrayOutputStream()
                contentResolver.openInputStream(uri)?.use { stream ->
                    val buffer = ByteArray(8192)
                    while (true) {
                        val length = stream.read(buffer)
                        if (length < 0) break
                        if (bytes.size() + length > 200 * 1024 * 1024) {
                            error("The backup is larger than 200 MB.")
                        }
                        bytes.write(buffer, 0, length)
                    }
                } ?: error("Could not open the selected document.")
                result.success(bytes.toByteArray())
            }
        } catch (error: Exception) {
            result.error("document", error.message ?: "Could not read or save the backup.", null)
        } finally {
            pendingResult = null
            pendingBytes = null
        }
    }
}
