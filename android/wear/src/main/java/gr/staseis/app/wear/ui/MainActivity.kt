package gr.staseis.app.wear.ui

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.lifecycle.lifecycleScope
import gr.staseis.app.wear.BuildConfig
import gr.staseis.app.wear.core.City
import gr.staseis.app.wear.core.Payload
import gr.staseis.app.wear.data.FavStore
import gr.staseis.app.wear.glance.Glance
import gr.staseis.app.wear.sync.FavsSync
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch

/** A stop to open. Built only from validated values. */
data class StopRef(val city: City, val id: String, val name: String)

/** A screen to open from outside (tile, complication, debug demo hook). */
sealed interface Target {
    data object Favourites : Target
    data object Nearby : Target
    data class Stop(val ref: StopRef) : Target
}

class MainActivity : ComponentActivity() {
    companion object {
        const val EXTRA_CITY = "city"
        const val EXTRA_STOP = "stop"
        const val EXTRA_NAME = "name"

        // Debug builds only (store screenshots): ignored in release.
        const val EXTRA_DEMO_FAVS = "demoFavs"
        const val EXTRA_DEMO_SCREEN = "demoScreen"

        /** The activity is exported (launcher, tile, complication): extras are untrusted. */
        fun stopFrom(intent: Intent?): StopRef? {
            intent ?: return null
            val city = City.fromKey(intent.getStringExtra(EXTRA_CITY)) ?: return null
            val id = intent.getStringExtra(EXTRA_STOP)?.takeIf { Payload.ID_RE.matches(it) } ?: return null
            val name = intent.getStringExtra(EXTRA_NAME).orEmpty().take(Payload.MAX_NAME)
            return StopRef(city, id, name)
        }

        /** `favourites`, `nearby` or `stop:<city>:<id>`. */
        fun demoScreen(value: String?): Target? = when {
            value == "favourites" -> Target.Favourites
            value == "nearby" -> Target.Nearby
            value != null && value.startsWith("stop:") -> {
                val p = value.split(':')
                val city = City.fromKey(p.getOrNull(1))
                val id = p.getOrNull(2)?.takeIf { Payload.ID_RE.matches(it) }
                if (p.size == 3 && city != null && id != null) Target.Stop(StopRef(city, id, "")) else null
            }
            else -> null
        }
    }

    private val deepLink = MutableStateFlow<Target?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState == null) handle(intent)
        setContent { StaseisApp(deepLink) }
        lifecycleScope.launch {
            FavsSync.pull(this@MainActivity)
            Glance.reschedule(this@MainActivity)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handle(intent)
    }

    private fun handle(intent: Intent?) {
        if (BuildConfig.DEBUG && intent != null) {
            intent.getStringExtra(EXTRA_DEMO_FAVS)?.let { json ->
                if (FavStore.accept(this, json)) Glance.favouritesChanged(this)
            }
            demoScreen(intent.getStringExtra(EXTRA_DEMO_SCREEN))?.let {
                deepLink.value = fillName(it)
                return
            }
        }
        stopFrom(intent)?.let { deepLink.value = Target.Stop(it) }
    }

    /** A demo stop opened by id takes its name from the favourites, if it is one. */
    private fun fillName(t: Target): Target {
        if (t !is Target.Stop) return t
        val fav = FavStore.get(this)?.takeIf { it.city == t.ref.city }?.favs?.firstOrNull { it.id == t.ref.id }
        return if (fav != null) Target.Stop(t.ref.copy(name = fav.name)) else t
    }
}
