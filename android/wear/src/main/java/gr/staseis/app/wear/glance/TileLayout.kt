package gr.staseis.app.wear.glance

import android.content.Context
import androidx.wear.protolayout.DeviceParametersBuilders.DeviceParameters
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.ModifiersBuilders
import androidx.wear.protolayout.material3.ColorScheme
import androidx.wear.protolayout.material3.Typography
import androidx.wear.protolayout.material3.materialScope
import androidx.wear.protolayout.material3.primaryLayout
import androidx.wear.protolayout.material3.text
import androidx.wear.protolayout.types.LayoutColor
import androidx.wear.protolayout.types.LayoutString

/**
 * The tile's layout: protolayout-material3 `primaryLayout`, which keeps every slot inside the round
 * screen (title at the top, main slot in the safe middle). Pure inputs, so the screenshot tests render it.
 */
object TileLayout {
    private val scheme = ColorScheme(
        primary = LayoutColor(0xFF8AB4F8.toInt()),
        onPrimary = LayoutColor(0xFF0B1B3A.toInt()),
        primaryContainer = LayoutColor(0xFF1E58C6.toInt()),
        onPrimaryContainer = LayoutColor(0xFFFFFFFF.toInt()),
        onSurface = LayoutColor(0xFFECEDE9.toInt()),
        onSurfaceVariant = LayoutColor(0xFFA3A9B1.toInt()),
        background = LayoutColor(0xFF000000.toInt()),
    )

    /** [title]: the stop (one line); [big]: "040 · 3′" or "—"; [caption]: «Επόμενο λεωφορείο». */
    fun build(
        context: Context,
        device: DeviceParameters,
        title: String,
        big: String,
        caption: String,
        onClick: ModifiersBuilders.Clickable?,
    ): LayoutElementBuilders.LayoutElement = materialScope(context, device, allowDynamicTheme = false, defaultColorScheme = scheme) {
        primaryLayout(
            titleSlot = { text(LayoutString(title), maxLines = 1) },
            mainSlot = {
                LayoutElementBuilders.Column.Builder()
                    .setHorizontalAlignment(LayoutElementBuilders.HORIZONTAL_ALIGN_CENTER)
                    .addContent(text(LayoutString(big), typography = Typography.DISPLAY_SMALL, maxLines = 1, color = colorScheme.primary))
                    .addContent(text(LayoutString(caption), typography = Typography.BODY_MEDIUM, maxLines = 2, color = colorScheme.onSurfaceVariant))
                    .build()
            },
            onClick = onClick,
        )
    }
}
