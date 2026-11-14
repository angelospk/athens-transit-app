# Πριν τη δημοσίευση · τι μένει

Έλεγχος 2026-11-14 (ονόματα, GDPR, σχέση με τους φορείς). Δεν είναι νομική συμβουλή. Οι αλλαγές σε κώδικα και
κείμενα είναι σε αυτό το PR και στο PR του `athens-transit-map` (σελίδες privacy, terms, support).

## Έγινε σε αυτό το PR

- **Λογότυπο ΟΑΣΑ**: βγήκε (`assets/icons/oasa.png`). Τα chips των γραμμών της Αθήνας είναι πλέον απλά (ο
  αριθμός στο χρώμα της γραμμής), όπως στη Θεσσαλονίκη (2026-11-14, `lib/ui/widgets.dart`). Λόγος: Play Impersonation policy
  («copying the logo of a business entity»), App Store 5.2.1 και 4.1.
- **Αποποίηση μέσα στην εφαρμογή**: «Ανεπίσημη εφαρμογή. Δεν έχει σχέση με τον ΟΑΣΑ, τον ΟΑΣΘ, τη ΣΤΑΣΥ ή την
  Hellenic Train…» στο Σχετικά και στην τελευταία σελίδα του welcome (`unofficialNote`, `lib/ui/menu.dart`).
- **Πηγές και άδειες** στο Σχετικά: ΟΑΣΑ (GTFS CC BY-NC, telematics), ΟΑΣΘ (data.gov.gr), ΣΤΑΣΥ (GTFS),
  Hellenic Train, OpenFreeMap/OSM, Photon. Copyright: «© 2026 Άγγελος Παπαμιχαήλ & Antonios Freris».
- **Welcome**: ο τίτλος «Δεν κρατάμε τίποτα από σένα» έγινε «Χωρίς λογαριασμό, διαφημίσεις ή tracking»,
  γιατί η αναφορά «Λάθος θέση;» και τα logs των διακομιστών είναι δεδομένα.
- **Πολιτική απορρήτου** (`privacy-policy.md`, ίδια με το `staseis.gr/privacy/`): από κοινού υπεύθυνοι
  επεξεργασίας (άρθρο 26 ΓΚΠΔ) ο Άγγελος Παπαμιχαήλ και ο Antonios Freris (εκδότης στα stores, «frerisdev»
  στο Play), email επικοινωνίας, νομική βάση και χρόνος διατήρησης ανά σκοπό, αποδέκτες, διαβιβάσεις εκτός ΕΕ,
  δικαιώματα και ΑΠΔΠΧ, ενότητα διαγραφής (`#delete`, το link του Play Data safety), πλήρες αγγλικό κείμενο,
  παιδιά κάτω των 13.
- **Keywords App Store**: χωρίς «ΟΑΣΑ» / «oasa» (guideline 2.3.7).
- **Review notes**: Αθήνα και Θεσσαλονίκη, και οι πηγές με τις άδειές τους (για το 5.2.2).
- **Target audience Play**: 13-15, 16-17, 18+ (όχι κάτω των 13: κανόνες Families· το ESRB «Teen» το
  απαγορεύει ούτως ή άλλως).

## Πρέπει να γίνουν πριν την υποβολή

1. ~~Build και tests~~ — έγινε 2026-11-14 μετά το merge: `flutter analyze` και `flutter test` περνούν.
2. ~~Νέο `app-release.aab`~~ (και iOS unsigned build) χωρίς το λογότυπο — έγινε 2026-11-14 (0.3.0+9, δεν έχει
   ανέβει ακόμα πουθενά).
3. **Logs διακομιστών: 14 ημέρες.** Η πολιτική το υπόσχεται. Ισχύει για τα access logs (IP, ώρα, URL) των
   `transit.haroldpoi.dev`, `transit-thess.haroldpoi.dev`, `bus.haroldpoi.dev`, `push.haroldpoi.dev`
   (reverse proxy / web server / εφαρμογή). Ρύθμισε rotation με διαγραφή μετά τις 14 μέρες.
4. **Αναφορές «Λάθος θέση;»: το πολύ 12 μήνες** στο Google Sheet. Σβήσε (ή κράτα χωρίς τον τυχαίο κωδικό)
   ό,τι είναι παλιότερο. Αιτήματα διαγραφής: μέσα σε 30 μέρες.
5. ~~Deploy του staseis.gr~~ με τις νέες σελίδες privacy, terms, support — έγινε 2026-11-14 (web PR #80).
   Το Play Data safety δείχνει ήδη το `https://staseis.gr/privacy/#delete`.
6. ~~Λογότυπο ΟΑΣΑ και στο web~~ — βγήκε 2026-11-14 (web `7290cd9`): `src/lib/ui/LineChip.svelte`, `src/lib/ui/HelpPop.svelte`,
   `src/lib/map/mapIcons.ts`, `public/icons/oasa.png`. Το staseis.gr είναι το marketing URL των stores.
7. **Screenshots**: έλεγξε ότι κανένα δεν δείχνει το λογότυπο ΟΑΣΑ. Αν ναι, ξαναβγάλ' τα
   (`docs/store/screenshots/src/render.sh`) μετά το νέο build.
8. **Play Console**: store listing (κείμενα, εικονίδιο, feature graphic, screenshots), κατηγορία Maps &
   Navigation, δήλωση foreground service (μετά το πρώτο upload), content rating, closed test αν ισχύει,
   πρόσβαση του Άγγελου.
9. **App Store Connect**: app record, App Privacy (Search History, Other User Content, Device ID· όλα not
   linked, not tracking), keywords χωρίς ΟΑΣΑ, review notes, copyright «© 2026 Άγγελος Παπαμιχαήλ & Antonios
   Freris», build από Mac.

## Προαιρετικά (καλό να γίνουν)

- **Email σε ΟΑΣΑ και ΟΑΣΘ** για άδεια χρήσης των live δεδομένων, και κράτα την απάντηση. Δεν απαιτείται για
  τη δημοσίευση· είναι ασφάλεια αν η Apple ζητήσει απόδειξη (5.2.2) ή αν έρθει παράπονο. Οι όροι του
  telematics.oasa.gr λένε «για προσωπική χρήση». Το 2009 ο ΟΑΣΘ σταμάτησε ένα παλιό site με το ίδιο όνομα
  (staseis.gr) από τα live δεδομένα του
  ([Insomnia.gr, 28/12/2009](https://www.insomnia.gr/articles/various/internet/%CE%BF%CE%B1%CF%83%CE%B8-%CE%B1%CF%80%CE%B1%CE%B3%CF%8C%CF%81%CE%B5%CF%85%CF%83%CE%B7-%CF%87%CF%81%CE%AE%CF%83%CE%B7%CF%82-%CE%B4%CE%B5%CE%B4%CE%BF%CE%BC%CE%AD%CE%BD%CF%89%CE%BD-%CF%84%CE%BF%CF%85-%CE%B1%CF%80%CF%8C-%CE%B9%CF%83%CF%84%CE%BF%CF%83%CE%B5%CE%BB%CE%AF%CE%B4%CE%B1-r1621/)).
  Σήμερα το GTFS του ΟΑΣΘ είναι ανοιχτό στο data.gov.gr.
- **Συμφωνία Άγγελου–Αντώνη** (μία σελίδα): από κοινού υπεύθυνοι, ποιος κρατά τι (λογαριασμοί, κώδικας,
  διακομιστές, domain), τι γίνεται αν χωρίσουν. Καλό ένα κοίταγμα από Έλληνα δικηγόρο.
- **Διαβιβάσεις εκτός ΕΕ**: Cloudflare (όλα τα domains), Google (Apps Script) και GitHub (Fastly) είναι
  αμερικανικές εταιρείες. Η πολιτική το λέει με «μπορεί». Αν θέλετε να το βγάλετε, χρειάζεται αλλαγή
  υποδομής (π.χ. αναφορές σε δικό σας διακομιστή στην ΕΕ), όχι μόνο κειμένου.

## Στατιστικά (`/athens` → ⓘ → Στατιστικά): δεν αλλάζουν

Είναι συγκεντρωτικά δεδομένα οχημάτων (θέσεις GPS λεωφορείων, ταχύτητες, εκτελεσμένα δρομολόγια), όχι δεδομένα
χρηστών. Δεν μπαίνουν στην πολιτική απορρήτου ούτε στο Data safety, και δεν χρειάζονται όριο διατήρησης. Το
όριο των 14 ημερών αφορά μόνο τα logs με διευθύνσεις IP των χρηστών.
