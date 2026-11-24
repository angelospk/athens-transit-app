// Screenshot + round-edge tests for every screen and state (and TileShotTest for the tile).
// - `./gradlew :wear:testDebugUnitTest` runs the edge checks; no golden images needed.
// - `./gradlew :wear:recordRoborazziDebug` writes the PNGs, contact sheets (_sheet.png) and edge reports to
//   src/test/screenshots/ (git-ignored) for review.
// - `./gradlew :wear:verifyRoborazziDebug` compares against previously recorded PNGs: on demand only,
//   after a record on the same machine.
package gr.staseis.app.wear.shots

import android.graphics.Bitmap
import android.graphics.Color
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.activity.ComponentActivity
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.core.view.drawToBitmap
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.swipeUp
import androidx.wear.compose.material3.AppScaffold
import com.github.takahirom.roborazzi.RobolectricDeviceQualifiers
import com.github.takahirom.roborazzi.captureRoboImage
import gr.staseis.app.wear.core.Arrival
import gr.staseis.app.wear.core.StopView
import gr.staseis.app.wear.ui.FavouritesContent
import gr.staseis.app.wear.ui.HomeScreen
import gr.staseis.app.wear.ui.LocalChrome
import gr.staseis.app.wear.ui.NearState
import gr.staseis.app.wear.ui.NearbyContent
import gr.staseis.app.wear.ui.NoFavouritesContent
import gr.staseis.app.wear.ui.StaseisTheme
import gr.staseis.app.wear.ui.StopContent
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.RuleChain
import org.junit.rules.TestRule
import org.junit.runner.Description
import org.junit.runner.RunWith
import org.junit.runners.model.Statement
import org.robolectric.ParameterizedRobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File
import java.util.TimeZone
import kotlin.math.hypot

/**
 * Every screen and state on SMALL_ROUND (192 dp), LARGE_ROUND (227 dp) and SQUARE, at font scale 1.0 and
 * 1.24 (and 1.3 on the round ones), in Greek and English. Each render is checked automatically: no text or
 * control may reach the last 2 dp before the round (or square) edge, at the start and at the end of each
 * list (the 30% band where a list continues off screen is skipped there). PNGs: src/test/screenshots/.
 */
@RunWith(ParameterizedRobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [35])
class ScreensShotTest(private val device: String, private val font: Float, private val locale: String) {

    companion object {
        private val DEVICES = mapOf(
            "small_round" to RobolectricDeviceQualifiers.WearOSSmallRound,
            "large_round" to RobolectricDeviceQualifiers.WearOSLargeRound,
            "square" to RobolectricDeviceQualifiers.WearOSSquare,
        )
        const val DIR = "src/test/screenshots"
        /** Real lists; every other case is a static state that must fit at rest at font scale 1.0. */
        private val LISTS = setOf("favourites", "nearby_found", "stop_arrivals", "stop_offline")
        private const val BG = 0xFF0F1113.toInt()

        @JvmStatic
        @ParameterizedRobolectricTestRunner.Parameters(name = "{0}_{1}_{2}")
        fun params(): List<Array<Any>> {
            val out = ArrayList<Array<Any>>()
            for (d in DEVICES.keys) for (f in listOf(1.0f, 1.24f)) for (l in listOf("el", "en")) out += arrayOf(d, f, l)
            out += arrayOf<Any>("small_round", 1.3f, "el")
            out += arrayOf<Any>("large_round", 1.3f, "en")
            return out
        }
    }

    private val compose = createAndroidComposeRule<ComponentActivity>()

    /** Device, language and font scale must be set before the compose rule starts its activity. */
    private val config = TestRule { base: Statement, _: Description ->
        object : Statement() {
            override fun evaluate() {
                TimeZone.setDefault(TimeZone.getTimeZone("Europe/Athens"))
                RuntimeEnvironment.setQualifiers("$locale-${DEVICES.getValue(device).removePrefix("+")}")
                RuntimeEnvironment.setFontScale(font)
                base.evaluate()
            }
        }
    }

    @get:Rule val rules: RuleChain = RuleChain.outerRule(config).around(compose)

    private val stopRows = StopView.Rows(Demo.arrivals, Demo.NOW - 20, offline = false)

    private val cases: List<Pair<String, @Composable () -> Unit>> = listOf(
        "home" to { HomeScreen({}, {}) },
        "favourites" to { FavouritesContent(Demo.favRows, {}) },
        "favourites_empty" to { NoFavouritesContent() },
        "nearby_permission" to { Nearby(NearState.NeedPermission) },
        "nearby_denied" to { Nearby(NearState.Denied) },
        "nearby_locating" to { Nearby(NearState.Locating) },
        "nearby_loading_stops" to { Nearby(NearState.LoadingStops) },
        "nearby_no_location" to { Nearby(NearState.NoLocation) },
        "nearby_no_index" to { Nearby(NearState.NoIndex) },
        "nearby_none" to { Nearby(NearState.NoneNearby) },
        "nearby_found" to { Nearby(NearState.Found(Demo.city, Demo.nearby)) },
        "stop_loading" to { StopContent(Demo.LONG_STOP, StopView.Loading, Demo.NOW) },
        "stop_no_data" to { StopContent(Demo.LONG_STOP, StopView.NoData, Demo.NOW) },
        "stop_arrivals" to { StopContent(Demo.LONG_STOP, stopRows, Demo.NOW) },
        "stop_offline" to { StopContent("ΠΑΠΑΣΠΥΡΟΥ", stopRows.copy(offline = true, updatedAtS = Demo.NOW - 600), Demo.NOW) },
        "stop_no_bus" to { StopContent("ΠΑΠΑΣΠΥΡΟΥ", StopView.Rows(emptyList<Arrival>(), Demo.NOW, false), Demo.NOW) },
    )

    @Composable
    private fun Nearby(s: NearState) = NearbyContent(s, {}, {}, {}, {})

    @Test
    fun screens() {
        var current by mutableStateOf(0)
        compose.setContent {
            StaseisTheme {
                // No time text or scroll indicator here: both are system components drawn on the edge by design.
                CompositionLocalProvider(LocalChrome provides false) {
                    AppScaffold(timeText = {}) {
                        key(current) { cases[current].second() }
                    }
                }
            }
        }
        val problems = ArrayList<String>()
        val sheet = ArrayList<Pair<String, Bitmap>>()
        val tag = "${device}_${"%.2f".format(java.util.Locale.ROOT, font)}_$locale"
        cases.forEachIndexed { i, (name, _) ->
            current = i
            compose.mainClock.advanceTimeBy(2_000)
            compose.waitForIdle()
            val top = shot()
            save(top, "$tag/${name}.png")
            sheet += name to top
            repeat(6) {
                compose.onRoot().performTouchInput { swipeUp() }
                compose.mainClock.advanceTimeBy(1_500)
            }
            compose.waitForIdle()
            val end = shot()
            // A list that scrolls continues past the bottom at the start and past the top at the end: those
            // bands are scroll content. Everything else, and everything on a screen that does not scroll,
            // must sit inside the circle.
            val scrolls = !end.sameAs(top)
            if (scrolls && font == 1.0f && name !in LISTS) problems += "$tag $name: scrolls at the default font size (must fit at rest)"
            problems += edges(top, skipBottom = scrolls).map { "$tag $name (start): $it" }
            if (scrolls) {
                problems += edges(end, skipTop = true).map { "$tag $name (end): $it" }
                save(end, "$tag/${name}_end.png")
                sheet += "${name}_end" to end
            }
        }
        save(contactSheet(sheet), "$tag/_sheet.png")
        File(DIR, "$tag/edge-report.txt").apply { parentFile!!.mkdirs() }
            .writeText(if (problems.isEmpty()) "OK: nothing within 2 dp of the edge\n" else problems.joinToString("\n", postfix = "\n"))
        assertTrue(problems.joinToString("\n"), problems.isEmpty())
    }

    private fun shot(): Bitmap {
        compose.waitForIdle()
        return compose.activity.window.decorView.drawToBitmap()
    }

    /** All renders of one configuration side by side, the physical edge outlined in red, for review. */
    private fun contactSheet(shots: List<Pair<String, Bitmap>>): Bitmap {
        val cols = 6
        val cell = shots.first().second.width
        val label = 28
        val rows = (shots.size + cols - 1) / cols
        val out = Bitmap.createBitmap(cols * cell, rows * (cell + label), Bitmap.Config.ARGB_8888)
        val c = android.graphics.Canvas(out)
        c.drawColor(Color.WHITE)
        val text = android.graphics.Paint().apply { color = Color.BLACK; textSize = 20f; isAntiAlias = true }
        val edge = android.graphics.Paint().apply {
            color = Color.RED; style = android.graphics.Paint.Style.STROKE; strokeWidth = 2f; isAntiAlias = true
        }
        shots.forEachIndexed { i, (name, b) ->
            val x = (i % cols) * cell.toFloat()
            val y = (i / cols) * (cell + label).toFloat()
            c.drawText(name, x + 6, y + 21, text)
            c.drawBitmap(b, x, y + label, null)
            if (device.contains("round")) c.drawCircle(x + cell / 2f, y + label + cell / 2f, cell / 2f - 1, edge)
            else c.drawRect(x + 1, y + label + 1, x + cell - 1, y + label + cell - 1, edge)
        }
        return out
    }

    private fun save(b: Bitmap, path: String) = b.captureRoboImage("$DIR/$path")

    /**
     * Pixels that differ from the background in the last 2 dp before the edge (the circle on round devices).
     * [skipBottom]/[skipTop]: the band where a scrolled list legitimately continues off screen.
     */
    private fun edges(b: Bitmap, skipTop: Boolean = false, skipBottom: Boolean = false): List<String> {
        val w = b.width
        val h = b.height
        val round = device.contains("round")
        val dp = w / RuntimeEnvironment.getApplication().resources.configuration.screenWidthDp.toFloat()
        val margin = 2f * dp
        val r = w / 2f
        val band = h * 0.3f
        val hits = HashMap<String, Int>()
        for (y in 0 until h) {
            if (skipTop && y < band) continue
            if (skipBottom && y > h - band) continue
            for (x in 0 until w) {
                val outer = if (round) hypot(x + 0.5f - r, y + 0.5f - h / 2f) > r - margin
                else x < margin || x >= w - margin || y < margin || y >= h - margin
                if (!outer) continue
                if (!differs(b.getPixel(x, y))) continue
                val where = when {
                    y < h / 3 -> "top"
                    y > 2 * h / 3 -> "bottom"
                    else -> ""
                } + when {
                    x < w / 3 -> "-left"
                    x > 2 * w / 3 -> "-right"
                    else -> ""
                }
                hits[where] = (hits[where] ?: 0) + 1
            }
        }
        return hits.filter { it.value > 3 }.map { "${it.value} px at ${it.key}" }
    }

    private fun differs(c: Int): Boolean {
        if (Color.alpha(c) < 16) return false
        val d = maxOf(
            kotlin.math.abs(Color.red(c) - Color.red(BG)),
            kotlin.math.abs(Color.green(c) - Color.green(BG)),
            kotlin.math.abs(Color.blue(c) - Color.blue(BG)),
        )
        return d > 24
    }
}
