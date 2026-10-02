package zx.offical.fexpo

import android.app.AppOpsManager
import android.app.usage.StorageStatsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Process
import android.os.StatFs
import android.os.storage.StorageManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

/**
 * Bridges the handful of Android APIs that don't (yet) have a stable
 * first-party Flutter plugin:
 *  - the real root path of primary external storage (path_provider only
 *    exposes app-private directories, which is no good for a file manager)
 *  - Android 11+ "All files access" (MANAGE_EXTERNAL_STORAGE) status + the
 *    settings screen to grant it, since permission_handler's generic
 *    `manageExternalStorage` permission maps to this same intent but we
 *    want a direct, explicit path we control.
 *  - total/free space on primary external storage (via [StatFs]), used by
 *    the Storage Analyzer screen.
 *  - the App Manager: listing installed apps with their real app/data/cache
 *    sizes (via [StorageStatsManager]) and last-used timestamps (via
 *    [UsageStatsManager]) — both gated behind the same "Usage access"
 *    special permission — and triggering the system uninstall dialog.
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

                    "getStorageStats" -> {
                        val stat = StatFs(Environment.getExternalStorageDirectory().path)
                        result.success(
                            mapOf(
                                "total" to stat.totalBytes,
                                "free" to stat.freeBytes
                            )
                        )
                    }

                    "hasUsageAccess" -> result.success(hasUsageAccess())

                    "openUsageAccessSettings" -> {
                        try {
                            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        } catch (e: Exception) {
                            // No-op if no OEM screen handles this intent.
                        }
                        result.success(null)
                    }

                    "listInstalledApps" -> {
                        // Iterates every installed package, and for API 26+ queries
                        // StorageStatsManager per app — both can take a noticeable
                        // moment (100+ apps), so this runs off the main thread and
                        // posts the result back to avoid janking the UI.
                        Thread {
                            try {
                                val apps = listInstalledAppsWithStats()
                                runOnUiThread { result.success(apps) }
                            } catch (e: Exception) {
                                runOnUiThread {
                                    result.error("LIST_APPS_FAILED", e.message, null)
                                }
                            }
                        }.start()
                    }

                    "uninstallApp" -> {
                        val pkg = call.argument<String>("packageName")
                        if (pkg != null) {
                            try {
                                startActivity(
                                    Intent(Intent.ACTION_DELETE, Uri.parse("package:$pkg"))
                                )
                            } catch (e: Exception) {
                                // No-op — nothing sensible to do if this fails to launch.
                            }
                        }
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun hasUsageAccess(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun listInstalledAppsWithStats(): List<Map<String, Any>> {
        val pm = packageManager
        val apps = mutableListOf<Map<String, Any>>()
        val installed = pm.getInstalledApplications(PackageManager.GET_META_DATA)

        val storageStatsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            getSystemService(Context.STORAGE_STATS_SERVICE) as? StorageStatsManager
        } else {
            null
        }

        // One aggregated query across every package's history, rather than
        // one query per app — both cheaper and simpler. Needs the same
        // "Usage access" grant as the storage stats above.
        //
        // Deliberately NOT querying from beginTime=0L: on a lot of real
        // devices queryAndAggregateUsageStats silently returns an empty
        // map when given literal epoch-0 as the start (a long-documented
        // platform quirk, not something that throws), which is exactly
        // the "every app shows Never recorded" symptom. A large-but-finite
        // window avoids it.
        val lastUsedMap: Map<String, Long> = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val usageStatsManager =
                    getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
                val now = System.currentTimeMillis()
                val tenYearsMillis = 10L * 365L * 24L * 60L * 60L * 1000L
                val beginTime = (now - tenYearsMillis).coerceAtLeast(0L)
                usageStatsManager
                    ?.queryAndAggregateUsageStats(beginTime, now)
                    ?.mapValues { it.value.lastTimeUsed }
                    ?: emptyMap()
            } catch (e: Exception) {
                emptyMap()
            }
        } else {
            emptyMap()
        }

        for (appInfo in installed) {
            val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            val label = try {
                pm.getApplicationLabel(appInfo).toString()
            } catch (e: Exception) {
                appInfo.packageName
            }

            var appBytes = 0L
            var dataBytes = 0L
            var cacheBytes = 0L

            if (storageStatsManager != null) {
                try {
                    val stats = storageStatsManager.queryStatsForPackage(
                        StorageManager.UUID_DEFAULT,
                        appInfo.packageName,
                        Process.myUserHandle()
                    )
                    appBytes = stats.appBytes
                    dataBytes = stats.dataBytes
                    cacheBytes = stats.cacheBytes
                } catch (e: Exception) {
                    appBytes = apkSizeOf(appInfo)
                }
            } else {
                appBytes = apkSizeOf(appInfo)
            }

            val iconBytes = try {
                drawableToPngBytes(pm.getApplicationIcon(appInfo))
            } catch (e: Exception) {
                ByteArray(0)
            }

            apps.add(
                mapOf(
                    "packageName" to appInfo.packageName,
                    "appName" to label,
                    "isSystemApp" to isSystem,
                    "appBytes" to appBytes,
                    "dataBytes" to dataBytes,
                    "cacheBytes" to cacheBytes,
                    "icon" to iconBytes,
                    "lastUsed" to (lastUsedMap[appInfo.packageName] ?: 0L)
                )
            )
        }
        return apps
    }

    private fun apkSizeOf(appInfo: ApplicationInfo): Long {
        return try {
            File(appInfo.sourceDir).length()
        } catch (e: Exception) {
            0L
        }
    }

    private fun drawableToPngBytes(drawable: Drawable, size: Int = 96): ByteArray {
        val bitmap = if (drawable is BitmapDrawable && drawable.bitmap != null) {
            Bitmap.createScaledBitmap(drawable.bitmap, size, size, true)
        } else {
            val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bmp)
            drawable.setBounds(0, 0, size, size)
            drawable.draw(canvas)
            bmp
        }
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }
}
