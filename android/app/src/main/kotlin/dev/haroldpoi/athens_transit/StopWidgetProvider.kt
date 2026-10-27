package dev.haroldpoi.athens_transit

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.res.ColorStateList
import android.graphics.Color
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

// "Η στάση μου": the app saves each line's next arrivals as clock times (Unix s); every redraw (the
// app's scheduled updates, once a minute for half an hour) turns them into minutes from now, so the
// widget counts down without the app running.
class StopWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val now = System.currentTimeMillis() / 1000
        val rows = try { JSONArray(widgetData.getString("w_rows", "[]")) } catch (e: Exception) { JSONArray() }
        val rowIds = intArrayOf(R.id.row0, R.id.row1, R.id.row2)
        val lineIds = intArrayOf(R.id.line0, R.id.line1, R.id.line2)
        val noteIds = intArrayOf(R.id.note0, R.id.note1, R.id.note2)
        val etaIds = intArrayOf(R.id.eta0, R.id.eta1, R.id.eta2)
        for (id in appWidgetIds) {
            val v = RemoteViews(context.packageName, R.layout.stop_widget)
            v.setOnClickPendingIntent(R.id.widget_root, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
            widgetData.getString("w_title", null)?.let { v.setTextViewText(R.id.title, it) }
            val at = (widgetData.all["w_at"] as? Number)?.toLong() ?: 0L // home_widget saves a small Dart int as Integer
            val age = if (at == 0L) "" else " · δεδομένα πριν ${(now - at) / 60}′"
            widgetData.getString("w_sub", null)?.let { v.setTextViewText(R.id.sub, it + age) }
            var shown = 0
            for (i in 0 until rows.length()) {
                if (shown == 3) break
                val r = rows.getJSONObject(i)
                val times = r.getJSONArray("at")
                val left = (0 until times.length()).map { times.getLong(it) - now }.filter { it > -60 }
                if (left.isEmpty()) continue
                val fmt = { s: Long -> if (s < 45) "τώρα" else "${(s + 30) / 60}′" }
                v.setViewVisibility(rowIds[shown], View.VISIBLE)
                v.setTextViewText(lineIds[shown], r.getString("line"))
                v.setTextColor(lineIds[shown], Color.parseColor(r.getString("fg")))
                val bg = Color.parseColor(r.getString("bg"))
                if (Build.VERSION.SDK_INT >= 31) v.setColorStateList(lineIds[shown], "setBackgroundTintList", ColorStateList.valueOf(bg))
                else v.setInt(lineIds[shown], "setBackgroundColor", bg)
                v.setTextViewText(noteIds[shown], if (left.size > 1) "μετά ${fmt(left[1])}" else r.optString("note"))
                v.setTextViewText(etaIds[shown], "~" + fmt(left[0]))
                shown++
            }
            for (k in shown until 3) v.setViewVisibility(rowIds[k], View.GONE)
            appWidgetManager.updateAppWidget(id, v)
        }
    }
}
