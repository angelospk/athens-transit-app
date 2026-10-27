package dev.haroldpoi.live_card

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

private const val CHANNEL = "live_card"
private const val PREFS = "live_card"
private const val ENDED = "ended"
private const val EXTRA_ID = "id"

class LiveCardPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(b: FlutterPlugin.FlutterPluginBinding) {
        context = b.applicationContext
        channel = MethodChannel(b.binaryMessenger, "dev.haroldpoi/live_card")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(b: FlutterPlugin.FlutterPluginBinding) = channel.setMethodCallHandler(null)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "show" -> {
                show(
                    context,
                    call.argument<Int>("id")!!,
                    call.argument<String>("title")!!,
                    call.argument<String>("text")!!,
                    call.argument<String>("sub"),
                    call.argument<Int>("progress") ?: -1,
                    call.argument<String>("chip"),
                    call.argument<String>("endLabel") ?: "End",
                )
                result.success(null)
            }
            "takeEnded" -> {
                val p = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                val ended = p.getBoolean(ENDED, false)
                if (ended) p.edit().remove(ENDED).apply()
                result.success(ended)
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        private fun ensureChannel(nm: NotificationManager) {
            if (Build.VERSION.SDK_INT < 26 || nm.getNotificationChannel(CHANNEL) != null) return
            // Default importance: shown on the lock screen and allowed to be a Live Update. No sound:
            // the card changes every 30 s.
            val c = NotificationChannel(CHANNEL, "Live στην οθόνη κλειδώματος", NotificationManager.IMPORTANCE_DEFAULT)
            c.description = "Η πορεία του λεωφορείου σου ως τη στάση"
            c.setSound(null, null)
            c.enableVibration(false)
            c.setShowBadge(false)
            c.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            nm.createNotificationChannel(c)
        }

        fun show(ctx: Context, id: Int, title: String, text: String, sub: String?, progress: Int, chip: String?, endLabel: String) {
            // "Τέλος" after the service read the flag: keep the plain card until the next tick reads it.
            if (ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean(ENDED, false)) return
            val nm = ctx.getSystemService(NotificationManager::class.java)
            ensureChannel(nm)
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            val open = ctx.packageManager.getLaunchIntentForPackage(ctx.packageName)
                ?.let { PendingIntent.getActivity(ctx, 0, it, flags) }
            val end = PendingIntent.getBroadcast(ctx, 1, Intent(ctx, LiveCardEndReceiver::class.java).putExtra(EXTRA_ID, id), flags)
            val icon = ctx.resources.getIdentifier("ic_stat_bus", "drawable", ctx.packageName)
            val b = NotificationCompat.Builder(ctx, CHANNEL)
                .setSmallIcon(if (icon != 0) icon else ctx.applicationInfo.icon)
                .setContentTitle(title)
                .setContentText(text)
                .setSubText(sub)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setShowWhen(false)
                .setCategory(NotificationCompat.CATEGORY_PROGRESS)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setContentIntent(open)
                .addAction(0, endLabel, end)
                .setRequestPromotedOngoing(true)
            if (chip != null) b.setShortCriticalText(chip)
            if (Build.VERSION.SDK_INT >= 36 && progress >= 0 && nm.canPostPromotedNotifications()) {
                // Android 16 with Live Updates: their progress style, with the bus as the tracker. The first
                // Android 16 builds have no Live Updates and draw no bar for this style: they get the plain bar.
                val n = b.build()
                val style = Notification.ProgressStyle().setProgress(progress.coerceIn(0, 100))
                    .setProgressSegments(listOf(Notification.ProgressStyle.Segment(100)))
                    .setStyledByProgress(true)
                if (icon != 0) style.setProgressTrackerIcon(android.graphics.drawable.Icon.createWithResource(ctx, icon))
                val pb = Notification.Builder.recoverBuilder(ctx, n).setStyle(style)
                nm.notify(id, pb.build())
                return
            }
            if (progress >= 0) b.setProgress(100, progress.coerceIn(0, 100), false)
            nm.notify(id, b.build())
        }
    }
}

// The card's end button: remember it for the service (which stops the live card for the rules active
// now) and show at once a plain card, which the service keeps while it runs.
class LiveCardEndReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putBoolean(ENDED, true).apply()
        val id = intent.getIntExtra(EXTRA_ID, 0)
        val nm = ctx.getSystemService(NotificationManager::class.java)
        val icon = ctx.resources.getIdentifier("ic_stat_bus", "drawable", ctx.packageName)
        val n = NotificationCompat.Builder(ctx, "live") // the service's own low channel
            .setSmallIcon(if (icon != 0) icon else ctx.applicationInfo.icon)
            .setContentTitle("Athens Transit")
            .setContentText("Σε ειδοποιώ όταν έρθει το λεωφορείο.")
            .setOngoing(true)
            .setShowWhen(false)
            .build()
        nm.notify(id, n)
    }
}
