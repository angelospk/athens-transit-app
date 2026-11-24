package gr.staseis.app.wear.core

/**
 * When the tile / complication may ask for a background refresh, and when a refresh is worth redrawing
 * them. Without these limits a failing stop (outage, captive Wi‑Fi, a stop id that 404s) would loop:
 * worker → redraw → stale cache → worker → …
 */
object RefreshPolicy {
    /** The cache counts as stale after this long. */
    const val STALE_S = 5 * 60L
    /** At most one extra refresh request ("kick") per this interval, persisted across processes. */
    const val MIN_KICK_INTERVAL_S = 10 * 60L

    /**
     * [force]: a user action (favourites changed on the phone, a tile or complication just added); it is
     * not a loop, so it skips both the staleness and the interval checks.
     */
    fun shouldKick(fetchedAtS: Long?, lastKickS: Long?, nowS: Long, force: Boolean = false): Boolean {
        if (force) return true
        val stale = fetchedAtS == null || nowS - fetchedAtS > STALE_S
        if (!stale) return false
        // A clock that went backwards must not block refreshes for good.
        return lastKickS == null || lastKickS > nowS || nowS - lastKickS >= MIN_KICK_INTERVAL_S
    }

    /** Redraw the tile / complication only when the refresh brought new data. */
    fun shouldRedraw(beforeFetchedAtS: Long?, afterFetchedAtS: Long?, afterFailed: Boolean): Boolean =
        !afterFailed && afterFetchedAtS != null && afterFetchedAtS != beforeFetchedAtS
}
