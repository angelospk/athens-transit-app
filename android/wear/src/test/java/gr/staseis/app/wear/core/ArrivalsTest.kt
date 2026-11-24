package gr.staseis.app.wear.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ArrivalsTest {
    private val t = 1_795_540_000L

    @Test fun decodesSpecExample() {
        val body = """{"stop":{"id":"340098","name":"ΠΑΠΑΣΠΥΡΟΥ","lat":37.95,"lon":23.71,"code":"340098"},
            "lines":["040","137"],
            "arrivals":[{"line":"040","headsign":"ΠΕΙΡΑΙΑΣ - ΣΥΝΤΑΓΜΑ","eta_s":180,"at":${t + 365},
            "delay_s":1571,"source":"live","stops_away":3,"distance_m":783,"future":{"x":1}}]}"""
        val d = Arrivals.decode(body, "340098", t)!!
        assertEquals("ΠΑΠΑΣΠΥΡΟΥ", d.name)
        assertEquals(listOf(Arrival("040", "ΠΕΙΡΑΙΑΣ - ΣΥΝΤΑΓΜΑ", t + 365, 1571)), d.arrivals)
    }

    @Test fun missingFields() {
        val body = """{"arrivals":[
            {"headsign":"no line","eta_s":60},
            {"line":"","eta_s":60},
            {"line":"A1"},
            {"line":"B2","eta_s":120},
            {"line":"C3","at":${t + 30}},
            {"line":737,"eta_s":10},
            "junk", null, 5]}"""
        val d = Arrivals.decode(body, "1", t)!!
        assertEquals("", d.name)
        assertEquals(listOf("737", "C3", "B2"), d.arrivals.map { it.line })
        assertEquals(t + 120, d.arrivals.last().atS)
        assertNull(d.arrivals.last().delayS)
        assertEquals("", d.arrivals.last().headsign)
    }

    @Test fun noArrivalsKey() {
        assertEquals(0, Arrivals.decode("""{"stop":{}}""", "1", t)!!.arrivals.size)
    }

    @Test fun clamping() {
        val body = """{"arrivals":[{"line":"A","eta_s":-50},{"line":"B","eta_s":99999},{"line":"C","at":${t + 999_999}}]}"""
        val d = Arrivals.decode(body, "1", t)!!.arrivals.associateBy { it.line }
        assertEquals(t, d["A"]!!.atS)
        assertEquals(t + 7200, d["B"]!!.atS)
        assertEquals(t + 7200, d["C"]!!.atS)
    }

    @Test fun malformedJson() {
        listOf(null, "", "not json", "{", "[1,2]", """{"arrivals":"x"}""").forEach {
            val d = Arrivals.decode(it, "1", t)
            assertTrue("$it", d == null || d.arrivals.isEmpty())
        }
        assertNull(Arrivals.decode("not json", "1", t))
        assertNull(Arrivals.decode("x".repeat(Arrivals.MAX_BODY + 1), "1", t))
    }
}
