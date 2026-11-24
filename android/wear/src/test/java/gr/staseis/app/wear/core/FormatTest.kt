package gr.staseis.app.wear.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class FormatTest {
    private val now = 1_795_540_000L

    @Test fun minutes() {
        assertEquals("now", Format.minutesLabel(now, now, "now"))
        assertEquals("now", Format.minutesLabel(now - 100, now, "now"))
        assertEquals("now", Format.minutesLabel(now + 44, now, "now"))
        assertEquals("1′", Format.minutesLabel(now + 45, now, "now"))
        assertEquals("1′", Format.minutesLabel(now + 89, now, "now"))
        assertEquals("2′", Format.minutesLabel(now + 90, now, "now"))
        assertEquals("3′", Format.minutesLabel(now + 180, now, "now"))
        assertEquals("12′", Format.minutesLabel(now + 12 * 60 + 10, now, "τώρα"))
        assertEquals("τώρα", Format.minutesLabel(now + 10, now, "τώρα"))
    }

    @Test fun cachedAnswerStaysRight() {
        // Fetched 2 min ago with a bus due in 5 min: now 3′.
        assertEquals("3′", Format.minutesLabel(now + 180, now, "now"))
    }

    @Test fun lateLevels() {
        assertNull(Format.late(null))
        assertNull(Format.late(-600)) // earlier: no badge on the watch
        assertNull(Format.late(-60))
        assertNull(Format.late(0))
        assertNull(Format.late(90))
        assertNull(Format.late(300))
        assertEquals(Late.AMBER, Format.late(301))
        assertEquals(Late.AMBER, Format.late(600))
        assertEquals(Late.RED, Format.late(601))
        assertEquals(Late.RED, Format.late(1571))
        assertNull(Format.lateLabel(300))
        assertEquals("+5′", Format.lateLabel(301))
        assertEquals("+10′", Format.lateLabel(600))
        assertEquals("+26′", Format.lateLabel(1571))
    }

    @Test fun summaryFiltersLines() {
        val a = listOf(
            Arrival("040", "", now + 180, null), Arrival("550", "", now + 240, null),
            Arrival("137", "", now + 720, null), Arrival("040", "", now + 900, null),
        )
        assertEquals("040 3′ · 137 12′", Format.nextSummary(a, now, listOf("040", "137"), "now"))
        assertEquals("040 3′ · 550 4′", Format.nextSummary(a, now, emptyList(), "now"))
        assertEquals("", Format.nextSummary(a, now, listOf("999"), "now"))
    }
}
