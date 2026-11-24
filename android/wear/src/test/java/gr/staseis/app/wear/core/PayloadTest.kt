package gr.staseis.app.wear.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class PayloadTest {
    private val good = """{"v":1,"city":"athens","favs":[{"id":"340098","name":"ΠΑΠΑΣΠΥΡΟΥ","lines":["040","137"]}]}"""

    @Test fun good() {
        val p = Payload.parse(good)!!
        assertEquals(City.ATHENS, p.city)
        assertEquals(listOf(Fav("340098", "ΠΑΠΑΣΠΥΡΟΥ", listOf("040", "137"))), p.favs)
    }

    @Test fun thessalonikiAndGreekLines() {
        val p = Payload.parse("""{"v":1,"city":"thessaloniki","favs":[{"id":"a_1-B","name":"Χ","lines":["Χ1","31Α","ά"]}]}""")
        assertEquals(City.THESSALONIKI, p!!.city)
        assertEquals(listOf("Χ1", "31Α", "ά"), p.favs[0].lines)
    }

    @Test fun roundTrip() {
        val p = Payload.parse(good)!!
        assertEquals(p, Payload.parse(Payload.encode(p)))
    }

    @Test fun emptyFavsIsValid() {
        assertEquals(0, Payload.parse("""{"v":1,"city":"athens","favs":[]}""")!!.favs.size)
    }

    @Test fun badVersion() {
        assertNull(Payload.parse(good.replace("\"v\":1", "\"v\":2")))
        assertNull(Payload.parse(good.replace("\"v\":1", "\"v\":\"1\"")))
        assertNull(Payload.parse(good.replace("\"v\":1,", "")))
    }

    @Test fun badId() {
        listOf("", "34 0098", "../etc", "12345678901234567", "a/b", "ΑΒΓ").forEach { id ->
            assertNull(id, Payload.parse(good.replace("340098", id)))
        }
        assertNull(Payload.parse("""{"v":1,"city":"athens","favs":[{"id":340098}]}"""))
    }

    @Test fun badLinesAndName() {
        assertNull(Payload.parse(good.replace("\"137\"", "\"123456789\"")))
        assertNull(Payload.parse(good.replace("\"137\"", "\"1 3\"")))
        assertNull(Payload.parse(good.replace("\"137\"", "137")))
        val thirteen = (1..13).joinToString(",") { "\"$it\"" }
        assertNull(Payload.parse(good.replace("[\"040\",\"137\"]", "[$thirteen]")))
        assertNull(Payload.parse(good.replace("ΠΑΠΑΣΠΥΡΟΥ", "x".repeat(81))))
        assertNotNull(Payload.parse(good.replace("ΠΑΠΑΣΠΥΡΟΥ", "x".repeat(80))))
    }

    @Test fun controlCharactersInNamesRejected() {
        listOf("\\u0000", "\\n", "\\t", "\\u001b[31m", "\\u007f").forEach { c ->
            assertNull(c, Payload.parse(good.replace("ΠΑΠΑΣΠΥΡΟΥ", "ΠΑΠΑ${c}ΣΠΥΡΟΥ")))
        }
    }

    @Test fun tooManyFavs() {
        fun favs(n: Int) = (1..n).joinToString(",") { """{"id":"$it","name":"s","lines":[]}""" }
        assertEquals(20, Payload.parse("""{"v":1,"city":"athens","favs":[${favs(20)}]}""")!!.favs.size)
        assertNull(Payload.parse("""{"v":1,"city":"athens","favs":[${favs(21)}]}"""))
    }

    @Test fun unknownCity() {
        assertNull(Payload.parse(good.replace("athens", "patras")))
        assertNull(Payload.parse(good.replace("\"athens\"", "\"https://evil.example\"")))
        assertNull(Payload.parse(good.replace("\"city\":\"athens\",", "")))
    }

    @Test fun extraKeysIgnored() {
        val p = Payload.parse(
            """{"v":1,"city":"athens","home":{"lat":1},"favs":[{"id":"340098","name":"Α","lines":[],"color":"red"}],"x":[1,2]}""",
        )
        assertEquals(listOf(Fav("340098", "Α", emptyList())), p!!.favs)
    }

    @Test fun malformed() {
        listOf(null, "", "{", "[]", "null", """{"v":1,"city":"athens","favs":{}}""", """{"v":1,"city":"athens","favs":[1]}""")
            .forEach { assertNull(it, Payload.parse(it)) }
    }

    @Test fun duplicateIdsKeptOnce() {
        val p = Payload.parse("""{"v":1,"city":"athens","favs":[{"id":"1","name":"a"},{"id":"1","name":"b"}]}""")
        assertEquals(1, p!!.favs.size)
    }
}
