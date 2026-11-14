# Πολιτική απορρήτου · Στάσεις

> Η σελίδα που ανοίγει η εφαρμογή (Μενού → Απόρρητο) είναι η https://staseis.gr/privacy/
> (`athens-transit-map/public/privacy/index.html`). Κράτα τις δύο ίδιες.

Ισχύει από: 14 Νοεμβρίου 2026 · Τελευταία αλλαγή: 14 Νοεμβρίου 2026 · Επικοινωνία: angelos.papamichail@gmail.com

Αυτή η πολιτική αφορά την εφαρμογή «Στάσεις: Live Συγκοινωνίες» (Staseis: Live Transit, `gr.staseis.app`, Android και iOS) και τον χάρτη στο staseis.gr.

**Ανεπίσημη εφαρμογή.** Οι Στάσεις δεν έχουν σχέση με τον ΟΑΣΑ, τον ΟΑΣΘ, την ΟΣΥ, τη ΣΤΑΣΥ, την Hellenic Train ή άλλον φορέα, και δεν τους εκπροσωπούν.

## Ποιοι είμαστε

Οι Στάσεις είναι έργο δύο ιδιωτών, όχι εταιρείας:

- **Άγγελος Παπαμιχαήλ** (Angelos Papamichail): ανάπτυξη της εφαρμογής, διακομιστές και αναφορές.
- **Antonios Freris**: έκδοση της εφαρμογής στο App Store και στο Google Play (στο Google Play με όνομα προγραμματιστή «frerisdev»).

Είναι **από κοινού υπεύθυνοι επεξεργασίας** (άρθρο 26 ΓΚΠΔ) για τα δεδομένα που περιγράφει αυτή η πολιτική. Μπορείς να ασκήσεις τα δικαιώματά σου απέναντι σε οποιονδήποτε από τους δύο, γράφοντας στο angelos.papamichail@gmail.com.

## Τι δεν συλλέγουμε

- Δεν έχουμε λογαριασμούς. Δεν ζητάμε όνομα, email ή τηλέφωνο.
- Η εφαρμογή δεν έχει διαφημίσεις, analytics ή tracking.
- Η ακριβής θέση σου **δεν φεύγει από το κινητό**. Η εφαρμογή τη χρησιμοποιεί για τις κοντινές στάσεις, την απόσταση ως τη στάση σου και τις ειδοποιήσεις. Δεν τη στέλνει σε κανέναν διακομιστή.
- Τα αγαπημένα, τα μέρη (π.χ. «Σπίτι», «Δουλειά») και οι ειδοποιήσεις σου μένουν μόνο στο κινητό.

## Τι φεύγει από το κινητό

- **Αιτήματα για δεδομένα συγκοινωνιών** (γραμμές, στάσεις, αφίξεις, στατιστικά) προς τους διακομιστές μας (`transit.haroldpoi.dev`, `transit-thess.haroldpoi.dev`, `bus.haroldpoi.dev`, `staseis.gr`), προς το GitHub, όπου είναι τα στατικά αρχεία (`angelospk.github.io`, `raw.githubusercontent.com`), και προς την Hellenic Train (`railway.gov.gr`). Δεν περιέχουν στοιχεία σου ούτε την ακριβή θέση σου, αλλά δείχνουν ποια περιοχή του χάρτη κοιτάς: τα λεωφορεία έρχονται σε πλακίδια περίπου 5 × 5 χλμ., όπως και ο ίδιος ο χάρτης, και η περιοχή αυτή συχνά είναι γύρω σου. Κάθε διακομιστής που λαμβάνει ένα αίτημα βλέπει τη διεύθυνση IP σου. Οι διακομιστές μας κρατούν τεχνικά logs (διεύθυνση IP, ώρα, αίτημα) για ασφάλεια και διάγνωση σφαλμάτων.
- **Το κείμενο της αναζήτησης διευθύνσεων** πηγαίνει στο Photon (`photon.komoot.io`, δεδομένα OpenStreetMap), για να βρεθεί η διεύθυνση. Η θέση σου δεν στέλνεται.
- **Ο χάρτης** φορτώνει από το OpenFreeMap (`tiles.openfreemap.org`) πλακίδια για την περιοχή που βλέπεις.
- **Οι οδηγίες περπατήματος** ως μια στάση ανοίγουν την εφαρμογή χαρτών του κινητού (Google Maps ή Apple Maps) με τη θέση της στάσης. Μετά ισχύει η πολιτική της εφαρμογής χαρτών.

## «Λάθος θέση στάσης;»

Στην εφαρμογή και στο web, μόνο αν πατήσεις «Λάθος θέση στάσης;» και στείλεις, φεύγουν: το σημείο του χάρτη όπου έβαλες την πινέζα (όχι η θέση σου), η στάση, ένας τυχαίος κωδικός και η έκδοση της εφαρμογής και του λειτουργικού (στο web, του browser και το μέγεθος του παραθύρου). Ο τυχαίος κωδικός (12 χαρακτήρες) δημιουργείται την πρώτη φορά που στέλνεις αναφορά. Δεν είναι το αναγνωριστικό της συσκευής ή διαφήμισης, και χρησιμεύει μόνο για να μετράμε μία φορά τις αναφορές ενός κινητού. Η αναφορά πηγαίνει σε ένα φύλλο Google (μέσω Google Apps Script), όπου τη διαβάζουμε για να διορθώσουμε τη θέση της στάσης.

## Ο χάρτης στο web

Το staseis.gr μετράει επισκέψεις με το Cloudflare Web Analytics. Δεν βάζει cookies και δεν σε ακολουθεί σε άλλα sites. Βλέπουμε μόνο συνολικούς αριθμούς (π.χ. πόσες επισκέψεις είχε μια σελίδα). Τα αγαπημένα του χάρτη μένουν στον browser σου.

Μια λειτουργία του web στέλνει δεδομένα, και μόνο όταν τη χρησιμοποιήσεις:

- **Ειδοποίηση στον browser**: η διεύθυνση push του browser σου και η στάση, η γραμμή και το λεωφορείο της ειδοποίησης πηγαίνουν στο `push.haroldpoi.dev`. Σβήνονται όταν τελειώσει η ειδοποίηση ή όταν την ακυρώσεις.

## Το bot στο Telegram

Αν το χρησιμοποιείς, το bot κρατά το αναγνωριστικό της συζήτησης, τις ειδοποιήσεις και τις στάσεις που αποθηκεύεις εκεί. Το `/stop` σβήνει τις ειδοποιήσεις. Αν μπλοκάρεις το bot, σβήνονται όλα.

## Γιατί και πόσο τα κρατάμε

- **Logs των διακομιστών μας**: για την ασφάλεια και τη λειτουργία της υπηρεσίας (έννομο συμφέρον, άρθρο 6 παρ. 1 στ ΓΚΠΔ). Σβήνονται αυτόματα μετά από **14 ημέρες**.
- **Αναφορές «Λάθος θέση στάσης;»**: για να διορθώνουμε τις στάσεις (έννομο συμφέρον). Τις κρατάμε ώσπου να διορθωθεί η στάση και το πολύ **12 μήνες**. Μετά σβήνονται.
- **Αναζήτηση διευθύνσεων, ειδοποίηση στον browser, bot στο Telegram**: για να σου δώσουμε τη λειτουργία που ζητάς (άρθρο 6 παρ. 1 β ΓΚΠΔ), για όσο χρόνο γράφει παραπάνω.
- **Μετρήσεις επισκέψεων του web**: μόνο συνολικοί αριθμοί, για να ξέρουμε ποιες σελίδες χρησιμοποιούνται (έννομο συμφέρον).
- **Τα δεδομένα στο κινητό σου** (αγαπημένα, μέρη, ειδοποιήσεις, ο τυχαίος κωδικός) μένουν εκεί ώσπου να τα σβήσεις.

## Ποιοι άλλοι τα βλέπουν

Δεν πουλάμε και δεν δίνουμε δεδομένα για διαφημίσεις. Τα δεδομένα περνούν μόνο από όσους χρειάζονται για να δουλέψει η υπηρεσία: τον πάροχο φιλοξενίας των διακομιστών μας, την Cloudflare (staseis.gr), το GitHub (στατικά αρχεία), την Google (φύλλο αναφορών), το Photon της komoot (αναζήτηση), το OpenFreeMap (χάρτης), την Hellenic Train (δρομολόγια τρένων) και το Telegram (αν χρησιμοποιείς το bot). Ο καθένας βλέπει τη διεύθυνση IP σου όταν του στέλνει αίτημα το κινητό σου, και έχει τη δική του πολιτική απορρήτου.

Η Google, το GitHub και η Cloudflare μπορεί να επεξεργάζονται δεδομένα εκτός ΕΕ (π.χ. στις ΗΠΑ), με τις εγγυήσεις που προβλέπει ο ΓΚΠΔ (π.χ. EU-US Data Privacy Framework ή τυποποιημένες συμβατικές ρήτρες).

## Διαγραφή δεδομένων

1. **Στο κινητό**: Ρυθμίσεις → «Διαγραφή όλων των δεδομένων». Σβήνει τα αγαπημένα, τα μέρη, τις ειδοποιήσεις και τον τυχαίο κωδικό. Το ίδιο γίνεται αν απεγκαταστήσεις την εφαρμογή.
2. **Αναφορές «Λάθος θέση στάσης;»**: γράψε στο angelos.papamichail@gmail.com τη στάση και περίπου πότε έστειλες την αναφορά. Τη σβήνουμε μέσα σε 30 ημέρες και σου απαντάμε. Αν έχεις ήδη πατήσει «Διαγραφή όλων», δεν μπορούμε να ξέρουμε ποιες αναφορές ήταν δικές σου χωρίς αυτά τα στοιχεία.
3. **Logs των διακομιστών**: σβήνονται μόνα τους μετά από 14 ημέρες.

Δεν υπάρχει λογαριασμός να διαγραφεί.

## Τα δικαιώματά σου

Έχεις δικαίωμα πρόσβασης, διόρθωσης, διαγραφής, περιορισμού και αντίρρησης στην επεξεργασία. Γράψε μας στο angelos.papamichail@gmail.com. Μπορείς επίσης να κάνεις καταγγελία στην Αρχή Προστασίας Δεδομένων Προσωπικού Χαρακτήρα (www.dpa.gr).

## Άδειες της εφαρμογής

- **Τοποθεσία**: μόνο αν τη δώσεις. Χωρίς αυτή η εφαρμογή δουλεύει, αλλά χωρίς τις κοντινές στάσεις και τις ειδοποιήσεις που χρειάζονται τη θέση.
- **Ειδοποιήσεις**: για τις ειδοποιήσεις που ορίζεις εσύ.
- **Ακριβή ξυπνητήρια (Android)**: για να ξεκινούν οι εβδομαδιαίοι κανόνες στην ώρα τους.

## Παιδιά

Η εφαρμογή δεν απευθύνεται σε παιδιά κάτω των 13 ετών και δεν συλλέγει εν γνώσει της δεδομένα τους. Δεν συλλέγει δεδομένα από κανέναν, εκτός από όσα περιγράφονται παραπάνω.

## Αλλαγές

Αν αλλάξει αυτή η πολιτική, αλλάζει και η ημερομηνία στην αρχή.

---

# Privacy policy · Στάσεις

Effective: 14 November 2026 · Last updated: 14 November 2026 · Contact: angelos.papamichail@gmail.com

This policy covers the app "Staseis: Live Transit" (Στάσεις: Live Συγκοινωνίες, `gr.staseis.app`, Android and iOS) and the map at staseis.gr.

**Unofficial app.** Staseis is not affiliated with, endorsed by or acting for OASA, OASTH, OSY, STASY, Hellenic Train or any other operator.

## Who we are

Staseis is a project of two individuals, not a company: **Angelos Papamichail** (Άγγελος Παπαμιχαήλ), who develops the app and runs the servers and reports, and **Antonios Freris**, who publishes the app on the App Store and Google Play (on Google Play under the developer name "frerisdev"). They are **joint controllers** (GDPR Art. 26) of the data described here. You can exercise your rights against either of them at angelos.papamichail@gmail.com.

## What we do not collect

- No accounts. We never ask for your name, email or phone number.
- The app has no ads, no analytics and no tracking.
- Your exact location **stays on your phone**. It is used for nearby stops, the distance to your stop and alerts, and is never sent to any server.
- Favourites, places (e.g. "Home", "Work") and alerts are stored only on your phone.

## What leaves your phone

- **Transit data requests** (lines, stops, arrivals, statistics) to our servers (`transit.haroldpoi.dev`, `transit-thess.haroldpoi.dev`, `bus.haroldpoi.dev`, `staseis.gr`), to GitHub, which hosts the static files (`angelospk.github.io`, `raw.githubusercontent.com`), and to Hellenic Train (`railway.gov.gr`). They carry no personal data and not your exact location, but they show which area of the map you look at: buses load in tiles of about 5 × 5 km, like the map itself, and that area is often around you. Every server that receives a request sees your IP address. Our servers keep technical logs (IP address, time, request) for security and debugging.
- **Address search text** goes to Photon (`photon.komoot.io`, OpenStreetMap data), without your location.
- **Map tiles** for the area you view load from OpenFreeMap (`tiles.openfreemap.org`).
- **Walking directions** to a stop open your phone's map app (Google Maps or Apple Maps) with the stop's position. After that, the map app's privacy policy applies.
- **"Wrong stop position?"** (app and website), only if you send it: the map point where you placed the pin (not your location), the stop, a random code and the app and OS version (on the website, the browser and window size). The random 12-character code is created the first time you send a report. It is not the device or advertising ID, and only lets us count one phone's reports once. Reports go to a Google Sheet (via Google Apps Script), which we read to correct stop positions.
- **Website**: visits are counted with Cloudflare Web Analytics (no cookies, no cross-site tracking, totals only). A browser alert sends your browser's push address and the alert's stop, line and bus to `push.haroldpoi.dev`; they are deleted when the alert ends or you cancel it.
- **Telegram bot**, if you use it: it keeps the chat id and the alerts and stops you save there. `/stop` deletes the alerts; blocking the bot deletes everything.

## Why, and for how long

- **Server logs**: security and operation of the service (legitimate interest, GDPR Art. 6(1)(f)). Deleted automatically after **14 days**.
- **"Wrong stop position?" reports**: to correct stops (legitimate interest). Kept until the stop is corrected and at most **12 months**, then deleted.
- **Address search, browser alerts, Telegram bot**: to provide the feature you ask for (Art. 6(1)(b)), for as long as stated above.
- **Website visit counts**: totals only, to see which pages are used (legitimate interest).
- **Data on your phone** (favourites, places, alerts, the random code) stays there until you delete it.

## Who else sees it

We do not sell data or share it for advertising. Data only passes through the services the app needs: our server hosting provider, Cloudflare (staseis.gr), GitHub (static files), Google (the report sheet), komoot's Photon (search), OpenFreeMap (map), Hellenic Train (train times) and Telegram (if you use the bot). Each one sees your IP address when your phone sends it a request, and has its own privacy policy. Google, GitHub and Cloudflare may process data outside the EU (e.g. in the US) under the safeguards the GDPR provides (e.g. the EU-US Data Privacy Framework or standard contractual clauses).

## Deleting your data

1. **On your phone**: Settings → «Διαγραφή όλων των δεδομένων» (Delete all data). It removes favourites, places, alerts and the random code. Uninstalling the app does the same.
2. **"Wrong stop position?" reports**: email angelos.papamichail@gmail.com with the stop and roughly when you sent it. We delete it within 30 days and reply. After "Delete all data" we cannot tell which reports were yours without these details.
3. **Server logs** delete themselves after 14 days.

There is no account to delete.

## Your rights

You have the right to access, rectify, erase and restrict your data, and to object to its processing. Email angelos.papamichail@gmail.com. You can also complain to the Hellenic Data Protection Authority (www.dpa.gr).

## App permissions

- **Location**: only if you allow it. Without it the app works, but without nearby stops and location-based alerts.
- **Notifications**: for the alerts you set.
- **Exact alarms (Android)**: so weekly rules start on time.

## Children

The app is not directed at children under 13 and does not knowingly collect their data. It collects no data from anyone beyond what is described above.

## Changes

If this policy changes, so does the date at the top.
