package gr.staseis.app.wear.data

import android.content.Context
import gr.staseis.app.wear.core.Arrivals
import gr.staseis.app.wear.core.City
import gr.staseis.app.wear.core.Payload
import gr.staseis.app.wear.core.StopData
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.File

/** The last answer for a stop and how the last attempt went. */
data class StopSnapshot(
    val data: StopData?,
    val fetchedAtS: Long?,
    val lastFailed: Boolean,
    val decodeFailed: Boolean,
)

/**
 * Arrivals per stop: one request in flight per stop, back-off 30 → 60 → 120 s after failures, the last
 * body cached in app-private files with its time so the tile, the complication and the offline state
 * can use it.
 */
object ArrivalsRepo {
    private val BACKOFF_S = longArrayOf(30, 60, 120)
    private const val CACHE_MAX_AGE_S = 24 * 3600L

    private class Backoff(var failures: Int = 0, var notBeforeS: Long = 0)

    private val lock = Any()
    private val inflight = HashMap<String, CompletableDeferred<StopSnapshot>>()
    private val backoff = HashMap<String, Backoff>()
    private val flows = HashMap<String, MutableStateFlow<StopSnapshot?>>()

    private fun key(city: City, id: String) = "${city.key}_$id"
    fun nowS() = System.currentTimeMillis() / 1000

    fun flow(city: City, id: String): StateFlow<StopSnapshot?> = mutableFlow(city, id)

    private fun mutableFlow(city: City, id: String): MutableStateFlow<StopSnapshot?> = synchronized(lock) {
        flows.getOrPut(key(city, id)) { MutableStateFlow(null) }
    }

    private fun cacheDir(ctx: Context) = File(ctx.applicationContext.filesDir, "arrivals").apply { mkdirs() }
    private fun cacheFile(ctx: Context, city: City, id: String) = File(cacheDir(ctx), "${key(city, id)}.json")

    /** Cached arrivals (no network). Safe to call from the tile / complication. */
    fun cached(ctx: Context, city: City, id: String): StopSnapshot? {
        if (!Payload.ID_RE.matches(id)) return null
        flow(city, id).value?.let { return it }
        return try {
            val f = cacheFile(ctx, city, id)
            if (!f.exists()) return null
            val o = JSONObject(f.readText())
            val at = o.getLong("at")
            val data = Arrivals.decode(o.optString("body"), id, at)
            val snap = StopSnapshot(data, at, lastFailed = false, decodeFailed = data == null)
            mutableFlow(city, id).compareAndSet(null, snap)
            snap
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Fetches the stop unless a request is already in flight (then waits for it) or the back-off says
     * wait (then returns the cache). Never throws.
     */
    suspend fun refresh(ctx: Context, city: City, id: String): StopSnapshot? {
        if (!Payload.ID_RE.matches(id)) return null
        val k = key(city, id)
        val now = nowS()
        val (deferred, owner) = synchronized(lock) {
            inflight[k]?.let { return@synchronized it to false }
            val b = backoff[k]
            if (b != null && now < b.notBeforeS) return@synchronized null to false
            val d = CompletableDeferred<StopSnapshot>()
            inflight[k] = d
            d to true
        }
        if (deferred == null) return cached(ctx, city, id)
        if (!owner) return deferred.await()
        val snap = try {
            fetch(ctx, city, id)
        } finally {
            synchronized(lock) { inflight.remove(k) }
        }
        deferred.complete(snap)
        return snap
    }

    private suspend fun fetch(ctx: Context, city: City, id: String): StopSnapshot = withContext(Dispatchers.IO) {
        val k = key(city, id)
        val prev = cached(ctx, city, id)
        val snap = try {
            val body = Http.getString("${city.api}/v1/stops/$id", Arrivals.MAX_BODY)
            val at = nowS()
            val data = Arrivals.decode(body, id, at)
            if (data != null) {
                writeCache(ctx, city, id, body, at)
                StopSnapshot(data, at, lastFailed = false, decodeFailed = false)
            } else {
                StopSnapshot(null, at, lastFailed = false, decodeFailed = true)
            }
        } catch (_: Exception) {
            null
        }
        synchronized(lock) {
            if (snap != null && !snap.decodeFailed) {
                backoff.remove(k)
            } else {
                val b = backoff.getOrPut(k) { Backoff() }
                b.notBeforeS = nowS() + BACKOFF_S[minOf(b.failures, BACKOFF_S.size - 1)]
                b.failures++
            }
        }
        val result = snap ?: StopSnapshot(prev?.data, prev?.fetchedAtS, lastFailed = true, decodeFailed = false)
        mutableFlow(city, id).value = result
        result
    }

    private fun writeCache(ctx: Context, city: City, id: String, body: String, at: Long) {
        try {
            val f = cacheFile(ctx, city, id)
            val tmp = File(f.parentFile, f.name + ".tmp")
            tmp.writeText(JSONObject().put("at", at).put("body", body).toString())
            tmp.renameTo(f)
            val cutoff = System.currentTimeMillis() - CACHE_MAX_AGE_S * 1000
            cacheDir(ctx).listFiles()?.forEach { if (it.lastModified() < cutoff) it.delete() }
        } catch (_: Exception) {
        }
    }
}
