package gr.staseis.app.wear.core

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test
import java.util.concurrent.atomic.AtomicInteger

class SingleFlightTest {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    @Test fun cancelledFirstCallerDoesNotHangTheOthers() = runBlocking {
        val flight = SingleFlight<String, Int>(scope)
        val gate = CompletableDeferred<Unit>()
        val started = CompletableDeferred<Unit>()
        val calls = AtomicInteger()
        val block: suspend () -> Int = {
            calls.incrementAndGet()
            started.complete(Unit)
            gate.await()
            42
        }
        // The first caller starts the fetch, then is cancelled mid-fetch (a screen closed).
        val first = launch(Dispatchers.Default) { flight.run("k", block) }
        started.await()
        val second = async(Dispatchers.Default) { flight.run("k", block) }
        first.cancelAndJoin()
        gate.complete(Unit)
        assertEquals(42, withTimeout(5_000) { second.await() })
        assertEquals(1, calls.get())
        assertFalse(flight.inFlight("k"))
    }

    @Test fun oneCallPerKeyAndNextCallStartsFresh() = runBlocking {
        val flight = SingleFlight<String, Int>(scope)
        val calls = AtomicInteger()
        val gate = CompletableDeferred<Unit>()
        val a = async(Dispatchers.Default) { flight.run("k") { calls.incrementAndGet(); gate.await(); 1 } }
        val b = async(Dispatchers.Default) {
            while (!flight.inFlight("k")) kotlinx.coroutines.yield()
            flight.run("k") { calls.incrementAndGet(); 2 }
        }
        while (!flight.inFlight("k")) kotlinx.coroutines.yield()
        kotlinx.coroutines.delay(50)
        gate.complete(Unit)
        assertEquals(1, a.await())
        assertEquals(1, b.await())
        assertEquals(1, calls.get())
        assertEquals(3, flight.run("k") { calls.incrementAndGet(); 3 })
        assertEquals(2, calls.get())
    }

    @Test fun failureReachesEveryCallerAndClearsTheKey() = runBlocking {
        val flight = SingleFlight<String, Int>(scope)
        val r = runCatching { flight.run("k") { error("boom") } }
        assertEquals("boom", r.exceptionOrNull()?.message)
        assertFalse(flight.inFlight("k"))
        assertEquals(7, flight.run("k") { 7 })
    }
}
