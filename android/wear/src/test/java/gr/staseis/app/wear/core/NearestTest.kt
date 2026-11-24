package gr.staseis.app.wear.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class NearestTest {
    // Syntagma, Athens.
    private val lat = 37.9755
    private val lon = 23.7348

    /** A stop [m] metres north of the point (1° lat ≈ 111 195 m). */
    private fun north(id: String, m: Double) = IndexStop(id, "S$id", lat + m / 111_195.0, lon)

    @Test fun orderingAndLimit() {
        val stops = listOf(north("a", 500.0), north("b", 100.0), north("c", 900.0), north("d", 50.0),
            north("e", 300.0), north("f", 700.0))
        val r = Nearest.nearest(stops, lat, lon)
        assertEquals(listOf("d", "b", "e", "a", "f"), r.map { it.stop.id })
        assertTrue(kotlin.math.abs(r[0].distanceM - 50) <= 1)
        assertTrue(kotlin.math.abs(r[1].distanceM - 100) <= 1)
    }

    @Test fun oneKilometreCut() {
        val r = Nearest.nearest(listOf(north("in", 990.0), north("out", 1010.0)), lat, lon)
        assertEquals(listOf("in"), r.map { it.stop.id })
        assertEquals(0, Nearest.nearest(emptyList(), lat, lon).size)
    }

    @Test fun haversine() {
        // Syntagma → Piraeus port ≈ 8.9 km.
        val d = Nearest.haversineM(lat, lon, 37.9420, 23.6465)
        assertTrue("$d", d in 8_000.0..9_500.0)
        assertEquals(0.0, Nearest.haversineM(lat, lon, lat, lon), 1e-6)
    }

    @Test fun cityBox() {
        assertEquals(City.ATHENS, City.at(lat, lon))
        assertEquals(City.THESSALONIKI, City.at(40.6401, 22.9444))
        assertNull(City.at(39.6650, 20.8537)) // Ioannina
        assertNull(City.at(51.5, -0.12))
        assertEquals(City.ATHENS, City.at(37.5, 22.9)) // edge inclusive
    }
}
