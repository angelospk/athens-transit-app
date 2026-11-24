package gr.staseis.app.wear.core

import org.json.JSONArray
import org.json.JSONObject

/**
 * Validates the phone → watch favourites payload (Data Layer item `/staseis/favs`, key `json`).
 * The payload is untrusted: any failure returns null and the caller keeps the previous favourites.
 * Unknown keys are ignored.
 */
object Payload {
    const val MAX_FAVS = 20
    const val MAX_NAME = 80
    const val MAX_LINES = 12
    private const val MAX_BYTES = 32 * 1024

    val ID_RE = Regex("^[A-Za-z0-9_-]{1,16}$")
    val LINE_RE = Regex("^[A-Za-z0-9Α-Ωα-ωΆ-Ώά-ώ_-]{1,8}$")

    fun parse(json: String?): FavsPayload? {
        if (json == null || json.length > MAX_BYTES) return null
        return try {
            val o = JSONObject(json)
            if (o.opt("v") !is Int || o.getInt("v") != 1) return null
            val city = City.fromKey(o.opt("city") as? String) ?: return null
            val arr = o.opt("favs") as? JSONArray ?: return null
            if (arr.length() > MAX_FAVS) return null
            val favs = ArrayList<Fav>(arr.length())
            val seen = HashSet<String>()
            for (i in 0 until arr.length()) {
                val f = arr.opt(i) as? JSONObject ?: return null
                val id = f.opt("id") as? String ?: return null
                if (!ID_RE.matches(id)) return null
                val name = when (val n = f.opt("name")) {
                    null, JSONObject.NULL -> ""
                    is String -> n
                    else -> null
                } ?: return null
                if (name.length > MAX_NAME) return null
                val lines = when (val l = f.opt("lines")) {
                    null, JSONObject.NULL -> emptyList()
                    is JSONArray -> {
                        if (l.length() > MAX_LINES) return null
                        (0 until l.length()).map { j ->
                            val s = l.opt(j) as? String ?: return null
                            if (!LINE_RE.matches(s)) return null
                            s
                        }
                    }
                    else -> null
                } ?: return null
                if (seen.add(id)) favs += Fav(id, name.trim(), lines)
            }
            FavsPayload(city, favs)
        } catch (_: Exception) {
            null
        }
    }

    /** Canonical JSON for local storage (only the validated fields). */
    fun encode(p: FavsPayload): String = JSONObject().apply {
        put("v", 1)
        put("city", p.city.key)
        put("favs", JSONArray().apply {
            p.favs.forEach { f ->
                put(JSONObject().apply {
                    put("id", f.id)
                    put("name", f.name)
                    put("lines", JSONArray(f.lines))
                })
            }
        })
    }.toString()
}
