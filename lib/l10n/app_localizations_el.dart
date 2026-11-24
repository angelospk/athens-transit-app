// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get appName => 'Στάσεις';

  @override
  String get commonCancel => 'Άκυρο';

  @override
  String get commonDelete => 'Διαγραφή';

  @override
  String get commonSave => 'Αποθήκευση';

  @override
  String get commonRetry => 'Δοκίμασε ξανά';

  @override
  String get commonLess => 'Λιγότερο';

  @override
  String get commonMore => 'Περισσότερο';

  @override
  String get commonClose => 'Κλείσιμο';

  @override
  String get commonNext => 'Επόμενο';

  @override
  String get commonOk => 'Εντάξει';

  @override
  String get commonNow => 'τώρα';

  @override
  String get commonOnTime => 'στην ώρα του';

  @override
  String get commonSearching => 'Αναζήτηση…';

  @override
  String get commonLocating => 'Αναζήτηση θέσης…';

  @override
  String get commonHome => 'Σπίτι';

  @override
  String get commonWork => 'Δουλειά';

  @override
  String get commonMetro => 'Μετρό';

  @override
  String get commonTram => 'Τραμ';

  @override
  String get commonSuburban => 'Προαστιακός';

  @override
  String get commonBuses => 'Λεωφορεία';

  @override
  String get commonNoNotificationPermission =>
      'Για να σε ειδοποιήσουμε, χρειάζεται άδεια ειδοποιήσεων.';

  @override
  String stopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count στάσεις',
      one: '1 στάση',
    );
    return '$_temp0';
  }

  @override
  String minutesShort(int n) {
    return '$n′';
  }

  @override
  String mapOnBusSnack(String line) {
    return 'Είσαι στο $line; Διάλεξε πού κατεβαίνεις.';
  }

  @override
  String get mapOnBusSnackAction => 'Άνοιξέ το';

  @override
  String get mapLayersMine => 'Χάρτης: οι γραμμές μου';

  @override
  String get mapLayers => 'Τι δείχνει ο χάρτης';

  @override
  String get mapWhereAmI => 'Πού είμαι';

  @override
  String get mapMenu => 'Μενού';

  @override
  String get mapTitle => 'Χάρτης';

  @override
  String get mapLegend => 'Τι σημαίνει κάθε σύμβολο';

  @override
  String get mapBusesAllHint =>
      'Λεωφορεία: όλα. Βάλε αστέρι σε μια γραμμή για να βλέπεις μόνο τις δικές σου.';

  @override
  String get mapAllBuses => 'Όλα τα λεωφορεία';

  @override
  String get mapMyLines => 'Οι γραμμές μου';

  @override
  String get mapAdvanced => 'Για προχωρημένους';

  @override
  String get mapOthersWhenSelected =>
      'Όταν πατάς ένα λεωφορείο ή μια γραμμή, τα άλλα:';

  @override
  String get mapOthersNormal => 'Φαίνονται';

  @override
  String get mapOthersDim => 'Αχνά';

  @override
  String get mapOthersHide => 'Κρύβονται';

  @override
  String get mapRecentOnly => 'Μόνο με πρόσφατη θέση';

  @override
  String get mapRecentOnlyHint => 'Έστειλαν θέση τα τελευταία 1½ λεπτά.';

  @override
  String get mapOnTimeOnly => 'Μόνο στην ώρα τους';

  @override
  String get mapOnTimeOnlyHint => 'Έως 5 λεπτά καθυστέρηση.';

  @override
  String get mapShowAge => 'Πόσο παλιά είναι η θέση';

  @override
  String get mapShowAgeHint =>
      'Δίπλα σε κάθε λεωφορείο. Οι παλιές φαίνονται πάντα.';

  @override
  String get mapAttribution =>
      'Χάρτης: © OpenStreetMap contributors · OpenFreeMap';

  @override
  String mapLastData(String time, String ago) {
    return 'Τελευταία δεδομένα $time · πριν $ago';
  }

  @override
  String get mapOffline => 'Χωρίς σύνδεση';

  @override
  String get mapSeeNearby => 'Δες τι περνάει κοντά σου';

  @override
  String get mapLocationPitch =>
      'Με την τοποθεσία σου βλέπεις τις πιο κοντινές στάσεις και πότε έρχεται το λεωφορείο. Η θέση μένει στο κινητό.';

  @override
  String get mapUseMyLocation => 'Χρήση της θέσης μου';

  @override
  String get mapOrSearch => 'Ή γράψε μια στάση ή γραμμή στην αναζήτηση.';

  @override
  String get mapLoadingStops => 'Φόρτωση στάσεων…';

  @override
  String get mapNoStopWithin => 'Καμία στάση σε 2,5 χλμ.';

  @override
  String get mapDragForMore => 'σύρε για περισσότερες στάσεις';

  @override
  String get mapNoSavedStops =>
      'Καμία αποθηκευμένη στάση ακόμη. Άνοιξε μια στάση και πάτα το αστέρι.';

  @override
  String get mapFavorites => 'Αγαπημένα';

  @override
  String get mapAllFavorites => 'Όλα τα αγαπημένα · προσθήκη, σπίτι, δουλειά';

  @override
  String get mapNearYou => 'Κοντά σου';

  @override
  String mapQuietLines(String lines) {
    return '$lines: κανένα λεωφορείο με GPS τώρα';
  }

  @override
  String get mapWalkDirections => 'Οδηγίες με τα πόδια';

  @override
  String mapWalkDirectionsMin(int m) {
    return 'Οδηγίες με τα πόδια, $m λεπτά';
  }

  @override
  String get mapCancelled => 'ακυρώθηκε';

  @override
  String get mapRailLive => 'live από railway.gov.gr';

  @override
  String get mapMetroSchedule => 'πρόγραμμα ΣΤΑΣΥ, όχι live';

  @override
  String get mapStopsNear => 'Στάσεις κοντά';

  @override
  String get mapNoStopWithin600 => 'Καμία στάση σε 600 μ.';

  @override
  String mapStopDistLines(int dist, String lines) {
    return '$dist μ. · $lines';
  }

  @override
  String mapBusesOnRoad(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count λεωφορεία στον δρόμο',
      one: '1 λεωφορείο στον δρόμο',
    );
    return '$_temp0';
  }

  @override
  String get mapAllOnTime => 'όλα στην ώρα τους';

  @override
  String mapLateCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count αργούν πάνω από 5′',
      one: '1 αργεί πάνω από 5′',
    );
    return '$_temp0';
  }

  @override
  String get mapMyLinesNow => 'Οι γραμμές μου τώρα';

  @override
  String get mapMyLinesHint =>
      'τα άλλα λεωφορεία κρυμμένα · πάτα μια γραμμή για τη διαδρομή της';

  @override
  String get mapNoLineSelected =>
      'Καμία γραμμή επιλεγμένη. Διάλεξε από το κουμπί του χάρτη (σύρε το πλαίσιο προς τα κάτω).';

  @override
  String get plannerTitle => 'Διαδρομή';

  @override
  String get plannerMyLocation => 'Η θέση μου';

  @override
  String get plannerFrom => 'Από';

  @override
  String get plannerTo => 'Προς';

  @override
  String get plannerWhereAreYou => 'Πού είσαι;';

  @override
  String get plannerWhereTo => 'Πού πας; στάση, περιοχή, κατάστημα, διεύθυνση';

  @override
  String get plannerSwap => 'Αντιστροφή';

  @override
  String get plannerNow => 'Τώρα';

  @override
  String get plannerLater => 'Αργότερα';

  @override
  String plannerLeaveAt(String time) {
    return 'Φεύγω $time';
  }

  @override
  String get plannerWithMetro => 'Με μετρό';

  @override
  String get plannerLinesFailed =>
      'Δεν φόρτωσαν οι γραμμές. Χρειάζεται σύνδεση την πρώτη φορά.';

  @override
  String get plannerPickFrom =>
      'Διάλεξε από πού φεύγεις ή δώσε άδεια τοποθεσίας: έτσι υπολογίζεται πόσο περπατάς ως τη στάση.';

  @override
  String get plannerPickTo =>
      'Διάλεξε πού πας. Θα δεις λεωφορεία χωρίς αλλαγή ή με μία, και το μετρό όταν σε βολεύει.';

  @override
  String get plannerNoBus =>
      'Δεν βρέθηκε λεωφορείο σε 500 μ. από την αφετηρία και τον προορισμό σου, ούτε με μία αλλαγή. Δοκίμασε μια κοντινή στάση ή το μετρό.';

  @override
  String get plannerDirect => 'Χωρίς αλλαγή';

  @override
  String get plannerOneChange => 'Με μία αλλαγή';

  @override
  String get plannerTimesLive =>
      'Χρόνοι: περπάτημα 4,5 χλμ/ώ, λεωφορείο 15 χλμ/ώ με τις στάσεις· η αναμονή είναι live από το GPS των λεωφορείων.';

  @override
  String get plannerTimesLater =>
      'Για αργότερα δεν ξέρουμε ποιο λεωφορείο θα έρθει: οι χρόνοι είναι χωρίς αναμονή.';

  @override
  String plannerMetroWalk(int walk) {
    return 'Περπάτημα $walk′ συνολικά · τρένο κάθε λίγα λεπτά (πρόγραμμα, όχι live)';
  }

  @override
  String get plannerMetroWait =>
      'Μετρό με το πρόγραμμα (όχι live), αναμονή ~5′.';

  @override
  String plannerBoardChange(String board, String change) {
    return 'Ανεβαίνεις: $board · αλλαγή: $change';
  }

  @override
  String plannerTransferWalk(int m) {
    return ' ($m μ. με τα πόδια)';
  }

  @override
  String plannerStopsWalk(int stops, int walk) {
    return '$stops στάσεις · περπάτημα $walk′';
  }

  @override
  String plannerBoard(String stop) {
    return 'Ανεβαίνεις: $stop';
  }

  @override
  String plannerGetOff(String stop) {
    return 'Κατεβαίνεις: $stop';
  }

  @override
  String get plannerNearMyLocation => 'κοντά στη θέση σου';

  @override
  String plannerNearStop(String stop) {
    return 'κοντά σε $stop';
  }

  @override
  String get plannerNearMeApprox => 'Κοντά στη θέση μου (περίπου)';

  @override
  String plannerPlaceHint(String name) {
    return '$name: διεύθυνση ή περιοχή';
  }

  @override
  String get plannerFromHint => 'Από: στάση, περιοχή, διεύθυνση';

  @override
  String get plannerToHint => 'Προς: στάση, περιοχή, κατάστημα, διεύθυνση';

  @override
  String get plannerPlacePrivacy =>
      'Αρκεί μια περιοχή κοντά. Δεν κρατάμε τίποτα: το μέρος μένει μόνο στο κινητό σου.';

  @override
  String get plannerNoLocation =>
      'Δεν βρέθηκε η θέση σου. Ενεργοποίησε την τοποθεσία ή διάλεξε ένα μέρος.';

  @override
  String routeArrive(String time) {
    return 'φτάνεις ~$time';
  }

  @override
  String routeEstimateMetro(int wait) {
    return 'Εκτίμηση με αναμονή ~$wait′ για το τρένο.';
  }

  @override
  String get routeEstimateLive =>
      'Εκτίμηση χωρίς την αναμονή του πρώτου λεωφορείου· η αναμονή φαίνεται live στο βήμα του.';

  @override
  String get routeEstimateLater => 'Για αργότερα: εκτίμηση χωρίς αναμονή.';

  @override
  String get routeWalkToDest => 'Περπάτα ως τον προορισμό';

  @override
  String routeWalkToStation(String name) {
    return 'Περπάτα ως τον σταθμό $name';
  }

  @override
  String routeWalkToStop(String name) {
    return 'Περπάτα ως τη στάση $name';
  }

  @override
  String routeWalkTo(String name) {
    return 'Περπάτα ως $name';
  }

  @override
  String routeBoard(String line) {
    return 'Ανέβα στο $line';
  }

  @override
  String routeBoardToward(String line, String toward) {
    return 'Ανέβα στο $line προς $toward';
  }

  @override
  String routeStop(String name) {
    return 'Στάση: $name';
  }

  @override
  String routeGetOff(String name) {
    return 'Κατέβα: $name';
  }

  @override
  String routeChangeWait(int wait) {
    return 'Αλλαγή: αναμονή ~$wait′';
  }

  @override
  String routeTrainEvery(int wait) {
    return 'Τρένο κάθε λίγα λεπτά (πρόγραμμα, όχι live), αναμονή ~$wait′';
  }

  @override
  String get routeWhereGetOff => 'Πού κατεβαίνω;';

  @override
  String get routeLeaveInTime => 'Φύγε εγκαίρως';

  @override
  String get routeNoBusNear => 'Κανένα λεωφορείο με GPS κοντά τώρα';

  @override
  String get routeCantCatch => 'Δεν προλαβαίνεις αυτά που έρχονται τώρα';

  @override
  String get routeSearchingNext => 'Αναζήτηση επόμενου λεωφορείου…';

  @override
  String routeNextCatch(String eta, String clock) {
    return 'Το επόμενο που προλαβαίνεις σε $eta ($clock)';
  }

  @override
  String get routeLeaveNow => 'φύγε τώρα';

  @override
  String routeLeaveIn(int n) {
    return 'φύγε σε $n′';
  }

  @override
  String get mapSelBack => 'Πίσω';

  @override
  String mapSelLine(String line) {
    return 'Γραμμή $line';
  }

  @override
  String get mapSelStop => 'Στάση';

  @override
  String get searchClear => 'Καθαρισμός';

  @override
  String get searchHint => 'Στάση, γραμμή ή μέρος';

  @override
  String searchHiddenResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count αποτελέσματα σε κρυμμένα μέσα',
      one: '1 αποτέλεσμα σε κρυμμένα μέσα',
    );
    return '$_temp0';
  }

  @override
  String get searchShow => 'Εμφάνιση';

  @override
  String searchMunicipal(String municipality) {
    return 'Δημοτική · $municipality';
  }

  @override
  String get stationRail => 'Σταθμός Προαστιακού';

  @override
  String get stationMetroTram => 'Σταθμός μετρό / τραμ';

  @override
  String get stationDeparturesFailed =>
      'Δεν φόρτωσαν οι αναχωρήσεις. Νέα προσπάθεια σε λίγο.';

  @override
  String get stationBusStopsNear => 'Στάσεις λεωφορείων κοντά';

  @override
  String get stationNoTrain => 'Κανένα τρένο στις επόμενες ώρες.';

  @override
  String stationTrain(String train) {
    return 'Τρένο $train';
  }

  @override
  String stationDelay(int n) {
    return '+$n′ καθυστέρηση';
  }

  @override
  String get stationLine => 'γραμμή';

  @override
  String get stationRailNote =>
      'Live από railway.gov.gr. Ο πίνακας δίνει μόνο την επόμενη στάση· το «προς» είναι το τέρμα της γραμμής.';

  @override
  String stationToward(String name) {
    return 'προς $name';
  }

  @override
  String stationNextStop(String name) {
    return 'επόμενη στάση $name';
  }

  @override
  String get stationNoMetroTimes =>
      'Τα δρομολόγια μετρό και τραμ δεν είναι ακόμη διαθέσιμα.';

  @override
  String get stationNoDeparture => 'Καμία αναχώρηση στην επόμενη ώρα.';

  @override
  String get stationIndicative =>
      'Ενδεικτικά, από το πρόγραμμα της ΣΤΑΣΥ (όχι live).';

  @override
  String get stationSchedule => 'Από το πρόγραμμα της ΣΤΑΣΥ (όχι live).';

  @override
  String get muniBadge => 'Δ';

  @override
  String muniFromStop(String stop) {
    return ' από $stop';
  }

  @override
  String get muniScheduled => 'Προγραμματισμένα · όχι live';

  @override
  String muniLine(String municipality) {
    return 'Δημοτική γραμμή · $municipality';
  }

  @override
  String get muniNoTimetable =>
      'Δεν έχουμε ελεγμένο ωράριο για αυτή τη γραμμή.';

  @override
  String get muniTimetableLink => 'Ωράριο του δήμου';

  @override
  String get muniNextDepartures => 'Επόμενες αναχωρήσεις';

  @override
  String get muniNoMoreToday =>
      'Κανένα άλλο δρομολόγιο σήμερα, κατά το ωράριο.';

  @override
  String get muniApproxNote => '≈: ο δήμος δίνει συχνότητα, όχι ακριβείς ώρες.';

  @override
  String muniTimetableChecked(String municipality, String date) {
    return 'Ωράριο: $municipality, ελέγχθηκε $date.';
  }

  @override
  String get muniPageLink => 'Σελίδα του δήμου';

  @override
  String muniRouteSource(String source) {
    return 'Διαδρομή και στάσεις: $source';
  }

  @override
  String get muniStopKicker => 'Στάση δημοτικής γραμμής';

  @override
  String get muniLinesFailed =>
      'Δεν φόρτωσαν οι δημοτικές γραμμές. Δοκίμασε ξανά σε λίγο.';

  @override
  String get muniNoCheckedTimetable => 'Χωρίς ελεγμένο ωράριο';

  @override
  String get muniNoMoreTodayShort => 'Κανένα άλλο δρομολόγιο σήμερα';

  @override
  String get muniTimesFromStart =>
      'Οι ώρες είναι από την αφετηρία που γράφει ο δήμος, όχι από αυτή τη στάση.';

  @override
  String get helpDelayUpTo2 => 'έως 2′ ή νωρίτερα';

  @override
  String get helpDelayOver10 => 'πάνω από 10′';

  @override
  String get helpDelayNoTrip => 'χωρίς δρομολόγιο';

  @override
  String get helpDelayTitle => 'Καθυστέρηση από το πρόγραμμα';

  @override
  String get helpBus =>
      'Λεωφορείο. Το χρώμα του δείχνει πόσο αργεί σε σχέση με το πρόγραμμα.';

  @override
  String get helpMyBus =>
      'Λεωφορείο μιας από τις γραμμές σου: έχει το χρώμα της γραμμής, και το δαχτυλίδι γύρω του δείχνει την καθυστέρηση.';

  @override
  String get helpDirection =>
      'Η κατεύθυνση που πηγαίνει. Λείπει όταν δεν είναι γνωστή.';

  @override
  String get helpFaded =>
      'Αχνό: η θέση του είναι παλιά, πάνω από 1½ λεπτό. Δίπλα γράφει πόσο παλιά (π.χ. 2′).';

  @override
  String get helpBlueRing =>
      'Μπλε δαχτυλίδι: το λεωφορείο ή η γραμμή που άνοιξες.';

  @override
  String get helpRoute =>
      'Η διαδρομή, με βέλη προς τα πού πηγαίνει. Κάθε κατεύθυνση έχει τη δική της λωρίδα.';

  @override
  String get helpStop => 'Στάση. Πάτα τη για να δεις τι έρχεται.';

  @override
  String get helpTapEmpty =>
      'Πάτα σε κενό σημείο του χάρτη για να κλείσεις ό,τι είναι ανοιχτό.';

  @override
  String get helpDataTitle => 'Από πού έρχονται τα δεδομένα';

  @override
  String get helpPosition => 'Θέση';

  @override
  String get helpPositionText =>
      'Κάθε λεωφορείο στέλνει το GPS του στον ΟΑΣΑ. Ο server μας το διαβάζει κάθε 30″ περίπου. Ανάμεσα σε δύο θέσεις η εφαρμογή κινεί το λεωφορείο πάνω στη διαδρομή του, με την ταχύτητά του.';

  @override
  String get helpEta => 'Χρόνος άφιξης';

  @override
  String get helpEtaText =>
      'Τον υπολογίζει η εφαρμογή: από το πού είναι το λεωφορείο και την τυπική ταχύτητα κάθε κομματιού του δρόμου (από τις θέσεις των τελευταίων 14 ημερών). Δεν είναι η πρόβλεψη του ΟΑΣΑ.';

  @override
  String get helpDelay => 'Καθυστέρηση';

  @override
  String get helpDelayText =>
      'Σύγκριση με το πρόγραμμα του ΟΑΣΑ για το δρομολόγιο που κάνει το λεωφορείο.';

  @override
  String get helpTilde => '«~» πριν από έναν χρόνο';

  @override
  String get helpTildeText =>
      'Χωρίς σύνδεση: εκτίμηση από τα τελευταία δεδομένα. Διορθώνεται μόλις βρεθεί σήμα.';

  @override
  String get lineSpeedTitle => 'Ταχύτητα γραμμής';

  @override
  String get lineSpeedDaysFailed => 'Δεν φόρτωσαν τα στατιστικά των ημερών.';

  @override
  String get lineSpeedNext2km => 'Τα επόμενα 2 χλμ';

  @override
  String lineSpeedAheadHint(int kmh) {
    return 'Η συνήθης ταχύτητα ανά 200 μ. τέτοια μέρα και ώρα· η γραμμή είναι το λεωφορείο τώρα ($kmh χλμ/ώ).';
  }

  @override
  String get lineSpeedNoData =>
      'Δεν υπάρχουν μετρήσεις για τη γραμμή τις τελευταίες μέρες.';

  @override
  String lineSpeedLastDays(int n) {
    return 'Τις τελευταίες $n μέρες';
  }

  @override
  String get lineSpeedKmhWeekdays => 'χλμ/ώ καθημερινές';

  @override
  String get lineSpeedKmhWeekends => 'χλμ/ώ Σαββατοκύριακα';

  @override
  String lineSpeedRank(int place, int total) {
    return 'Χθες: $placeη πιο αργή από $total γραμμές.';
  }

  @override
  String lineSpeedDayKmh(String date, String kmh) {
    return '$date: $kmh χλμ/ώ';
  }

  @override
  String get lineSpeedWeekday => 'καθημερινή';

  @override
  String get lineSpeedWeekend => 'Σαββατοκύριακο';

  @override
  String get lineSpeedFooter =>
      'Μέση ταχύτητα όλης της μέρας, με τις στάσεις. Πηγή: καταγραφές θέσεων του ΟΑΣΑ από τον server μας.';

  @override
  String get lineSpeedMon => 'Δε';

  @override
  String get lineSpeedTue => 'Τρ';

  @override
  String get lineSpeedWed => 'Τε';

  @override
  String get lineSpeedThu => 'Πε';

  @override
  String get lineSpeedFri => 'Πα';

  @override
  String get lineSpeedSat => 'Σα';

  @override
  String get lineSpeedSun => 'Κυ';

  @override
  String alertNoSchedule(String line) {
    return 'Δεν βρέθηκε πρόγραμμα για το $line.';
  }

  @override
  String alertLastGone(String line, String time) {
    return 'Το τελευταίο $line πέρασε ήδη (~$time).';
  }

  @override
  String alertLastNoteTitle(String line) {
    return 'Σε λίγο περνά το τελευταίο $line';
  }

  @override
  String alertLastNoteBody(String stop, String time, String departs) {
    return 'Από $stop ~$time (φεύγει $departs από την αφετηρία).';
  }

  @override
  String alertLastSet(int before, String line, String time) {
    return 'Θα σε ειδοποιήσουμε $before′ πριν: το τελευταίο $line περνά ~$time.';
  }

  @override
  String alertLastSetDay(int before, String line, String day, String time) {
    return 'Θα σε ειδοποιήσουμε $before′ πριν: το τελευταίο $line περνά $day ~$time.';
  }

  @override
  String get alertOnMonday => 'τη Δευτέρα';

  @override
  String get alertOnTuesday => 'την Τρίτη';

  @override
  String get alertOnWednesday => 'την Τετάρτη';

  @override
  String get alertOnThursday => 'την Πέμπτη';

  @override
  String get alertOnFriday => 'την Παρασκευή';

  @override
  String get alertOnSaturday => 'το Σάββατο';

  @override
  String get alertOnSunday => 'την Κυριακή';

  @override
  String get alertScheduleOffline =>
      'Δεν φόρτωσε το πρόγραμμα. Δοκίμασε ξανά με σύνδεση.';

  @override
  String get alertNoLocation =>
      'Δεν βρέθηκε η θέση σου (άδεια ή GPS). Βάλε τον χρόνο περπατήματος με το χέρι.';

  @override
  String get alertWeeklySet => 'Κανόνας: Δε–Πα τέτοια ώρα.';

  @override
  String get alertWeeklyInexact =>
      'Χωρίς άδεια για ακριβή ξυπνητήρια μπορεί να ξεκινά λίγα λεπτά αργότερα.';

  @override
  String alertLeaveSet(String line) {
    return 'Θα σου πούμε πότε να φύγεις για το $line.';
  }

  @override
  String alertSet(String line) {
    return 'Θα σε ειδοποιήσουμε για το $line.';
  }

  @override
  String get alertWalkQuestion => 'Πόσο απέχεις από τη στάση;';

  @override
  String get alertWalkExplain =>
      'Με τη θέση σου υπολογίζεται πόσο περπατάς ως τη στάση και πότε να ξεκινήσεις, για να είσαι εκεί έγκαιρα. Η θέση μένει στο κινητό.';

  @override
  String get alertUseMyLocation => 'Χρήση της θέσης μου';

  @override
  String get alertLeaveNow => 'Φύγε τώρα';

  @override
  String alertLeaveIn(int n) {
    return 'Φύγε σε $n′';
  }

  @override
  String alertAtClock(String time) {
    return 'στις $time';
  }

  @override
  String alertWalkTo(int n, String stop) {
    return 'περπάτημα $n′ ως $stop';
  }

  @override
  String get alertTooLate => 'μάλλον δεν προλαβαίνεις αυτό';

  @override
  String alertBarNow(int n) {
    return 'τώρα · $n′';
  }

  @override
  String alertBarWalk(int n) {
    return 'περπάτημα $n′';
  }

  @override
  String alertBarWait(int n) {
    return 'περιμένεις $n′';
  }

  @override
  String get alertBeAtStop => 'Θέλω να είμαι στη στάση';

  @override
  String alertMarginBefore(int n) {
    return '$n′ πριν';
  }

  @override
  String get alertWalk => 'Περπάτημα';

  @override
  String get alertLeaveLateHint =>
      'Αν το λεωφορείο αργήσει, σου λέμε να φύγεις αργότερα: ο χρόνος διορθώνεται με κάθε νέα θέση του λεωφορείου.';

  @override
  String get alertBeforeArrives => 'πριν φτάσει';

  @override
  String alertStopsBefore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'στάσεις πριν',
      one: 'στάση πριν',
    );
    return '$_temp0';
  }

  @override
  String alertTitle(String stop) {
    return 'Ειδοποίηση για τη στάση $stop';
  }

  @override
  String alertToward(String headsign) {
    return 'προς $headsign';
  }

  @override
  String get alertNearStart =>
      'Η στάση σου είναι κοντά στην αφετηρία: θα σε ειδοποιήσουμε μόλις ξεκινήσει.';

  @override
  String get alertMeansNow => 'Τώρα αυτό σημαίνει';

  @override
  String get alertWhenAt => 'όταν είναι στο ';

  @override
  String alertWhenAtTail(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n στάσεις πριν',
      one: '$n στάση πριν',
    );
    return ', $_temp0';
  }

  @override
  String get alertTimeUpdates =>
      'Ο χρόνος διορθώνεται με κάθε νέα θέση του λεωφορείου.';

  @override
  String get alertLeaveButton => 'Πες μου πότε να φύγω';

  @override
  String alertNotifyMinutes(int n) {
    return 'Ειδοποίησέ με $n′ πριν';
  }

  @override
  String alertNotifyStops(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n στάσεις',
      one: '$n στάση',
    );
    return 'Ειδοποίησέ με $_temp0 πριν';
  }

  @override
  String get alertMoreOptions => 'Περισσότερες επιλογές';

  @override
  String get alertModeMinutes => 'Λεπτά πριν';

  @override
  String get alertModeStops => 'Στάσεις πριν';

  @override
  String get alertModeLeave => 'Φύγε εγκαίρως';

  @override
  String get alertLiveLockScreen => 'Live στην οθόνη κλειδώματος';

  @override
  String get alertLiveLockScreenSub => 'Δείχνει την πορεία ως τη στάση σου';

  @override
  String get alertLateToo => 'Πες μου και αν αργεί';

  @override
  String alertLateTooSub(int n) {
    return 'Μία ειδοποίηση όταν ένα λεωφορείο για τη στάση σου έχει καθυστέρηση $n′ ή παραπάνω';
  }

  @override
  String get alertWeekdays => 'Κάθε καθημερινή τέτοια ώρα;';

  @override
  String get alertLastOfDay => 'Για το τελευταίο της ημέρας';

  @override
  String get alertLastOfDaySub =>
      'Ειδοποίηση 15′ πριν περάσει από εδώ, από το πρόγραμμα';

  @override
  String ruleEditMinutesBefore(int n) {
    return '$n′ πριν φτάσει';
  }

  @override
  String ruleEditStopsBefore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n στάσεις πριν φτάσει',
      one: '$n στάση πριν φτάσει',
    );
    return '$_temp0';
  }

  @override
  String get ruleEditWhenLeave => 'πότε να φύγω';

  @override
  String get ruleEditTitle => 'Κανόνας';

  @override
  String get ruleEditNoStop => 'Πρώτα αποθήκευσε μια στάση (καρτέλα Στάσεις).';

  @override
  String get ruleEditEvery => 'Κάθε';

  @override
  String get ruleEditFrom => 'από';

  @override
  String get ruleEditUntil => 'ως';

  @override
  String get ruleEditTellMe => 'πες μου';

  @override
  String get ruleEditForThe => 'για το';

  @override
  String get ruleEditAt => 'στο';

  @override
  String ruleEditNotServed(String line) {
    return 'Το $line δεν σταματά σε αυτή τη στάση (ή είναι το τέρμα του).';
  }

  @override
  String ruleEditLeaveMath(int walk, int n) {
    return 'Περπάτημα $walk′ + να είσαι εκεί 5′ νωρίτερα = ειδοποίηση $n′ πριν φτάσει.';
  }

  @override
  String get ruleEditEndAfterStart => 'Το τέλος πρέπει να είναι μετά την αρχή.';

  @override
  String ruleEditLateSub(int n) {
    return 'Όταν η καθυστέρηση φτάσει $n′';
  }

  @override
  String get ruleEditEarlier => '15′ νωρίτερα';

  @override
  String get ruleEditLater => '15′ αργότερα';

  @override
  String get ruleEditPickStopFirst => 'Διάλεξε πρώτα στάση.';

  @override
  String get rulesDayMon => 'Δε';

  @override
  String get rulesDayTue => 'Τρ';

  @override
  String get rulesDayWed => 'Τε';

  @override
  String get rulesDayThu => 'Πε';

  @override
  String get rulesDayFri => 'Πα';

  @override
  String get rulesDaySat => 'Σα';

  @override
  String get rulesDaySun => 'Κυ';

  @override
  String get rulesMonFri => 'Δε–Πα';

  @override
  String get rulesEveryDay => 'Κάθε μέρα';

  @override
  String get rulesWeekend => 'Σα–Κυ';

  @override
  String rulesMinutesBefore(int n) {
    return '$n′ πριν';
  }

  @override
  String rulesStopsBefore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n στάσεις πριν',
      one: '$n στάση πριν',
    );
    return '$_temp0';
  }

  @override
  String get rulesAndIfLate => 'και αν αργεί';

  @override
  String get rulesNewRule => 'Νέος κανόνας';

  @override
  String get rulesNow => 'Τώρα';

  @override
  String get rulesNowEmpty =>
      'Πάτα το καμπανάκι δίπλα σε μια γραμμή στη στάση σου.';

  @override
  String rulesTrip(String line, String stop) {
    return 'Ταξίδι με το $line · κατεβαίνεις $stop';
  }

  @override
  String get rulesStoppedFromCard => 'Σταμάτησε από την κάρτα live';

  @override
  String rulesUntil(String time) {
    return 'ως $time';
  }

  @override
  String get rulesWeekly => 'Κάθε εβδομάδα';

  @override
  String get rulesWeeklyEmpty =>
      'Π.χ. «Δε–Πα 08:00–08:40, 5′ πριν το 602 στη στάση σου».';

  @override
  String get rulesPaused => 'Σε παύση';

  @override
  String get rulesStoppedToday => 'Σταμάτησε για σήμερα';

  @override
  String get rulesRunningNow => 'Τρέχει τώρα';

  @override
  String rulesNext(String when, String time) {
    return 'Επόμενη: $when $time';
  }

  @override
  String get rulesToday => 'σήμερα';

  @override
  String get rulesTomorrow => 'αύριο';

  @override
  String rulesInDays(int n) {
    return 'σε $n μέρες';
  }

  @override
  String get rulesResume => 'Συνέχισε';

  @override
  String get rulesExactHint =>
      'Οι κανόνες μπορεί να ξεκινούν λίγα λεπτά αργότερα: το Android δεν μας έχει δώσει άδεια για ακριβή ξυπνητήρια.';

  @override
  String get rulesGrant => 'Δώσε άδεια';

  @override
  String get followNoLocation =>
      'Χρειάζεται άδεια τοποθεσίας για να καταλάβει η εφαρμογή πότε ανεβαίνεις.';

  @override
  String get followStopNotOnLine => 'Η στάση δεν βρέθηκε στη γραμμή.';

  @override
  String get followNotStarted =>
      'Δεν ξεκίνησε η ειδοποίηση. Πάτα ξανά με την εφαρμογή ανοιχτή.';

  @override
  String get followLineNotLoaded =>
      'Δεν φόρτωσε η γραμμή. Δοκίμασε ξανά με σύνδεση.';

  @override
  String followReady(String line, String stop) {
    return 'Έτοιμο. Ανέβα στο $line και θα σε ειδοποιήσουμε μία στάση πριν από $stop, ακόμη κι αν η εφαρμογή είναι κλειστή.';
  }

  @override
  String get followStop => 'Σταμάτα';

  @override
  String get followButton => 'Πες μου πότε να κατέβω';

  @override
  String get rideNoBus =>
      'Δεν βρέθηκε λεωφορείο κοντά σου. Διάλεξέ το στον χάρτη και πάτα «Πού κατεβαίνω;».';

  @override
  String get rideAtTerminus =>
      'Το λεωφορείο είναι στο τέρμα: καμία στάση μετά.';

  @override
  String get rideWhere => 'Πού κατεβαίνεις;';

  @override
  String get rideVibrate =>
      'Θα δονηθεί το κινητό μία στάση πριν: «Κατέβα στην επόμενη».';

  @override
  String get rideVibrateAlerts =>
      'Θα δονηθεί το κινητό μία στάση πριν: «Κατέβα στην επόμενη». Το βλέπεις και στις Ειδοποιήσεις.';

  @override
  String get rideOnBoard => 'Είσαι μέσα · θα σε ειδοποιήσουμε';

  @override
  String get rideNoPermission => 'Χωρίς άδεια ειδοποιήσεων';

  @override
  String get rideGetOffAt => 'Κατεβαίνεις στο';

  @override
  String rideAbout(String mins) {
    return 'περίπου $mins';
  }

  @override
  String get favsAddStop => 'Στάση';

  @override
  String get favsWhereHome => 'Πού είναι το σπίτι σου;';

  @override
  String get favsPlacesSub =>
      'Μέρη: σπίτι, δουλειά και άλλα · μένουν μόνο στο κινητό';

  @override
  String get favsPlaces => 'Μέρη';

  @override
  String get favsMorning => 'Πρωί: πρώτα η στάση του σπιτιού';

  @override
  String get favsAfternoon => 'Απόγευμα: πρώτα η στάση της δουλειάς';

  @override
  String get favsEmpty => 'Καμία αποθηκευμένη στάση ακόμη. Πάτα «+ Στάση».';

  @override
  String get favsStops => 'Στάσεις';

  @override
  String get favsLines => 'Γραμμές';

  @override
  String get favsLinesEmpty =>
      'Καμία γραμμή ακόμη. Πάτα το αστέρι σε μια γραμμή για να τη βλέπεις εδώ.';

  @override
  String favsLastHome(String line) {
    return 'Το τελευταίο $line για το σπίτι';
  }

  @override
  String favsLastHomeBody(
    String departs,
    String from,
    String time,
    String stop,
  ) {
    return 'Φεύγει $departs από $from και περνά ~$time από $stop. Πρόγραμμα, όχι live.';
  }

  @override
  String get favsWillNotify => 'Θα σε ειδοποιήσουμε';

  @override
  String get favsNoGpsBus => 'κανένα λεωφορείο με GPS τώρα';

  @override
  String favsOnRoad(int n) {
    return '$n στον δρόμο';
  }

  @override
  String get favsAllOnTime => 'όλα στην ώρα τους';

  @override
  String favsLate(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n αργούν',
      one: '$n αργεί',
    );
    return '$_temp0';
  }

  @override
  String get favsOptions => 'Επιλογές';

  @override
  String get favsIsHome => 'Είναι το σπίτι';

  @override
  String get favsIsWork => 'Είναι η δουλειά';

  @override
  String get favsNeither => 'Ούτε σπίτι ούτε δουλειά';

  @override
  String get favsRemove => 'Αφαίρεση';

  @override
  String favsQuiet(String lines) {
    return 'Χωρίς λεωφορείο με GPS τώρα: $lines';
  }

  @override
  String favsAllLines(int n) {
    return 'Όλες οι γραμμές εδώ ($n) ›';
  }

  @override
  String get addStopTitle => 'Ποια στάση θέλεις να κρατήσεις;';

  @override
  String get addStopSub =>
      'Θα τη βρίσκεις στα αγαπημένα, με τις γραμμές που διαλέγεις.';

  @override
  String get addStopSearchHint => 'Γράψε το όνομα της στάσης';

  @override
  String get addStopSearchHintOr => 'Ή γράψε το όνομα της στάσης';

  @override
  String get addStopNone => 'Δεν βρέθηκε στάση. Γράψε το όνομά της.';

  @override
  String addStopMeters(int m) {
    return '$m μ.';
  }

  @override
  String get addStopWhichLines => 'Ποιες γραμμές σε νοιάζουν εδώ;';

  @override
  String addStopMaxLines(int n) {
    return 'Ως $n γραμμές συνολικά.';
  }

  @override
  String get addStopPickStop => 'Διάλεξε στάση';

  @override
  String get addStopPickLine => 'Διάλεξε τουλάχιστον μία γραμμή';

  @override
  String linesPickerMax(int n) {
    return 'Ως $n γραμμές σε όλη την εφαρμογή.';
  }

  @override
  String stopReturn(String place) {
    return '$place (επιστροφή)';
  }

  @override
  String stopBellOn(String line) {
    return 'Ειδοποίηση για το $line: ενεργή';
  }

  @override
  String stopBellOff(String line) {
    return 'Ειδοποίησέ με για το $line';
  }

  @override
  String stopLinesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n γραμμές',
      one: '$n γραμμή',
    );
    return '$_temp0';
  }

  @override
  String stopAcross(int m) {
    return 'Απέναντι στάση · $m μ.';
  }

  @override
  String get stopSave => 'Αποθήκευση στάσης';

  @override
  String get stopSaved => 'Αποθηκευμένη στάση';

  @override
  String get stopHowToGet => 'Πώς πάω εκεί';

  @override
  String get stopTripFrom => 'Ταξίδι από εδώ';

  @override
  String get stopEstimate =>
      'Οι χρόνοι είναι εκτίμηση από τα τελευταία δεδομένα και την ταχύτητα που έχει συνήθως η γραμμή. Διορθώνονται μόλις βρεθεί σήμα.';

  @override
  String get stopNoBus => 'Κανένα λεωφορείο με GPS δεν έρχεται τώρα.';

  @override
  String get stopYourLines => 'Οι γραμμές σου';

  @override
  String get stopAlsoHere => 'Περνούν επίσης';

  @override
  String stopAllLines(int n) {
    return 'Όλες οι γραμμές · +$n ›';
  }

  @override
  String get stopMissed =>
      'Δεν ξεκίνησαν · δεν φάνηκε λεωφορείο να φεύγει από την αφετηρία';

  @override
  String stopMissedRun(String headsign, String time) {
    return '→ $headsign · των $time';
  }

  @override
  String get stopOtherOption => 'Άλλη επιλογή';

  @override
  String get stopPlanned => 'Δεν ξεκίνησαν ακόμη · από το πρόγραμμα';

  @override
  String get stopPlannedNote =>
      'Ώρα αναχώρησης από την αφετηρία + η διαδρομή ως εδώ με μέση ταχύτητα. Όχι live.';

  @override
  String stopQuiet(String lines) {
    return 'Χωρίς λεωφορείο κοντά τώρα: $lines';
  }

  @override
  String get stopFixSent =>
      'Έστειλες διόρθωση θέσης για αυτή τη στάση. Ευχαριστούμε!';

  @override
  String get stopWrongPlace => 'Λάθος θέση;';

  @override
  String get vehicleOffline =>
      'Δεν φορτώνει το λεωφορείο: χωρίς σύνδεση. Νέα προσπάθεια σε λίγο.';

  @override
  String vehicleGone(String id) {
    return 'Το λεωφορείο #$id δεν στέλνει θέση τώρα: μάλλον τελείωσε το δρομολόγιό του.';
  }

  @override
  String vehicleSeeLine(String line) {
    return 'Δες τα λεωφορεία του $line';
  }

  @override
  String vehicleAtYourStop(String stop) {
    return 'στη στάση σου · $stop';
  }

  @override
  String vehicleAtNextStop(String stop) {
    return 'στην επόμενη στάση · $stop';
  }

  @override
  String get vehicleNotify => 'Ειδοποίησέ με';

  @override
  String get vehicleWhereGetOff => 'Πού κατεβαίνω;';

  @override
  String get vehicleDetails => 'Λεπτομέρειες';

  @override
  String get vehicleNoSpeed => '— χλμ/ώ';

  @override
  String vehicleSpeed(int speed) {
    return '$speed χλμ/ώ';
  }

  @override
  String get vehicleLineSpeeds => 'ταχύτητες γραμμής';

  @override
  String vehicleUsually(int usual) {
    return 'συνήθως $usual';
  }

  @override
  String vehicleFixAge(String ago) {
    return 'θέση πριν $ago';
  }

  @override
  String vehicleId(String id) {
    return 'όχημα $id';
  }

  @override
  String vehicleTrip(String trip) {
    return 'δρομολόγιο $trip';
  }

  @override
  String get vehicleNextStops => 'Επόμενες στάσεις';

  @override
  String vehicleAllNext(int n) {
    return 'Όλες οι επόμενες ($n)';
  }

  @override
  String get vehicleUnknownTrip =>
      'Δεν ξέρουμε ακόμη ποιο δρομολόγιο κάνει το λεωφορείο.';

  @override
  String vehicleYourStop(String stop) {
    return '$stop · η στάση σου';
  }

  @override
  String get vehicleWhichStop => 'Σε ποια στάση;';

  @override
  String get vehicleWhichStopSub =>
      'Θα σε ειδοποιήσουμε πριν φτάσει εκεί το λεωφορείο.';

  @override
  String get goHomeKickerHome => 'ΓΥΡΝΑΣ ΣΠΙΤΙ';

  @override
  String get goHomeKickerWork => 'ΠΑΜΕ ΔΟΥΛΕΙΑ';

  @override
  String goHomeKickerFrom(String stop) {
    return 'ΑΠΟ $stop';
  }

  @override
  String get goHomeAskHomeSub =>
      'Αρκεί μια περιοχή. Μένει μόνο στο κινητό σου.';

  @override
  String goHomeNoneComing(String lines) {
    return 'Κανένα από $lines δεν έρχεται τώρα';
  }

  @override
  String goHomeNext(String line, String toward) {
    return 'Το $line → $toward';
  }

  @override
  String goHomeWith(String line, String stop) {
    return 'Με το $line από $stop';
  }

  @override
  String get goHomeNoDirect => 'Χωρίς απευθείας λεωφορείο';

  @override
  String get goHomeMyLocation => 'Η θέση μου';

  @override
  String goHomePassesIn(String mins) {
    return 'περνά σε $mins';
  }

  @override
  String get goHomeTapForRoute => 'Πάτα για διαδρομή με αλλαγή ή μετρό.';

  @override
  String get goHomeLeaveIn => 'φύγε σε';

  @override
  String goHomeLast(int n, String runs) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'τελευταία',
      one: 'τελευταίο',
    );
    return '$_temp0: $runs';
  }

  @override
  String goHomeRunAt(String line, String time) {
    return '$line στις $time';
  }

  @override
  String get stopfixThanks => 'Ευχαριστούμε, το λάβαμε!';

  @override
  String get stopfixNotImmediate =>
      'Η στάση δεν αλλάζει αμέσως: κάθε πρόταση ελέγχεται με το GPS των λεωφορείων.';

  @override
  String get stopfixTapMap => 'Πάτα στον χάρτη εκεί που είναι το κολωνάκι';

  @override
  String stopfixTooFar(int m) {
    return 'Πάνω από $m μ. από τη στάση. Φέρε την πιο κοντά.';
  }

  @override
  String get stopfixFailed =>
      'Δεν στάλθηκε. Έλεγξε τη σύνδεση και ξαναδοκίμασε.';

  @override
  String get stopfixKnown => 'Η μικρή τελεία είναι η θέση που ξέρουμε.';

  @override
  String stopfixMoved(int m) {
    return 'Μετακίνηση $m μ.';
  }

  @override
  String get stopfixSending => 'Αποστολή…';

  @override
  String get stopfixSend => 'Αποστολή';

  @override
  String get stopfixStreetView => 'Δες το σημείο στο Street View ›';

  @override
  String get stopfixPrivacy =>
      'Στέλνεται η θέση της πινέζας, η στάση και ένας τυχαίος κωδικός συσκευής.';

  @override
  String get menuCity => 'Πόλη';

  @override
  String get menuPlanner => 'Διαδρομή';

  @override
  String get menuLines => 'Γραμμές';

  @override
  String get menuUpdates => 'Ενημερώσεις';

  @override
  String get menuAlerts => 'Ειδοποιήσεις';

  @override
  String get menuPlaces => 'Μέρη';

  @override
  String get menuWidgets => 'Widgets';

  @override
  String get menuStats => 'Στατιστικά';

  @override
  String get menuSettings => 'Ρυθμίσεις';

  @override
  String get menuAbout => 'Σχετικά';

  @override
  String get menuHowItWorks => 'Πώς δουλεύει';

  @override
  String get menuCityBuses => 'λεωφορεία';

  @override
  String get menuLinesError => 'Δεν φόρτωσαν. Δοκίμασε ξανά';

  @override
  String get menuLinesHint => 'Αριθμός ή όνομα γραμμής';

  @override
  String get menuUpdatesSoon =>
      'Εδώ θα βλέπεις τις ανακοινώσεις του ΟΑΣΑ: απεργίες, αλλαγές γραμμών. Έρχεται σύντομα.';

  @override
  String get menuPlaceAdd => 'Πρόσθεσε διεύθυνση ή περιοχή';

  @override
  String get menuPlaceApprox => 'περίπου';

  @override
  String get menuOtherPlace => 'Άλλο μέρος';

  @override
  String get menuPlacesNote =>
      'Αρκεί μια περιοχή. Δεν κρατάμε κανένα δεδομένο: τα μέρη μένουν μόνο στο κινητό σου. Με το «Σπίτι» βλέπεις πώς γυρνάς· με τη «Δουλειά», πώς πας το πρωί.';

  @override
  String get menuNewPlace => 'Νέο μέρος';

  @override
  String get menuNewPlaceHint => 'Όνομα, π.χ. Σχολείο';

  @override
  String get menuWidgetStop => '«Η στάση μου»';

  @override
  String get menuWidgetStopBody =>
      'Οι επόμενες αφίξεις στην αγαπημένη σου στάση.';

  @override
  String get menuWidgetHome => '«Γυρνάς σπίτι»';

  @override
  String get menuWidgetHomeBody =>
      'Τα τελευταία λεωφορεία για το σπίτι σήμερα. Γεμίζει όταν ανοίξεις την εφαρμογή μακριά από το σπίτι.';

  @override
  String get menuLinkIdea => 'Πρότεινε μια ιδέα';

  @override
  String get menuLinkWrongStop => 'Λάθος θέση στάσης; Πες μας';

  @override
  String get menuLinkAbout => 'Σχετικά · δεδομένα · ανοιχτό API';

  @override
  String get menuLinkWeb => 'Ο χάρτης στο web';

  @override
  String get menuUnofficialNote =>
      'Ανεπίσημη εφαρμογή. Δεν έχει σχέση με τον ΟΑΣΑ, τον ΟΑΣΘ, τη ΣΤΑΣΥ ή την Hellenic Train, και δεν εκπροσωπεί κανέναν από αυτούς.';

  @override
  String menuVersion(String version) {
    return 'Έκδοση $version';
  }

  @override
  String get menuTerms => 'Όροι χρήσης';

  @override
  String get menuPrivacy => 'Πολιτική απορρήτου';

  @override
  String get menuLicenses => 'Άδειες ανοιχτού κώδικα';

  @override
  String get menuDataSources =>
      'Πηγές δεδομένων: ΟΑΣΑ (GTFS, άδεια CC BY-NC, και δημόσια δεδομένα telematics) · ΟΑΣΘ (δημόσια δεδομένα, data.gov.gr) · ΣΤΑΣΥ (GTFS) · Hellenic Train (railway.gov.gr). Χάρτης: OpenFreeMap, © OpenStreetMap contributors. Αναζήτηση διευθύνσεων: Photon (komoot), © OpenStreetMap contributors.';

  @override
  String get settingsTheme => 'Θέμα';

  @override
  String get settingsThemeSystem => 'Σύστημα';

  @override
  String get settingsThemeLight => 'Ανοιχτό';

  @override
  String get settingsThemeDark => 'Σκούρο';

  @override
  String get settingsWalk => 'Περπάτημα ως τη στάση του σπιτιού';

  @override
  String get settingsWalkNote => 'Για τον κανόνα «πότε να φύγω».';

  @override
  String get settingsLiveCard => 'Live κάρτα στις νέες ειδοποιήσεις';

  @override
  String get settingsLiveCardBody =>
      'Η πορεία του λεωφορείου στην οθόνη κλειδώματος. Αλλάζει και σε κάθε ειδοποίηση.';

  @override
  String get settingsLastBus =>
      'Παρασκευή και Σάββατο βράδυ: το τελευταίο για το σπίτι';

  @override
  String get settingsLastBusBody =>
      'Στις 21:00 μια ειδοποίηση με το τελευταίο λεωφορείο της στάσης «Σπίτι»';

  @override
  String get settingsMapHelp => 'Πώς διαβάζεται ο χάρτης';

  @override
  String get settingsMapHelpBody =>
      'Χρώματα, σύμβολα, από πού έρχονται οι χρόνοι';

  @override
  String get settingsDeleteAll => 'Διαγραφή όλων των δεδομένων';

  @override
  String get settingsDeleteAllBody =>
      'Αγαπημένα, μέρη, ειδοποιήσεις, ρυθμίσεις. Η εφαρμογή ξεκινά από την αρχή.';

  @override
  String get settingsDeleteAllTitle => 'Διαγραφή όλων των δεδομένων;';

  @override
  String get settingsDeleteAllWarning =>
      'Θα διαγραφούν από αυτό το κινητό τα αγαπημένα, τα μέρη, οι ειδοποιήσεις και οι ρυθμίσεις. Δεν αναιρείται.';

  @override
  String get welcomeHomeTitle => 'Καλώς ήρθες στις Στάσεις';

  @override
  String get welcomeHomeBody =>
      'Κάθε λεωφορείο της πόλης στον χάρτη, ζωντανά. Το χρώμα του δείχνει αν αργεί σε σχέση με το πρόγραμμα.';

  @override
  String get welcomeStopTitle => 'Στάσεις και αγαπημένα';

  @override
  String get welcomeStopBody =>
      'Πάτα μια στάση για να δεις τι έρχεται και σε πόσα λεπτά. Με το αστέρι την κρατάς στα αγαπημένα.';

  @override
  String get welcomeAlertTitle => 'Πες μου πότε να φύγω';

  @override
  String get welcomeAlertBody =>
      'Πάτα το καμπανάκι δίπλα σε ένα λεωφορείο και θα σε ειδοποιήσουμε λίγο πριν φτάσει. Ή φτιάξε κανόνα για κάθε πρωί.';

  @override
  String get welcomePlanTitle => 'Από εδώ ως εκεί';

  @override
  String get welcomePlanBody =>
      'Η «Διαδρομή» στο μενού βρίσκει πώς πας κάπου, με τις αλλαγές και τους χρόνους από τα λεωφορεία που κινούνται τώρα.';

  @override
  String get welcomeSkip => 'Παράλειψη';

  @override
  String get welcomeStart => 'Ξεκίνα';

  @override
  String get welcomePermissionsTitle => 'Δύο άδειες';

  @override
  String get welcomePermissionsBody =>
      'Και οι δύο είναι προαιρετικές. Τις αλλάζεις όποτε θέλεις από τις ρυθμίσεις του κινητού.';

  @override
  String get welcomePrivacyTitle => 'Χωρίς λογαριασμό, διαφημίσεις ή tracking';

  @override
  String get welcomePrivacyBody =>
      'Η θέση σου, το σπίτι, η δουλειά και τα αγαπημένα μένουν μόνο στο κινητό σου.';

  @override
  String get welcomeLocationTitle => 'Τοποθεσία';

  @override
  String get welcomeLocationBody =>
      'Για τις στάσεις κοντά σου και τον χρόνο περπατήματος. Η θέση μένει στο κινητό.';

  @override
  String get welcomeNotificationsTitle => 'Ειδοποιήσεις';

  @override
  String get welcomeNotificationsBody =>
      'Για να σου λέμε πότε να φύγεις και πότε φτάνει το λεωφορείο σου.';

  @override
  String get welcomeGranted => 'Δόθηκε';

  @override
  String get welcomeDenied => 'Δεν δόθηκε · δοκίμασε ξανά';

  @override
  String get welcomeAllow => 'Επίτρεψε';

  @override
  String statsDayName(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'mon': 'Δευτέρα',
      'tue': 'Τρίτη',
      'wed': 'Τετάρτη',
      'thu': 'Πέμπτη',
      'fri': 'Παρασκευή',
      'sat': 'Σάββατο',
      'other': 'Κυριακή',
    });
    return '$_temp0';
  }

  @override
  String statsMonthName(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'jan': 'Ιανουαρίου',
      'feb': 'Φεβρουαρίου',
      'mar': 'Μαρτίου',
      'apr': 'Απριλίου',
      'may': 'Μαΐου',
      'jun': 'Ιουνίου',
      'jul': 'Ιουλίου',
      'aug': 'Αυγούστου',
      'sep': 'Σεπτεμβρίου',
      'oct': 'Οκτωβρίου',
      'nov': 'Νοεμβρίου',
      'other': 'Δεκεμβρίου',
    });
    return '$_temp0';
  }

  @override
  String statsDate(String weekday, int day, String month) {
    return '$weekday $day $month';
  }

  @override
  String get statsTitle => 'Στατιστικά δικτύου';

  @override
  String get statsTabYesterday => 'Χθες';

  @override
  String get statsTabTrends => 'Τάσεις';

  @override
  String get statsLongError => 'Δεν φόρτωσαν οι προηγούμενες μέρες.';

  @override
  String get statsNeedDays => 'Χρειάζονται τουλάχιστον 2 πλήρεις μέρες.';

  @override
  String statsLastDays(int count) {
    return 'Οι τελευταίες $count πλήρεις μέρες';
  }

  @override
  String get statsSpeedByHour => 'Μέση ταχύτητα ανά ώρα';

  @override
  String get statsSpeedNote =>
      'Η μπάρα: από την πιο αργή ως την πιο γρήγορη μέρα. Η τελεία: όλες μαζί.';

  @override
  String get statsWeekdaysWeekends => 'Καθημερινές και Σαββατοκύριακα';

  @override
  String statsKmhWeekdays(int count) {
    return 'χλμ/ώ καθημερινές ($count)';
  }

  @override
  String statsKmhWeekends(int count) {
    return 'χλμ/ώ Σ/Κ ($count)';
  }

  @override
  String get statsBusesByHour => 'Λεωφορεία ανά ώρα';

  @override
  String get statsLegendWeekday => 'καθημερινή';

  @override
  String get statsLegendWeekend => 'Σαββατοκύριακο';

  @override
  String statsChanged(String date) {
    return 'Γραμμές που άλλαξαν ($date)';
  }

  @override
  String statsComparedWeekdays(int count) {
    return 'Σε σχέση με $count προηγούμενες καθημερινές.';
  }

  @override
  String statsComparedWeekends(int count) {
    return 'Σε σχέση με $count προηγούμενες μέρες Σαββατοκύριακου.';
  }

  @override
  String get statsLongSource =>
      'Μόνο πλήρεις μέρες (χωρίς κενά στις καταγραφές). Πηγή: καταγραφές θέσεων του ΟΑΣΑ από τον server μας.';

  @override
  String get statsWorst => 'Χειρότερες γραμμές';

  @override
  String statsDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count μέρες',
      one: '1 μέρα',
    );
    return '$_temp0';
  }

  @override
  String get statsMissedTitle => 'Δρομολόγια που δεν έγιναν';

  @override
  String get statsNoLines => 'Καμία γραμμή με αρκετά δρομολόγια.';

  @override
  String statsMissedOf(int missed, int measured) {
    return '$missed από $measured δεν έγιναν';
  }

  @override
  String statsExpiredDays(int expired, int count) {
    return '$expired από τις $count μέρες μετρήθηκαν με παλιό πρόγραμμα: κάποια «χαμένα» δρομολόγια μπορεί να μην υπάρχουν πια.';
  }

  @override
  String get statsSlowest => 'Πιο αργές';

  @override
  String statsKmh(String speed) {
    return '$speed χλμ/ώ';
  }

  @override
  String statsHours(int count) {
    return '$count ώρες';
  }

  @override
  String get statsNoDelayNote =>
      'Καθυστέρηση ανά δρομολόγιο δεν καταγράφεται ακόμη· εδώ μετράνε τα χαμένα δρομολόγια και η ταχύτητα.';

  @override
  String statsTrend(String speed, String usual) {
    return '$speed χλμ/ώ (συνήθως $usual)';
  }

  @override
  String get statsDayError => 'Δεν φόρτωσαν τα στατιστικά.';

  @override
  String get statsBuses => 'λεωφορεία';

  @override
  String get statsLines => 'γραμμές';

  @override
  String get statsAvgKmh => 'μέση χλμ/ώ';

  @override
  String get statsSlowLines => 'Πιο αργές γραμμές';

  @override
  String get statsFastLines => 'Πιο γρήγορες γραμμές';

  @override
  String get statsDaySource =>
      'Πηγή: καταγραφές θέσεων του ΟΑΣΑ από τον server μας. Ανανεώνεται μία φορά τη μέρα.';

  @override
  String get statsTrips => 'Δρομολόγια';

  @override
  String statsTripsShare(int percent) {
    return 'Έγινε το $percent% των δρομολογίων';
  }

  @override
  String statsRunOf(int run, int measured) {
    return '$run από $measured';
  }

  @override
  String statsExpired(String date) {
    return 'Η σύγκριση γίνεται με το πρόγραμμα του ΟΑΣΑ της $date, γιατί νεότερο δεν έχει δημοσιευτεί. Μερικά δρομολόγια που λείπουν μπορεί να μην υπάρχουν πια.';
  }

  @override
  String statsUnseen(int count) {
    return '$count γραμμές χωρίς κανένα δρομολόγιο';
  }

  @override
  String statsKmHours(int km, int hours) {
    return '$km χλμ · $hours ώρες';
  }

  @override
  String widgetsLive(String time) {
    return 'ζωντανά: $time';
  }

  @override
  String widgetsLate(int minutes) {
    return 'αργεί $minutes′';
  }

  @override
  String widgetsEarly(int minutes) {
    return 'νωρίτερα $minutes′';
  }

  @override
  String get widgetsFromTimetable => 'από το πρόγραμμα';

  @override
  String get widgetsEstimate => 'εκτίμηση';

  @override
  String widgetsStopsAway(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count στάσεις μακριά',
      one: '1 στάση μακριά',
    );
    return '$_temp0';
  }

  @override
  String widgetsThen(String times) {
    return 'μετά $times';
  }

  @override
  String widgetsReturn(String headsign) {
    return '$headsign (επιστροφή)';
  }

  @override
  String get widgetsOffline => 'Χωρίς σύνδεση';

  @override
  String widgetsLastData(String ago) {
    return 'τελευταία δεδομένα πριν $ago';
  }

  @override
  String get widgetsLiveNote => 'Live';

  @override
  String widgetsUpdatedAt(String time) {
    return 'Τελευταία ενημέρωση $time';
  }

  @override
  String widgetsLineTooltip(String line) {
    return 'Η γραμμή $line';
  }

  @override
  String get lineRemoveMine => 'Βγάλε από τις γραμμές μου';

  @override
  String get lineAddMine => 'Στις γραμμές μου';

  @override
  String get lineMaxMine =>
      'Ως 5 γραμμές. Βγάλε μία από τις γραμμές σου πρώτα.';

  @override
  String get lineNow => 'Τώρα';

  @override
  String get lineTimetable => 'Δρομολόγια';

  @override
  String lineTo(String stop) {
    return 'προς $stop';
  }

  @override
  String lineFrom(String stop) {
    return 'από $stop';
  }

  @override
  String lineOtherDirection(String stop) {
    return 'Η άλλη κατεύθυνση: προς $stop';
  }

  @override
  String get lineAll => 'Όλες';

  @override
  String get lineStopsLink => 'στάσεις';

  @override
  String get lineStopsTitle => 'Στάσεις';

  @override
  String lineGaps(String gaps) {
    return 'Κενά από το μπροστινό: $gaps στάσεις';
  }

  @override
  String lineBigGap(int n) {
    return 'μεγάλο κενό μετά το $nο λεωφορείο';
  }

  @override
  String get lineScheduleError => 'Δεν φόρτωσαν τα δρομολόγια.';

  @override
  String get lineScheduleMissing => 'Τα δρομολόγια δεν είναι ακόμη διαθέσιμα.';

  @override
  String get lineNoRunsToday => 'Κανένα δρομολόγιο σήμερα.';

  @override
  String get lineExpired =>
      'Το πρόγραμμα του ΟΑΣΑ έχει λήξει: δείχνουμε τις ώρες του παλιού για την ίδια μέρα της εβδομάδας.';

  @override
  String lineRunsToday(int count) {
    return '$count δρομολόγια σήμερα';
  }

  @override
  String lineRanSoFar(int seen, int known) {
    return 'έγιναν $seen από $known ως τώρα';
  }

  @override
  String get lineSourceDaily =>
      'Πρόγραμμα ημέρας ΟΑΣΑ, ώρα αναχώρησης από την αφετηρία.';

  @override
  String get lineSource =>
      'Πρόγραμμα ΟΑΣΑ, ώρα αναχώρησης από την αφετηρία. Διαγραμμένη: δεν φάνηκε λεωφορείο.';

  @override
  String get lineNoGps => 'Κανένα λεωφορείο με GPS τώρα.';

  @override
  String get lineEnRoute => 'στη διαδρομή';

  @override
  String lineNextStop(String stop) {
    return 'επόμενη: $stop';
  }

  @override
  String get lineLoading => 'Φόρτωση…';

  @override
  String get lineNoneOnWay => 'Κανένα καθ’ οδόν τώρα';

  @override
  String lineAlertTooltip(String line, String stop) {
    return 'Ειδοποίηση για το $line στη στάση $stop';
  }

  @override
  String get lineWalkDirections => 'Οδηγίες με τα πόδια ως τη στάση';

  @override
  String get serviceHitChannelName => 'Το λεωφορείο έρχεται';

  @override
  String get serviceHitChannelDescription =>
      'Ειδοποίηση όταν το λεωφορείο πλησιάζει στη στάση σου';

  @override
  String get serviceLiveChannelName => 'Live πορεία λεωφορείου';

  @override
  String get serviceLiveChannelDescription =>
      'Η πορεία του λεωφορείου σου ως τη στάση';

  @override
  String get serviceExactAlarmTitle => 'Να ξεκινά ακριβώς στην ώρα του;';

  @override
  String get serviceExactAlarmBody =>
      'Το Android θέλει την άδεια «Ξυπνητήρια και υπενθυμίσεις» για αυτό. Θα ανοίξουν οι ρυθμίσεις: άνοιξε τον διακόπτη και γύρνα πίσω. Χωρίς αυτήν, ο κανόνας ξεκινά, αλλά ίσως λίγα λεπτά αργότερα.';

  @override
  String get serviceExactAlarmLater => 'Όχι τώρα';

  @override
  String get serviceExactAlarmOpenSettings => 'Άνοιξε τις ρυθμίσεις';

  @override
  String get serviceRunningTitle => 'Στάσεις · live';

  @override
  String get serviceRunningText => 'Οι ειδοποιήσεις σου είναι ενεργές';

  @override
  String get serviceRuleStartsTitle => 'Ξεκινά ο κανόνας σου';

  @override
  String get serviceRuleStartsBody =>
      'Άνοιξε την εφαρμογή για live ειδοποιήσεις.';

  @override
  String get serviceNudgeTitleFriday =>
      'Βράδυ Παρασκευής · το τελευταίο για το σπίτι';

  @override
  String get serviceNudgeTitleSaturday =>
      'Βράδυ Σαββάτου · το τελευταίο για το σπίτι';

  @override
  String serviceNudgeBody(String line, String stop) {
    return 'Δες πότε φεύγει το τελευταίο $line για $stop και βάλε ειδοποίηση.';
  }

  @override
  String serviceNudgeLastRun(String line, String time, String from) {
    return 'Το τελευταίο $line φεύγει $time από $from. Θες ειδοποίηση;';
  }

  @override
  String serviceBoardedTitle(String line) {
    return 'Είσαι στο $line';
  }

  @override
  String serviceOneStopBefore(String stop) {
    return 'Θα σε ειδοποιήσουμε μία στάση πριν από $stop.';
  }

  @override
  String serviceTripTitle(String line) {
    return 'Ταξίδι με το $line';
  }

  @override
  String serviceTripText(String stop) {
    return 'Μόλις ανέβεις, θα σε ειδοποιήσουμε μία στάση πριν από $stop.';
  }

  @override
  String get serviceIdleText =>
      'Θα σε ειδοποιήσουμε όταν πλησιάσει το λεωφορείο.';

  @override
  String get serviceNoBusYet => 'Δεν φαίνεται ακόμη λεωφορείο με GPS.';

  @override
  String serviceArrivingNow(String line, String stop) {
    return '$line · φτάνει τώρα στο $stop';
  }

  @override
  String serviceArrivingIn(String line, String stop, String eta) {
    return '$line · $stop σε $eta';
  }

  @override
  String serviceArrivesAt(String time) {
    return 'φτάνει $time';
  }

  @override
  String get serviceNextStop => 'επόμενη στάση';

  @override
  String get serviceOfflineEstimate => 'χωρίς σήμα, εκτίμηση';

  @override
  String get serviceOffline => 'χωρίς σήμα';

  @override
  String get serviceStop => 'Σταμάτα';

  @override
  String get homeWidgetMyStop => 'Η στάση μου';

  @override
  String homeWidgetNoBus(String place) {
    return '$place · κανένα λεωφορείο με GPS';
  }

  @override
  String ruleHitDelay(int min) {
    return 'καθυστέρηση $min′';
  }

  @override
  String ruleHitIn(int min) {
    return 'σε ~$min′';
  }

  @override
  String ruleHitNextStop(String line, String stop, String late) {
    return 'Το $line έρχεται: επόμενη στάση $stop$late.';
  }

  @override
  String ruleHitArrives(String line, String stop, String late, String eta) {
    return 'Το $line φτάνει στη στάση $stop$late$eta.';
  }

  @override
  String ruleHitStopsAway(
    String line,
    String stops,
    String stop,
    String late,
    String eta,
  ) {
    return 'Το $line είναι $stops πριν από $stop$late$eta.';
  }

  @override
  String ruleHitLateTitle(String line, int min) {
    return '$line αργεί $min′';
  }

  @override
  String ruleHitLateBody(String stop, String eta, String stops) {
    return 'Για τη στάση $stop$eta$stops.';
  }

  @override
  String ruleHitLateEta(int min) {
    return 'φτάνει σε ~$min′';
  }

  @override
  String ruleHitLeaveTitle(String line) {
    return 'Φύγε τώρα για το $line';
  }

  @override
  String ruleHitLeaveBody(String stop, String eta) {
    return 'Για να είσαι στη στάση $stop πριν έρθει$eta.';
  }

  @override
  String get ruleHitRideTitle => 'Κατέβα στην επόμενη';

  @override
  String ruleHitRideBody(String stop) {
    return 'Επόμενη στάση: $stop.';
  }

  @override
  String get cityAthensName => 'Αθήνα';

  @override
  String get cityAthensAgency => 'ΟΑΣΑ';

  @override
  String get cityAthensIn => 'στην Αθήνα';

  @override
  String get cityThessalonikiName => 'Θεσσαλονίκη';

  @override
  String get cityThessalonikiAgency => 'ΟΣΕΘ';

  @override
  String get cityThessalonikiIn => 'στη Θεσσαλονίκη';

  @override
  String get coreKindBusStop => 'στάση λεωφορείων';

  @override
  String get coreKindMetro => 'σταθμός μετρό';

  @override
  String get coreKindTram => 'στάση τραμ';

  @override
  String get coreKindRail => 'σταθμός προαστιακού';

  @override
  String get coreLastRunOnMonday => 'τη Δευτέρα';

  @override
  String get coreLastRunOnTuesday => 'την Τρίτη';

  @override
  String get coreLastRunOnWednesday => 'την Τετάρτη';

  @override
  String get coreLastRunOnThursday => 'την Πέμπτη';

  @override
  String get coreLastRunOnFriday => 'την Παρασκευή';

  @override
  String get coreLastRunOnSaturday => 'το Σάββατο';

  @override
  String get coreLastRunOnSunday => 'την Κυριακή';

  @override
  String get coreNearestMetro => 'Κοντινότερος σταθμός μετρό';

  @override
  String coreToward(String names) {
    return 'προς $names';
  }

  @override
  String coreDistanceM(int m) {
    return '$m μ.';
  }

  @override
  String coreDistanceKm(String km) {
    return '$km χλμ.';
  }
}
