package gr.staseis.app.wear.core

/** What the stop screen shows, from the cache and the last attempt. Pure, so it is unit-tested. */
sealed interface StopView {
    data object Loading : StopView
    data object NoData : StopView
    /** [rows] may be empty ("no bus with GPS"). [offline]: the last attempt failed, rows are dimmed. */
    data class Rows(val rows: List<Arrival>, val updatedAtS: Long, val offline: Boolean) : StopView

    companion object {
        const val MAX_ROWS = 8

        fun of(data: StopData?, fetchedAtS: Long?, lastFailed: Boolean, decodeFailed: Boolean, nowS: Long): StopView {
            if (decodeFailed) return NoData
            if (data == null || fetchedAtS == null) return if (lastFailed) NoData else Loading
            val age = nowS - fetchedAtS
            if (age > Format.STALE_AFTER_S) return if (lastFailed) NoData else Loading
            return Rows(Format.upcoming(data.arrivals, nowS).take(MAX_ROWS), fetchedAtS, lastFailed)
        }
    }
}

/** One entry for the tile / complication timeline: shown from [startS] until [endS] (null = open). */
data class NextBusEntry(val startS: Long, val endS: Long?, val line: String?, val minutes: String?) {
    val isEmpty get() = line == null
    fun short(dash: String = "—"): String = if (line == null) dash else "$line · $minutes"
}

object NextBusTimeline {
    private const val MAX_ENTRIES = 30

    /**
     * Minute-by-minute entries from [nowS] built from cached arrivals, so the time rolls without a fetch.
     * After the last known arrival, or once the data is older than 20 min, a final open "—" entry.
     */
    fun build(arrivals: List<Arrival>, lines: List<String>, fetchedAtS: Long?, nowS: Long, nowWord: String): List<NextBusEntry> {
        if (fetchedAtS == null) return listOf(NextBusEntry(nowS, null, null, null))
        val pick = arrivals.filter { lines.isEmpty() || it.line in lines }.sortedBy { it.atS }
        val staleAt = fetchedAtS + Format.STALE_AFTER_S
        val out = ArrayList<NextBusEntry>()
        var t = nowS
        while (t < staleAt && out.size < MAX_ENTRIES) {
            // The bus stays as "now" until it is due; then the next one.
            val next = pick.firstOrNull { it.atS >= t } ?: break
            out += NextBusEntry(t, minOf(t + 60, staleAt), next.line, Format.minutesLabel(next.atS, t, nowWord))
            t += 60
        }
        out += NextBusEntry(maxOf(nowS, minOf(t, staleAt)), null, null, null)
        return out
    }
}
