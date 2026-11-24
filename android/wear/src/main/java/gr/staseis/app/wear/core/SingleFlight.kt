package gr.staseis.app.wear.core

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.async

/**
 * One call in flight per key. The work runs in [scope] (an app-level SupervisorJob scope), not in the
 * caller: a caller that is cancelled (a screen closed, a worker stopped) stops waiting, but the work goes
 * on and every other caller still gets its result, so nobody can be left waiting forever.
 */
class SingleFlight<K, V>(private val scope: CoroutineScope) {
    private val lock = Any()
    private val inflight = HashMap<K, Deferred<V>>()

    suspend fun run(key: K, block: suspend () -> V): V {
        val d = synchronized(lock) {
            inflight[key] ?: scope.async(start = CoroutineStart.LAZY) { block() }.also { def ->
                inflight[key] = def
                def.invokeOnCompletion { synchronized(lock) { if (inflight[key] === def) inflight.remove(key) } }
            }
        }
        d.start()
        return d.await()
    }

    fun inFlight(key: K): Boolean = synchronized(lock) { inflight.containsKey(key) }
}
