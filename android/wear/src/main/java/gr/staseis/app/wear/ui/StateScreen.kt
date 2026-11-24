package gr.staseis.app.wear.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.ButtonDefaults
import androidx.wear.compose.material3.CircularProgressIndicator
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.ScrollIndicator
import androidx.wear.compose.material3.Text

/** Side padding of a state's buttons: 10%; its text gets 5% more, so it sits ~15% in from the edge. */
private const val STATE_SIDE = 0.10f
private const val STATE_TEXT_EXTRA = 0.05f
/** Top padding (the title is narrow text) and bottom padding (a full-width button needs ~23%, see LIST_BOTTOM). */
private const val STATE_TOP = 0.15f
/** On a square screen the corners are not in the way: a small even padding. */
private const val STATE_SQUARE = 0.08f

/**
 * A static state (empty, no permission, not found, no data, loading): title, text and actions centred in
 * the safe middle of the screen; it scrolls (with padding at both ends) only when the text is long, e.g.
 * at large font scales, so nothing rests on the round edge.
 */
@Composable
fun StateScreen(title: String?, body: @Composable ColumnScope.() -> Unit) {
    val scroll = rememberScrollState()
    val chrome = LocalChrome.current
    val round = LocalConfiguration.current.isScreenRound
    ScreenScaffold(scrollState = scroll, scrollIndicator = { if (chrome) ScrollIndicator(scroll, Modifier.align(Alignment.CenterEnd)) }) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Column(
                Modifier.verticalScroll(scroll)
                    .padding(
                        start = screenFraction(STATE_SIDE),
                        end = screenFraction(STATE_SIDE),
                        top = screenFraction(if (round) STATE_TOP else STATE_SQUARE),
                        bottom = screenFraction(if (round) LIST_BOTTOM else STATE_SQUARE),
                    ),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                if (title != null) Text(
                    title,
                    textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.titleMedium,
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis,
                )
                body()
            }
        }
    }
}

@Composable
fun StateText(text: String, small: Boolean = false) {
    Text(
        text,
        textAlign = TextAlign.Center,
        style = if (small) MaterialTheme.typography.bodySmall else MaterialTheme.typography.bodyMedium,
        color = if (small) MaterialTheme.colorScheme.onSurfaceVariant else MaterialTheme.colorScheme.onSurface,
        modifier = Modifier.fillMaxWidth().padding(horizontal = screenFraction(STATE_TEXT_EXTRA)),
    )
}

@Composable
fun StateProgress() = CircularProgressIndicator(Modifier.padding(4.dp))

@Composable
fun StateButton(label: String, onClick: () -> Unit, tonal: Boolean = false) {
    Button(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        colors = if (tonal) ButtonDefaults.filledTonalButtonColors() else ButtonDefaults.buttonColors(),
    ) {
        Text(label, maxLines = 2, overflow = TextOverflow.Ellipsis, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth())
    }
}
