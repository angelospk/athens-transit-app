package gr.staseis.app.wear.core

/** The two cities the backend serves. An enum, never a URL from outside: endpoints are hardcoded. */
enum class City(
    val key: String,
    val api: String,
    val stopIndexUrl: String,
    val south: Double,
    val west: Double,
    val north: Double,
    val east: Double,
) {
    ATHENS("athens", "https://transit.haroldpoi.dev", "https://staseis.gr/trips.json", 37.5, 22.9, 38.5, 24.5),
    THESSALONIKI(
        "thessaloniki", "https://transit-thess.haroldpoi.dev", "https://staseis.gr/trips-thessaloniki.json",
        40.3, 22.6, 41.0, 23.4,
    );

    fun contains(lat: Double, lon: Double): Boolean = lat in south..north && lon in west..east

    companion object {
        fun fromKey(key: String?): City? = entries.firstOrNull { it.key == key }

        /** The city whose box holds the point, or null outside both. */
        fun at(lat: Double, lon: Double): City? = entries.firstOrNull { it.contains(lat, lon) }
    }
}

/** A favourite stop synced from the phone. [lines] empty means all lines. */
data class Fav(val id: String, val name: String, val lines: List<String>)

data class FavsPayload(val city: City, val favs: List<Fav>)

/** One arrival. [atS] is the Unix second the bus is due; minutes are always shown relative to now. */
data class Arrival(
    val line: String,
    val headsign: String,
    val atS: Long,
    val delayS: Int?,
)

data class StopData(val id: String, val name: String, val arrivals: List<Arrival>)

/** A stop from the local index, with the lines that serve it (sorted, may be empty). */
data class IndexStop(
    val id: String,
    val name: String,
    val lat: Double,
    val lon: Double,
    val lines: List<String> = emptyList(),
)

data class NearStop(val stop: IndexStop, val distanceM: Int)
