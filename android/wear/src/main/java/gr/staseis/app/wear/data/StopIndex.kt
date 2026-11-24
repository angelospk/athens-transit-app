package gr.staseis.app.wear.data

import android.content.Context
import android.util.JsonReader
import android.util.JsonToken
import gr.staseis.app.wear.core.City
import gr.staseis.app.wear.core.IndexStop
import gr.staseis.app.wear.core.StopIndexFormat
import gr.staseis.app.wear.core.StopIndexFormat.RawStop
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.io.File
import java.io.InputStreamReader

/**
 * The stop index (`trips.json`), reduced to its stops and the lines that serve each one, kept as a
 * compact TSV in app-private files (see [StopIndexFormat]). Refreshed at most weekly with a conditional GET.
 */
object StopIndex {
    private const val MAX_INDEX_BYTES = 8L * 1024 * 1024
    private const val WEEK_MS = 7L * 24 * 3600 * 1000
    private const val PREFS = "stop_index"

    private val mutex = Mutex()
    private val memory = java.util.concurrent.ConcurrentHashMap<City, List<IndexStop>>()

    private fun file(ctx: Context, city: City) =
        File(ctx.applicationContext.filesDir, "stops-v${StopIndexFormat.VERSION}-${city.key}.tsv")

    /**
     * The stops of [city]. With a cached index it returns at once and, when the index is over a week old,
     * refreshes it in the background (an unreachable server must not delay Nearby). Without one it has to
     * download first. Empty on failure.
     */
    suspend fun stops(ctx: Context, city: City): List<IndexStop> = withContext(Dispatchers.IO) {
        val app = ctx.applicationContext
        File(app.filesDir, "stops-${city.key}.tsv").delete() // format 1
        val f = file(app, city)
        if (!f.exists()) {
            mutex.withLock { if (!f.exists()) tryDownload(app, city, f) }
        } else if (isDue(app, city)) {
            AppScope.launch { mutex.withLock { if (isDue(app, city)) tryDownload(app, city, f) } }
        }
        memory[city]?.let { return@withContext it }
        val list = try {
            if (f.exists()) f.bufferedReader().useLines { l -> l.mapNotNull(StopIndexFormat::decode).toList() } else emptyList()
        } catch (_: Exception) {
            emptyList()
        }
        if (list.isNotEmpty()) memory[city] = list
        list
    }

    private fun isDue(ctx: Context, city: City): Boolean {
        val checked = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getLong("${city.key}.checked", 0)
        return System.currentTimeMillis() - checked > WEEK_MS
    }

    private fun tryDownload(ctx: Context, city: City, f: File) {
        try {
            download(ctx, city, f)
        } catch (_: Exception) {
            // Keep the old file, if any; try again next time.
        }
    }

    private fun download(ctx: Context, city: City, f: File) {
        val prefs = ctx.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val have = f.exists()
        // Without the file (first run, or a new cache format) never send validators: a 304 would leave us empty.
        val r = Http.open(
            city.stopIndexUrl,
            etag = if (have) prefs.getString("${city.key}.etag", null) else null,
            lastModified = if (have) prefs.getString("${city.key}.lm", null) else null,
        )
        try {
            when (r.code) {
                304 -> {}
                200 -> {
                    val stops = Http.CappedInputStream(r.conn.inputStream, MAX_INDEX_BYTES).use { input ->
                        parse(JsonReader(InputStreamReader(input, Charsets.UTF_8)))
                    }
                    if (stops.isEmpty()) return
                    val tmp = File(f.parentFile, f.name + ".tmp")
                    tmp.bufferedWriter().use { out ->
                        stops.forEach { out.write(StopIndexFormat.encode(it)); out.write("\n") }
                    }
                    tmp.renameTo(f)
                    memory.remove(city)
                    prefs.edit()
                        .putString("${city.key}.etag", r.etag)
                        .putString("${city.key}.lm", r.lastModified)
                        .apply()
                }
                else -> return
            }
            prefs.edit().putLong("${city.key}.checked", System.currentTimeMillis()).apply()
        } finally {
            r.conn.disconnect()
        }
    }

    /** Streams `{"s":[[name,lat,lon,id],...], "l":{line:{variant:[i,...]}}, ...}`; skips anything else. */
    private fun parse(reader: JsonReader): List<IndexStop> {
        val rows = ArrayList<RawStop>(9000)
        val lineStops = ArrayList<Pair<String, List<Int>>>()
        reader.beginObject()
        while (reader.hasNext()) {
            when (reader.nextName()) {
                "s" -> if (reader.peek() == JsonToken.BEGIN_ARRAY) readStops(reader, rows) else reader.skipValue()
                "l" -> if (reader.peek() == JsonToken.BEGIN_OBJECT) readLines(reader, lineStops) else reader.skipValue()
                else -> reader.skipValue()
            }
        }
        reader.endObject()
        return StopIndexFormat.build(rows, lineStops)
    }

    private fun scalar(reader: JsonReader): String? = when (reader.peek()) {
        JsonToken.STRING, JsonToken.NUMBER -> reader.nextString()
        else -> {
            reader.skipValue()
            null
        }
    }

    private fun readStops(reader: JsonReader, rows: MutableList<RawStop>) {
        reader.beginArray()
        while (reader.hasNext()) {
            if (reader.peek() != JsonToken.BEGIN_ARRAY) {
                // Keep the index positions of `s` intact for `l`.
                reader.skipValue()
                rows += RawStop(null, null, null, null)
                continue
            }
            reader.beginArray()
            val v = ArrayList<String?>(4)
            while (reader.hasNext()) {
                if (v.size < 4) v += scalar(reader) else reader.skipValue()
            }
            reader.endArray()
            rows += RawStop(v.getOrNull(0), v.getOrNull(1), v.getOrNull(2), v.getOrNull(3))
        }
        reader.endArray()
    }

    private fun readLines(reader: JsonReader, out: MutableList<Pair<String, List<Int>>>) {
        reader.beginObject()
        while (reader.hasNext()) {
            val line = reader.nextName()
            if (reader.peek() != JsonToken.BEGIN_OBJECT) {
                reader.skipValue()
                continue
            }
            reader.beginObject()
            while (reader.hasNext()) {
                reader.nextName()
                if (reader.peek() != JsonToken.BEGIN_ARRAY) {
                    reader.skipValue()
                    continue
                }
                val idx = ArrayList<Int>()
                reader.beginArray()
                while (reader.hasNext()) {
                    if (reader.peek() == JsonToken.NUMBER) {
                        val d = reader.nextDouble()
                        if (d >= 0 && d < Int.MAX_VALUE && d == Math.floor(d)) idx += d.toInt()
                    } else {
                        reader.skipValue()
                    }
                }
                reader.endArray()
                out += line to idx
            }
            reader.endObject()
        }
        reader.endObject()
    }
}
