package gr.staseis.app.wear.ui

import androidx.annotation.StringRes
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.Text
import gr.staseis.app.wear.core.Late
import gr.staseis.app.wear.data.ArrivalsRepo
import kotlinx.coroutines.delay
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

/** Neutral line badge, as on the phone for a line without its own colour: surface + ink. */
val BadgeBg = Tones.surface
val BadgeFg = Tones.ink
val Amber = Color(0xFFFFB300)
val LateRed = Color(0xFFFF5449)

fun Late.color() = when (this) {
    Late.AMBER -> Amber
    Late.RED -> LateRed
}

private val HHMM = DateTimeFormatter.ofPattern("HH:mm")
fun hhmm(s: Long): String = HHMM.format(Instant.ofEpochSecond(s).atZone(ZoneId.systemDefault()))

/** Now in Unix seconds, ticking every [everyMs] so the minutes roll without a fetch. */
@Composable
fun rememberNowS(everyMs: Long = 10_000): Long {
    var now by remember { mutableLongStateOf(ArrivalsRepo.nowS()) }
    LaunchedEffect(Unit) {
        while (true) {
            delay(everyMs)
            now = ArrivalsRepo.nowS()
        }
    }
    return now
}

@Composable
fun MessageScreen(@StringRes text: Int) {
    StateScreen(stringResource(gr.staseis.app.wear.R.string.app_name)) { StateText(stringResource(text)) }
}
