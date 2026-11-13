# Στάσεις · Πακέτο για τα stores (για τον φίλο που ανεβάζει)

Ενημερώθηκε 2026-11-14 · έκδοση 0.3.0+9 · bundle ID / applicationId `gr.staseis.app` (και στα δύο stores)

Όλα τα αρχεία είναι στο δημόσιο repo. Βάση για τα links:
`https://github.com/angelospk/athens-transit-app/blob/main/`. Στον πίνακα το βάζω ως `repo:`.

## 1. Στοιχεία επικοινωνίας: τι να βάλεις

Συμπληρώνει ο Άγγελος τα `<...>` **πριν** το στείλει.

| Πεδίο | Τιμή | Πού |
|---|---|---|
| Όνομα εφαρμογής | Στάσεις | Play + App Store |
| Website | https://staseis.gr | Play (Website), App Store (Marketing URL) |
| Support URL | `<https://staseis.gr/support>` (ΔΕΝ υπάρχει ακόμα· βλ. §5) | App Store (υποχρεωτικό) |
| Privacy policy URL | https://staseis.gr/privacy/ (200, ελέγχθηκε 2026-11-14) | Play + App Store |
| Email επικοινωνίας | `<support@staseis.gr ή άλλο>` | Play (Developer contact + Store listing), App Store (Review contact) |
| Τηλέφωνο | `<τηλέφωνο με +30>` | Play (επαλήθευση λογαριασμού), App Store (Review contact, ιδιωτικό) |
| Copyright | © 2026 `<όνομα>` | App Store |
| Τιμή | Δωρεάν, χωρίς αγορές μέσα στην εφαρμογή, χωρίς διαφημίσεις | και τα δύο |
| Χώρες | Ελλάδα (ή όλες) | και τα δύο |

Σημειώσεις:

- **Email**: η Google δείχνει το email της σελίδας δημόσια. Προτείνω ξεχωριστή διεύθυνση στο
  `staseis.gr` (π.χ. Cloudflare Email Routing, δωρεάν, προωθεί στο κανονικό email) αντί για προσωπικό.
- **Τηλέφωνο**: ζητείται για επαλήθευση και για επαφή του review. Σε δωρεάν εφαρμογή χωρίς εμπορική
  δραστηριότητα επίλεξε **non-trader** στο EU/DSA (Play και App Store). Έτσι δεν δημοσιεύονται
  διεύθυνση και τηλέφωνο. Έλεγξε τη δήλωση στο Console, γιατί τα πεδία αλλάζουν.
- **Εκδότης**: η πολιτική απορρήτου γράφει «Εκδότης: Άγγελος Παπαμιχαήλ». Στο store θα φαίνεται το
  όνομα του λογαριασμού του φίλου. Αποφασίστε ποιος είναι ο εκδότης και ταιριάξτε πολιτική, copyright
  και όνομα προγραμματιστή (αλλαγή στο `docs/store/privacy-policy.md` και στο `athens-transit-map`).

## 2. Κείμενα και δηλώσεις (links)

| Τι | Link |
|---|---|
| Τίτλοι, περιγραφές, keywords, κατηγορίες (EL + EN, Play + App Store) | repo: `docs/store/listing.md` |
| Data safety, App Privacy, foreground service, review notes, ratings | repo: `docs/store/declarations.md` |
| Πολιτική απορρήτου (EL + EN), ίδια με τη ζωντανή | repo: `docs/store/privacy-policy.md` · live: https://staseis.gr/privacy/ |
| iOS privacy manifest | repo: `ios/Runner/PrivacyInfo.xcprivacy` |
| Βήματα δημοσίευσης, Shorebird | repo: `docs/store/README.md` |

Γρήγορα, χωρίς να ανοίξεις το `listing.md`:

- **Play**: τίτλος «Στάσεις: Λεωφορεία Αθήνας live» · κατηγορία Maps & Navigation · tags Public transit,
  Navigation.
- **App Store**: όνομα «Στάσεις: Λεωφορεία Αθήνας live» · υπότιτλος «Αφίξεις live και ειδοποιήσεις» ·
  κατηγορία Navigation, δευτερεύουσα Travel · Age rating 4+.
- **Content rating**: IARC όλα «Όχι» → PEGI 3. **Ads**: Όχι. **Target audience**: 18+.
- **Export compliance**: μόνο HTTPS, `ITSAppUsesNonExemptEncryption = false` (ήδη στο `Info.plist`).
- **Review notes (App Store, αντιγραφή)**:
  > Staseis shows live public transport in Athens, Greece. Outside Athens the map still works: pan to
  > Athens, or use the search to open "Σύνταγμα" (Syntagma), then tap any stop to see live arrivals. No
  > login is needed. Alerts: open a stop, tap a line, choose "Ειδοποίησέ με" (notify me). The app is
  > unofficial and uses public data from OASA, STASY and Hellenic Train.
- **Δεν χρειάζεται demo λογαριασμός**: η εφαρμογή δεν έχει login.

## 3. Γραφικά

Όλα 8-bit PNG. Φάκελοι στο GitHub:

| Τι | Μέγεθος | Link |
|---|---|---|
| Play screenshots, Ελληνικά (5) | 1080×2160 | repo: `docs/store/screenshots/play/el/` (01-05.png) |
| Play screenshots, English (5) | 1080×2160 | repo: `docs/store/screenshots/play/en/` |
| iPhone 6.9" screenshots, Ελληνικά (4) | 1320×2868 | repo: `docs/store/screenshots/ios/el/` (01-04.png) |
| iPhone 6.9" screenshots, English (4) | 1320×2868 | repo: `docs/store/screenshots/ios/en/` |
| Εικονίδιο 1024×1024 (App Store) | 1024×1024 | repo: `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` |
| Πηγή και ξαναδημιουργία | | repo: `docs/store/screenshots/src/` (`render.sh`, `slides.html`) |

Raw (κατεβάζονται απευθείας), π.χ.:
`https://raw.githubusercontent.com/angelospk/athens-transit-app/main/docs/store/screenshots/play/el/01.png`

Καρέ (Play): 01 χάρτης live · 02 στάση και αφίξεις · 03 ειδοποίηση πριν έρθει · 04 «Ακόμα και κλειστή» ·
05 διαδρομή. Το iOS set δεν έχει το 04 (στο iOS δεν τρέχει live κάρτα στο παρασκήνιο).

**Λείπουν** (βλ. §5): Play icon 512×512 και Play feature graphic 1024×500.

## 4. Αρχεία που δεν είναι στο GitHub

| Τι | Πού είναι | Πώς φτάνει σε σένα |
|---|---|---|
| Υπογεγραμμένο `app-release.aab` (v0.3.0+9, 73 MB) | mini PC `~/staseis-store/app-release.aab` | ο Άγγελος το στέλνει (Drive / AirDrop). Δεν μπαίνει στο git: έχει υπογραφή. |
| Βίντεο foreground service (55 s) | mini PC `~/staseis-store/staseis-fgs-demo.mp4` | ο Άγγελος το ανεβάζει unlisted στο YouTube και δίνει το link για το Play Console |
| iOS build | χτίζεται από Mac (`flutter build ipa`) | με το team του φίλου στο Xcode (`docs/store/README.md` → iOS) |

Το upload key του Android είναι μόνο στο mini PC του Άγγελου. Το Play App Signing κρατά το κλειδί
υπογραφής. Το keystore **δεν** στέλνεται σε κανέναν.

## 5. Τι λείπει ακόμα (σειρά προτεραιότητας)

1. **Email και τηλέφωνο** (§1). Χωρίς αυτά δεν κλείνει ο λογαριασμός.
2. **Σελίδα support** στο `staseis.gr/support`: σήμερα 404. Η Apple θέλει Support URL με τρόπο
   επικοινωνίας. Μικρή σελίδα στο `athens-transit-map` (email + GitHub issues). Μέχρι τότε: https://staseis.gr.
3. **Feature graphic 1024×500** (Play) και **icon 512×512** (Play, από το 1024). Δεν υπάρχουν.
4. **Πρόσβαση** του Άγγελου στο Play Console (Admin ή Release manager) και στο App Store Connect
   (App Manager), και στο developer team για το Xcode.
5. **Δοκιμή σε κινητό** (`docs/TEST-CHECKLIST.md` #2, #17) και σε iPhone με κλειδωμένη οθόνη (καρέ 03).
6. **Έλεγχος ονόματος**: ψάξε «Στάσεις» / «Staseis» στα δύο stores για ίδιο όνομα.
7. **Play, λογαριασμός προσωπικός μετά τις 13/11/2023**: closed test με 12 testers για 14 μέρες πριν το
   production.

## 6. Γνωστοί κίνδυνοι στο review

- Η Google μπορεί να θεωρήσει ότι το polling αφίξεων δεν είναι `dataSync`. Αν το απορρίψει, χρειάζεται νέα
  έκδοση με `shortService` ή `specialUse` (`declarations.md`).
- Η Apple μπορεί να κόψει το «ΟΑΣΑ» από τα keywords (guideline 2.3.7). Αν απορριφθεί, σβήστο.
- Ένας reviewer στις ΗΠΑ βλέπει άδειο χάρτη στη θέση του. Τα review notes λένε πώς να πάει στην Αθήνα.
