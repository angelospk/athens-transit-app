package gr.staseis.app.wear.ui

import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.calculateEndPadding
import androidx.compose.foundation.layout.calculateStartPadding
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.wear.compose.foundation.lazy.TransformingLazyColumn
import androidx.wear.compose.foundation.lazy.TransformingLazyColumnItemScope
import androidx.wear.compose.foundation.lazy.TransformingLazyColumnScope
import androidx.wear.compose.foundation.lazy.rememberTransformingLazyColumnState
import androidx.wear.compose.material3.ListHeader
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.ScreenScaffold
import androidx.wear.compose.material3.ScrollIndicator
import androidx.wear.compose.material3.SurfaceTransformation
import androidx.wear.compose.material3.Text
import androidx.wear.compose.material3.lazy.TransformationSpec
import androidx.wear.compose.material3.lazy.rememberTransformationSpec
import androidx.wear.compose.material3.lazy.transformedHeight

/*
 * Round-safe screens (Wear quality guideline "watch shapes"): every screen is a TransformingLazyColumn in a
 * ScreenScaffold, so it scrolls, items morph near the top and bottom edges, the padding is a percentage of
 * the screen, and the title is the first (centred) item. Plain text gets ~15% side padding.
 */

/** The system's time text and scroll indicator. Off only in the screenshot tests' edge check. */
val LocalChrome = staticCompositionLocalOf { true }

/** Side padding of list items: 5.2% of the screen width (the Wear M3 guidance for cards and buttons). */
const val ITEM_SIDE = 0.052f
/** Extra side padding for plain text, so it sits about 15% in from the edge. */
const val TEXT_EXTRA = 0.10f
/**
 * Bottom padding of a list without an EdgeButton: 23% of the screen, so the last card can rest fully inside
 * the circle (a 52 dp card at 5.2% side padding fits only while its corners are within ~36 dp (192 dp
 * screen) / ~44 dp (227 dp) below the centre).
 */
const val LIST_BOTTOM = 0.23f

@Composable
fun screenFraction(f: Float): Dp = (LocalConfiguration.current.screenWidthDp * f).dp

@Composable
fun ListScreen(
    edgeButton: (@Composable BoxScope.() -> Unit)? = null,
    content: TransformingLazyColumnScope.(TransformationSpec) -> Unit,
) {
    val state = rememberTransformingLazyColumnState()
    val spec = rememberTransformationSpec()
    val chrome = LocalChrome.current
    val indicator: @Composable BoxScope.() -> Unit = {
        if (chrome) ScrollIndicator(state = state, modifier = Modifier.align(Alignment.CenterEnd))
    }
    val side = screenFraction(ITEM_SIDE)
    val dir = LocalLayoutDirection.current
    val bottom = (LocalConfiguration.current.screenHeightDp * LIST_BOTTOM).dp
    val list: @Composable BoxScope.(PaddingValues) -> Unit = { p ->
        TransformingLazyColumn(
            state = state,
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(
                start = maxOf(side, p.calculateStartPadding(dir)),
                end = maxOf(side, p.calculateEndPadding(dir)),
                top = p.calculateTopPadding(),
                bottom = if (edgeButton != null) p.calculateBottomPadding() else maxOf(p.calculateBottomPadding(), bottom),
            ),
        ) { content(spec) }
    }
    if (edgeButton != null) {
        ScreenScaffold(scrollState = state, edgeButton = edgeButton, scrollIndicator = indicator, content = list)
    } else {
        ScreenScaffold(scrollState = state, scrollIndicator = indicator, content = list)
    }
}

/** Height and content transforms for a plain (non-surface) item. */
fun Modifier.morph(scope: TransformingLazyColumnItemScope, spec: TransformationSpec): Modifier = with(scope) {
    this@morph.transformedHeight(scope, spec).graphicsLayer { with(spec) { applyContentTransformation(scrollProgress) } }
}

/** A surface item (card-like) that narrows and fades near the edges like the M3 components. */
fun Modifier.morphSurface(scope: TransformingLazyColumnItemScope, spec: TransformationSpec): Modifier = with(scope) {
    this@morphSurface.transformedHeight(scope, spec).graphicsLayer {
        with(spec) {
            applyContainerTransformation(scrollProgress)
            applyContentTransformation(scrollProgress)
        }
    }
}

fun TransformingLazyColumnScope.title(spec: TransformationSpec, text: String) = item {
    ListHeader(
        modifier = Modifier.fillMaxWidth().transformedHeight(this, spec),
        transformation = SurfaceTransformation(spec),
    ) {
        Text(text, textAlign = TextAlign.Center, maxLines = 3, overflow = TextOverflow.Ellipsis)
    }
}

fun TransformingLazyColumnScope.message(spec: TransformationSpec, text: String, small: Boolean = false, dim: Boolean = false) = item {
    Message(text, Modifier.morph(this, spec), small, dim)
}

@Composable
fun Message(text: String, modifier: Modifier = Modifier, small: Boolean = false, dim: Boolean = false) {
    Text(
        text,
        modifier = modifier.fillMaxWidth().padding(horizontal = screenFraction(TEXT_EXTRA), vertical = 4.dp),
        textAlign = TextAlign.Center,
        style = if (small) MaterialTheme.typography.bodySmall else MaterialTheme.typography.bodyMedium,
        color = when {
            dim || small -> MaterialTheme.colorScheme.onSurfaceVariant
            else -> MaterialTheme.colorScheme.onSurface
        },
    )
}

