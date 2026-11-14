# Δημοσίευση στο Play Store και στο App Store

Αρχεία σε αυτόν τον φάκελο:

- `privacy-policy.md`: πολιτική απορρήτου (EL + EN). Συμπλήρωσε τα `<...>` και ανέβασέ τη σε δημόσιο
  URL (π.χ. `staseis.gr/privacy`). Το URL μπαίνει και στα δύο stores.
- `SUBMISSION.md`: το κεντρικό έγγραφο, με links GitHub σε όλα: https://github.com/angelospk/athens-transit-app/blob/main/docs/store/SUBMISSION.md
- `listing.md`: τίτλοι, περιγραφές, keywords, γραφικά που λείπουν.
- `declarations.md`: Data safety, foreground service, App Privacy, review notes, λογαριασμός.

## Κατάσταση (2026-11-11)

Έτοιμα:

- Πολιτική απορρήτου στο https://staseis.gr/privacy/ (ίδια με το `privacy-policy.md`).
- Data safety, App Privacy και `ios/Runner/PrivacyInfo.xcprivacy` δηλώνουν την αναφορά «Λάθος θέση;».
- Υπογεγραμμένο `.aab` χτίζεται (`flutter build appbundle --release`, upload key από
  `~/.config/athens-transit-app/key.properties`). Αντίγραφο: `~/staseis-store/app-release.aab` (v0.3.0+9).
- Βίντεο για το foreground service (55 s, emulator): `~/staseis-store/staseis-fgs-demo.mp4`. Δείχνει
  στάση → «Ειδοποίησέ με» → η κάρτα → η ειδοποίηση «Το 040 έρχεται» στο shade. Αν ο reviewer το θέλει
  πιο καθαρό, ξαναγράψ' το σε κινητό, με την εφαρμογή κλειστή πριν φτάσει το λεωφορείο.
- Screenshots (`screenshots/play`, `screenshots/ios`) και κείμενα (`listing.md`).

Μένουν (θέλουν εσένα):

1. Πρόσβαση στο Play Console και στο App Store Connect από τον φίλο.
2. `shorebird login` (browser) και `shorebird init`, πριν από το πρώτο ανέβασμα.
3. Δοκιμή σε κινητό με `docs/TEST-CHECKLIST.md` (#2, #17).
4. Το βίντεο unlisted στο YouTube και το link στο Play Console.


### Πριν από όλα (μία φορά)

1. Ο φίλος σε προσθέτει στο Play Console και στο App Store Connect (`declarations.md` → «Λογαριασμός»).
2. Αποφάσισε το όνομα και τα bundle IDs. Μετά τη δημοσίευση δεν αλλάζουν.
3. Βάλε το Shorebird (παρακάτω) **πριν** το πρώτο build που ανεβαίνει στο store.
4. Ανέβασε την πολιτική απορρήτου.

### Android

1. `shorebird release android` (ή `flutter build appbundle` χωρίς OTA) → `.aab`
2. Play Console → νέα εφαρμογή → Internal testing → ανέβασμα του `.aab`
3. App content: privacy policy, Data safety, foreground service (με βίντεο), content rating, ads,
   target audience
4. Store listing: κείμενα και γραφικά από το `listing.md`
5. Closed testing (αν το ζητά ο λογαριασμός: 12 testers, 14 μέρες) → Production

### iOS (από το Mac)

1. Xcode → Runner → Signing: διάλεξε το team του φίλου
2. `shorebird release ios` (ή `flutter build ipa`) → ανέβασμα με Transporter ή Xcode
3. App Store Connect: App Privacy, κείμενα, screenshots 6.9", review notes από το `declarations.md`
4. TestFlight σε 2-3 iPhone → Submit for review

## OTA updates με το Shorebird

Το Shorebird στέλνει αλλαγές σε **Dart** στις εγκατεστημένες εφαρμογές χωρίς νέο review. Αλλαγές σε
native κώδικα, plugins, `AndroidManifest.xml`, `Info.plist` ή assets που δεν είναι Dart θέλουν
κανονική έκδοση στο store.

Τιμές (shorebird.dev/pricing, 2026-11): δωρεάν έως 5.000 εγκαταστάσεις patch τον μήνα. Pro 20$/μήνα για
50.000. Υπολογισμός: patches τον μήνα × ενεργοί χρήστες.

Εγκατάσταση (μία φορά, χρειάζεται login στον browser):

```bash
curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash
shorebird login
cd ~/athens-transit-app && shorebird init      # γράφει shorebird.yaml, προσθέτει το asset
```

Κάθε έκδοση στο store:

```bash
shorebird release android        # και: shorebird release ios (στο Mac)
```

Γρήγορη διόρθωση μετά:

```bash
shorebird patch android          # και: shorebird patch ios
```

Οι χρήστες παίρνουν το patch στην επόμενη εκκίνηση (κατεβαίνει στο παρασκήνιο, εφαρμόζεται στην
μεθεπόμενη). Το `version` στο `pubspec.yaml` μένει ίδιο σε ένα patch· αλλάζει μόνο σε release.
