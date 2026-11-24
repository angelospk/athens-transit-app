package gr.staseis.app.wear.core

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class RefreshPolicyTest {
    private val now = 1_795_540_000L

    @Test fun kickOnlyWhenStale() {
        assertFalse(RefreshPolicy.shouldKick(fetchedAtS = now - 60, lastKickS = null, nowS = now))
        assertTrue(RefreshPolicy.shouldKick(fetchedAtS = now - 301, lastKickS = null, nowS = now))
        assertTrue(RefreshPolicy.shouldKick(fetchedAtS = null, lastKickS = null, nowS = now))
    }

    @Test fun failingStopCannotLoop() {
        // Cache missing (a 404 stop id, an outage): the first request kicks, then not again for 10 min.
        assertTrue(RefreshPolicy.shouldKick(null, lastKickS = null, nowS = now))
        assertFalse(RefreshPolicy.shouldKick(null, lastKickS = now, nowS = now + 1))
        assertFalse(RefreshPolicy.shouldKick(null, lastKickS = now, nowS = now + 599))
        assertTrue(RefreshPolicy.shouldKick(null, lastKickS = now, nowS = now + 600))
        // A clock that went backwards does not block refreshes.
        assertTrue(RefreshPolicy.shouldKick(null, lastKickS = now + 3600, nowS = now))
    }

    @Test fun forceIsAUserAction() {
        assertTrue(RefreshPolicy.shouldKick(fetchedAtS = now, lastKickS = now, nowS = now, force = true))
    }

    @Test fun redrawOnlyOnNewData() {
        assertTrue(RefreshPolicy.shouldRedraw(beforeFetchedAtS = now - 900, afterFetchedAtS = now, afterFailed = false))
        assertTrue(RefreshPolicy.shouldRedraw(beforeFetchedAtS = null, afterFetchedAtS = now, afterFailed = false))
        // Failure (keeps the old cache time), back-off (returns the cache), nothing at all.
        assertFalse(RefreshPolicy.shouldRedraw(now - 900, now - 900, afterFailed = true))
        assertFalse(RefreshPolicy.shouldRedraw(now - 900, now - 900, afterFailed = false))
        assertFalse(RefreshPolicy.shouldRedraw(null, null, afterFailed = true))
        assertFalse(RefreshPolicy.shouldRedraw(now - 900, now, afterFailed = true))
    }
}
