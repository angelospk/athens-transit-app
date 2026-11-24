package gr.staseis.app.wear.sync

import android.content.Context
import android.net.Uri
import com.google.android.gms.wearable.DataItem
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Wearable
import gr.staseis.app.wear.data.FavStore
import gr.staseis.app.wear.glance.Glance
import kotlinx.coroutines.tasks.await

/** Phone → watch favourites: Data Layer item `/staseis/favs`, string key `json`. */
object FavsSync {
    const val PATH = "/staseis/favs"
    const val KEY = "json"

    /** Applies one DataItem; returns true when the favourites changed. */
    fun apply(ctx: Context, item: DataItem): Boolean {
        if (item.uri.path != PATH) return false
        val json = try {
            DataMapItem.fromDataItem(item).dataMap.getString(KEY)
        } catch (_: Exception) {
            null
        }
        val changed = FavStore.accept(ctx, json)
        if (changed) Glance.favouritesChanged(ctx)
        return changed
    }

    /** Reads the current items at app start (the listener may have missed changes). */
    suspend fun pull(ctx: Context) {
        try {
            val buffer = Wearable.getDataClient(ctx.applicationContext).getDataItems(Uri.parse("wear://*$PATH")).await()
            try {
                buffer.forEach { apply(ctx, it) }
            } finally {
                buffer.release()
            }
        } catch (_: Exception) {
            // No Play services / no phone: keep what we have.
        }
    }
}
