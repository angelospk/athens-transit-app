package gr.staseis.app.wear.ui

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.wear.compose.material3.ColorScheme
import androidx.wear.compose.material3.MaterialTheme

/**
 * The phone app's palette (lib/ui/theme.dart, dark tones) instead of the stock Material lavender:
 * dark ground, the icon's accent blue for primary buttons, the phone's surfaces for cards.
 */
object Tones {
    val ground = Color(0xFF0F1113)
    val card = Color(0xFF181B1E)
    val surface = Color(0xFF24282C)
    val rule = Color(0xFF2E3337)
    val ink = Color(0xFFECEDE9)
    val muted = Color(0xFFA3A9B1)
    val outline = Color(0xFF4A5560)
    val accent = Color(0xFF2A66DE)
    val accentDeep = Color(0xFF1E58C6)
    val accentLight = Color(0xFF8AB4F8)
}

private val Scheme = ColorScheme(
    primary = Tones.accent,
    primaryDim = Tones.accentDeep,
    primaryContainer = Tones.accentDeep,
    onPrimary = Color.White,
    onPrimaryContainer = Color.White,
    secondary = Tones.accentLight,
    secondaryDim = Tones.accentLight,
    secondaryContainer = Tones.rule,
    onSecondary = Tones.ground,
    onSecondaryContainer = Tones.ink,
    tertiary = Tones.accentLight,
    tertiaryDim = Tones.accentLight,
    tertiaryContainer = Tones.rule,
    onTertiary = Tones.ground,
    onTertiaryContainer = Tones.ink,
    surfaceContainerLow = Tones.card,
    surfaceContainer = Tones.surface,
    surfaceContainerHigh = Tones.rule,
    onSurface = Tones.ink,
    onSurfaceVariant = Tones.muted,
    outline = Tones.outline,
    outlineVariant = Tones.rule,
    background = Tones.ground,
    onBackground = Tones.ink,
)

@Composable
fun StaseisTheme(content: @Composable () -> Unit) = MaterialTheme(colorScheme = Scheme, content = content)
