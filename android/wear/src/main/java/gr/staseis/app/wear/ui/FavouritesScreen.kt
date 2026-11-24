package gr.staseis.app.wear.ui

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.repeatOnLifecycle
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.ButtonDefaults
import androidx.wear.compose.material3.SurfaceTransformation
import androidx.wear.compose.material3.Text
import androidx.wear.compose.material3.lazy.transformedHeight
import gr.staseis.app.wear.R
import gr.staseis.app.wear.core.City
import gr.staseis.app.wear.core.Fav
import gr.staseis.app.wear.core.Format
import gr.staseis.app.wear.data.ArrivalsRepo
import gr.staseis.app.wear.data.FavStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withPermit
import kotlinx.coroutines.withContext

private const val FAV_REFRESH_MS = 60_000L
private const val MAX_VISIBLE_FETCH = 4
private const val PARALLEL = 2

/** One favourites row: the stop and its next two arrivals ("040 3′ · 137 12′", "…" loading, "—" none). */
data class FavRow(val title: String, val summary: String)

@Composable
fun FavouritesScreen(open: (StopRef) -> Unit) {
    val ctx = LocalContext.current
    val payload by remember { FavStore.flow(ctx) }.collectAsState()
    val favs = payload?.favs.orEmpty()
    val city = payload?.city
    if (city == null || favs.isEmpty()) {
        NoFavouritesContent()
        return
    }
    // Which favourites are on screen, reported by the rows as they compose.
    val visible = remember { mutableStateOf(setOf<String>()) }
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    LaunchedEffect(city, favs) {
        // Every 60 s while visible and resumed (not ambient / background): at most 4 visible stops, 2 at a time.
        lifecycle.repeatOnLifecycle(Lifecycle.State.RESUMED) {
            while (true) {
                val seen = visible.value
                val targets = favs.filter { it.id in seen }.ifEmpty { favs }.take(MAX_VISIBLE_FETCH)
                val sem = Semaphore(PARALLEL)
                coroutineScope {
                    targets.forEach { f -> launch { sem.withPermit { ArrivalsRepo.refresh(ctx, city, f.id) } } }
                }
                delay(FAV_REFRESH_MS)
            }
        }
    }
    val nowS = rememberNowS()
    val nowWord = stringResource(R.string.now)
    val rows = favs.map { f -> favRow(city, f, nowS, nowWord) }
    FavouritesContent(
        rows,
        onOpen = { i -> open(StopRef(city, favs[i].id, favs[i].name)) },
        onShown = { i, shown ->
            val id = favs[i].id
            visible.value = if (shown) visible.value + id else visible.value - id
        },
    )
}

@Composable
private fun favRow(city: City, f: Fav, nowS: Long, nowWord: String): FavRow {
    val ctx = LocalContext.current
    val snap by remember(city, f.id) { ArrivalsRepo.flow(city, f.id) }.collectAsState()
    LaunchedEffect(city, f.id) { withContext(Dispatchers.IO) { ArrivalsRepo.cached(ctx, city, f.id) } }
    val s = snap
    val fresh = s?.fetchedAtS?.let { nowS - it <= Format.STALE_AFTER_S } == true
    val summary = when {
        s?.data == null || !fresh -> if (s?.lastFailed == true || s?.decodeFailed == true) "—" else "…"
        else -> Format.nextSummary(s.data.arrivals, nowS, f.lines, nowWord).ifEmpty { "—" }
    }
    return FavRow(f.name.ifEmpty { s?.data?.name.orEmpty() }.ifEmpty { f.id }, summary)
}

@Composable
fun NoFavouritesContent() {
    StateScreen(stringResource(R.string.favourites)) { StateText(stringResource(R.string.no_favs)) }
}

@Composable
fun FavouritesContent(rows: List<FavRow>, onOpen: (Int) -> Unit, onShown: (Int, Boolean) -> Unit = { _, _ -> }) {
    val header = stringResource(R.string.favourites)
    ListScreen { spec ->
        title(spec, header)
        rows.forEachIndexed { i, r ->
            item(key = i) {
                androidx.compose.runtime.DisposableEffect(i) {
                    onShown(i, true)
                    onDispose { onShown(i, false) }
                }
                Button(
                    onClick = { onOpen(i) },
                    modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
                    transformation = SurfaceTransformation(spec),
                    colors = ButtonDefaults.filledTonalButtonColors(),
                    secondaryLabel = { Text(r.summary, maxLines = 2, overflow = TextOverflow.Ellipsis) },
                ) {
                    Text(r.title, maxLines = 2, overflow = TextOverflow.Ellipsis)
                }
            }
        }
    }
}
