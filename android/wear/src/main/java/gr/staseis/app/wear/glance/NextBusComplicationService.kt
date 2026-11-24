package gr.staseis.app.wear.glance

import android.app.PendingIntent
import android.graphics.drawable.Icon
import androidx.wear.watchface.complications.data.ComplicationData
import androidx.wear.watchface.complications.data.ComplicationType
import androidx.wear.watchface.complications.data.LongTextComplicationData
import androidx.wear.watchface.complications.data.MonochromaticImage
import androidx.wear.watchface.complications.data.PlainComplicationText
import androidx.wear.watchface.complications.data.ShortTextComplicationData
import androidx.wear.watchface.complications.datasource.ComplicationDataTimeline
import androidx.wear.watchface.complications.datasource.ComplicationRequest
import androidx.wear.watchface.complications.datasource.SuspendingTimelineComplicationDataSourceService
import androidx.wear.watchface.complications.datasource.TimeInterval
import androidx.wear.watchface.complications.datasource.TimelineEntry
import gr.staseis.app.wear.R
import gr.staseis.app.wear.core.NextBusEntry
import gr.staseis.app.wear.data.ArrivalsRepo
import java.time.Instant

/** Complication: the next bus at the first favourite stop (SHORT_TEXT, LONG_TEXT), from the cache. */
class NextBusComplicationService : SuspendingTimelineComplicationDataSourceService() {

    override fun onComplicationActivated(complicationInstanceId: Int, type: ComplicationType) {
        Glance.setInUse(this, "complication", complicationInstanceId, true)
        Glance.kick(this, null, ArrivalsRepo.nowS(), force = true)
    }

    override fun onComplicationDeactivated(complicationInstanceId: Int) {
        Glance.setInUse(this, "complication", complicationInstanceId, false)
    }

    override suspend fun onComplicationRequest(request: ComplicationRequest): ComplicationDataTimeline? = try {
        val nowS = ArrivalsRepo.nowS()
        val (target, entries) = Glance.entries(this, nowS)
        val name = target?.let { Glance.stopName(this, it) }
        val tap = PendingIntent.getActivity(
            this, 0, Glance.openStopIntent(this, target),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val type = request.complicationType
        val default = data(type, NextBusEntry(nowS, null, null, null), name, tap)
            ?: return null
        val timeline = entries.filter { !it.isEmpty && it.endS != null }.mapNotNull { e ->
            data(type, e, name, tap)?.let {
                TimelineEntry(TimeInterval(Instant.ofEpochSecond(e.startS), Instant.ofEpochSecond(e.endS!!)), it)
            }
        }
        ComplicationDataTimeline(default, timeline)
    } catch (_: Exception) {
        null
    }

    override fun getPreviewData(type: ComplicationType): ComplicationData? =
        data(type, NextBusEntry(0, 0, "040", "3′"), "ΠΑΠΑΣΠΥΡΟΥ", null)

    private fun data(type: ComplicationType, e: NextBusEntry, name: String?, tap: PendingIntent?): ComplicationData? {
        val desc = PlainComplicationText.Builder(
            if (e.isEmpty) getString(R.string.next_bus) else "${getString(R.string.next_bus)}: ${e.line}, ${e.minutes}",
        ).build()
        val icon = MonochromaticImage.Builder(Icon.createWithResource(this, R.drawable.ic_bus)).build()
        return when (type) {
            ComplicationType.SHORT_TEXT -> ShortTextComplicationData.Builder(
                PlainComplicationText.Builder(e.minutes ?: "—").build(), desc,
            ).apply {
                e.line?.let { setTitle(PlainComplicationText.Builder(it).build()) }
                if (e.isEmpty) setMonochromaticImage(icon)
                setTapAction(tap)
            }.build()
            ComplicationType.LONG_TEXT -> LongTextComplicationData.Builder(
                PlainComplicationText.Builder(e.label()).build(), desc,
            ).apply {
                name?.let { setTitle(PlainComplicationText.Builder(it).build()) }
                setMonochromaticImage(icon)
                setTapAction(tap)
            }.build()
            else -> null
        }
    }
}
