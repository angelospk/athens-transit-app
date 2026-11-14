# Στάσεις · Πακέτο για τα stores

Ενημερώθηκε 2026-11-14 · έκδοση 0.3.0+9 · bundle ID / applicationId `gr.staseis.app` (Play και App Store)

Αυτό είναι το κεντρικό έγγραφο. Κάθε αρχείο έχει πλήρες link GitHub, ώστε να το ανοίξει άνθρωπος ή agent.
Αυτό το έγγραφο: https://github.com/angelospk/athens-transit-app/blob/main/docs/store/SUBMISSION.md

## 1. Στοιχεία για τα forms

| Πεδίο | Τιμή |
|---|---|
| Όνομα εφαρμογής (Play και App Store) | Στάσεις: Live Συγκοινωνίες (26 χαρακτήρες) |
| Όνομα EN | Staseis: Live Transit |
| Εκδότης / Copyright | Άγγελος Παπαμιχαήλ · © 2026 Άγγελος Παπαμιχαήλ |
| Website / Marketing URL | https://staseis.gr |
| Support URL | https://staseis.gr/support/ |
| Privacy policy URL | https://staseis.gr/privacy/ |
| Email, τηλέφωνο | ΔΕΝ είναι στο δημόσιο repo. Βλ. §4: ιδιωτικό αρχείο `CONTACT.md` |
| Τιμή | Δωρεάν, χωρίς αγορές μέσα στην εφαρμογή, χωρίς διαφημίσεις |
| Χώρες | Ελλάδα (ή όλες) |
| Πόλεις στην εφαρμογή | Αθήνα, Θεσσαλονίκη |

Σημειώσεις:

- **Email**: η Google το δείχνει δημόσια στη σελίδα της εφαρμογής. Μπορεί να είναι ξεχωριστή διεύθυνση στο
  `staseis.gr` (Cloudflare Email Routing).
- **Τηλέφωνο**: ζητείται για επαλήθευση και για επαφή του review. Σε δωρεάν εφαρμογή χωρίς εμπορική
  δραστηριότητα επίλεξε **non-trader** (EU/DSA). Έτσι δεν δημοσιεύονται διεύθυνση και τηλέφωνο. Έλεγξε τη
  δήλωση στο Console, γιατί τα πεδία αλλάζουν.
- **Εκδότης**: ο Άγγελος Παπαμιχαήλ, όπως στην πολιτική απορρήτου. Αν ανεβάζει ο φίλος με δικό του λογαριασμό,
  το «Developer name» θα είναι το δικό του, και η πολιτική πρέπει να το λέει.

## 2. Κείμενα και δηλώσεις

| Τι | Link |
|---|---|
| Τίτλοι, περιγραφές, keywords, κατηγορίες (EL + EN, Play + App Store) | https://github.com/angelospk/athens-transit-app/blob/main/docs/store/listing.md |
| Data safety, App Privacy, foreground service, review notes, ratings, λογαριασμοί | https://github.com/angelospk/athens-transit-app/blob/main/docs/store/declarations.md |
| Πολιτική απορρήτου (EL + EN) | https://github.com/angelospk/athens-transit-app/blob/main/docs/store/privacy-policy.md · live: https://staseis.gr/privacy/ |
| iOS privacy manifest | https://github.com/angelospk/athens-transit-app/blob/main/ios/Runner/PrivacyInfo.xcprivacy |
| Βήματα δημοσίευσης Android και iOS, Shorebird | https://github.com/angelospk/athens-transit-app/blob/main/docs/store/README.md |

Γρήγορα, χωρίς να ανοίξεις το `listing.md`:

- **Play**: κατηγορία Maps & Navigation · tags Public transit, Navigation.
- **App Store**: υπότιτλος «Αφίξεις live και ειδοποιήσεις» · κατηγορία Navigation, δευτερεύουσα Travel · Age
  rating 4+.
- **Content rating**: IARC όλα «Όχι» → PEGI 3. **Ads**: Όχι. **Target audience**: 18+.
- **Export compliance**: μόνο HTTPS, `ITSAppUsesNonExemptEncryption = false` (ήδη στο `Info.plist`).
- **Review notes (App Store, αντιγραφή)**:
  > Staseis shows live public transport in Athens and Thessaloniki, Greece. Outside Greece the map still
  > works: pan to Athens, or use the search to open "Σύνταγμα" (Syntagma), then tap any stop to see live
  > arrivals. No login is needed. Alerts (Athens): open a stop, tap a line, choose "Ειδοποίησέ με" (notify
  > me). The app is unofficial and uses public data from OASA, OASTH, STASY and Hellenic Train.
- **Δεν χρειάζεται demo λογαριασμός**: η εφαρμογή δεν έχει login.

## 3. Γραφικά

Όλα 8-bit PNG.

| Τι | Μέγεθος | Link |
|---|---|---|
| Play screenshots, Ελληνικά (5: 01-05.png) | 1080×2160 | https://github.com/angelospk/athens-transit-app/tree/main/docs/store/screenshots/play/el |
| Play screenshots, English (5) | 1080×2160 | https://github.com/angelospk/athens-transit-app/tree/main/docs/store/screenshots/play/en |
| iPhone 6.9" screenshots, Ελληνικά (4: 01-04.png) | 1320×2868 | https://github.com/angelospk/athens-transit-app/tree/main/docs/store/screenshots/ios/el |
| iPhone 6.9" screenshots, English (4) | 1320×2868 | https://github.com/angelospk/athens-transit-app/tree/main/docs/store/screenshots/ios/en |
| Play εικονίδιο | 512×512 | https://raw.githubusercontent.com/angelospk/athens-transit-app/main/docs/store/graphics/icon-512.png |
| Play feature graphic | 1024×500 | https://raw.githubusercontent.com/angelospk/athens-transit-app/main/docs/store/graphics/feature-graphic-1024x500.png |
| App Store εικονίδιο | 1024×1024 | https://raw.githubusercontent.com/angelospk/athens-transit-app/main/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024%401x.png |
| Πηγή screenshots (`render.sh`, `slides.html`) | | https://github.com/angelospk/athens-transit-app/tree/main/docs/store/screenshots/src |
| Πηγή γραφικών Play (`feature.html`) | | https://github.com/angelospk/athens-transit-app/tree/main/docs/store/graphics |

Direct download ενός screenshot, π.χ.:
https://raw.githubusercontent.com/angelospk/athens-transit-app/main/docs/store/screenshots/play/el/01.png

Καρέ (Play): 01 χάρτης live · 02 στάση και αφίξεις · 03 ειδοποίηση πριν έρθει · 04 «Ακόμα και κλειστή» ·
05 διαδρομή. Το iOS set δεν έχει το 04 (στο iOS δεν τρέχει live κάρτα στο παρασκήνιο). Τα καρέ δείχνουν
την Αθήνα.

## 4. Αρχεία και links εκτός GitHub

| Τι | Πού | Πώς φτάνει σε σένα |
|---|---|---|
| Βίντεο foreground service (55 s) | https://youtube.com/shorts/0Y5P6Zeynyg | Το link μπαίνει στο Play Console → App content → Foreground service |
| Υπογεγραμμένο `app-release.aab` (v0.3.0+9, 73 MB, χτίστηκε 2026-11-14 από το `main`) | mini PC `~/staseis-store/app-release.aab` | Ο Άγγελος το δίνει (βλ. «Παράδοση» παρακάτω). Δεν μπαίνει στο git. |
| Στοιχεία επικοινωνίας (email, τηλέφωνο) | mini PC `~/staseis-store/CONTACT.md` | Ο Άγγελος τα δίνει ιδιωτικά, όχι από το GitHub |
| iOS build | χτίζεται από Mac (`flutter build ipa`) | με το team του φίλου στο Xcode (βλ. https://github.com/angelospk/athens-transit-app/blob/main/docs/store/README.md) |

Παράδοση του `.aab`: ο Άγγελος το ανεβάζει ο ίδιος στο Play Console (Internal testing → Create release), αν
ο φίλος τον προσθέσει στο Console. Αλλιώς το στέλνει στον φίλο (Drive, WeTransfer, AirDrop) και ο φίλος το
ανεβάζει.

Το upload key του Android είναι μόνο στο mini PC του Άγγελου. Το Play App Signing κρατά το κλειδί
υπογραφής. Το keystore **δεν** στέλνεται σε κανέναν.

## 5. Τι λείπει ακόμα

1. **Πρόσβαση** του Άγγελου στο Play Console (Admin ή Release manager) και στο App Store Connect
   (App Manager), και στο developer team για το Xcode.
2. **Play, λογαριασμός προσωπικός μετά τις 13/11/2023**: closed test με 12 testers για 14 μέρες πριν το
   production.
3. **iOS**: build από Mac, και δοκιμή σε iPhone με κλειδωμένη οθόνη για το καρέ 03.
4. Δοκιμή σε κινητό (https://github.com/angelospk/athens-transit-app/blob/main/docs/TEST-CHECKLIST.md #2, #17):
   αποφασίστηκε 2026-11-14 να μη γίνει πριν το release.

Έλεγχος ονόματος (2026-11-14): κανένα ίδιο «Στάσεις» ή «Staseis» στο App Store GR ή στο Play. Ανταγωνιστές
με παρόμοιο θέμα: Busmate (Athens Bus & Metro), BusMakro. Το `gr.staseis.app` δεν υπάρχει ακόμα στο Play.

## 6. Γνωστοί κίνδυνοι στο review

- Η Google μπορεί να θεωρήσει ότι το polling αφίξεων δεν είναι `dataSync`. Αν το απορρίψει, χρειάζεται νέα
  έκδοση με `shortService` ή `specialUse`
  (https://github.com/angelospk/athens-transit-app/blob/main/docs/store/declarations.md).
- Η Apple μπορεί να κόψει το «ΟΑΣΑ» από τα keywords (guideline 2.3.7). Αν απορριφθεί, σβήστο.
- Ένας reviewer στις ΗΠΑ βλέπει άδειο χάρτη στη θέση του. Τα review notes λένε πώς να πάει στην Αθήνα.
