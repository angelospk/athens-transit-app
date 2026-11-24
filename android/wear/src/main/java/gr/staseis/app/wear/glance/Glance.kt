package gr.staseis.app.wear.glance

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import androidx.wear.tiles.TileService
import androidx.wear.watchface.complications.datasource.ComplicationDataSourceUpdateRequester
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import gr.staseis.app.wear.core.City
import gr.staseis.app.wear.core.Fav
import gr.staseis.app.wear.core.NextBusEntry
import gr.staseis.app.wear.core.NextBusTimeline
import gr.staseis.app.wear.data.ArrivalsRepo
import gr.staseis.app.wear.data.FavStore
import gr.staseis.app.wear.ui.MainActivity
import gr.staseis.app.wear.R
import java.util.concurrent.TimeUnit

/**
 * Shared by the tile and the complication: the first favourite's next bus from the cache, and the
 * background refresh that runs only while a tile or a complication is in use.
 */
object Glance {
    private const val PREFS = "glance"
    private const val PERIODIC = "glance-refresh"
    private const val ONCE = "glance-refresh-now"
    private const val STALE_FOR_KICK_S = 5 * 60

    data class Target(val city: City, val fav: Fav)

    fun target(ctx: Context): Target? {
        val p = FavStore.get(ctx) ?: return null
        val f = p.favs.firstOrNull() ?: return null
        return Target(p.city, f)
    }

    /** Entries for the tile / complication, from the cache only (never the network). */
    fun entries(ctx: Context, nowS: Long): Pair<Target?, List<NextBusEntry>> {
        val t = target(ctx) ?: return null to listOf(NextBusEntry(nowS, null, null, null))
        val snap = ArrivalsRepo.cached(ctx, t.city, t.fav.id)
        val list = NextBusTimeline.build(
            snap?.data?.arrivals.orEmpty(), t.fav.lines, snap?.fetchedAtS?.takeIf { snap.data != null },
            nowS, ctx.getString(R.string.now),
        )
        if (snap?.fetchedAtS == null || nowS - snap.fetchedAtS > STALE_FOR_KICK_S) kick(ctx)
        return t to list
    }

    fun stopName(ctx: Context, t: Target): String =
        t.fav.name.ifEmpty { ArrivalsRepo.cached(ctx, t.city, t.fav.id)?.data?.name.orEmpty() }.ifEmpty { t.fav.id }

    fun openStopIntent(ctx: Context, t: Target?): Intent = Intent(ctx, MainActivity::class.java).apply {
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        if (t != null) {
            putExtra(MainActivity.EXTRA_CITY, t.city.key)
            putExtra(MainActivity.EXTRA_STOP, t.fav.id)
            putExtra(MainActivity.EXTRA_NAME, t.fav.name)
        }
    }

    // --- In use: tiles and complications register here; the periodic job runs only while any is in use.

    private fun prefs(ctx: Context) = ctx.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun setInUse(ctx: Context, kind: String, id: Int, inUse: Boolean) {
        val key = "inuse.$kind"
        val set = prefs(ctx).getStringSet(key, emptySet())!!.toMutableSet()
        if (inUse) set += id.toString() else set -= id.toString()
        prefs(ctx).edit().putStringSet(key, set).apply()
        reschedule(ctx)
    }

    private fun anyInUse(ctx: Context): Boolean =
        listOf("tile", "complication").any { prefs(ctx).getStringSet("inuse.$it", emptySet())!!.isNotEmpty() }

    fun reschedule(ctx: Context) {
        val wm = WorkManager.getInstance(ctx.applicationContext)
        if (anyInUse(ctx)) {
            val req = PeriodicWorkRequestBuilder<RefreshWorker>(15, TimeUnit.MINUTES)
                .setConstraints(networkConstraint())
                .build()
            wm.enqueueUniquePeriodicWork(PERIODIC, ExistingPeriodicWorkPolicy.KEEP, req)
        } else {
            wm.cancelUniqueWork(PERIODIC)
        }
    }

    /** One refresh soon, when the cache is stale and something is on screen. */
    fun kick(ctx: Context) {
        if (!anyInUse(ctx) || target(ctx) == null) return
        val req = OneTimeWorkRequestBuilder<RefreshWorker>().setConstraints(networkConstraint()).build()
        WorkManager.getInstance(ctx.applicationContext).enqueueUniqueWork(ONCE, ExistingWorkPolicy.KEEP, req)
    }

    private fun networkConstraint() = Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build()

    fun requestUpdates(ctx: Context) {
        try {
            TileService.getUpdater(ctx).requestUpdate(NextBusTileService::class.java)
        } catch (_: Exception) {
        }
        try {
            ComplicationDataSourceUpdateRequester
                .create(ctx, ComponentName(ctx, NextBusComplicationService::class.java))
                .requestUpdateAll()
        } catch (_: Exception) {
        }
    }

    fun favouritesChanged(ctx: Context) {
        requestUpdates(ctx)
        kick(ctx)
    }

    fun nowWord(ctx: Context) = ctx.getString(R.string.now)
}

class RefreshWorker(ctx: Context, params: WorkerParameters) : CoroutineWorker(ctx, params) {
    override suspend fun doWork(): Result {
        val t = Glance.target(applicationContext) ?: return Result.success()
        ArrivalsRepo.refresh(applicationContext, t.city, t.fav.id)
        Glance.requestUpdates(applicationContext)
        return Result.success()
    }
}

/** Short labels used by both surfaces. */
internal fun NextBusEntry.label(): String = short("—")

