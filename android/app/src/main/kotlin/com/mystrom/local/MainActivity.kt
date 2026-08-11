package ch.mystrom.local

import android.Manifest
import android.annotation.SuppressLint
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.location.LocationManager
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "mystrom.local/wifi"
    private val REQUEST_CODE_PERMISSIONS = 4242
    private val SCAN_TIMEOUT_MS = 8000L

    private var wifiManager: WifiManager? = null
    private var pendingScanResult: MethodChannel.Result? = null
    private var scanReceiver: BroadcastReceiver? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            android.util.Log.i("MyStromWifi", "MethodChannel received: ${call.method}")
            when (call.method) {
                "scanMyStromAps" -> {
                    pendingScanResult = result
                    if (hasWifiScanPermission()) {
                        performWifiScan(result)
                    } else {
                        android.util.Log.w("MyStromWifi", "No WiFi scan permission, requesting...")
                        requestWifiScanPermission()
                    }
                }
                "getCurrentSsid" -> {
                    result.success(getCurrentSsid())
                }
                "connectToAp" -> {
                    // On Android 10+ you cannot programmatically connect to
                    // an arbitrary open network. We just tell the user to
                    // connect manually via system settings.
                    result.success(false)
                }
                "disconnectFromAp" -> {
                    // On modern Android we cannot force-disconnect either.
                    result.success(false)
                }
                else -> result.notImplemented()
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun performWifiScan(result: MethodChannel.Result) {
        val mgr = wifiManager ?: run {
            android.util.Log.e("MyStromWifi", "No WifiManager")
            result.error("no_wifi_manager", "WifiManager unavailable", null)
            return
        }

        android.util.Log.i("MyStromWifi", "performWifiScan: starting async scan...")

        // On Android 6-9, WiFi scan results are empty when Location (GPS) is
        // turned off in system settings. Warn the user in that case.
        if (!isLocationEnabled()) {
            android.util.Log.w("MyStromWifi", "Location (GPS) is OFF — WiFi scan may return empty")
        }

        // Try to kick off a fresh scan first. On Android 9+ startScan() is
        // throttled and may return false, but we still register for the
        // broadcast — the system may emit it from a previous pending scan
        // or when WiFi state changes. If no broadcast arrives within
        // SCAN_TIMEOUT_MS we fall back to whatever cached results exist.
        try {
            val started = mgr.startScan()
            android.util.Log.i("MyStromWifi", "startScan() returned: $started")
        } catch (e: Exception) {
            android.util.Log.e("MyStromWifi", "startScan exception: ${e.message}")
        }

        // Register a one-shot receiver for SCAN_RESULTS_AVAILABLE_ACTION.
        // The receiver fires when the system has fresh scan results.
        scanReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                android.util.Log.i("MyStromWifi", "SCAN_RESULTS_AVAILABLE_ACTION received")
                handler.removeCallbacksAndMessages(null)
                context.unregisterReceiver(this)
                scanReceiver = null
                deliverScanResults(result)
            }
        }

        try {
            registerReceiver(
                scanReceiver,
                IntentFilter(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION)
            )
        } catch (e: Exception) {
            android.util.Log.e("MyStromWifi", "registerReceiver failed: ${e.message}")
        }

        // Fallback timeout: if no broadcast within 8s, deliver whatever
        // cached scan results the system already has.
        handler.postDelayed({
            scanReceiver?.let { rcv ->
                android.util.Log.w("MyStromWifi", "Scan timed out, using cached results")
                try { unregisterReceiver(rcv) } catch (_: Exception) {}
                scanReceiver = null
                deliverScanResults(result)
            }
        }, SCAN_TIMEOUT_MS)
    }

    @SuppressLint("MissingPermission")
    private fun deliverScanResults(result: MethodChannel.Result) {
        val mgr = wifiManager ?: run {
            result.error("no_wifi_manager", "WifiManager unavailable", null)
            return
        }

        val results = mgr.scanResults
        android.util.Log.i("MyStromWifi", "scanResults count: ${results.size}")

        val apList = mutableListOf<Map<String, Any>>()

        // myStrom AP SSID prefixes — must match lib/core/utils/ap_ssid.dart.
        val prefixes = listOf(
            "my-bulb-", "my-button-", "my-switch-", "my-pir-",
            "my-cube-lamp-", "my-strip-", "my-bp2-", "my-bm1-"
        )
        val genericPrefix = "my-"

        for (r in results) {
            val ssid = r.SSID ?: continue
            if (ssid.isEmpty()) continue
            val lower = ssid.lowercase()

            val matches = prefixes.any { lower.startsWith(it) } || lower.startsWith(genericPrefix)
            if (!matches) continue

            android.util.Log.i("MyStromWifi", "Found myStrom AP: $ssid (${r.level} dBm)")

            val bssid = r.BSSID ?: ""
            val signal = r.level
            val freq = r.frequency

            apList.add(mapOf(
                "ssid" to ssid,
                "bssid" to bssid,
                "signal" to signal,
                "frequency" to freq
            ))
        }

        android.util.Log.i("MyStromWifi", "Returning ${apList.size} myStrom APs")
        result.success(apList)
    }

    @SuppressLint("MissingPermission")
    private fun getCurrentSsid(): String? {
        val mgr = wifiManager ?: return null
        if (!hasWifiScanPermission()) return null

        @Suppress("DEPRECATION")
        val info = mgr.connectionInfo
        var ssid = info.ssid
        // Android wraps the SSID in quotes: "\"my-bulb-abc\"".
        if (ssid.startsWith("\"") && ssid.endsWith("\"")) {
            ssid = ssid.substring(1, ssid.length - 1)
        }
        // "<unknown ssid>" when not connected / no permission.
        if (ssid == "<unknown ssid>") return null
        return ssid
    }

    private fun hasWifiScanPermission(): Boolean {
        // Android 13+ (API 33): NEARBY_WIFI_DEVICES
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return ActivityCompat.checkSelfPermission(
                this, Manifest.permission.NEARBY_WIFI_DEVICES
            ) == PackageManager.PERMISSION_GRANTED ||
            ActivityCompat.checkSelfPermission(
                this, Manifest.permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        }
        // Android 6-12: ACCESS_FINE_LOCATION
        return ActivityCompat.checkSelfPermission(
            this, Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }

    /// Check whether system Location (GPS) is enabled. On Android 6-9 the
    /// WiFi scan returns empty results when Location is off.
    @SuppressLint("MissingPermission")
    private fun isLocationEnabled(): Boolean {
        val lm = getSystemService(Context.LOCATION_SERVICE) as? LocationManager
            ?: return true // assume enabled if we can't check
        return lm.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
            lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
    }

    private fun requestWifiScanPermission() {
        val perms = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            arrayOf(
                Manifest.permission.NEARBY_WIFI_DEVICES,
                Manifest.permission.ACCESS_FINE_LOCATION
            )
        } else {
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }
        ActivityCompat.requestPermissions(this, perms, REQUEST_CODE_PERMISSIONS)
    }

    @SuppressLint("MissingPermission")
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_CODE_PERMISSIONS) return

        val result = pendingScanResult ?: return
        pendingScanResult = null

        val granted = grantResults.isNotEmpty() &&
            grantResults.any { it == PackageManager.PERMISSION_GRANTED }

        if (granted) {
            performWifiScan(result)
        } else {
            result.error(
                "permission_denied",
                "WiFi scan requires Nearby Wi-Fi devices or Location permission. " +
                "Grant it in Settings → Apps → mystrom_local → Permissions.",
                null
            )
        }
    }
}
