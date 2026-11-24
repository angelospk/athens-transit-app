package gr.staseis.app.wear.shots

import android.graphics.Bitmap
import android.graphics.Color
import android.view.View
import android.widget.FrameLayout
import androidx.activity.ComponentActivity
import androidx.core.view.drawToBitmap
import androidx.wear.protolayout.DeviceParametersBuilders
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.ResourceBuilders
import androidx.wear.tiles.renderer.TileRenderer
import com.github.takahirom.roborazzi.RobolectricDeviceQualifiers
import com.github.takahirom.roborazzi.captureRoboImage
import gr.staseis.app.wear.glance.TileLayout
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.ParameterizedRobolectricTestRunner
import org.robolectric.Robolectric
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File
import java.util.concurrent.TimeUnit
import kotlin.math.hypot

/**
 * The tile (protolayout-material3 primaryLayout) rendered with the platform tile renderer on the same
 * devices and font scales, Greek data, and checked against the round edge like the app screens.
 */
@RunWith(ParameterizedRobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [35])
class TileShotTest(private val device: String, private val font: Float) {
    companion object {
        private val DEVICES = mapOf(
            "small_round" to (RobolectricDeviceQualifiers.WearOSSmallRound to 192),
            "large_round" to (RobolectricDeviceQualifiers.WearOSLargeRound to 227),
            "square" to (RobolectricDeviceQualifiers.WearOSSquare to 180),
        )

        @JvmStatic
        @ParameterizedRobolectricTestRunner.Parameters(name = "{0}_{1}")
        fun params(): List<Array<Any>> = DEVICES.keys.flatMap { d -> listOf(1.0f, 1.24f, 1.3f).map { arrayOf<Any>(d, it) } }
    }

    @Test
    fun tile() {
        val (qualifiers, dp) = DEVICES.getValue(device)
        RuntimeEnvironment.setQualifiers("el-${qualifiers.removePrefix("+")}")
        RuntimeEnvironment.setFontScale(font)
        val activity = Robolectric.buildActivity(ComponentActivity::class.java).setup().get()
        val density = activity.resources.displayMetrics.density
        val params = DeviceParametersBuilders.DeviceParameters.Builder()
            .setScreenWidthDp(dp).setScreenHeightDp(dp).setScreenDensity(density).setFontScale(font)
            .setScreenShape(
                if (device.contains("round")) DeviceParametersBuilders.SCREEN_SHAPE_ROUND
                else DeviceParametersBuilders.SCREEN_SHAPE_RECT,
            )
            .build()
        val cases = listOf(
            "next_bus" to Triple(Demo.LONG_STOP, "040 · 12′", "Επόμενο λεωφορείο"),
            "no_data" to Triple("ΠΑΠΑΣΠΥΡΟΥ", "—", "Επόμενο λεωφορείο"),
            "no_favourites" to Triple("Στάσεις", "—", "Άνοιξε τις Στάσεις στο κινητό"),
        )
        val problems = ArrayList<String>()
        val tag = "tile_${device}_${"%.2f".format(java.util.Locale.ROOT, font)}"
        for ((name, t) in cases) {
            val root = TileLayout.build(activity, params, t.first, t.second, t.third, null)
            val parent = FrameLayout(activity)
            val px = (dp * density).toInt()
            activity.setContentView(parent, FrameLayout.LayoutParams(px, px))
            parent.setBackgroundColor(Color.BLACK)
            val renderer = TileRenderer(activity, { it.run() }) { }
            val future = renderer.inflateAsync(
                LayoutElementBuilders.Layout.Builder().setRoot(root).build(),
                ResourceBuilders.Resources.Builder().setVersion("1").build(),
                parent,
            )
            shadowOf(activity.mainLooper).idle()
            val view: View = future.get(5, TimeUnit.SECONDS)
            parent.measure(View.MeasureSpec.makeMeasureSpec(px, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(px, View.MeasureSpec.EXACTLY))
            parent.layout(0, 0, px, px)
            shadowOf(activity.mainLooper).idle()
            val bmp = parent.drawToBitmap()
            bmp.captureRoboImage("${ScreensShotTest.DIR}/tiles/${tag}_$name.png")
            problems += edges(bmp, density).map { "$tag $name: $it" }
            check(view.width >= 0)
        }
        File(ScreensShotTest.DIR, "tiles/${tag}-edge-report.txt").apply { parentFile!!.mkdirs() }
            .writeText(if (problems.isEmpty()) "OK\n" else problems.joinToString("\n", postfix = "\n"))
        assertTrue(problems.joinToString("\n"), problems.isEmpty())
    }

    private fun edges(b: Bitmap, density: Float): List<String> {
        val r = b.width / 2f
        val margin = 2f * density
        var n = 0
        for (y in 0 until b.height) for (x in 0 until b.width) {
            val outer = if (device.contains("round")) hypot(x + 0.5f - r, y + 0.5f - r) > r - margin
            else x < margin || x >= b.width - margin || y < margin || y >= b.height - margin
            if (!outer) continue
            val c = b.getPixel(x, y)
            if (maxOf(Color.red(c), Color.green(c), Color.blue(c)) > 24) n++
        }
        return if (n > 3) listOf("$n px within 2 dp of the edge") else emptyList()
    }
}
