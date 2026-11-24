package gr.staseis.app.wear.sync

import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.WearableListenerService

/** Receives favourites from the phone (DATA_CHANGED on `/staseis/favs`). Deletions keep the old list. */
class FavsListenerService : WearableListenerService() {
    override fun onDataChanged(events: DataEventBuffer) {
        try {
            events.forEach { e ->
                if (e.type == DataEvent.TYPE_CHANGED) FavsSync.apply(this, e.dataItem)
            }
        } catch (_: Exception) {
        } finally {
            events.release()
        }
    }
}
