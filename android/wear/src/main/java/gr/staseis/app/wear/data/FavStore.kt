package gr.staseis.app.wear.data

import android.content.Context
import gr.staseis.app.wear.core.FavsPayload
import gr.staseis.app.wear.core.Payload
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

/** Favourites from the phone, validated, in app-private SharedPreferences. */
object FavStore {
    private const val PREFS = "favs"
    private const val KEY = "json"
    private val state = MutableStateFlow<FavsPayload?>(null)
    @Volatile private var loaded = false

    fun flow(ctx: Context): StateFlow<FavsPayload?> {
        get(ctx)
        return state
    }

    fun get(ctx: Context): FavsPayload? {
        if (!loaded) synchronized(this) {
            if (!loaded) {
                val raw = ctx.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null)
                state.value = Payload.parse(raw)
                loaded = true
            }
        }
        return state.value
    }

    /** Validates [json]; on failure keeps the previous favourites and returns false. */
    fun accept(ctx: Context, json: String?): Boolean {
        val p = Payload.parse(json) ?: return false
        val canonical = Payload.encode(p)
        val prefs = ctx.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (prefs.getString(KEY, null) == canonical) {
            get(ctx)
            return false
        }
        prefs.edit().putString(KEY, canonical).apply()
        synchronized(this) {
            state.value = p
            loaded = true
        }
        return true
    }
}
