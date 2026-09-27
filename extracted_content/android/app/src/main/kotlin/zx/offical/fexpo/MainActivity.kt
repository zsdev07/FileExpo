package zx.offical.fexpo

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges the handful of storage APIs that don't (yet) have a stable
 * first-party Flutter plugin:
 *  - the real root path of primary external storage (path_provider only
 *    exposes app-private directories, which is no good for a file manager)
 *  - Android 11+ "All files access" (MANAGE_EXTERNAL_STORAGE) status + the
 *    settings screen to grant it, since permission_handler's generic
 *    `manageExternalStorage` permission maps to this same intent but we
 *    want a direct, explicit path we control.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "zx.offical.fexpo/storage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getRootPath" -> result.success(
                        Environment.getExternalStorageDirectory().absolutePath
                    )

                    "isManageStorageGranted" -> result.success(
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            Environment.isExternalStorageManager()
                        } else {
                            // Pre-R devices rely on the classic runtime permission
                            // instead, which the Dart side requests separately.
                            true
                        }
                    )

                    "openManageStorageSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            try {
                                val intent = Intent(
                                    Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                                    Uri.parse("package:$packageName")
                                )
                                startActivity(intent)
                            } catch (e: Exception) {
                                // Some OEM ROMs don't support the per-app variant.
                                startActivity(Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION))
                            }
                        }
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
