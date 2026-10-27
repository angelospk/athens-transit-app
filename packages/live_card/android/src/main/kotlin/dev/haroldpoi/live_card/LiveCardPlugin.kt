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
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

private const val CHANNEL = "live_card"
private const val PREFS = "live_card"
private const val ENDED = "ended_ids" // rule ids whose card's end button was pressed, until the service reads them
private const val EXTRA_ID = "id"
private const val EXTRA_RULE = "rule"
private const val EXTRA_OPEN = "dev.haroldpoi.live_card.OPEN"

// Also attached to the app's activity: a tap on the card starts or resumes it with EXTRA_OPEN, which the
// app takes once ("takeOpen") to show that bus.
class LiveCardPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware, PluginRegistry.NewIntentListener {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: ActivityPluginBinding? = null

    override fun onAttachedToActivity(b: ActivityPluginBinding) {
        activity = b
        b.addOnNewIntentListener(this)
        take(b.activity.intent)
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(b: ActivityPluginBinding) = onAttachedToActivity(b)

    override fun onDetachedFromActivity() {
        activity?.removeOnNewIntentListener(this)
        activity = null
    }

    override fun onNewIntent(intent: Intent): Boolean {
        take(intent)
        // The app may be in front already: no resume follows, so hand the payload to Dart now.
        pendingOpen?.let {
            pendingOpen = null
            channel.invokeMethod("open", it)
        }
        return false
    }

    private fun take(i: Intent?) {
        val o = i?.getStringExtra(EXTRA_OPEN) ?: return
        pendingOpen = o
        i.removeExtra(EXTRA_OPEN) // a later re-attach (rotation) must not open it again
    }

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
                    call.argument<String>("ruleId") ?: "",
                    call.argument<String>("open"),
                )
                result.success(null)
            }
            "takeEnded" -> {
                val p = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                val ended = p.getStringSet(ENDED, null)?.toList() ?: emptyList()
                if (ended.isNotEmpty()) p.edit().remove(ENDED).commit()
                result.success(ended)
            }
            "takeOpen" -> {
                result.success(pendingOpen)
                pendingOpen = null
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        @Volatile var pendingOpen: String? = null

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

        fun show(ctx: Context, id: Int, title: String, text: String, sub: String?, progress: Int, chip: String?, endLabel: String, ruleId: String, openWith: String?) {
            // Ended, and the service has not read it yet: keep the receiver's short card until it does.
            if (ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getStringSet(ENDED, null)?.contains(ruleId) == true) return
            val nm = ctx.getSystemService(NotificationManager::class.java)
            ensureChannel(nm)
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            val open = ctx.packageManager.getLaunchIntentForPackage(ctx.packageName)
                ?.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                ?.also { if (openWith != null) it.putExtra(EXTRA_OPEN, openWith) }
                ?.let { PendingIntent.getActivity(ctx, 0, it, flags) }
            val end = PendingIntent.getBroadcast(
                ctx, 1, Intent(ctx, LiveCardEndReceiver::class.java).putExtra(EXTRA_ID, id).putExtra(EXTRA_RULE, ruleId), flags)
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

// The card's end button: remember the rule for the service (which stops it for today, and stops itself
// when no other rule is active) and show at once a short card that goes away by itself.
class LiveCardEndReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        val p = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val rule = intent.getStringExtra(EXTRA_RULE) ?: ""
        p.edit().putStringSet(ENDED, (p.getStringSet(ENDED, null) ?: emptySet()) + rule).commit()
        val id = intent.getIntExtra(EXTRA_ID, 0)
        val nm = ctx.getSystemService(NotificationManager::class.java)
        val icon = ctx.resources.getIdentifier("ic_stat_bus", "drawable", ctx.packageName)
        val n = NotificationCompat.Builder(ctx, "live") // the service's own low channel
            .setSmallIcon(if (icon != 0) icon else ctx.applicationInfo.icon)
            .setContentTitle("Η ειδοποίηση σταμάτησε")
            .setContentText("Δεν θα σε ειδοποιήσω ξανά για αυτό σήμερα.")
            .setShowWhen(false)
            .setTimeoutAfter(15_000)
            .build()
        nm.notify(id, n)
    }
}
