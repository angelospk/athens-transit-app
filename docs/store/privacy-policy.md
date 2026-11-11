# Πολιτική απορρήτου · Στάσεις

> Η σελίδα που ανοίγει η εφαρμογή (Μενού → Απόρρητο) είναι η https://staseis.gr/privacy/
> (`athens-transit-map/public/privacy/index.html`). Κράτα τις δύο ίδιες.

Τελευταία αλλαγή: 11 Νοεμβρίου 2026
Εκδότης: Άγγελος Παπαμιχαήλ · Επικοινωνία: GitHub issues (https://github.com/angelospk/athens-transit-app/issues)

Οι Στάσεις (staseis.gr) είναι ανεπίσημη εφαρμογή. Δεν έχει σχέση με τον ΟΑΣΑ, τη ΣΤΑΣΥ ή την Hellenic Train.

## Τι δεν συλλέγουμε

- Δεν έχουμε λογαριασμούς χρηστών. Δεν ζητάμε όνομα, email ή τηλέφωνο.
- Δεν έχουμε διαφημίσεις, analytics ή tracking.
- Η ακριβής θέση σου **δεν φεύγει από το κινητό**. Η εφαρμογή τη χρησιμοποιεί για τις κοντινές
  στάσεις, την απόσταση από τη στάση σου, το «Φύγε εγκαίρως», το «Πού κατεβαίνω;» και το
  «Ακολούθησέ με». Δεν τη στέλνει σε κανέναν διακομιστή. (Ο χάρτης όμως ζητά την περιοχή που
  βλέπεις: δες παρακάτω.)
- Τα αγαπημένα, τα μέρη (π.χ. «Σπίτι») και οι ειδοποιήσεις σου μένουν μόνο στο κινητό. Αν σβήσεις την
  εφαρμογή, σβήνονται και αυτά.

## Τι φεύγει από το κινητό

- **Αιτήματα για δεδομένα συγκοινωνιών** (γραμμές, στάσεις, αφίξεις, στατιστικά) προς τους
  διακομιστές μας (`transit.haroldpoi.dev`, `transit-thess.haroldpoi.dev`, `bus.haroldpoi.dev`,
  `staseis.gr`), προς το GitHub, όπου βρίσκονται τα στατικά αρχεία (`angelospk.github.io`,
  `raw.githubusercontent.com`), και προς την Hellenic Train (`railway.gov.gr`). Τα αιτήματα δεν
  περιέχουν στοιχεία σου ούτε την ακριβή θέση σου. Τα λεωφορεία στον χάρτη έρχονται σε πλακίδια
  περίπου 5 × 5 χλμ., όπως και ο χάρτης. Έτσι ο διακομιστής βλέπει ποια περιοχή κοιτάς, που
  συχνά είναι κοντά σου. Οι διακομιστές μπορεί να κρατούν για λίγες μέρες τεχνικά logs
  (διεύθυνση IP, ώρα, αίτημα) για ασφάλεια και διάγνωση σφαλμάτων.
- **Αναφορά «Λάθος θέση;»**: μόνο αν την στείλεις εσύ. Περιέχει τη στάση, το σημείο που έδειξες
  στον χάρτη (πού είναι η στάση, όχι πού είσαι εσύ), έναν τυχαίο κωδικό της εφαρμογής, την έκδοση
  της εφαρμογής και του λειτουργικού. Ο τυχαίος κωδικός μετρά τις αναφορές ενός κινητού μία φορά.
  Δεν σχετίζεται με το όνομά σου ή με άλλον κωδικό της συσκευής, και σβήνεται με το «Διαγραφή
  όλων». Η αναφορά πηγαίνει σε φύλλο Google (Google Apps Script) που διαβάζουμε για να διορθώνουμε
  τις στάσεις. Για να σβήσουμε τις αναφορές σου, γράψε μας (στοιχεία επικοινωνίας στην αρχή).
- **Το κείμενο της αναζήτησης διευθύνσεων** στέλνεται στο Photon (`photon.komoot.io`, δεδομένα
  OpenStreetMap) για να βρεθεί η διεύθυνση. Δεν στέλνεται η θέση σου.
- **Ο χάρτης** φορτώνει πλακίδια από το OpenFreeMap (`tiles.openfreemap.org`) για την περιοχή που
  βλέπεις.
- **Οδηγίες περπατήματος** ως μια στάση ανοίγουν την εφαρμογή χαρτών του κινητού (Google Maps ή
  Apple Maps) με τη θέση της στάσης. Από εκεί και πέρα ισχύει η πολιτική εκείνης της εφαρμογής.

Οι τρίτοι αυτοί έχουν τις δικές τους πολιτικές απορρήτου.

## Άδειες της εφαρμογής

- **Τοποθεσία**: μόνο όταν τη δώσεις. Χωρίς αυτή, η εφαρμογή δουλεύει, αλλά χωρίς τις κοντινές στάσεις
  και τις ειδοποιήσεις που βασίζονται στη θέση.
- **Ειδοποιήσεις**: για τις ειδοποιήσεις που ορίζεις εσύ (λεωφορείο που έρχεται, τελευταίο λεωφορείο).
- **Ακριβείς υπενθυμίσεις (Android)**: για να ξεκινούν οι εβδομαδιαίοι κανόνες στην ώρα τους.

## Παιδιά

Η εφαρμογή δεν απευθύνεται ειδικά σε παιδιά. Δεν συλλέγει δεδομένα, εκτός από την αναφορά «Λάθος
θέση;» που στέλνει ο χρήστης.

## Αλλαγές

Αν αλλάξει αυτή η πολιτική, θα αλλάξει και η ημερομηνία στην αρχή.

---

# Privacy policy · Staseis

Last updated: 11 November 2026 · Publisher: Άγγελος Παπαμιχαήλ · Contact: GitHub issues (https://github.com/angelospk/athens-transit-app/issues)

Staseis (staseis.gr) is an unofficial app, not affiliated with OASA, STASY or Hellenic Train.

- No accounts, no ads, no analytics, no tracking.
- Your exact location **stays on your phone**. It is used for nearby stops, distance to your stop and
  location-based alerts, and is never sent to any server.
- Favourites, places and alerts are stored only on your phone.
- The app requests transit data (lines, stops, arrivals, statistics) from our servers
  (`transit.haroldpoi.dev`, `transit-thess.haroldpoi.dev`, `bus.haroldpoi.dev`, `staseis.gr`), from
  GitHub, which hosts the static files (`angelospk.github.io`, `raw.githubusercontent.com`), and from
  Hellenic Train (`railway.gov.gr`). These requests carry no personal data and no exact location. Buses
  on the map, like the map itself, load in tiles of about 5 × 5 km, so the server sees the area you
  view, which is often near you. Servers may keep short-lived technical logs (IP address, time,
  request) for security.
- "Wrong stop position?" reports are sent only when you send one. A report holds the stop, the point you
  marked on the map (where the stop is, not where you are), a random app ID, and the app and OS
  versions. The random ID counts one phone's reports once. It is not linked to your name or to any
  device identifier, and "Delete all" clears it. Reports go to a Google Sheet (Google Apps Script) that
  we read to fix stop positions. Contact us (see the top) to have yours deleted.
- Address search text is sent to Photon (`photon.komoot.io`, OpenStreetMap data), without your location.
- Map tiles for the area you view load from OpenFreeMap (`tiles.openfreemap.org`).
- Walking directions to a stop open your phone's map app (Google Maps or Apple Maps) with the stop's
  position; that app's own policy applies from there.
