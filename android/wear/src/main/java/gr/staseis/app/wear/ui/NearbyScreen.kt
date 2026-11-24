package gr.staseis.app.wear.ui

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.LifecycleResumeEffect
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.ButtonDefaults
import androidx.wear.compose.material3.SurfaceTransformation
import androidx.wear.compose.material3.Text
import androidx.wear.compose.material3.lazy.transformedHeight
import gr.staseis.app.wear.R
import gr.staseis.app.wear.core.City
import gr.staseis.app.wear.core.Format
import gr.staseis.app.wear.core.NearStop
import gr.staseis.app.wear.core.Nearest
import gr.staseis.app.wear.data.Locator
import gr.staseis.app.wear.data.StopIndex
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

sealed interface NearState {
    data object NeedPermission : NearState
    data object Denied : NearState
    data object Locating : NearState
    data object LoadingStops : NearState
    data object NoLocation : NearState
    data object NoIndex : NearState
    data object NoneNearby : NearState
    data class Found(val city: City, val stops: List<NearStop>) : NearState
}

@Composable
fun NearbyScreen(open: (StopRef) -> Unit) {
    val ctx = LocalContext.current
    fun granted() = listOf(Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_FINE_LOCATION)
        .any { ContextCompat.checkSelfPermission(ctx, it) == PackageManager.PERMISSION_GRANTED }

    var state by remember { mutableStateOf<NearState>(if (granted()) NearState.Locating else NearState.NeedPermission) }
    var attempt by remember { mutableIntStateOf(0) }
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { res ->
        if (res.values.any { it }) {
            state = NearState.Locating
            attempt++
        } else {
            state = NearState.Denied
        }
    }

    LaunchedEffect(attempt) {
        if (!granted()) return@LaunchedEffect
        state = NearState.Locating
        val loc = Locator.current(ctx)
        if (loc == null) {
            state = NearState.NoLocation
            return@LaunchedEffect
        }
        val city = City.at(loc.latitude, loc.longitude)
        if (city == null) {
            state = NearState.NoneNearby
            return@LaunchedEffect
        }
        state = NearState.LoadingStops
        val stops = StopIndex.stops(ctx, city)
        if (stops.isEmpty()) {
            state = NearState.NoIndex
            return@LaunchedEffect
        }
        val near = withContext(Dispatchers.Default) { Nearest.nearest(stops, loc.latitude, loc.longitude) }
        state = if (near.isEmpty()) NearState.NoneNearby else NearState.Found(city, near)
    }

    // Back from the app's settings with the permission granted: start again without a button.
    LifecycleResumeEffect(Unit) {
        if ((state == NearState.Denied || state == NearState.NeedPermission) && granted()) attempt++
        onPauseOrDispose {}
    }

    val requestPermission = {
        launcher.launch(arrayOf(Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_FINE_LOCATION))
    }
    NearbyContent(
        state,
        onAllow = requestPermission,
        onRetry = { attempt++ },
        onSettings = {
            try {
                ctx.startActivity(
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", ctx.packageName, null))
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                )
            } catch (_: Exception) {
            }
        },
        onOpen = open,
    )
}

@Composable
fun NearbyContent(
    state: NearState,
    onAllow: () -> Unit,
    onRetry: () -> Unit,
    onSettings: () -> Unit,
    onOpen: (StopRef) -> Unit,
) {
    val header = stringResource(R.string.nearby)
    if (state is NearState.Found) {
        ListScreen { spec ->
            title(spec, header)
            state.stops.forEach { n ->
                item(key = n.stop.id) {
                    Button(
                        onClick = { onOpen(StopRef(state.city, n.stop.id, n.stop.name)) },
                        modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
                        transformation = SurfaceTransformation(spec),
                        colors = ButtonDefaults.filledTonalButtonColors(),
                        secondaryLabel = { Text(Format.nearbyLabel(n), maxLines = 2, overflow = TextOverflow.Ellipsis) },
                    ) {
                        Text(n.stop.name.ifEmpty { n.stop.id }, maxLines = 2, overflow = TextOverflow.Ellipsis)
                    }
                }
            }
        }
        return
    }
    // Static states: centred, round-safe; the action is a normal button (an EdgeButton's label area is too
    // narrow for «Δοκίμασε ξανά» / «Επίτρεψε» on 192–227 dp screens).
    // The permission state drops its title so text and button fit at rest on a 192 dp screen at font scale 1.0.
    StateScreen(if (state == NearState.NeedPermission) null else header) {
        when (state) {
            NearState.NeedPermission -> {
                StateText(stringResource(R.string.location_rationale))
                StateButton(stringResource(R.string.allow), onAllow)
            }
            // One button: the user grants it in the settings, and the screen retries on resume.
            NearState.Denied -> {
                StateText(stringResource(R.string.no_permission))
                StateButton(stringResource(R.string.settings), onSettings)
            }
            NearState.Locating -> {
                StateProgress()
                StateText(stringResource(R.string.locating))
            }
            NearState.LoadingStops -> {
                StateProgress()
                StateText(stringResource(R.string.loading_stops))
            }
            NearState.NoLocation -> {
                StateText(stringResource(R.string.no_location))
                StateButton(stringResource(R.string.retry), onRetry)
            }
            NearState.NoIndex -> {
                StateText(stringResource(R.string.no_data))
                StateButton(stringResource(R.string.retry), onRetry)
            }
            NearState.NoneNearby -> StateText(stringResource(R.string.no_stops_nearby))
            is NearState.Found -> {}
        }
    }
}
