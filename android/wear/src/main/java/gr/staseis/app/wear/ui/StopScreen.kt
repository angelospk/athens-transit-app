package gr.staseis.app.wear.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.repeatOnLifecycle
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.Text
import gr.staseis.app.wear.R
import gr.staseis.app.wear.core.Arrival
import gr.staseis.app.wear.core.Format
import gr.staseis.app.wear.core.StopView
import gr.staseis.app.wear.data.ArrivalsRepo
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext

private const val STOP_REFRESH_MS = 30_000L

@Composable
fun StopScreen(ref: StopRef) {
    val ctx = LocalContext.current
    val snap by remember(ref) { ArrivalsRepo.flow(ref.city, ref.id) }.collectAsState()
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    LaunchedEffect(ref) {
        withContext(Dispatchers.IO) { ArrivalsRepo.cached(ctx, ref.city, ref.id) }
        // On appear, then every 30 s while resumed; stops in ambient / background.
        lifecycle.repeatOnLifecycle(Lifecycle.State.RESUMED) {
            while (true) {
                ArrivalsRepo.refresh(ctx, ref.city, ref.id)
                delay(STOP_REFRESH_MS)
            }
        }
    }
    val nowS = rememberNowS()
    val s = snap
    val view = StopView.of(s?.data, s?.fetchedAtS, s?.lastFailed == true, s?.decodeFailed == true, nowS)
    val title = ref.name.ifEmpty { s?.data?.name.orEmpty() }.ifEmpty { ref.id }
    StopContent(title, view, nowS)
}

@Composable
fun StopContent(title: String, view: StopView, nowS: Long) {
    val nowWord = stringResource(R.string.now)
    val noData = stringResource(R.string.no_data)
    val noBus = stringResource(R.string.no_bus)
    val footer = (view as? StopView.Rows)?.let {
        if (it.offline) stringResource(R.string.offline, hhmm(it.updatedAtS)) else stringResource(R.string.updated, hhmm(it.updatedAtS))
    }
    when {
        view == StopView.Loading -> {
            StateScreen(title) { StateProgress() }
            return
        }
        view == StopView.NoData -> {
            StateScreen(title) { StateText(noData) }
            return
        }
        view is StopView.Rows && view.rows.isEmpty() -> {
            StateScreen(title) {
                StateText(noBus)
                StateText(footer!!, small = true)
            }
            return
        }
    }
    ListScreen { spec ->
        title(spec, title)
        when (view) {
            StopView.Loading, StopView.NoData -> {}
            is StopView.Rows -> {
                view.rows.forEach { a ->
                    item { ArrivalCard(a, nowS, nowWord, dimmed = view.offline, modifier = Modifier.morphSurface(this, spec)) }
                }
                message(spec, footer!!, small = true)
            }
        }
    }
}

/** Line badge and minutes (+ late) on the first line, the headsign below: nothing sits at the side edges. */
@Composable
private fun ArrivalCard(a: Arrival, nowS: Long, nowWord: String, dimmed: Boolean, modifier: Modifier) {
    val late = Format.late(a.delayS)
    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(MaterialTheme.colorScheme.surfaceContainerLow)
            .padding(horizontal = 14.dp, vertical = 8.dp)
            .alpha(if (dimmed) 0.5f else 1f),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Box(
                Modifier.clip(RoundedCornerShape(8.dp)).background(BadgeBg).padding(horizontal = 6.dp, vertical = 1.dp)
                    .widthIn(min = 26.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(a.line, color = BadgeFg, fontWeight = FontWeight.ExtraBold, style = MaterialTheme.typography.labelMedium, maxLines = 1)
            }
            Spacer(Modifier.weight(1f))
            Text(
                Format.minutesLabel(a.atS, nowS, nowWord),
                fontWeight = FontWeight.Bold,
                style = MaterialTheme.typography.labelMedium,
                maxLines = 1,
            )
            if (late != null) {
                Text(Format.lateLabel(a.delayS)!!, color = late.color(), style = MaterialTheme.typography.labelSmall, maxLines = 1)
            }
        }
        if (a.headsign.isNotEmpty()) {
            Text(
                a.headsign,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}
