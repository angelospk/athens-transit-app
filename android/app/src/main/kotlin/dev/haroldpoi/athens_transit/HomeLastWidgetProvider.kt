package dev.haroldpoi.athens_transit

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Paint
import android.os.Build
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

// "Γυρνάς σπίτι": the app saves today's last run home of each line (Unix s) from where it last was;
// the widget shows them as Athens clock times, strikes the gone ones, and counts down. 2×1 and 2×2
// show the first last run that has not gone (W3b), 4×2 the list (W3c).
class HomeLastWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (id in appWidgetIds) {
            val v = if (Build.VERSION.SDK_INT >= 31) {
                RemoteViews(
                    mapOf(
                        SizeF(110f, 40f) to small(context, widgetData),
                        SizeF(250f, 110f) to list(context, widgetData),
                    )
                )
            } else {
                list(context, widgetData)
            }
            appWidgetManager.updateAppWidget(id, v)
        }
    }

    private data class Run(val line: String, val bg: Int, val fg: Int, val t: Long)

    private fun runs(widgetData: SharedPreferences): List<Run> {
        val a = try { JSONArray(widgetData.getString("h_rows", "[]")) } catch (e: Exception) { JSONArray() }
        return (0 until a.length()).map {
            val r = a.getJSONObject(it)
            Run(r.getString("line"), Color.parseColor(r.getString("bg")), Color.parseColor(r.getString("fg")), r.getLong("t"))
        }
    }

    // "από Σύνταγμα · πριν 25′": where the app last was, and how long ago.
    private fun from(widgetData: SharedPreferences, now: Long): String? {
        val f = widgetData.getString("h_from", null) ?: return null
        val at = (widgetData.all["h_at"] as? Number)?.toLong() ?: return "από $f"
        return "από $f · πριν ${inWords(now - at)}"
    }

    private fun list(context: Context, widgetData: SharedPreferences): RemoteViews {
        val now = System.currentTimeMillis() / 1000
        val v = RemoteViews(context.packageName, R.layout.home_last_widget)
        v.setOnClickPendingIntent(R.id.hroot, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
        val runs = runs(widgetData)
        from(widgetData, now)?.let { f ->
            val first = runs.firstOrNull { it.t > now - 60 }
            v.setTextViewText(R.id.hsub, if (first == null) "$f · τα τελευταία έφυγαν" else "$f · πρώτα χάνεται το ${first.line}")
        }
        for (k in ROW.indices) {
            val r = runs.getOrNull(k)
            if (r == null) {
                v.setViewVisibility(ROW[k], View.GONE)
                continue
            }
            val left = r.t - now
            val gone = left < -60
            v.setViewVisibility(ROW[k], View.VISIBLE)
            badge(v, LINE[k], r)
            v.setTextViewText(WHEN[k], if (gone) "έφυγε" else "σε ${inWords(left)}")
            v.setTextViewText(TIME[k], clock(r.t))
            v.setInt(TIME[k], "setPaintFlags", if (gone) Paint.STRIKE_THRU_TEXT_FLAG or Paint.ANTI_ALIAS_FLAG else Paint.ANTI_ALIAS_FLAG)
            if (!gone && left < SOON_S) v.setTextColor(TIME[k], LATE) else v.setTextColor(TIME[k], context.getColor(R.color.widget_ink))
        }
        return v
    }

    private fun small(context: Context, widgetData: SharedPreferences): RemoteViews {
        val now = System.currentTimeMillis() / 1000
        val v = RemoteViews(context.packageName, R.layout.home_last_small)
        v.setOnClickPendingIntent(R.id.hroot, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
        val f = from(widgetData, now) ?: return v
        val r = runs(widgetData).firstOrNull { it.t > now - 60 }
        if (r == null) {
            v.setTextViewText(R.id.hbig, "—")
            v.setViewVisibility(R.id.hbigline, View.GONE)
            v.setTextViewText(R.id.hbigsub, "Τα τελευταία έφυγαν · $f")
            return v
        }
        val left = r.t - now
        v.setTextViewText(R.id.hbig, clock(r.t))
        v.setTextColor(R.id.hbig, if (left < SOON_S) LATE else context.getColor(R.color.widget_ink))
        v.setViewVisibility(R.id.hbigline, View.VISIBLE)
        badge(v, R.id.hbigline, r)
        v.setTextViewText(R.id.hbigsub, "σε ${inWords(left)} · $f")
        return v
    }

    private fun badge(v: RemoteViews, id: Int, r: Run) {
        v.setTextViewText(id, r.line)
        v.setTextColor(id, r.fg)
        if (Build.VERSION.SDK_INT >= 31) v.setColorStateList(id, "setBackgroundTintList", ColorStateList.valueOf(r.bg))
        else v.setInt(id, "setBackgroundColor", r.bg)
    }

    companion object {
        private val ROW = intArrayOf(R.id.hrow0, R.id.hrow1, R.id.hrow2, R.id.hrow3)
        private val LINE = intArrayOf(R.id.hline0, R.id.hline1, R.id.hline2, R.id.hline3)
        private val WHEN = intArrayOf(R.id.hwhen0, R.id.hwhen1, R.id.hwhen2, R.id.hwhen3)
        private val TIME = intArrayOf(R.id.htime0, R.id.htime1, R.id.htime2, R.id.htime3)
        private const val SOON_S = 30 * 60 // the warning colour within this
        private val LATE = Color.parseColor("#C2410C")

        private fun clock(t: Long): String =
            SimpleDateFormat("HH:mm", Locale.US).apply { timeZone = TimeZone.getTimeZone("Europe/Athens") }.format(Date(t * 1000))

        // "45′", "1ώ 12′".
        private fun inWords(s: Long): String {
            val m = (s.coerceAtLeast(0) + 30) / 60
            return if (m < 60) "$m′" else "${m / 60}ώ ${m % 60}′"
        }
    }
}
