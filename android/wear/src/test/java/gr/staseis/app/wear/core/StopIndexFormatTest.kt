package gr.staseis.app.wear.core

import gr.staseis.app.wear.core.StopIndexFormat.RawStop
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class StopIndexFormatTest {
    // Three stops all named ΣΥΝΤΑΓΜΑ near Syntagma (the watchOS case), plus one far away.
    private val rows = listOf(
        RawStop("ΣΥΝΤΑΓΜΑ", "37.9755", "23.7348", "1001"),
        RawStop("ΣΥΝΤΑΓΜΑ", "37.9760", "23.7350", "1002"),
        RawStop("ΣΥΝΤΑΓΜΑ", "37.9750", "23.7340", "1003"),
        RawStop("ΠΕΙΡΑΙΑΣ", "37.9420", "23.6465", "2001"),
    )
    private val l = listOf(
        "11" to listOf(0, 1), "2" to listOf(0), "1" to listOf(0, 3), "4" to listOf(0),
        "040" to listOf(0, 3), "Α2" to listOf(0), "137" to listOf(0), "550" to listOf(2), "2" to listOf(0, 2),
    )

    @Test fun nearestStopsCarryTheirLines() {
        val stops = StopIndexFormat.build(rows, l)
        val near = Nearest.nearest(stops, 37.9755, 23.7348)
        assertEquals(listOf("1001", "1002", "1003"), near.map { it.stop.id }) // ~0, 57, 88 m
        assertEquals(listOf("1", "2", "4", "11", "040", "137", "Α2"), near[0].stop.lines)
        assertEquals(listOf("11"), near[1].stop.lines)
        assertEquals(listOf("2", "550"), near[2].stop.lines)
        assertEquals("0 m · 1, 2, 4, 11 +3", Format.nearbyLabel(near[0]))
        assertEquals("70 m · 2, 550", Format.nearbyLabel(NearStop(near[2].stop, 70)))
    }

    @Test fun malformedLinesGiveNoLines() {
        val bad = listOf(
            "1" to listOf(-1, 99, Int.MAX_VALUE),
            "bad line!" to listOf(0, 1),
            "" to listOf(0),
            "123456789" to listOf(0),
        )
        StopIndexFormat.build(rows, bad).forEach { assertTrue(it.id, it.lines.isEmpty()) }
        StopIndexFormat.build(rows, emptyList()).forEach { assertTrue(it.lines.isEmpty()) }
        val near = Nearest.nearest(StopIndexFormat.build(rows, bad), 37.9755, 23.7348)
        assertEquals("0 m", Format.nearbyLabel(near[0]))
    }

    @Test fun badRowsSkippedButIndicesKept() {
        val r = listOf(
            RawStop(null, null, null, null), // a malformed `s` entry keeps its index
            RawStop("A", "x", "23.7", "1"),
            RawStop("B", "37.9", "23.7", "bad id"),
            RawStop("C\tD\nE", "37.9", "23.7", "3"),
        )
        val out = StopIndexFormat.build(r, listOf("7" to listOf(3)))
        assertEquals(1, out.size)
        assertEquals(IndexStop("3", "C D E", 37.9, 23.7, listOf("7")), out[0])
    }

    @Test fun tsvRoundTrip() {
        StopIndexFormat.build(rows, l).forEach { assertEquals(it, StopIndexFormat.decode(StopIndexFormat.encode(it))) }
        assertNull(StopIndexFormat.decode("1001\t37.9\t23.7\tΣΥΝΤΑΓΜΑ")) // format 1 line
        assertNull(StopIndexFormat.decode("garbage"))
        assertEquals(listOf("1"), StopIndexFormat.decode("9\t1.0\t2.0\t1,bad line,\tX")!!.lines)
    }

    @Test fun linesLabel() {
        assertEquals("", Format.linesLabel(emptyList()))
        assertEquals("1, 2", Format.linesLabel(listOf("1", "2")))
        assertEquals("1, 2, 4, 11", Format.linesLabel(listOf("1", "2", "4", "11")))
        assertEquals("1, 2, 4, 11 +3", Format.linesLabel(listOf("1", "2", "4", "11", "12", "13", "14")))
    }
}
