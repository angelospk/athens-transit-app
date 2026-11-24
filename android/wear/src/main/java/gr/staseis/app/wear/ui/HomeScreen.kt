package gr.staseis.app.wear.ui

import androidx.annotation.DrawableRes
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.Icon
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.ScrollIndicator
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.Text
import gr.staseis.app.wear.R

/**
 * Side padding of the home rows: 10%. With a compact title and two 52 dp rows centred, the second row's
 * corners stay inside a 192 dp circle at rest (corner centre ~65 dp from the middle, + 26 dp radius < 94 dp).
 */
private const val HOME_SIDE = 0.10f

/**
 * Two rows with icons, as on watchOS: a star for the favourites, a location arrow for nearby. A short fixed
 * menu, so it is centred vertically (fits at rest on 192 dp at font scale 1.3) and scrolls only if needed.
 */
@Composable
fun HomeScreen(onFavs: () -> Unit, onNearby: () -> Unit) {
    val scroll = rememberScrollState()
    val chrome = LocalChrome.current
    // On a small screen at a large font scale the icon would squeeze «Αγαπημένα» into a mid-word break.
    val icons = LocalDensity.current.fontScale <= 1.1f || LocalConfiguration.current.screenWidthDp >= 210
    ScreenScaffold(scrollState = scroll, scrollIndicator = { if (chrome) ScrollIndicator(scroll, Modifier.align(Alignment.CenterEnd)) }) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Column(
                Modifier.verticalScroll(scroll).padding(horizontal = screenFraction(HOME_SIDE), vertical = 8.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                Text(
                    stringResource(R.string.app_name),
                    textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.titleMedium,
                    modifier = Modifier.padding(bottom = 2.dp),
                )
                HomeRow(R.drawable.ic_star.takeIf { icons }, R.string.favourites, onFavs)
                HomeRow(R.drawable.ic_near.takeIf { icons }, R.string.nearby, onNearby)
            }
        }
    }
}

@Composable
private fun HomeRow(@DrawableRes icon: Int?, label: Int, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        icon = icon?.let { { Icon(painterResource(it), contentDescription = null, modifier = Modifier.size(22.dp)) } },
    ) { Text(stringResource(label), maxLines = 2, overflow = TextOverflow.Ellipsis) }
}
