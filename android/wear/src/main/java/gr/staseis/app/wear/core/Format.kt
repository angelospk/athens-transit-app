package gr.staseis.app.wear.core

import kotlin.math.roundToLong

enum class Late { AMBER, RED }

object Format {
    const val NOW_UNDER_S = 45
    /** Cached rows stay on screen (dimmed) this long after the last update. */
    const val STALE_AFTER_S = 20 * 60

    /** Whole minutes until [atS], or null for "now" (under 45 s, or past). */
    fun minutesUntil(atS: Long, nowS: Long): Long? {
        val d = maxOf(0L, atS - nowS)
        if (d < NOW_UNDER_S) return null
        return (d / 60.0).roundToLong()
    }

    /** "τώρα"/"now" (passed in, localized) or "N′". */
    fun minutesLabel(atS: Long, nowS: Long, nowWord: String): String =
        minutesUntil(atS, nowS)?.let { "$it′" } ?: nowWord

    /**
     * Agreed delay levels (backend docs/QUALITY.md, live vehicle level): > 300 s amber, > 600 s red;
     * −60…+300 s, earlier, or missing → no badge.
     */
    fun late(delayS: Int?): Late? = when {
        delayS == null -> null
        delayS > 600 -> Late.RED
        delayS > 300 -> Late.AMBER
        else -> null
    }

    /** "+N′" for a late badge, or null when no badge is shown. */
    fun lateLabel(delayS: Int?): String? =
        if (late(delayS) == null) null else "+${(delayS!! / 60.0).roundToLong()}′"

    /** Arrivals still to come (a bus up to 60 s past due may still be at the stop). */
    fun upcoming(arrivals: List<Arrival>, nowS: Long, lines: List<String> = emptyList()): List<Arrival> =
        arrivals.filter { it.atS >= nowS - 60 && (lines.isEmpty() || it.line in lines) }

    /** "040 3′ · 137 12′": the next [n] arrivals for the chosen lines. */
    fun nextSummary(arrivals: List<Arrival>, nowS: Long, lines: List<String>, nowWord: String, n: Int = 2): String =
        upcoming(arrivals, nowS, lines).take(n).joinToString(" · ") { "${it.line} ${minutesLabel(it.atS, nowS, nowWord)}" }

    fun distanceLabel(m: Int): String = "$m m"

    /** "1, 2, 4, 11 +3": the first [max] lines, then how many more. */
    fun linesLabel(lines: List<String>, max: Int = 4): String {
        if (lines.isEmpty()) return ""
        val head = lines.take(max).joinToString(", ")
        return if (lines.size > max) "$head +${lines.size - max}" else head
    }

    /** Nearby row: "70 m · 1, 2, 4, 11 +3" (just "70 m" when the lines are unknown). */
    fun nearbyLabel(n: NearStop): String =
        linesLabel(n.stop.lines).let { if (it.isEmpty()) distanceLabel(n.distanceM) else "${distanceLabel(n.distanceM)} · $it" }
}
