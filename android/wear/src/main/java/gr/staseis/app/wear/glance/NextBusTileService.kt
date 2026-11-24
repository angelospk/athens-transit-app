package gr.staseis.app.wear.glance

import androidx.concurrent.futures.CallbackToFutureAdapter
import androidx.wear.protolayout.ActionBuilders
import androidx.wear.protolayout.DeviceParametersBuilders.DeviceParameters
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.ModifiersBuilders
import androidx.wear.protolayout.ResourceBuilders
import androidx.wear.protolayout.TimelineBuilders
import androidx.wear.tiles.EventBuilders
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import com.google.common.util.concurrent.ListenableFuture
import gr.staseis.app.wear.R
import gr.staseis.app.wear.data.ArrivalsRepo
import gr.staseis.app.wear.ui.MainActivity

/** Tile: the next bus at the first favourite stop, from the cache only (never blocks on the network). */
class NextBusTileService : TileService() {
    private val resVersion = "1"

    override fun onTileRequest(requestParams: RequestBuilders.TileRequest): ListenableFuture<TileBuilders.Tile> =
        CallbackToFutureAdapter.getFuture { c ->
            c.set(
                try {
                    buildTile(requestParams.deviceConfiguration)
                } catch (_: Exception) {
                    emptyTile(requestParams.deviceConfiguration)
                },
            )
            "tile"
        }

    override fun onTileResourcesRequest(
        requestParams: RequestBuilders.ResourcesRequest,
    ): ListenableFuture<ResourceBuilders.Resources> = CallbackToFutureAdapter.getFuture { c ->
        c.set(ResourceBuilders.Resources.Builder().setVersion(resVersion).build())
        "res"
    }

    override fun onTileAddEvent(requestParams: EventBuilders.TileAddEvent) {
        Glance.setInUse(this, "tile", requestParams.tileId, true)
        Glance.kick(this, null, ArrivalsRepo.nowS(), force = true)
    }

    override fun onTileRemoveEvent(requestParams: EventBuilders.TileRemoveEvent) {
        Glance.setInUse(this, "tile", requestParams.tileId, false)
    }

    private fun buildTile(device: DeviceParameters): TileBuilders.Tile {
        val nowS = ArrivalsRepo.nowS()
        val (target, entries) = Glance.entries(this, nowS)
        val title = if (target == null) getString(R.string.app_name) else Glance.stopName(this, target)
        val caption = if (target == null) getString(R.string.no_favs_short) else getString(R.string.next_bus)
        val click = clickable(target)
        val timeline = TimelineBuilders.Timeline.Builder()
        entries.forEach { e ->
            val validity = TimelineBuilders.TimeInterval.Builder().setStartMillis(e.startS * 1000)
            e.endS?.let { validity.setEndMillis(it * 1000) }
            timeline.addTimelineEntry(
                TimelineBuilders.TimelineEntry.Builder()
                    .setValidity(validity.build())
                    .setLayout(
                        LayoutElementBuilders.Layout.Builder()
                            .setRoot(TileLayout.build(this, device, title, e.label(), caption, click))
                            .build(),
                    )
                    .build(),
            )
        }
        return TileBuilders.Tile.Builder()
            .setResourcesVersion(resVersion)
            .setFreshnessIntervalMillis(15 * 60 * 1000L)
            .setTileTimeline(timeline.build())
            .build()
    }

    private fun emptyTile(device: DeviceParameters): TileBuilders.Tile = TileBuilders.Tile.Builder()
        .setResourcesVersion(resVersion)
        .setTileTimeline(
            TimelineBuilders.Timeline.fromLayoutElement(
                TileLayout.build(this, device, getString(R.string.app_name), "—", getString(R.string.next_bus), clickable(null)),
            ),
        )
        .build()

    private fun clickable(t: Glance.Target?): ModifiersBuilders.Clickable {
        val launch = ActionBuilders.LaunchAction.Builder().setAndroidActivity(
            ActionBuilders.AndroidActivity.Builder()
                .setPackageName(packageName)
                .setClassName(MainActivity::class.java.name)
                .apply {
                    if (t != null) {
                        addKeyToExtraMapping(MainActivity.EXTRA_CITY, ActionBuilders.stringExtra(t.city.key))
                        addKeyToExtraMapping(MainActivity.EXTRA_STOP, ActionBuilders.stringExtra(t.fav.id))
                        addKeyToExtraMapping(MainActivity.EXTRA_NAME, ActionBuilders.stringExtra(t.fav.name))
                    }
                }
                .build(),
        ).build()
        return ModifiersBuilders.Clickable.Builder().setId("open").setOnClick(launch).build()
    }
}
