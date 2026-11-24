package gr.staseis.app.wear.core

/**
 * The compact stop cache built from `trips.json`: `s` = `[[name, lat, lon, id], ...]` and
 * `l` = `{line: {variant: [index into s, ...]}}`. Stored as TSV, one stop per line:
 * `id \t lat \t lon \t line,line,... \t name`. Pure, so it is unit-tested; the streaming JSON reader
 * (data/StopIndex) only collects the raw values.
 */
object StopIndexFormat {
    /** Bump when the TSV layout changes: the cache file name carries it, so an old file is ignored. */
    const val VERSION = 2
    private val WS = Regex("[\\t\\r\\n]")

    /** One raw `s` row, as strings (numbers come as their text). */
    data class RawStop(val name: String?, val lat: String?, val lon: String?, val id: String?)

    /**
     * Validated stops with their lines. [lineStops]: (line, indices into [rows]) for every variant;
     * bad lines and out-of-range indices are skipped.
     */
    fun build(rows: List<RawStop>, lineStops: List<Pair<String, List<Int>>>): List<IndexStop> {
        val lines = arrayOfNulls<MutableSet<String>>(rows.size)
        for ((line, idx) in lineStops) {
            if (!Payload.LINE_RE.matches(line)) continue
            for (i in idx) {
                if (i !in rows.indices) continue
                (lines[i] ?: HashSet<String>().also { lines[i] = it }).add(line)
            }
        }
        val out = ArrayList<IndexStop>(rows.size)
        rows.forEachIndexed { i, r ->
            val id = r.id?.takeIf { Payload.ID_RE.matches(it) } ?: return@forEachIndexed
            val lat = r.lat?.toDoubleOrNull()?.takeIf { it.isFinite() && it in -90.0..90.0 } ?: return@forEachIndexed
            val lon = r.lon?.toDoubleOrNull()?.takeIf { it.isFinite() && it in -180.0..180.0 } ?: return@forEachIndexed
            val name = (r.name ?: "").replace(WS, " ").trim().take(Payload.MAX_NAME)
            out += IndexStop(id, name, lat, lon, lines[i]?.sortedWith(LineOrder).orEmpty())
        }
        return out
    }

    fun encode(s: IndexStop): String = "${s.id}\t${s.lat}\t${s.lon}\t${s.lines.joinToString(",")}\t${s.name}"

    /** One TSV line back to a stop, or null when it is not valid. */
    fun decode(line: String): IndexStop? {
        val p = line.split('\t', limit = 5)
        if (p.size != 5 || !Payload.ID_RE.matches(p[0])) return null
        val lat = p[1].toDoubleOrNull() ?: return null
        val lon = p[2].toDoubleOrNull() ?: return null
        val lines = if (p[3].isEmpty()) emptyList() else p[3].split(',').filter { Payload.LINE_RE.matches(it) }
        return IndexStop(p[0], p[4], lat, lon, lines)
    }

    /** Natural order: numbers by value (040 = 40, before 137), then the rest alphabetically. */
    object LineOrder : Comparator<String> {
        private fun num(s: String) = s.takeWhile { it.isDigit() }.toIntOrNull()
        override fun compare(a: String, b: String): Int {
            val na = num(a)
            val nb = num(b)
            return when {
                na != null && nb != null && na != nb -> na.compareTo(nb)
                na != null && nb == null -> -1
                na == null && nb != null -> 1
                else -> a.compareTo(b)
            }
        }
    }
}
