package gr.staseis.app.wear.core

import kotlin.math.asin
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.math.sqrt

object Nearest {
    const val MAX_DISTANCE_M = 1000.0
    const val LIMIT = 5

    fun haversineM(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
        val r = 6_371_000.0
        val dLat = Math.toRadians(lat2 - lat1)
        val dLon = Math.toRadians(lon2 - lon1)
        val h = sin(dLat / 2).let { it * it } +
            cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) * sin(dLon / 2).let { it * it }
        return 2 * r * asin(min(1.0, sqrt(h)))
    }

    /** The [limit] nearest stops within [maxM], nearest first. */
    fun nearest(
        stops: List<IndexStop>,
        lat: Double,
        lon: Double,
        limit: Int = LIMIT,
        maxM: Double = MAX_DISTANCE_M,
    ): List<NearStop> {
        val within = ArrayList<Pair<IndexStop, Double>>()
        for (s in stops) {
            val d = haversineM(lat, lon, s.lat, s.lon)
            if (d <= maxM) within += s to d
        }
        within.sortBy { it.second }
        return within.take(limit).map { NearStop(it.first, it.second.roundToInt()) }
    }
}
