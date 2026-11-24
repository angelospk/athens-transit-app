package gr.staseis.app.wear.core

import org.json.JSONArray
import org.json.JSONObject

/** Decodes `GET {api}/v1/stops/{id}`. Every field is optional; a malformed body gives null. */
object Arrivals {
    const val MAX_BODY = 256 * 1024
    const val MAX_ETA_S = 7200

    /** [fetchedAtS]: when the body was received; `eta_s` counts from then. */
    fun decode(body: String?, stopId: String, fetchedAtS: Long): StopData? {
        if (body == null || body.length > MAX_BODY) return null
        return try {
            val root = JSONObject(body)
            val stop = root.optJSONObject("stop")
            val name = (stop?.opt("name") as? String)?.take(Payload.MAX_NAME)?.trim().orEmpty()
            val arr = root.opt("arrivals") as? JSONArray
            val out = ArrayList<Arrival>()
            if (arr != null) {
                for (i in 0 until arr.length()) {
                    val a = arr.opt(i) as? JSONObject ?: continue
                    decodeArrival(a, fetchedAtS)?.let { out += it }
                }
            }
            out.sortBy { it.atS }
            StopData(stopId, name, out)
        } catch (_: Exception) {
            null
        }
    }

    private fun decodeArrival(a: JSONObject, fetchedAtS: Long): Arrival? {
        val line = when (val l = a.opt("line")) {
            is String -> l.trim()
            is Number -> l.toString()
            else -> null
        } ?: return null
        if (line.isEmpty()) return null
        val eta = (a.opt("eta_s") as? Number)?.toDouble()?.takeIf { it.isFinite() }
        val at = (a.opt("at") as? Number)?.toDouble()?.takeIf { it.isFinite() && it > 0 }
        if (eta == null && at == null) return null
        val maxAt = fetchedAtS + MAX_ETA_S
        val atS = when {
            at != null -> at.toLong().coerceIn(fetchedAtS - MAX_ETA_S, maxAt)
            else -> fetchedAtS + eta!!.toLong().coerceIn(0, MAX_ETA_S.toLong())
        }
        val headsign = (a.opt("headsign") as? String)?.trim()?.take(80).orEmpty()
        val delay = (a.opt("delay_s") as? Number)?.toDouble()?.takeIf { it.isFinite() }
            ?.coerceIn(-86_400.0, 86_400.0)?.toInt()
        return Arrival(line.take(8), headsign, atS, delay)
    }
}
