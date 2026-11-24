package gr.staseis.app.wear.data

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob

/** Process-wide scope for work that must outlive the screen or worker that started it. */
val AppScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
