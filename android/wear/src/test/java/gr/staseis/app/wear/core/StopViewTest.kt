package gr.staseis.app.wear.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class StopViewTest {
    private val now = 1_795_540_000L
    private val data = StopData("1", "S", (0 until 10).map { Arrival("L$it", "", now + 60L * it, null) })

    @Test fun states() {
        assertEquals(StopView.Loading, StopView.of(null, null, false, false, now))
        assertEquals(StopView.NoData, StopView.of(null, null, true, false, now))
        assertEquals(StopView.NoData, StopView.of(null, now, false, true, now))
        val fresh = StopView.of(data, now - 10, false, false, now) as StopView.Rows
        assertEquals(8, fresh.rows.size)
        assertEquals(false, fresh.offline)
        val offline = StopView.of(data, now - 600, true, false, now) as StopView.Rows
        assertTrue(offline.offline)
        assertEquals(StopView.NoData, StopView.of(data, now - 1201, true, false, now))
        val empty = StopView.of(StopData("1", "", emptyList()), now, false, false, now) as StopView.Rows
        assertEquals(0, empty.rows.size)
    }

    @Test fun timelineRollsAndEnds() {
        val arrivals = listOf(Arrival("040", "", now + 180, null), Arrival("137", "", now + 400, null))
        val e = NextBusTimeline.build(arrivals, emptyList(), now, now, "now")
        assertEquals("040 · 3′", e[0].short())
        assertEquals("040 · 2′", e[1].short())
        assertEquals("137 · 3′", e[4].short()) // t+240: 040 gone, 137 in 160 s
        assertEquals(null, e.last().endS)
        assertEquals("—", e.last().short())
        assertEquals(now + 7 * 60, e.last().startS) // no bus after t+400
    }

    @Test fun timelineStopsAtStaleData() {
        val arrivals = listOf(Arrival("040", "", now + 3600, null))
        val e = NextBusTimeline.build(arrivals, emptyList(), now - 1000, now, "now")
        assertEquals(now - 1000 + 1200, e.last().startS)
        assertEquals("—", e.last().short())
        assertEquals("—", NextBusTimeline.build(arrivals, emptyList(), null, now, "now").single().short())
        assertEquals("—", NextBusTimeline.build(arrivals, listOf("137"), now, now, "now").single().short())
    }
}
