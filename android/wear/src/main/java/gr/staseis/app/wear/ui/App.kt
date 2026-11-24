package gr.staseis.app.wear.ui

import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.navigation.NavType
import androidx.navigation.navArgument
import androidx.wear.compose.material3.AppScaffold
import androidx.wear.compose.navigation.SwipeDismissableNavHost
import androidx.wear.compose.navigation.composable
import androidx.wear.compose.navigation.rememberSwipeDismissableNavController
import gr.staseis.app.wear.core.City
import gr.staseis.app.wear.core.Payload
import kotlinx.coroutines.flow.MutableStateFlow

private fun stopRoute(s: StopRef) = "stop/${s.city.key}/${s.id}?name=${Uri.encode(s.name)}"

@Composable
fun StaseisApp(deepLink: MutableStateFlow<Target?>) {
    val nav = rememberSwipeDismissableNavController()
    val link by deepLink.collectAsState()
    LaunchedEffect(link) {
        val route = when (val t = link) {
            null -> null
            Target.Favourites -> "favs"
            Target.Nearby -> "nearby"
            is Target.Stop -> stopRoute(t.ref)
        }
        if (route != null) {
            nav.navigate(route) { launchSingleTop = true }
            deepLink.value = null
        }
    }
    val open: (StopRef) -> Unit = { nav.navigate(stopRoute(it)) }
    StaseisTheme {
        AppScaffold {
            SwipeDismissableNavHost(navController = nav, startDestination = "home") {
                composable("home") {
                    HomeScreen(onFavs = { nav.navigate("favs") }, onNearby = { nav.navigate("nearby") })
                }
                composable("favs") { FavouritesScreen(open) }
                composable("nearby") { NearbyScreen(open) }
                composable(
                    "stop/{city}/{id}?name={name}",
                    arguments = listOf(
                        navArgument("city") { type = NavType.StringType },
                        navArgument("id") { type = NavType.StringType },
                        navArgument("name") { type = NavType.StringType; defaultValue = "" },
                    ),
                ) { entry ->
                    val a = entry.arguments
                    val city = City.fromKey(a?.getString("city"))
                    val id = a?.getString("id")?.takeIf { Payload.ID_RE.matches(it) }
                    if (city != null && id != null) {
                        StopScreen(StopRef(city, id, a.getString("name").orEmpty().take(Payload.MAX_NAME)))
                    } else {
                        MessageScreen(gr.staseis.app.wear.R.string.no_data)
                    }
                }
            }
        }
    }
}
