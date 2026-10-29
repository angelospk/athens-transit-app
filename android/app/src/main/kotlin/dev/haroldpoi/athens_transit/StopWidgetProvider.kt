package dev.haroldpoi.athens_transit

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.res.ColorStateList
import android.graphics.Color
import android.os.Build
import android.util.SizeF
import android.view.Gravity
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

// "Η στάση μου": the app saves each line's next arrivals as clock times (Unix s); every redraw (the
// app's scheduled updates, once a minute for half an hour) turns them into minutes from now, so the
// widget counts down without the app running. From Android 12 the launcher picks one layout per
// size: 2×1 one line, 4×1 two, 4×2 three, 4×3 four. The heights are what the rows need (a Pixel
// row of cells is ~105dp), so a launcher with lower cells gets fewer rows instead of clipped ones.
class StopWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (id in appWidgetIds) {
            val v = if (Build.VERSION.SDK_INT >= 31) {
                RemoteViews(
                    mapOf(
                        SizeF(110f, 40f) to views(context, widgetData, 1, false),
                        SizeF(250f, 80f) to views(context, widgetData, 2, false),
                        SizeF(250f, 150f) to views(context, widgetData, 3, true),
                        SizeF(250f, 260f) to views(context, widgetData, 4, true),
                    )
                )
            } else {
                views(context, widgetData, 3, true)
            }
            appWidgetManager.updateAppWidget(id, v)
        }
    }

    private fun views(context: Context, widgetData: SharedPreferences, maxRows: Int, head: Boolean): RemoteViews {
        val now = System.currentTimeMillis() / 1000
        val rows = try { JSONArray(widgetData.getString("w_rows", "[]")) } catch (e: Exception) { JSONArray() }
        val v = RemoteViews(context.packageName, R.layout.stop_widget)
        v.setOnClickPendingIntent(R.id.widget_root, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
        widgetData.getString("w_title", null)?.let { v.setTextViewText(R.id.title, it) }
        val at = (widgetData.all["w_at"] as? Number)?.toLong() ?: 0L // home_widget saves a small Dart int as Integer
        val age = if (at == 0L) "" else " · δεδομένα πριν ${(now - at) / 60}′"
        widgetData.getString("w_sub", null)?.let { v.setTextViewText(R.id.sub, it + age) }
        // A short widget keeps the lines: the stop's name and the age go.
        val visible = if (head) View.VISIBLE else View.GONE
        v.setViewVisibility(R.id.title, visible)
        v.setViewVisibility(R.id.sub, visible)
        v.setInt(R.id.widget_root, "setGravity", if (head) Gravity.TOP else Gravity.CENTER_VERTICAL)
        val fmt = { s: Long -> if (s < 45) "τώρα" else "${(s + 30) / 60}′" }
        var shown = 0
        for (i in 0 until rows.length()) {
            if (shown == maxRows) break
            val r = rows.getJSONObject(i)
            val times = r.getJSONArray("at")
            val left = (0 until times.length()).map { times.getLong(it) - now }.filter { it > -60 }
            if (left.isEmpty()) continue
            v.setViewVisibility(ROW[shown], View.VISIBLE)
            v.setTextViewText(LINE[shown], r.getString("line"))
            v.setTextColor(LINE[shown], Color.parseColor(r.getString("fg")))
            val bg = Color.parseColor(r.getString("bg"))
            if (Build.VERSION.SDK_INT >= 31) v.setColorStateList(LINE[shown], "setBackgroundTintList", ColorStateList.valueOf(bg))
            else v.setInt(LINE[shown], "setBackgroundColor", bg)
            // The destination, the next bus big, the one after small: «→ Πειραιάς  2′ · 14′».
            v.setTextViewText(NOTE[shown], r.optString("note"))
            v.setTextViewText(ETA[shown], fmt(left[0]))
            v.setTextViewText(NEXT[shown], if (left.size > 1) "· ${fmt(left[1])}" else "")
            shown++
        }
        for (k in shown until ROW.size) v.setViewVisibility(ROW[k], View.GONE)
        return v
    }

    companion object {
        private val ROW = intArrayOf(R.id.row0, R.id.row1, R.id.row2, R.id.row3)
        private val LINE = intArrayOf(R.id.line0, R.id.line1, R.id.line2, R.id.line3)
        private val NOTE = intArrayOf(R.id.note0, R.id.note1, R.id.note2, R.id.note3)
        private val ETA = intArrayOf(R.id.eta0, R.id.eta1, R.id.eta2, R.id.eta3)
        private val NEXT = intArrayOf(R.id.next0, R.id.next1, R.id.next2, R.id.next3)
    }
}
