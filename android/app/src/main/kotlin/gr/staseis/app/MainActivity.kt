package gr.staseis.app

import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The favourite stops for the Wear OS app (lib/background/watch_sync.dart, docs/WATCH.md): one
        // DataItem the watch reads at start and listens to. Without Google Play services it fails quietly.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "gr.staseis.app/watch").setMethodCallHandler { call, result ->
            if (call.method != "sync") return@setMethodCallHandler result.notImplemented()
            val json = call.arguments as? String
            if (json == null || json.length > 16_000) return@setMethodCallHandler result.error("bad", "payload", null)
            try {
                val req = PutDataMapRequest.create(WATCH_FAVS_PATH).apply { dataMap.putString("json", json) }
                    .asPutDataRequest().setUrgent()
                Wearable.getDataClient(this).putDataItem(req)
                    .addOnSuccessListener { result.success(null) }
                    .addOnFailureListener { result.success(null) } // no watch or no Play services: nothing to do
            } catch (e: Exception) {
                result.success(null)
            }
        }
    }

    companion object {
        const val WATCH_FAVS_PATH = "/staseis/favs"
    }
}
