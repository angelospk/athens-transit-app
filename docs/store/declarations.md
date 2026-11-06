# Δηλώσεις και σημειώσεις για το review

Πηγή των απαντήσεων: ο κώδικας στις 2026-11-06. Η θέση χρησιμοποιείται μόνο τοπικά
(`lib/background/service.dart`). Το geocoder στέλνει μόνο το κείμενο της αναζήτησης
(`lib/data/api.dart:160`). Αν αλλάξει κάτι από αυτά, ξαναδές αυτό το αρχείο.

## Google Play · Data safety

- Συλλέγει ή μοιράζεται η εφαρμογή δεδομένα χρηστών; **Όχι.**
  - Η θέση δεν φεύγει από τη συσκευή, άρα δεν μετρά ως «συλλογή» για το Play.
  - Το κείμενο αναζήτησης διευθύνσεων πάει στο Photon χωρίς στοιχεία χρήστη. Αν ο reviewer το
    αμφισβητήσει, δήλωσε: App activity → «Other user-generated content», **Shared**, όχι
    υποχρεωτικό, σκοπός App functionality, ephemeral.
- Κρυπτογράφηση κατά τη μεταφορά: **Ναι** (μόνο HTTPS).
- Διαγραφή δεδομένων: δεν υπάρχουν δεδομένα στους διακομιστές· όλα σβήνονται με την απεγκατάσταση.

## Google Play · Foreground service (Play Console → App content)

Η εφαρμογή ξεκινά foreground service μόνο όταν ο χρήστης ορίζει ειδοποίηση. Χρειάζεται βίντεο
(30-60 s, unlisted YouTube) που δείχνει: στάση → «Ειδοποίησέ με» → η μόνιμη ειδοποίηση εμφανίζεται →
κλείσιμο εφαρμογής → η ειδοποίηση «έρχεται σε 5′».

**dataSync**:
> The user sets an alert for a bus at a stop. While the alert is active, the service checks live arrival
> times (a 10-second tick, each line fetched when its data is due) and posts a notification when the bus is the chosen number of minutes or
> stops away. The user starts it and sees it in a persistent notification with a Stop action. It ends
> when the bus arrives or the user stops it. Deferring the work would make the alert late, so
> WorkManager does not fit.

**location**:
> Only for "Leave on time", "Where do I get off?" and "Follow me", started by the user. While the alert
> runs, the service reads the device position to compute walking time to the stop, or to detect that the
> user boarded and is one stop before the destination. Uses while-in-use permission only (no background
> location). The position never leaves the device.

**Κίνδυνος**: η Google μπορεί να κρίνει ότι το polling αφίξεων δεν είναι «data sync». Αν το
απορρίψει, η λύση είναι αλλαγή τύπου σε `shortService` ή `specialUse` με αιτιολόγηση. Είναι
αλλαγή κώδικα και θα χρειαστεί νέα έκδοση.
Το Android 15 δίνει στο `dataSync` όριο 6 ωρών ανά 24 ώρες. Για ειδοποιήσεις λεωφορείων αρκεί.

## Google Play · Λοιπά

- **Exact alarms**: `SCHEDULE_EXACT_ALARM` (όχι `USE_EXACT_ALARM`). Ο χρήστης το δίνει στις
  ρυθμίσεις· χωρίς αυτό οι κανόνες ξεκινούν λίγο αργά (`lib/ui/rules_screen.dart:191`). Δεν θέλει
  δήλωση· αν τη ζητήσει: «user-set weekly reminders for a bus at a set time».
- **Content rating**: IARC ερωτηματολόγιο, όλα «Όχι» → PEGI 3 / Everyone.
- **Ads**: Όχι. **Target audience**: 18+ (απλούστερο, αποφεύγει τους κανόνες Families).
- **Government app**: Όχι. Ανεπίσημη εφαρμογή.

## App Store · App Privacy (nutrition labels)

- Data types: **Search History** → not linked to user, not used for tracking, App Functionality.
  Ταιριάζει με το `ios/Runner/PrivacyInfo.xcprivacy`.
- Τίποτα άλλο. Location: **Not collected** (δεν φεύγει από τη συσκευή).
- Export compliance: `ITSAppUsesNonExemptEncryption = false` στο `Info.plist` (μόνο HTTPS). Δεν θα
  ρωτά σε κάθε build.

## App Store · Review notes

> Staseis shows live public transport in Athens, Greece. Outside Athens the map still works:
> pan to Athens, or use the search to open "Σύνταγμα" (Syntagma), then tap any stop to see live
> arrivals. No login is needed. Alerts: open a stop, tap a line, choose "Ειδοποίησέ με" (notify me).
> The app is unofficial and uses public data from OASA, STASY and Hellenic Train.

Ο χάρτης ανοίγει στη θέση του χρήστη (`lib/ui/map_screen.dart:716`). Ένας reviewer στις ΗΠΑ θα δει
άδειο χάρτη. Έλεγξε σε simulator με θέση στις ΗΠΑ πριν την υποβολή: τι δείχνει το «Κοντά σου»;

## Λογαριασμός του φίλου

- **Play Console**: ο ιδιοκτήτης σε προσθέτει στο Users and permissions (Admin ή Release manager για
  την εφαρμογή). Αν ο λογαριασμός είναι προσωπικός και ανοίχτηκε μετά τις 13/11/2023, ισχύει ο
  κανόνας closed test: 12 testers για 14 μέρες πριν το production.
- **App Store Connect**: σε προσθέτει στο Users and Access (App Manager). Για builds από το Mac
  χρειάζεσαι και πρόσβαση στο developer team (certificates, `DEVELOPMENT_TEAM` στο Xcode).
- **Bundle ID / applicationId**: `gr.staseis.app` και στις δύο πλατφόρμες (αλλαγή 2026-11-06). Δεν
  αλλάζει ποτέ μετά την πρώτη δημοσίευση· φαίνεται στο link του Play.
- **Play App Signing**: το upload key είναι στο `~/.config/athens-transit-app/key.properties`. Κράτα
  αντίγραφο ασφαλείας του keystore εκτός του mini PC.
