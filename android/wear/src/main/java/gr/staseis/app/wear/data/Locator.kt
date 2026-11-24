package gr.staseis.app.wear.data

import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import com.google.android.gms.location.CurrentLocationRequest
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withTimeoutOrNull

/** One-shot location, only while the Nearby screen is open. The position never leaves the watch. */
object Locator {
    private const val TIMEOUT_MS = 10_000L
    private const val REUSE_MS = 2 * 60 * 1000L

    /** Caller must hold a location permission. Null on timeout or failure. */
    @SuppressLint("MissingPermission")
    suspend fun current(ctx: Context): Location? = try {
        val client = LocationServices.getFusedLocationProviderClient(ctx.applicationContext)
        val last = try { client.lastLocation.await() } catch (_: Exception) { null }
        if (last != null && System.currentTimeMillis() - last.time < REUSE_MS) {
            last
        } else {
            val cts = CancellationTokenSource()
            val req = CurrentLocationRequest.Builder()
                .setPriority(Priority.PRIORITY_BALANCED_POWER_ACCURACY)
                .setDurationMillis(TIMEOUT_MS)
                .setMaxUpdateAgeMillis(REUSE_MS)
                .build()
            try {
                withTimeoutOrNull(TIMEOUT_MS) { client.getCurrentLocation(req, cts.token).await() }
            } finally {
                cts.cancel()
            }
        }
    } catch (_: Exception) {
        null
    }
}
