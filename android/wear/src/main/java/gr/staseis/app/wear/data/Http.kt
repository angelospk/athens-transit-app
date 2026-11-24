package gr.staseis.app.wear.data

import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL

/** Minimal HTTPS GET on the platform stack: 10 s timeouts, no cache, size cap, no cookies or ids. */
object Http {
    private const val TIMEOUT_MS = 10_000
    const val USER_AGENT = "Staseis-Watch/1.0 (wearos)"

    class Response(val code: Int, val etag: String?, val lastModified: String?, val conn: HttpURLConnection)

    /** Opens the connection; the caller reads [Response.conn] and must disconnect it. */
    fun open(url: String, etag: String? = null, lastModified: String? = null): Response {
        require(url.startsWith("https://")) { "HTTPS only" }
        val c = URL(url).openConnection() as HttpURLConnection
        c.connectTimeout = TIMEOUT_MS
        c.readTimeout = TIMEOUT_MS
        c.useCaches = false
        c.instanceFollowRedirects = false
        c.setRequestProperty("User-Agent", USER_AGENT)
        c.setRequestProperty("Accept", "application/json")
        etag?.let { c.setRequestProperty("If-None-Match", it) }
        lastModified?.let { c.setRequestProperty("If-Modified-Since", it) }
        val code = c.responseCode
        return Response(code, c.getHeaderField("ETag"), c.getHeaderField("Last-Modified"), c)
    }

    /** GET a small JSON body (UTF-8), at most [maxBytes]. Throws on non-200 or a bigger body. */
    fun getString(url: String, maxBytes: Int): String {
        val r = open(url)
        try {
            if (r.code != 200) throw IOException("HTTP ${r.code}")
            return r.conn.inputStream.use { readCapped(it, maxBytes) }.toString(Charsets.UTF_8)
        } finally {
            r.conn.disconnect()
        }
    }

    fun readCapped(input: InputStream, maxBytes: Int): ByteArray {
        val out = ByteArrayOutputStream()
        val buf = ByteArray(8192)
        while (true) {
            val n = input.read(buf)
            if (n < 0) break
            if (out.size() + n > maxBytes) throw IOException("body too large")
            out.write(buf, 0, n)
        }
        return out.toByteArray()
    }

    /** Wraps a stream so reading past [max] bytes throws. */
    class CappedInputStream(private val inner: InputStream, private val max: Long) : InputStream() {
        private var count = 0L
        override fun read(): Int {
            val b = inner.read()
            if (b >= 0 && ++count > max) throw IOException("body too large")
            return b
        }
        override fun read(b: ByteArray, off: Int, len: Int): Int {
            val n = inner.read(b, off, len)
            if (n > 0) {
                count += n
                if (count > max) throw IOException("body too large")
            }
            return n
        }
        override fun close() = inner.close()
    }
}
