package gr.staseis.app.wear.shots

import gr.staseis.app.wear.core.Arrival
import gr.staseis.app.wear.core.City
import gr.staseis.app.wear.core.IndexStop
import gr.staseis.app.wear.core.NearStop
import gr.staseis.app.wear.ui.FavRow

/** Real-looking demo data: long names and headsigns, 8 arrivals, amber and red late badges. */
object Demo {
    const val NOW = 1_795_540_000L // fixed clock (Europe/Athens in the tests)

    const val LONG_STOP = "ΠΛΑΤΕΙΑ ΚΑΡΑΪΣΚΑΚΗ (ΣΤΑΘΜΟΣ ΗΣΑΠ ΠΕΙΡΑΙΑ)"

    val arrivals = listOf(
        Arrival("1", "ΠΕΙΡΑΙΑΣ - ΣΥΝΤΑΓΜΑ (ΜΕΣΩ ΣΥΓΓΡΟΥ)", NOW + 20, null),
        Arrival("022", "ΚΑΝΙΓΓΟΣ - ΝΕΑ ΚΥΨΕΛΗ - ΚΟΛΩΝΑΚΙ", NOW + 120, 400),
        Arrival("025", "ΠΡΟΦΗΤΗΣ ΔΑΝΙΗΛ - ΠΛ. ΚΑΝΙΓΓΟΣ", NOW + 240, 2640),
        Arrival("040", "ΠΕΙΡΑΙΑΣ - ΣΥΝΤΑΓΜΑ", NOW + 420, -90),
        Arrival("137", "ΑΓ. ΙΩΑΝΝΗΣ ΡΕΝΤΗΣ - ΣΤ. ΜΕΤΡΟ ΚΑΛΛΙΘΕΑ", NOW + 600, 120),
        Arrival("550", "Π. ΦΑΛΗΡΟ - ΚΗΦΙΣΙΑ (ΜΕΣΩ ΜΕΣΟΓΕΙΩΝ ΚΑΙ ΚΗΦΙΣΙΑΣ)", NOW + 840, 700),
        Arrival("Χ95", "ΣΥΝΤΑΓΜΑ - ΑΕΡΟΛΙΜΕΝΑΣ (EXPRESS)", NOW + 1260, null),
        Arrival("Α2", "ΑΚΑΔΗΜΙΑ - ΑΝΩ ΓΛΥΦΑΔΑ", NOW + 1980, 310),
    )

    val favRows = listOf(
        FavRow(LONG_STOP, "1 τώρα · 022 2′"),
        FavRow("ΠΑΠΑΣΠΥΡΟΥ", "040 3′ · 137 12′"),
        FavRow("ΣΥΝΤΑΓΜΑ", "Χ95 21′ · 550 33′"),
        FavRow("ΑΓ. ΙΩΑΝΝΗΣ ΡΕΝΤΗΣ - ΣΤ. ΜΕΤΡΟ ΚΑΛΛΙΘΕΑ", "…"),
        FavRow("ΚΑΝΙΓΓΟΣ", "—"),
    )

    val nearby = listOf(
        NearStop(IndexStop("1001", "ΣΥΝΤΑΓΜΑ", 0.0, 0.0, listOf("1", "2", "4", "11", "040", "137", "Α2")), 70),
        NearStop(IndexStop("1002", "ΣΥΝΤΑΓΜΑ", 0.0, 0.0, listOf("2", "550")), 120),
        NearStop(IndexStop("1003", "ΣΥΝΤΑΓΜΑ", 0.0, 0.0, listOf("Χ95")), 160),
        NearStop(IndexStop("1004", "ΠΛΑΤΕΙΑ ΣΥΝΤΑΓΜΑΤΟΣ (ΒΟΥΛΗ ΤΩΝ ΕΛΛΗΝΩΝ)", 0.0, 0.0, emptyList()), 410),
        NearStop(IndexStop("1005", "ΜΗΤΡΟΠΟΛΕΩΣ", 0.0, 0.0, listOf("025", "026", "027", "035", "040", "049")), 980),
    )
    val city = City.ATHENS
}
