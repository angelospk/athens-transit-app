import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_el.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('el'),
    Locale('en'),
  ];

  /// The app's name on the store and the home screen. Keep «Στάσεις» / «Staseis».
  ///
  /// In el, this message translates to:
  /// **'Στάσεις'**
  String get appName;

  /// No description provided for @commonCancel.
  ///
  /// In el, this message translates to:
  /// **'Άκυρο'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In el, this message translates to:
  /// **'Διαγραφή'**
  String get commonDelete;

  /// No description provided for @commonSave.
  ///
  /// In el, this message translates to:
  /// **'Αποθήκευση'**
  String get commonSave;

  /// No description provided for @commonRetry.
  ///
  /// In el, this message translates to:
  /// **'Δοκίμασε ξανά'**
  String get commonRetry;

  /// No description provided for @commonLess.
  ///
  /// In el, this message translates to:
  /// **'Λιγότερο'**
  String get commonLess;

  /// No description provided for @commonMore.
  ///
  /// In el, this message translates to:
  /// **'Περισσότερο'**
  String get commonMore;

  /// No description provided for @commonClose.
  ///
  /// In el, this message translates to:
  /// **'Κλείσιμο'**
  String get commonClose;

  /// No description provided for @commonNext.
  ///
  /// In el, this message translates to:
  /// **'Επόμενο'**
  String get commonNext;

  /// No description provided for @commonOk.
  ///
  /// In el, this message translates to:
  /// **'Εντάξει'**
  String get commonOk;

  /// No description provided for @commonNow.
  ///
  /// In el, this message translates to:
  /// **'τώρα'**
  String get commonNow;

  /// No description provided for @commonOnTime.
  ///
  /// In el, this message translates to:
  /// **'στην ώρα του'**
  String get commonOnTime;

  /// No description provided for @commonSearching.
  ///
  /// In el, this message translates to:
  /// **'Αναζήτηση…'**
  String get commonSearching;

  /// No description provided for @commonLocating.
  ///
  /// In el, this message translates to:
  /// **'Αναζήτηση θέσης…'**
  String get commonLocating;

  /// No description provided for @commonHome.
  ///
  /// In el, this message translates to:
  /// **'Σπίτι'**
  String get commonHome;

  /// No description provided for @commonWork.
  ///
  /// In el, this message translates to:
  /// **'Δουλειά'**
  String get commonWork;

  /// No description provided for @commonMetro.
  ///
  /// In el, this message translates to:
  /// **'Μετρό'**
  String get commonMetro;

  /// No description provided for @commonTram.
  ///
  /// In el, this message translates to:
  /// **'Τραμ'**
  String get commonTram;

  /// No description provided for @commonSuburban.
  ///
  /// In el, this message translates to:
  /// **'Προαστιακός'**
  String get commonSuburban;

  /// No description provided for @commonBuses.
  ///
  /// In el, this message translates to:
  /// **'Λεωφορεία'**
  String get commonBuses;

  /// No description provided for @commonNoNotificationPermission.
  ///
  /// In el, this message translates to:
  /// **'Για να σε ειδοποιήσουμε, χρειάζεται άδεια ειδοποιήσεων.'**
  String get commonNoNotificationPermission;

  /// No description provided for @stopsCount.
  ///
  /// In el, this message translates to:
  /// **'{count, plural, =1{1 στάση} other{{count} στάσεις}}'**
  String stopsCount(int count);

  /// A short minutes value as on the boards: 5′
  ///
  /// In el, this message translates to:
  /// **'{n}′'**
  String minutesShort(int n);

  /// No description provided for @mapOnBusSnack.
  ///
  /// In el, this message translates to:
  /// **'Είσαι στο {line}; Διάλεξε πού κατεβαίνεις.'**
  String mapOnBusSnack(String line);

  /// Snack bar button: opens the bus on the map
  ///
  /// In el, this message translates to:
  /// **'Άνοιξέ το'**
  String get mapOnBusSnackAction;

  /// No description provided for @mapLayersMine.
  ///
  /// In el, this message translates to:
  /// **'Χάρτης: οι γραμμές μου'**
  String get mapLayersMine;

  /// Map button that opens the layers sheet
  ///
  /// In el, this message translates to:
  /// **'Τι δείχνει ο χάρτης'**
  String get mapLayers;

  /// Map button: centre on my location
  ///
  /// In el, this message translates to:
  /// **'Πού είμαι'**
  String get mapWhereAmI;

  /// No description provided for @mapMenu.
  ///
  /// In el, this message translates to:
  /// **'Μενού'**
  String get mapMenu;

  /// No description provided for @mapTitle.
  ///
  /// In el, this message translates to:
  /// **'Χάρτης'**
  String get mapTitle;

  /// No description provided for @mapLegend.
  ///
  /// In el, this message translates to:
  /// **'Τι σημαίνει κάθε σύμβολο'**
  String get mapLegend;

  /// No description provided for @mapBusesAllHint.
  ///
  /// In el, this message translates to:
  /// **'Λεωφορεία: όλα. Βάλε αστέρι σε μια γραμμή για να βλέπεις μόνο τις δικές σου.'**
  String get mapBusesAllHint;

  /// No description provided for @mapAllBuses.
  ///
  /// In el, this message translates to:
  /// **'Όλα τα λεωφορεία'**
  String get mapAllBuses;

  /// No description provided for @mapMyLines.
  ///
  /// In el, this message translates to:
  /// **'Οι γραμμές μου'**
  String get mapMyLines;

  /// No description provided for @mapAdvanced.
  ///
  /// In el, this message translates to:
  /// **'Για προχωρημένους'**
  String get mapAdvanced;

  /// No description provided for @mapOthersWhenSelected.
  ///
  /// In el, this message translates to:
  /// **'Όταν πατάς ένα λεωφορείο ή μια γραμμή, τα άλλα:'**
  String get mapOthersWhenSelected;

  /// The other buses: are shown
  ///
  /// In el, this message translates to:
  /// **'Φαίνονται'**
  String get mapOthersNormal;

  /// The other buses: faded
  ///
  /// In el, this message translates to:
  /// **'Αχνά'**
  String get mapOthersDim;

  /// The other buses: hidden
  ///
  /// In el, this message translates to:
  /// **'Κρύβονται'**
  String get mapOthersHide;

  /// No description provided for @mapRecentOnly.
  ///
  /// In el, this message translates to:
  /// **'Μόνο με πρόσφατη θέση'**
  String get mapRecentOnly;

  /// No description provided for @mapRecentOnlyHint.
  ///
  /// In el, this message translates to:
  /// **'Έστειλαν θέση τα τελευταία 1½ λεπτά.'**
  String get mapRecentOnlyHint;

  /// No description provided for @mapOnTimeOnly.
  ///
  /// In el, this message translates to:
  /// **'Μόνο στην ώρα τους'**
  String get mapOnTimeOnly;

  /// No description provided for @mapOnTimeOnlyHint.
  ///
  /// In el, this message translates to:
  /// **'Έως 5 λεπτά καθυστέρηση.'**
  String get mapOnTimeOnlyHint;

  /// No description provided for @mapShowAge.
  ///
  /// In el, this message translates to:
  /// **'Πόσο παλιά είναι η θέση'**
  String get mapShowAge;

  /// No description provided for @mapShowAgeHint.
  ///
  /// In el, this message translates to:
  /// **'Δίπλα σε κάθε λεωφορείο. Οι παλιές φαίνονται πάντα.'**
  String get mapShowAgeHint;

  /// No description provided for @mapAttribution.
  ///
  /// In el, this message translates to:
  /// **'Χάρτης: © OpenStreetMap contributors · OpenFreeMap'**
  String get mapAttribution;

  /// Offline banner. ago is a short duration such as 5′
  ///
  /// In el, this message translates to:
  /// **'Τελευταία δεδομένα {time} · πριν {ago}'**
  String mapLastData(String time, String ago);

  /// No description provided for @mapOffline.
  ///
  /// In el, this message translates to:
  /// **'Χωρίς σύνδεση'**
  String get mapOffline;

  /// No description provided for @mapSeeNearby.
  ///
  /// In el, this message translates to:
  /// **'Δες τι περνάει κοντά σου'**
  String get mapSeeNearby;

  /// No description provided for @mapLocationPitch.
  ///
  /// In el, this message translates to:
  /// **'Με την τοποθεσία σου βλέπεις τις πιο κοντινές στάσεις και πότε έρχεται το λεωφορείο. Η θέση μένει στο κινητό.'**
  String get mapLocationPitch;

  /// No description provided for @mapUseMyLocation.
  ///
  /// In el, this message translates to:
  /// **'Χρήση της θέσης μου'**
  String get mapUseMyLocation;

  /// No description provided for @mapOrSearch.
  ///
  /// In el, this message translates to:
  /// **'Ή γράψε μια στάση ή γραμμή στην αναζήτηση.'**
  String get mapOrSearch;

  /// No description provided for @mapLoadingStops.
  ///
  /// In el, this message translates to:
  /// **'Φόρτωση στάσεων…'**
  String get mapLoadingStops;

  /// No description provided for @mapNoStopWithin.
  ///
  /// In el, this message translates to:
  /// **'Καμία στάση σε 2,5 χλμ.'**
  String get mapNoStopWithin;

  /// No description provided for @mapDragForMore.
  ///
  /// In el, this message translates to:
  /// **'σύρε για περισσότερες στάσεις'**
  String get mapDragForMore;

  /// No description provided for @mapNoSavedStops.
  ///
  /// In el, this message translates to:
  /// **'Καμία αποθηκευμένη στάση ακόμη. Άνοιξε μια στάση και πάτα το αστέρι.'**
  String get mapNoSavedStops;

  /// Tab and page title: saved stops, lines and places
  ///
  /// In el, this message translates to:
  /// **'Αγαπημένα'**
  String get mapFavorites;

  /// No description provided for @mapAllFavorites.
  ///
  /// In el, this message translates to:
  /// **'Όλα τα αγαπημένα · προσθήκη, σπίτι, δουλειά'**
  String get mapAllFavorites;

  /// Tab of the home sheet; also the back label to it
  ///
  /// In el, this message translates to:
  /// **'Κοντά σου'**
  String get mapNearYou;

  /// No description provided for @mapQuietLines.
  ///
  /// In el, this message translates to:
  /// **'{lines}: κανένα λεωφορείο με GPS τώρα'**
  String mapQuietLines(String lines);

  /// No description provided for @mapWalkDirections.
  ///
  /// In el, this message translates to:
  /// **'Οδηγίες με τα πόδια'**
  String get mapWalkDirections;

  /// No description provided for @mapWalkDirectionsMin.
  ///
  /// In el, this message translates to:
  /// **'Οδηγίες με τα πόδια, {m} λεπτά'**
  String mapWalkDirectionsMin(int m);

  /// A departure that was cancelled
  ///
  /// In el, this message translates to:
  /// **'ακυρώθηκε'**
  String get mapCancelled;

  /// No description provided for @mapRailLive.
  ///
  /// In el, this message translates to:
  /// **'live από railway.gov.gr'**
  String get mapRailLive;

  /// No description provided for @mapMetroSchedule.
  ///
  /// In el, this message translates to:
  /// **'πρόγραμμα ΣΤΑΣΥ, όχι live'**
  String get mapMetroSchedule;

  /// No description provided for @mapStopsNear.
  ///
  /// In el, this message translates to:
  /// **'Στάσεις κοντά'**
  String get mapStopsNear;

  /// No description provided for @mapNoStopWithin600.
  ///
  /// In el, this message translates to:
  /// **'Καμία στάση σε 600 μ.'**
  String get mapNoStopWithin600;

  /// Distance to a stop in metres and its lines
  ///
  /// In el, this message translates to:
  /// **'{dist} μ. · {lines}'**
  String mapStopDistLines(int dist, String lines);

  /// No description provided for @mapBusesOnRoad.
  ///
  /// In el, this message translates to:
  /// **'{count, plural, =1{1 λεωφορείο στον δρόμο} other{{count} λεωφορεία στον δρόμο}}'**
  String mapBusesOnRoad(int count);

  /// No description provided for @mapAllOnTime.
  ///
  /// In el, this message translates to:
  /// **'όλα στην ώρα τους'**
  String get mapAllOnTime;

  /// No description provided for @mapLateCount.
  ///
  /// In el, this message translates to:
  /// **'{count, plural, =1{1 αργεί πάνω από 5′} other{{count} αργούν πάνω από 5′}}'**
  String mapLateCount(int count);

  /// No description provided for @mapMyLinesNow.
  ///
  /// In el, this message translates to:
  /// **'Οι γραμμές μου τώρα'**
  String get mapMyLinesNow;

  /// No description provided for @mapMyLinesHint.
  ///
  /// In el, this message translates to:
  /// **'τα άλλα λεωφορεία κρυμμένα · πάτα μια γραμμή για τη διαδρομή της'**
  String get mapMyLinesHint;

  /// No description provided for @mapNoLineSelected.
  ///
  /// In el, this message translates to:
  /// **'Καμία γραμμή επιλεγμένη. Διάλεξε από το κουμπί του χάρτη (σύρε το πλαίσιο προς τα κάτω).'**
  String get mapNoLineSelected;

  /// The trip planner page title, also the back label to it
  ///
  /// In el, this message translates to:
  /// **'Διαδρομή'**
  String get plannerTitle;

  /// No description provided for @plannerMyLocation.
  ///
  /// In el, this message translates to:
  /// **'Η θέση μου'**
  String get plannerMyLocation;

  /// No description provided for @plannerFrom.
  ///
  /// In el, this message translates to:
  /// **'Από'**
  String get plannerFrom;

  /// No description provided for @plannerTo.
  ///
  /// In el, this message translates to:
  /// **'Προς'**
  String get plannerTo;

  /// No description provided for @plannerWhereAreYou.
  ///
  /// In el, this message translates to:
  /// **'Πού είσαι;'**
  String get plannerWhereAreYou;

  /// No description provided for @plannerWhereTo.
  ///
  /// In el, this message translates to:
  /// **'Πού πας; στάση, περιοχή, κατάστημα, διεύθυνση'**
  String get plannerWhereTo;

  /// Button: swap start and destination
  ///
  /// In el, this message translates to:
  /// **'Αντιστροφή'**
  String get plannerSwap;

  /// Chip: leave now
  ///
  /// In el, this message translates to:
  /// **'Τώρα'**
  String get plannerNow;

  /// Chip: leave later
  ///
  /// In el, this message translates to:
  /// **'Αργότερα'**
  String get plannerLater;

  /// No description provided for @plannerLeaveAt.
  ///
  /// In el, this message translates to:
  /// **'Φεύγω {time}'**
  String plannerLeaveAt(String time);

  /// No description provided for @plannerWithMetro.
  ///
  /// In el, this message translates to:
  /// **'Με μετρό'**
  String get plannerWithMetro;

  /// No description provided for @plannerLinesFailed.
  ///
  /// In el, this message translates to:
  /// **'Δεν φόρτωσαν οι γραμμές. Χρειάζεται σύνδεση την πρώτη φορά.'**
  String get plannerLinesFailed;

  /// No description provided for @plannerPickFrom.
  ///
  /// In el, this message translates to:
  /// **'Διάλεξε από πού φεύγεις ή δώσε άδεια τοποθεσίας: έτσι υπολογίζεται πόσο περπατάς ως τη στάση.'**
  String get plannerPickFrom;

  /// No description provided for @plannerPickTo.
  ///
  /// In el, this message translates to:
  /// **'Διάλεξε πού πας. Θα δεις λεωφορεία χωρίς αλλαγή ή με μία, και το μετρό όταν σε βολεύει.'**
  String get plannerPickTo;

  /// No description provided for @plannerNoBus.
  ///
  /// In el, this message translates to:
  /// **'Δεν βρέθηκε λεωφορείο σε 500 μ. από την αφετηρία και τον προορισμό σου, ούτε με μία αλλαγή. Δοκίμασε μια κοντινή στάση ή το μετρό.'**
  String get plannerNoBus;

  /// No description provided for @plannerDirect.
  ///
  /// In el, this message translates to:
  /// **'Χωρίς αλλαγή'**
  String get plannerDirect;

  /// No description provided for @plannerOneChange.
  ///
  /// In el, this message translates to:
  /// **'Με μία αλλαγή'**
  String get plannerOneChange;

  /// No description provided for @plannerTimesLive.
  ///
  /// In el, this message translates to:
  /// **'Χρόνοι: περπάτημα 4,5 χλμ/ώ, λεωφορείο 15 χλμ/ώ με τις στάσεις· η αναμονή είναι live από το GPS των λεωφορείων.'**
  String get plannerTimesLive;

  /// No description provided for @plannerTimesLater.
  ///
  /// In el, this message translates to:
  /// **'Για αργότερα δεν ξέρουμε ποιο λεωφορείο θα έρθει: οι χρόνοι είναι χωρίς αναμονή.'**
  String get plannerTimesLater;

  /// No description provided for @plannerMetroWalk.
  ///
  /// In el, this message translates to:
  /// **'Περπάτημα {walk}′ συνολικά · τρένο κάθε λίγα λεπτά (πρόγραμμα, όχι live)'**
  String plannerMetroWalk(int walk);

  /// No description provided for @plannerMetroWait.
  ///
  /// In el, this message translates to:
  /// **'Μετρό με το πρόγραμμα (όχι live), αναμονή ~5′.'**
  String get plannerMetroWait;

  /// No description provided for @plannerBoardChange.
  ///
  /// In el, this message translates to:
  /// **'Ανεβαίνεις: {board} · αλλαγή: {change}'**
  String plannerBoardChange(String board, String change);

  /// Appended after a transfer stop; keep the leading space
  ///
  /// In el, this message translates to:
  /// **' ({m} μ. με τα πόδια)'**
  String plannerTransferWalk(int m);

  /// No description provided for @plannerStopsWalk.
  ///
  /// In el, this message translates to:
  /// **'{stops} στάσεις · περπάτημα {walk}′'**
  String plannerStopsWalk(int stops, int walk);

  /// No description provided for @plannerBoard.
  ///
  /// In el, this message translates to:
  /// **'Ανεβαίνεις: {stop}'**
  String plannerBoard(String stop);

  /// No description provided for @plannerGetOff.
  ///
  /// In el, this message translates to:
  /// **'Κατεβαίνεις: {stop}'**
  String plannerGetOff(String stop);

  /// Saved as the label of an approximate place
  ///
  /// In el, this message translates to:
  /// **'κοντά στη θέση σου'**
  String get plannerNearMyLocation;

  /// Saved as the label of an approximate place
  ///
  /// In el, this message translates to:
  /// **'κοντά σε {stop}'**
  String plannerNearStop(String stop);

  /// No description provided for @plannerNearMeApprox.
  ///
  /// In el, this message translates to:
  /// **'Κοντά στη θέση μου (περίπου)'**
  String get plannerNearMeApprox;

  /// No description provided for @plannerPlaceHint.
  ///
  /// In el, this message translates to:
  /// **'{name}: διεύθυνση ή περιοχή'**
  String plannerPlaceHint(String name);

  /// No description provided for @plannerFromHint.
  ///
  /// In el, this message translates to:
  /// **'Από: στάση, περιοχή, διεύθυνση'**
  String get plannerFromHint;

  /// No description provided for @plannerToHint.
  ///
  /// In el, this message translates to:
  /// **'Προς: στάση, περιοχή, κατάστημα, διεύθυνση'**
  String get plannerToHint;

  /// No description provided for @plannerPlacePrivacy.
  ///
  /// In el, this message translates to:
  /// **'Αρκεί μια περιοχή κοντά. Δεν κρατάμε τίποτα: το μέρος μένει μόνο στο κινητό σου.'**
  String get plannerPlacePrivacy;

  /// No description provided for @plannerNoLocation.
  ///
  /// In el, this message translates to:
  /// **'Δεν βρέθηκε η θέση σου. Ενεργοποίησε την τοποθεσία ή διάλεξε ένα μέρος.'**
  String get plannerNoLocation;

  /// No description provided for @routeArrive.
  ///
  /// In el, this message translates to:
  /// **'φτάνεις ~{time}'**
  String routeArrive(String time);

  /// No description provided for @routeEstimateMetro.
  ///
  /// In el, this message translates to:
  /// **'Εκτίμηση με αναμονή ~{wait}′ για το τρένο.'**
  String routeEstimateMetro(int wait);

  /// No description provided for @routeEstimateLive.
  ///
  /// In el, this message translates to:
  /// **'Εκτίμηση χωρίς την αναμονή του πρώτου λεωφορείου· η αναμονή φαίνεται live στο βήμα του.'**
  String get routeEstimateLive;

  /// No description provided for @routeEstimateLater.
  ///
  /// In el, this message translates to:
  /// **'Για αργότερα: εκτίμηση χωρίς αναμονή.'**
  String get routeEstimateLater;

  /// No description provided for @routeWalkToDest.
  ///
  /// In el, this message translates to:
  /// **'Περπάτα ως τον προορισμό'**
  String get routeWalkToDest;

  /// No description provided for @routeWalkToStation.
  ///
  /// In el, this message translates to:
  /// **'Περπάτα ως τον σταθμό {name}'**
  String routeWalkToStation(String name);

  /// No description provided for @routeWalkToStop.
  ///
  /// In el, this message translates to:
  /// **'Περπάτα ως τη στάση {name}'**
  String routeWalkToStop(String name);

  /// No description provided for @routeWalkTo.
  ///
  /// In el, this message translates to:
  /// **'Περπάτα ως {name}'**
  String routeWalkTo(String name);

  /// No description provided for @routeBoard.
  ///
  /// In el, this message translates to:
  /// **'Ανέβα στο {line}'**
  String routeBoard(String line);

  /// No description provided for @routeBoardToward.
  ///
  /// In el, this message translates to:
  /// **'Ανέβα στο {line} προς {toward}'**
  String routeBoardToward(String line, String toward);

  /// No description provided for @routeStop.
  ///
  /// In el, this message translates to:
  /// **'Στάση: {name}'**
  String routeStop(String name);

  /// No description provided for @routeGetOff.
  ///
  /// In el, this message translates to:
  /// **'Κατέβα: {name}'**
  String routeGetOff(String name);

  /// No description provided for @routeChangeWait.
  ///
  /// In el, this message translates to:
  /// **'Αλλαγή: αναμονή ~{wait}′'**
  String routeChangeWait(int wait);

  /// No description provided for @routeTrainEvery.
  ///
  /// In el, this message translates to:
  /// **'Τρένο κάθε λίγα λεπτά (πρόγραμμα, όχι live), αναμονή ~{wait}′'**
  String routeTrainEvery(int wait);

  /// Button: alert before the stop to get off
  ///
  /// In el, this message translates to:
  /// **'Πού κατεβαίνω;'**
  String get routeWhereGetOff;

  /// Button: notify when it is time to leave for the bus
  ///
  /// In el, this message translates to:
  /// **'Φύγε εγκαίρως'**
  String get routeLeaveInTime;

  /// No description provided for @routeNoBusNear.
  ///
  /// In el, this message translates to:
  /// **'Κανένα λεωφορείο με GPS κοντά τώρα'**
  String get routeNoBusNear;

  /// No description provided for @routeCantCatch.
  ///
  /// In el, this message translates to:
  /// **'Δεν προλαβαίνεις αυτά που έρχονται τώρα'**
  String get routeCantCatch;

  /// No description provided for @routeSearchingNext.
  ///
  /// In el, this message translates to:
  /// **'Αναζήτηση επόμενου λεωφορείου…'**
  String get routeSearchingNext;

  /// eta is short, like 5′ or now
  ///
  /// In el, this message translates to:
  /// **'Το επόμενο που προλαβαίνεις σε {eta} ({clock})'**
  String routeNextCatch(String eta, String clock);

  /// No description provided for @routeLeaveNow.
  ///
  /// In el, this message translates to:
  /// **'φύγε τώρα'**
  String get routeLeaveNow;

  /// No description provided for @routeLeaveIn.
  ///
  /// In el, this message translates to:
  /// **'φύγε σε {n}′'**
  String routeLeaveIn(int n);

  /// No description provided for @mapSelBack.
  ///
  /// In el, this message translates to:
  /// **'Πίσω'**
  String get mapSelBack;

  /// No description provided for @mapSelLine.
  ///
  /// In el, this message translates to:
  /// **'Γραμμή {line}'**
  String mapSelLine(String line);

  /// A stop without a name
  ///
  /// In el, this message translates to:
  /// **'Στάση'**
  String get mapSelStop;

  /// No description provided for @searchClear.
  ///
  /// In el, this message translates to:
  /// **'Καθαρισμός'**
  String get searchClear;

  /// No description provided for @searchHint.
  ///
  /// In el, this message translates to:
  /// **'Στάση, γραμμή ή μέρος'**
  String get searchHint;

  /// No description provided for @searchHiddenResults.
  ///
  /// In el, this message translates to:
  /// **'{count, plural, =1{1 αποτέλεσμα σε κρυμμένα μέσα} other{{count} αποτελέσματα σε κρυμμένα μέσα}}'**
  String searchHiddenResults(int count);

  /// No description provided for @searchShow.
  ///
  /// In el, this message translates to:
  /// **'Εμφάνιση'**
  String get searchShow;

  /// No description provided for @searchMunicipal.
  ///
  /// In el, this message translates to:
  /// **'Δημοτική · {municipality}'**
  String searchMunicipal(String municipality);

  /// No description provided for @stationRail.
  ///
  /// In el, this message translates to:
  /// **'Σταθμός Προαστιακού'**
  String get stationRail;

  /// No description provided for @stationMetroTram.
  ///
  /// In el, this message translates to:
  /// **'Σταθμός μετρό / τραμ'**
  String get stationMetroTram;

  /// No description provided for @stationDeparturesFailed.
  ///
  /// In el, this message translates to:
  /// **'Δεν φόρτωσαν οι αναχωρήσεις. Νέα προσπάθεια σε λίγο.'**
  String get stationDeparturesFailed;

  /// No description provided for @stationBusStopsNear.
  ///
  /// In el, this message translates to:
  /// **'Στάσεις λεωφορείων κοντά'**
  String get stationBusStopsNear;

  /// No description provided for @stationNoTrain.
  ///
  /// In el, this message translates to:
  /// **'Κανένα τρένο στις επόμενες ώρες.'**
  String get stationNoTrain;

  /// No description provided for @stationTrain.
  ///
  /// In el, this message translates to:
  /// **'Τρένο {train}'**
  String stationTrain(String train);

  /// No description provided for @stationDelay.
  ///
  /// In el, this message translates to:
  /// **'+{n}′ καθυστέρηση'**
  String stationDelay(int n);

  /// Small label under a rail line badge
  ///
  /// In el, this message translates to:
  /// **'γραμμή'**
  String get stationLine;

  /// No description provided for @stationRailNote.
  ///
  /// In el, this message translates to:
  /// **'Live από railway.gov.gr. Ο πίνακας δίνει μόνο την επόμενη στάση· το «προς» είναι το τέρμα της γραμμής.'**
  String get stationRailNote;

  /// No description provided for @stationToward.
  ///
  /// In el, this message translates to:
  /// **'προς {name}'**
  String stationToward(String name);

  /// No description provided for @stationNextStop.
  ///
  /// In el, this message translates to:
  /// **'επόμενη στάση {name}'**
  String stationNextStop(String name);

  /// No description provided for @stationNoMetroTimes.
  ///
  /// In el, this message translates to:
  /// **'Τα δρομολόγια μετρό και τραμ δεν είναι ακόμη διαθέσιμα.'**
  String get stationNoMetroTimes;

  /// No description provided for @stationNoDeparture.
  ///
  /// In el, this message translates to:
  /// **'Καμία αναχώρηση στην επόμενη ώρα.'**
  String get stationNoDeparture;

  /// No description provided for @stationIndicative.
  ///
  /// In el, this message translates to:
  /// **'Ενδεικτικά, από το πρόγραμμα της ΣΤΑΣΥ (όχι live).'**
  String get stationIndicative;

  /// No description provided for @stationSchedule.
  ///
  /// In el, this message translates to:
  /// **'Από το πρόγραμμα της ΣΤΑΣΥ (όχι live).'**
  String get stationSchedule;

  /// One letter on the badge of a municipal line without a number (Δ for Δημοτική, M for Municipal)
  ///
  /// In el, this message translates to:
  /// **'Δ'**
  String get muniBadge;

  /// After departure times: the stop they leave from; keep the leading space
  ///
  /// In el, this message translates to:
  /// **' από {stop}'**
  String muniFromStop(String stop);

  /// No description provided for @muniScheduled.
  ///
  /// In el, this message translates to:
  /// **'Προγραμματισμένα · όχι live'**
  String get muniScheduled;

  /// No description provided for @muniLine.
  ///
  /// In el, this message translates to:
  /// **'Δημοτική γραμμή · {municipality}'**
  String muniLine(String municipality);

  /// No description provided for @muniNoTimetable.
  ///
  /// In el, this message translates to:
  /// **'Δεν έχουμε ελεγμένο ωράριο για αυτή τη γραμμή.'**
  String get muniNoTimetable;

  /// No description provided for @muniTimetableLink.
  ///
  /// In el, this message translates to:
  /// **'Ωράριο του δήμου'**
  String get muniTimetableLink;

  /// No description provided for @muniNextDepartures.
  ///
  /// In el, this message translates to:
  /// **'Επόμενες αναχωρήσεις'**
  String get muniNextDepartures;

  /// No description provided for @muniNoMoreToday.
  ///
  /// In el, this message translates to:
  /// **'Κανένα άλλο δρομολόγιο σήμερα, κατά το ωράριο.'**
  String get muniNoMoreToday;

  /// No description provided for @muniApproxNote.
  ///
  /// In el, this message translates to:
  /// **'≈: ο δήμος δίνει συχνότητα, όχι ακριβείς ώρες.'**
  String get muniApproxNote;

  /// No description provided for @muniTimetableChecked.
  ///
  /// In el, this message translates to:
  /// **'Ωράριο: {municipality}, ελέγχθηκε {date}.'**
  String muniTimetableChecked(String municipality, String date);

  /// No description provided for @muniPageLink.
  ///
  /// In el, this message translates to:
  /// **'Σελίδα του δήμου'**
  String get muniPageLink;

  /// No description provided for @muniRouteSource.
  ///
  /// In el, this message translates to:
  /// **'Διαδρομή και στάσεις: {source}'**
  String muniRouteSource(String source);

  /// No description provided for @muniStopKicker.
  ///
  /// In el, this message translates to:
  /// **'Στάση δημοτικής γραμμής'**
  String get muniStopKicker;

  /// No description provided for @muniLinesFailed.
  ///
  /// In el, this message translates to:
  /// **'Δεν φόρτωσαν οι δημοτικές γραμμές. Δοκίμασε ξανά σε λίγο.'**
  String get muniLinesFailed;

  /// No description provided for @muniNoCheckedTimetable.
  ///
  /// In el, this message translates to:
  /// **'Χωρίς ελεγμένο ωράριο'**
  String get muniNoCheckedTimetable;

  /// No description provided for @muniNoMoreTodayShort.
  ///
  /// In el, this message translates to:
  /// **'Κανένα άλλο δρομολόγιο σήμερα'**
  String get muniNoMoreTodayShort;

  /// No description provided for @muniTimesFromStart.
  ///
  /// In el, this message translates to:
  /// **'Οι ώρες είναι από την αφετηρία που γράφει ο δήμος, όχι από αυτή τη στάση.'**
  String get muniTimesFromStart;

  /// No description provided for @helpDelayUpTo2.
  ///
  /// In el, this message translates to:
  /// **'έως 2′ ή νωρίτερα'**
  String get helpDelayUpTo2;

  /// No description provided for @helpDelayOver10.
  ///
  /// In el, this message translates to:
  /// **'πάνω από 10′'**
  String get helpDelayOver10;

  /// No description provided for @helpDelayNoTrip.
  ///
  /// In el, this message translates to:
  /// **'χωρίς δρομολόγιο'**
  String get helpDelayNoTrip;

  /// No description provided for @helpDelayTitle.
  ///
  /// In el, this message translates to:
  /// **'Καθυστέρηση από το πρόγραμμα'**
  String get helpDelayTitle;

  /// No description provided for @helpBus.
  ///
  /// In el, this message translates to:
  /// **'Λεωφορείο. Το χρώμα του δείχνει πόσο αργεί σε σχέση με το πρόγραμμα.'**
  String get helpBus;

  /// No description provided for @helpMyBus.
  ///
  /// In el, this message translates to:
  /// **'Λεωφορείο μιας από τις γραμμές σου: έχει το χρώμα της γραμμής, και το δαχτυλίδι γύρω του δείχνει την καθυστέρηση.'**
  String get helpMyBus;

  /// No description provided for @helpDirection.
  ///
  /// In el, this message translates to:
  /// **'Η κατεύθυνση που πηγαίνει. Λείπει όταν δεν είναι γνωστή.'**
  String get helpDirection;

  /// No description provided for @helpFaded.
  ///
  /// In el, this message translates to:
  /// **'Αχνό: η θέση του είναι παλιά, πάνω από 1½ λεπτό. Δίπλα γράφει πόσο παλιά (π.χ. 2′).'**
  String get helpFaded;

  /// No description provided for @helpBlueRing.
  ///
  /// In el, this message translates to:
  /// **'Μπλε δαχτυλίδι: το λεωφορείο ή η γραμμή που άνοιξες.'**
  String get helpBlueRing;

  /// No description provided for @helpRoute.
  ///
  /// In el, this message translates to:
  /// **'Η διαδρομή, με βέλη προς τα πού πηγαίνει. Κάθε κατεύθυνση έχει τη δική της λωρίδα.'**
  String get helpRoute;

  /// No description provided for @helpStop.
  ///
  /// In el, this message translates to:
  /// **'Στάση. Πάτα τη για να δεις τι έρχεται.'**
  String get helpStop;

  /// No description provided for @helpTapEmpty.
  ///
  /// In el, this message translates to:
  /// **'Πάτα σε κενό σημείο του χάρτη για να κλείσεις ό,τι είναι ανοιχτό.'**
  String get helpTapEmpty;

  /// No description provided for @helpDataTitle.
  ///
  /// In el, this message translates to:
  /// **'Από πού έρχονται τα δεδομένα'**
  String get helpDataTitle;

  /// No description provided for @helpPosition.
  ///
  /// In el, this message translates to:
  /// **'Θέση'**
  String get helpPosition;

  /// No description provided for @helpPositionText.
  ///
  /// In el, this message translates to:
  /// **'Κάθε λεωφορείο στέλνει το GPS του στον ΟΑΣΑ. Ο server μας το διαβάζει κάθε 30″ περίπου. Ανάμεσα σε δύο θέσεις η εφαρμογή κινεί το λεωφορείο πάνω στη διαδρομή του, με την ταχύτητά του.'**
  String get helpPositionText;

  /// No description provided for @helpEta.
  ///
  /// In el, this message translates to:
  /// **'Χρόνος άφιξης'**
  String get helpEta;

  /// No description provided for @helpEtaText.
  ///
  /// In el, this message translates to:
  /// **'Τον υπολογίζει η εφαρμογή: από το πού είναι το λεωφορείο και την τυπική ταχύτητα κάθε κομματιού του δρόμου (από τις θέσεις των τελευταίων 14 ημερών). Δεν είναι η πρόβλεψη του ΟΑΣΑ.'**
  String get helpEtaText;

  /// No description provided for @helpDelay.
  ///
  /// In el, this message translates to:
  /// **'Καθυστέρηση'**
  String get helpDelay;

  /// No description provided for @helpDelayText.
  ///
  /// In el, this message translates to:
  /// **'Σύγκριση με το πρόγραμμα του ΟΑΣΑ για το δρομολόγιο που κάνει το λεωφορείο.'**
  String get helpDelayText;

  /// No description provided for @helpTilde.
  ///
  /// In el, this message translates to:
  /// **'«~» πριν από έναν χρόνο'**
  String get helpTilde;

  /// No description provided for @helpTildeText.
  ///
  /// In el, this message translates to:
  /// **'Χωρίς σύνδεση: εκτίμηση από τα τελευταία δεδομένα. Διορθώνεται μόλις βρεθεί σήμα.'**
  String get helpTildeText;

  /// No description provided for @lineSpeedTitle.
  ///
  /// In el, this message translates to:
  /// **'Ταχύτητα γραμμής'**
  String get lineSpeedTitle;

  /// No description provided for @lineSpeedDaysFailed.
  ///
  /// In el, this message translates to:
  /// **'Δεν φόρτωσαν τα στατιστικά των ημερών.'**
  String get lineSpeedDaysFailed;

  /// No description provided for @lineSpeedNext2km.
  ///
  /// In el, this message translates to:
  /// **'Τα επόμενα 2 χλμ'**
  String get lineSpeedNext2km;

  /// No description provided for @lineSpeedAheadHint.
  ///
  /// In el, this message translates to:
  /// **'Η συνήθης ταχύτητα ανά 200 μ. τέτοια μέρα και ώρα· η γραμμή είναι το λεωφορείο τώρα ({kmh} χλμ/ώ).'**
  String lineSpeedAheadHint(int kmh);

  /// No description provided for @lineSpeedNoData.
  ///
  /// In el, this message translates to:
  /// **'Δεν υπάρχουν μετρήσεις για τη γραμμή τις τελευταίες μέρες.'**
  String get lineSpeedNoData;

  /// No description provided for @lineSpeedLastDays.
  ///
  /// In el, this message translates to:
  /// **'Τις τελευταίες {n} μέρες'**
  String lineSpeedLastDays(int n);

  /// No description provided for @lineSpeedKmhWeekdays.
  ///
  /// In el, this message translates to:
  /// **'χλμ/ώ καθημερινές'**
  String get lineSpeedKmhWeekdays;

  /// No description provided for @lineSpeedKmhWeekends.
  ///
  /// In el, this message translates to:
  /// **'χλμ/ώ Σαββατοκύριακα'**
  String get lineSpeedKmhWeekends;

  /// place 1 is the slowest line
  ///
  /// In el, this message translates to:
  /// **'Χθες: {place}η πιο αργή από {total} γραμμές.'**
  String lineSpeedRank(int place, int total);

  /// No description provided for @lineSpeedDayKmh.
  ///
  /// In el, this message translates to:
  /// **'{date}: {kmh} χλμ/ώ'**
  String lineSpeedDayKmh(String date, String kmh);

  /// No description provided for @lineSpeedWeekday.
  ///
  /// In el, this message translates to:
  /// **'καθημερινή'**
  String get lineSpeedWeekday;

  /// No description provided for @lineSpeedWeekend.
  ///
  /// In el, this message translates to:
  /// **'Σαββατοκύριακο'**
  String get lineSpeedWeekend;

  /// No description provided for @lineSpeedFooter.
  ///
  /// In el, this message translates to:
  /// **'Μέση ταχύτητα όλης της μέρας, με τις στάσεις. Πηγή: καταγραφές θέσεων του ΟΑΣΑ από τον server μας.'**
  String get lineSpeedFooter;

  /// 2-letter weekday: Monday
  ///
  /// In el, this message translates to:
  /// **'Δε'**
  String get lineSpeedMon;

  /// 2-letter weekday: Tuesday
  ///
  /// In el, this message translates to:
  /// **'Τρ'**
  String get lineSpeedTue;

  /// 2-letter weekday: Wednesday
  ///
  /// In el, this message translates to:
  /// **'Τε'**
  String get lineSpeedWed;

  /// 2-letter weekday: Thursday
  ///
  /// In el, this message translates to:
  /// **'Πε'**
  String get lineSpeedThu;

  /// 2-letter weekday: Friday
  ///
  /// In el, this message translates to:
  /// **'Πα'**
  String get lineSpeedFri;

  /// 2-letter weekday: Saturday
  ///
  /// In el, this message translates to:
  /// **'Σα'**
  String get lineSpeedSat;

  /// 2-letter weekday: Sunday
  ///
  /// In el, this message translates to:
  /// **'Κυ'**
  String get lineSpeedSun;

  /// No description provided for @alertNoSchedule.
  ///
  /// In el, this message translates to:
  /// **'Δεν βρέθηκε πρόγραμμα για το {line}.'**
  String alertNoSchedule(String line);

  /// No description provided for @alertLastGone.
  ///
  /// In el, this message translates to:
  /// **'Το τελευταίο {line} πέρασε ήδη (~{time}).'**
  String alertLastGone(String line, String time);

  /// Notification title: the last run of the day is about to pass the stop.
  ///
  /// In el, this message translates to:
  /// **'Σε λίγο περνά το τελευταίο {line}'**
  String alertLastNoteTitle(String line);

  /// Notification body for the last run of the day.
  ///
  /// In el, this message translates to:
  /// **'Από {stop} ~{time} (φεύγει {departs} από την αφετηρία).'**
  String alertLastNoteBody(String stop, String time, String departs);

  /// No description provided for @alertLastSet.
  ///
  /// In el, this message translates to:
  /// **'Θα σε ειδοποιήσουμε {before}′ πριν: το τελευταίο {line} περνά ~{time}.'**
  String alertLastSet(int before, String line, String time);

  /// {day} is one of alertOnMonday…alertOnSunday.
  ///
  /// In el, this message translates to:
  /// **'Θα σε ειδοποιήσουμε {before}′ πριν: το τελευταίο {line} περνά {day} ~{time}.'**
  String alertLastSetDay(int before, String line, String day, String time);

  /// No description provided for @alertOnMonday.
  ///
  /// In el, this message translates to:
  /// **'τη Δευτέρα'**
  String get alertOnMonday;

  /// No description provided for @alertOnTuesday.
  ///
  /// In el, this message translates to:
  /// **'την Τρίτη'**
  String get alertOnTuesday;

  /// No description provided for @alertOnWednesday.
  ///
  /// In el, this message translates to:
  /// **'την Τετάρτη'**
  String get alertOnWednesday;

  /// No description provided for @alertOnThursday.
  ///
  /// In el, this message translates to:
  /// **'την Πέμπτη'**
  String get alertOnThursday;

  /// No description provided for @alertOnFriday.
  ///
  /// In el, this message translates to:
  /// **'την Παρασκευή'**
  String get alertOnFriday;

  /// No description provided for @alertOnSaturday.
  ///
  /// In el, this message translates to:
  /// **'το Σάββατο'**
  String get alertOnSaturday;

  /// No description provided for @alertOnSunday.
  ///
  /// In el, this message translates to:
  /// **'την Κυριακή'**
  String get alertOnSunday;

  /// No description provided for @alertScheduleOffline.
  ///
  /// In el, this message translates to:
  /// **'Δεν φόρτωσε το πρόγραμμα. Δοκίμασε ξανά με σύνδεση.'**
  String get alertScheduleOffline;

  /// No description provided for @alertNoLocation.
  ///
  /// In el, this message translates to:
  /// **'Δεν βρέθηκε η θέση σου (άδεια ή GPS). Βάλε τον χρόνο περπατήματος με το χέρι.'**
  String get alertNoLocation;

  /// No description provided for @alertWeeklySet.
  ///
  /// In el, this message translates to:
  /// **'Κανόνας: Δε–Πα τέτοια ώρα.'**
  String get alertWeeklySet;

  /// No description provided for @alertWeeklyInexact.
  ///
  /// In el, this message translates to:
  /// **'Χωρίς άδεια για ακριβή ξυπνητήρια μπορεί να ξεκινά λίγα λεπτά αργότερα.'**
  String get alertWeeklyInexact;

  /// No description provided for @alertLeaveSet.
  ///
  /// In el, this message translates to:
  /// **'Θα σου πούμε πότε να φύγεις για το {line}.'**
  String alertLeaveSet(String line);

  /// No description provided for @alertSet.
  ///
  /// In el, this message translates to:
  /// **'Θα σε ειδοποιήσουμε για το {line}.'**
  String alertSet(String line);

  /// No description provided for @alertWalkQuestion.
  ///
  /// In el, this message translates to:
  /// **'Πόσο απέχεις από τη στάση;'**
  String get alertWalkQuestion;

  /// No description provided for @alertWalkExplain.
  ///
  /// In el, this message translates to:
  /// **'Με τη θέση σου υπολογίζεται πόσο περπατάς ως τη στάση και πότε να ξεκινήσεις, για να είσαι εκεί έγκαιρα. Η θέση μένει στο κινητό.'**
  String get alertWalkExplain;

  /// A button.
  ///
  /// In el, this message translates to:
  /// **'Χρήση της θέσης μου'**
  String get alertUseMyLocation;

  /// No description provided for @alertLeaveNow.
  ///
  /// In el, this message translates to:
  /// **'Φύγε τώρα'**
  String get alertLeaveNow;

  /// Large heading: minutes until the user should set off.
  ///
  /// In el, this message translates to:
  /// **'Φύγε σε {n}′'**
  String alertLeaveIn(int n);

  /// No description provided for @alertAtClock.
  ///
  /// In el, this message translates to:
  /// **'στις {time}'**
  String alertAtClock(String time);

  /// No description provided for @alertWalkTo.
  ///
  /// In el, this message translates to:
  /// **'περπάτημα {n}′ ως {stop}'**
  String alertWalkTo(int n, String stop);

  /// No description provided for @alertTooLate.
  ///
  /// In el, this message translates to:
  /// **'μάλλον δεν προλαβαίνεις αυτό'**
  String get alertTooLate;

  /// A short segment of a timeline bar.
  ///
  /// In el, this message translates to:
  /// **'τώρα · {n}′'**
  String alertBarNow(int n);

  /// A short segment of a timeline bar.
  ///
  /// In el, this message translates to:
  /// **'περπάτημα {n}′'**
  String alertBarWalk(int n);

  /// A short segment of a timeline bar.
  ///
  /// In el, this message translates to:
  /// **'περιμένεις {n}′'**
  String alertBarWait(int n);

  /// Label above chips: how many minutes early to be at the stop.
  ///
  /// In el, this message translates to:
  /// **'Θέλω να είμαι στη στάση'**
  String get alertBeAtStop;

  /// A chip: be at the stop this many minutes before the bus.
  ///
  /// In el, this message translates to:
  /// **'{n}′ πριν'**
  String alertMarginBefore(int n);

  /// No description provided for @alertWalk.
  ///
  /// In el, this message translates to:
  /// **'Περπάτημα'**
  String get alertWalk;

  /// No description provided for @alertLeaveLateHint.
  ///
  /// In el, this message translates to:
  /// **'Αν το λεωφορείο αργήσει, σου λέμε να φύγεις αργότερα: ο χρόνος διορθώνεται με κάθε νέα θέση του λεωφορείου.'**
  String get alertLeaveLateHint;

  /// Under a big minutes number.
  ///
  /// In el, this message translates to:
  /// **'πριν φτάσει'**
  String get alertBeforeArrives;

  /// Under a big number of stops.
  ///
  /// In el, this message translates to:
  /// **'{n, plural, =1{στάση πριν} other{στάσεις πριν}}'**
  String alertStopsBefore(int n);

  /// No description provided for @alertTitle.
  ///
  /// In el, this message translates to:
  /// **'Ειδοποίηση για τη στάση {stop}'**
  String alertTitle(String stop);

  /// The direction of a line.
  ///
  /// In el, this message translates to:
  /// **'προς {headsign}'**
  String alertToward(String headsign);

  /// No description provided for @alertNearStart.
  ///
  /// In el, this message translates to:
  /// **'Η στάση σου είναι κοντά στην αφετηρία: θα σε ειδοποιήσουμε μόλις ξεκινήσει.'**
  String get alertNearStart;

  /// No description provided for @alertMeansNow.
  ///
  /// In el, this message translates to:
  /// **'Τώρα αυτό σημαίνει'**
  String get alertMeansNow;

  /// Followed by a stop name in bold; keep the trailing space.
  ///
  /// In el, this message translates to:
  /// **'όταν είναι στο '**
  String get alertWhenAt;

  /// After the bold stop name of alertWhenAt.
  ///
  /// In el, this message translates to:
  /// **', {n, plural, =1{{n} στάση πριν} other{{n} στάσεις πριν}}'**
  String alertWhenAtTail(int n);

  /// No description provided for @alertTimeUpdates.
  ///
  /// In el, this message translates to:
  /// **'Ο χρόνος διορθώνεται με κάθε νέα θέση του λεωφορείου.'**
  String get alertTimeUpdates;

  /// A button.
  ///
  /// In el, this message translates to:
  /// **'Πες μου πότε να φύγω'**
  String get alertLeaveButton;

  /// A button.
  ///
  /// In el, this message translates to:
  /// **'Ειδοποίησέ με {n}′ πριν'**
  String alertNotifyMinutes(int n);

  /// A button.
  ///
  /// In el, this message translates to:
  /// **'Ειδοποίησέ με {n, plural, =1{{n} στάση} other{{n} στάσεις}} πριν'**
  String alertNotifyStops(int n);

  /// No description provided for @alertMoreOptions.
  ///
  /// In el, this message translates to:
  /// **'Περισσότερες επιλογές'**
  String get alertMoreOptions;

  /// A segmented button.
  ///
  /// In el, this message translates to:
  /// **'Λεπτά πριν'**
  String get alertModeMinutes;

  /// A segmented button.
  ///
  /// In el, this message translates to:
  /// **'Στάσεις πριν'**
  String get alertModeStops;

  /// A segmented button.
  ///
  /// In el, this message translates to:
  /// **'Φύγε εγκαίρως'**
  String get alertModeLeave;

  /// No description provided for @alertLiveLockScreen.
  ///
  /// In el, this message translates to:
  /// **'Live στην οθόνη κλειδώματος'**
  String get alertLiveLockScreen;

  /// No description provided for @alertLiveLockScreenSub.
  ///
  /// In el, this message translates to:
  /// **'Δείχνει την πορεία ως τη στάση σου'**
  String get alertLiveLockScreenSub;

  /// A switch.
  ///
  /// In el, this message translates to:
  /// **'Πες μου και αν αργεί'**
  String get alertLateToo;

  /// No description provided for @alertLateTooSub.
  ///
  /// In el, this message translates to:
  /// **'Μία ειδοποίηση όταν ένα λεωφορείο για τη στάση σου έχει καθυστέρηση {n}′ ή παραπάνω'**
  String alertLateTooSub(int n);

  /// No description provided for @alertWeekdays.
  ///
  /// In el, this message translates to:
  /// **'Κάθε καθημερινή τέτοια ώρα;'**
  String get alertWeekdays;

  /// No description provided for @alertLastOfDay.
  ///
  /// In el, this message translates to:
  /// **'Για το τελευταίο της ημέρας'**
  String get alertLastOfDay;

  /// No description provided for @alertLastOfDaySub.
  ///
  /// In el, this message translates to:
  /// **'Ειδοποίηση 15′ πριν περάσει από εδώ, από το πρόγραμμα'**
  String get alertLastOfDaySub;

  /// No description provided for @ruleEditMinutesBefore.
  ///
  /// In el, this message translates to:
  /// **'{n}′ πριν φτάσει'**
  String ruleEditMinutesBefore(int n);

  /// No description provided for @ruleEditStopsBefore.
  ///
  /// In el, this message translates to:
  /// **'{n, plural, =1{{n} στάση πριν φτάσει} other{{n} στάσεις πριν φτάσει}}'**
  String ruleEditStopsBefore(int n);

  /// A word in the rule sentence: «…tell me when to leave…».
  ///
  /// In el, this message translates to:
  /// **'πότε να φύγω'**
  String get ruleEditWhenLeave;

  /// Screen title.
  ///
  /// In el, this message translates to:
  /// **'Κανόνας'**
  String get ruleEditTitle;

  /// No description provided for @ruleEditNoStop.
  ///
  /// In el, this message translates to:
  /// **'Πρώτα αποθήκευσε μια στάση (καρτέλα Στάσεις).'**
  String get ruleEditNoStop;

  /// Rule sentence: «Every Mon–Fri from 08:00 to 08:40 tell me 5′ before it arrives for the 602 at <stop>».
  ///
  /// In el, this message translates to:
  /// **'Κάθε'**
  String get ruleEditEvery;

  /// Rule sentence word, see ruleEditEvery.
  ///
  /// In el, this message translates to:
  /// **'από'**
  String get ruleEditFrom;

  /// Rule sentence word, see ruleEditEvery.
  ///
  /// In el, this message translates to:
  /// **'ως'**
  String get ruleEditUntil;

  /// Rule sentence word, see ruleEditEvery.
  ///
  /// In el, this message translates to:
  /// **'πες μου'**
  String get ruleEditTellMe;

  /// Rule sentence word before a line number, see ruleEditEvery.
  ///
  /// In el, this message translates to:
  /// **'για το'**
  String get ruleEditForThe;

  /// Rule sentence word before a stop name, see ruleEditEvery.
  ///
  /// In el, this message translates to:
  /// **'στο'**
  String get ruleEditAt;

  /// No description provided for @ruleEditNotServed.
  ///
  /// In el, this message translates to:
  /// **'Το {line} δεν σταματά σε αυτή τη στάση (ή είναι το τέρμα του).'**
  String ruleEditNotServed(String line);

  /// No description provided for @ruleEditLeaveMath.
  ///
  /// In el, this message translates to:
  /// **'Περπάτημα {walk}′ + να είσαι εκεί 5′ νωρίτερα = ειδοποίηση {n}′ πριν φτάσει.'**
  String ruleEditLeaveMath(int walk, int n);

  /// No description provided for @ruleEditEndAfterStart.
  ///
  /// In el, this message translates to:
  /// **'Το τέλος πρέπει να είναι μετά την αρχή.'**
  String get ruleEditEndAfterStart;

  /// No description provided for @ruleEditLateSub.
  ///
  /// In el, this message translates to:
  /// **'Όταν η καθυστέρηση φτάσει {n}′'**
  String ruleEditLateSub(int n);

  /// A button tooltip.
  ///
  /// In el, this message translates to:
  /// **'15′ νωρίτερα'**
  String get ruleEditEarlier;

  /// A button tooltip.
  ///
  /// In el, this message translates to:
  /// **'15′ αργότερα'**
  String get ruleEditLater;

  /// No description provided for @ruleEditPickStopFirst.
  ///
  /// In el, this message translates to:
  /// **'Διάλεξε πρώτα στάση.'**
  String get ruleEditPickStopFirst;

  /// Two-letter weekday: Monday.
  ///
  /// In el, this message translates to:
  /// **'Δε'**
  String get rulesDayMon;

  /// Two-letter weekday: Tuesday.
  ///
  /// In el, this message translates to:
  /// **'Τρ'**
  String get rulesDayTue;

  /// Two-letter weekday: Wednesday.
  ///
  /// In el, this message translates to:
  /// **'Τε'**
  String get rulesDayWed;

  /// Two-letter weekday: Thursday.
  ///
  /// In el, this message translates to:
  /// **'Πε'**
  String get rulesDayThu;

  /// Two-letter weekday: Friday.
  ///
  /// In el, this message translates to:
  /// **'Πα'**
  String get rulesDayFri;

  /// Two-letter weekday: Saturday.
  ///
  /// In el, this message translates to:
  /// **'Σα'**
  String get rulesDaySat;

  /// Two-letter weekday: Sunday.
  ///
  /// In el, this message translates to:
  /// **'Κυ'**
  String get rulesDaySun;

  /// Weekdays, Monday to Friday.
  ///
  /// In el, this message translates to:
  /// **'Δε–Πα'**
  String get rulesMonFri;

  /// No description provided for @rulesEveryDay.
  ///
  /// In el, this message translates to:
  /// **'Κάθε μέρα'**
  String get rulesEveryDay;

  /// The weekend, Saturday and Sunday.
  ///
  /// In el, this message translates to:
  /// **'Σα–Κυ'**
  String get rulesWeekend;

  /// No description provided for @rulesMinutesBefore.
  ///
  /// In el, this message translates to:
  /// **'{n}′ πριν'**
  String rulesMinutesBefore(int n);

  /// No description provided for @rulesStopsBefore.
  ///
  /// In el, this message translates to:
  /// **'{n, plural, =1{{n} στάση πριν} other{{n} στάσεις πριν}}'**
  String rulesStopsBefore(int n);

  /// No description provided for @rulesAndIfLate.
  ///
  /// In el, this message translates to:
  /// **'και αν αργεί'**
  String get rulesAndIfLate;

  /// A button.
  ///
  /// In el, this message translates to:
  /// **'Νέος κανόνας'**
  String get rulesNewRule;

  /// Section heading: alerts active now.
  ///
  /// In el, this message translates to:
  /// **'Τώρα'**
  String get rulesNow;

  /// No description provided for @rulesNowEmpty.
  ///
  /// In el, this message translates to:
  /// **'Πάτα το καμπανάκι δίπλα σε μια γραμμή στη στάση σου.'**
  String get rulesNowEmpty;

  /// No description provided for @rulesTrip.
  ///
  /// In el, this message translates to:
  /// **'Ταξίδι με το {line} · κατεβαίνεις {stop}'**
  String rulesTrip(String line, String stop);

  /// No description provided for @rulesStoppedFromCard.
  ///
  /// In el, this message translates to:
  /// **'Σταμάτησε από την κάρτα live'**
  String get rulesStoppedFromCard;

  /// No description provided for @rulesUntil.
  ///
  /// In el, this message translates to:
  /// **'ως {time}'**
  String rulesUntil(String time);

  /// Section heading: weekly rules.
  ///
  /// In el, this message translates to:
  /// **'Κάθε εβδομάδα'**
  String get rulesWeekly;

  /// No description provided for @rulesWeeklyEmpty.
  ///
  /// In el, this message translates to:
  /// **'Π.χ. «Δε–Πα 08:00–08:40, 5′ πριν το 602 στη στάση σου».'**
  String get rulesWeeklyEmpty;

  /// No description provided for @rulesPaused.
  ///
  /// In el, this message translates to:
  /// **'Σε παύση'**
  String get rulesPaused;

  /// No description provided for @rulesStoppedToday.
  ///
  /// In el, this message translates to:
  /// **'Σταμάτησε για σήμερα'**
  String get rulesStoppedToday;

  /// No description provided for @rulesRunningNow.
  ///
  /// In el, this message translates to:
  /// **'Τρέχει τώρα'**
  String get rulesRunningNow;

  /// {when} is rulesToday, rulesTomorrow or rulesInDays.
  ///
  /// In el, this message translates to:
  /// **'Επόμενη: {when} {time}'**
  String rulesNext(String when, String time);

  /// No description provided for @rulesToday.
  ///
  /// In el, this message translates to:
  /// **'σήμερα'**
  String get rulesToday;

  /// No description provided for @rulesTomorrow.
  ///
  /// In el, this message translates to:
  /// **'αύριο'**
  String get rulesTomorrow;

  /// Two or more days.
  ///
  /// In el, this message translates to:
  /// **'σε {n} μέρες'**
  String rulesInDays(int n);

  /// A button.
  ///
  /// In el, this message translates to:
  /// **'Συνέχισε'**
  String get rulesResume;

  /// No description provided for @rulesExactHint.
  ///
  /// In el, this message translates to:
  /// **'Οι κανόνες μπορεί να ξεκινούν λίγα λεπτά αργότερα: το Android δεν μας έχει δώσει άδεια για ακριβή ξυπνητήρια.'**
  String get rulesExactHint;

  /// A button: grant the exact-alarm permission.
  ///
  /// In el, this message translates to:
  /// **'Δώσε άδεια'**
  String get rulesGrant;

  /// No description provided for @followNoLocation.
  ///
  /// In el, this message translates to:
  /// **'Χρειάζεται άδεια τοποθεσίας για να καταλάβει η εφαρμογή πότε ανεβαίνεις.'**
  String get followNoLocation;

  /// No description provided for @followStopNotOnLine.
  ///
  /// In el, this message translates to:
  /// **'Η στάση δεν βρέθηκε στη γραμμή.'**
  String get followStopNotOnLine;

  /// No description provided for @followNotStarted.
  ///
  /// In el, this message translates to:
  /// **'Δεν ξεκίνησε η ειδοποίηση. Πάτα ξανά με την εφαρμογή ανοιχτή.'**
  String get followNotStarted;

  /// No description provided for @followLineNotLoaded.
  ///
  /// In el, this message translates to:
  /// **'Δεν φόρτωσε η γραμμή. Δοκίμασε ξανά με σύνδεση.'**
  String get followLineNotLoaded;

  /// No description provided for @followReady.
  ///
  /// In el, this message translates to:
  /// **'Έτοιμο. Ανέβα στο {line} και θα σε ειδοποιήσουμε μία στάση πριν από {stop}, ακόμη κι αν η εφαρμογή είναι κλειστή.'**
  String followReady(String line, String stop);

  /// A button: stop following the trip.
  ///
  /// In el, this message translates to:
  /// **'Σταμάτα'**
  String get followStop;

  /// A button.
  ///
  /// In el, this message translates to:
  /// **'Πες μου πότε να κατέβω'**
  String get followButton;

  /// No description provided for @rideNoBus.
  ///
  /// In el, this message translates to:
  /// **'Δεν βρέθηκε λεωφορείο κοντά σου. Διάλεξέ το στον χάρτη και πάτα «Πού κατεβαίνω;».'**
  String get rideNoBus;

  /// No description provided for @rideAtTerminus.
  ///
  /// In el, this message translates to:
  /// **'Το λεωφορείο είναι στο τέρμα: καμία στάση μετά.'**
  String get rideAtTerminus;

  /// No description provided for @rideWhere.
  ///
  /// In el, this message translates to:
  /// **'Πού κατεβαίνεις;'**
  String get rideWhere;

  /// No description provided for @rideVibrate.
  ///
  /// In el, this message translates to:
  /// **'Θα δονηθεί το κινητό μία στάση πριν: «Κατέβα στην επόμενη».'**
  String get rideVibrate;

  /// «Ειδοποιήσεις» is the alerts screen of the app.
  ///
  /// In el, this message translates to:
  /// **'Θα δονηθεί το κινητό μία στάση πριν: «Κατέβα στην επόμενη». Το βλέπεις και στις Ειδοποιήσεις.'**
  String get rideVibrateAlerts;

  /// No description provided for @rideOnBoard.
  ///
  /// In el, this message translates to:
  /// **'Είσαι μέσα · θα σε ειδοποιήσουμε'**
  String get rideOnBoard;

  /// No description provided for @rideNoPermission.
  ///
  /// In el, this message translates to:
  /// **'Χωρίς άδεια ειδοποιήσεων'**
  String get rideNoPermission;

  /// Above a big stop name.
  ///
  /// In el, this message translates to:
  /// **'Κατεβαίνεις στο'**
  String get rideGetOffAt;

  /// {mins} is a short time such as 5′.
  ///
  /// In el, this message translates to:
  /// **'περίπου {mins}'**
  String rideAbout(String mins);

  /// A button with a + icon: add a stop.
  ///
  /// In el, this message translates to:
  /// **'Στάση'**
  String get favsAddStop;

  /// No description provided for @favsWhereHome.
  ///
  /// In el, this message translates to:
  /// **'Πού είναι το σπίτι σου;'**
  String get favsWhereHome;

  /// No description provided for @favsPlacesSub.
  ///
  /// In el, this message translates to:
  /// **'Μέρη: σπίτι, δουλειά και άλλα · μένουν μόνο στο κινητό'**
  String get favsPlacesSub;

  /// Page title: the saved places (home, work, others).
  ///
  /// In el, this message translates to:
  /// **'Μέρη'**
  String get favsPlaces;

  /// No description provided for @favsMorning.
  ///
  /// In el, this message translates to:
  /// **'Πρωί: πρώτα η στάση του σπιτιού'**
  String get favsMorning;

  /// No description provided for @favsAfternoon.
  ///
  /// In el, this message translates to:
  /// **'Απόγευμα: πρώτα η στάση της δουλειάς'**
  String get favsAfternoon;

  /// No description provided for @favsEmpty.
  ///
  /// In el, this message translates to:
  /// **'Καμία αποθηκευμένη στάση ακόμη. Πάτα «+ Στάση».'**
  String get favsEmpty;

  /// Section heading.
  ///
  /// In el, this message translates to:
  /// **'Στάσεις'**
  String get favsStops;

  /// Section heading.
  ///
  /// In el, this message translates to:
  /// **'Γραμμές'**
  String get favsLines;

  /// No description provided for @favsLinesEmpty.
  ///
  /// In el, this message translates to:
  /// **'Καμία γραμμή ακόμη. Πάτα το αστέρι σε μια γραμμή για να τη βλέπεις εδώ.'**
  String get favsLinesEmpty;

  /// No description provided for @favsLastHome.
  ///
  /// In el, this message translates to:
  /// **'Το τελευταίο {line} για το σπίτι'**
  String favsLastHome(String line);

  /// No description provided for @favsLastHomeBody.
  ///
  /// In el, this message translates to:
  /// **'Φεύγει {departs} από {from} και περνά ~{time} από {stop}. Πρόγραμμα, όχι live.'**
  String favsLastHomeBody(
    String departs,
    String from,
    String time,
    String stop,
  );

  /// No description provided for @favsWillNotify.
  ///
  /// In el, this message translates to:
  /// **'Θα σε ειδοποιήσουμε'**
  String get favsWillNotify;

  /// No description provided for @favsNoGpsBus.
  ///
  /// In el, this message translates to:
  /// **'κανένα λεωφορείο με GPS τώρα'**
  String get favsNoGpsBus;

  /// Buses of a line on the road now.
  ///
  /// In el, this message translates to:
  /// **'{n} στον δρόμο'**
  String favsOnRoad(int n);

  /// No description provided for @favsAllOnTime.
  ///
  /// In el, this message translates to:
  /// **'όλα στην ώρα τους'**
  String get favsAllOnTime;

  /// Buses running late.
  ///
  /// In el, this message translates to:
  /// **'{n, plural, =1{{n} αργεί} other{{n} αργούν}}'**
  String favsLate(int n);

  /// Menu tooltip.
  ///
  /// In el, this message translates to:
  /// **'Επιλογές'**
  String get favsOptions;

  /// No description provided for @favsIsHome.
  ///
  /// In el, this message translates to:
  /// **'Είναι το σπίτι'**
  String get favsIsHome;

  /// No description provided for @favsIsWork.
  ///
  /// In el, this message translates to:
  /// **'Είναι η δουλειά'**
  String get favsIsWork;

  /// No description provided for @favsNeither.
  ///
  /// In el, this message translates to:
  /// **'Ούτε σπίτι ούτε δουλειά'**
  String get favsNeither;

  /// No description provided for @favsRemove.
  ///
  /// In el, this message translates to:
  /// **'Αφαίρεση'**
  String get favsRemove;

  /// No description provided for @favsQuiet.
  ///
  /// In el, this message translates to:
  /// **'Χωρίς λεωφορείο με GPS τώρα: {lines}'**
  String favsQuiet(String lines);

  /// No description provided for @favsAllLines.
  ///
  /// In el, this message translates to:
  /// **'Όλες οι γραμμές εδώ ({n}) ›'**
  String favsAllLines(int n);

  /// No description provided for @addStopTitle.
  ///
  /// In el, this message translates to:
  /// **'Ποια στάση θέλεις να κρατήσεις;'**
  String get addStopTitle;

  /// No description provided for @addStopSub.
  ///
  /// In el, this message translates to:
  /// **'Θα τη βρίσκεις στα αγαπημένα, με τις γραμμές που διαλέγεις.'**
  String get addStopSub;

  /// No description provided for @addStopSearchHint.
  ///
  /// In el, this message translates to:
  /// **'Γράψε το όνομα της στάσης'**
  String get addStopSearchHint;

  /// No description provided for @addStopSearchHintOr.
  ///
  /// In el, this message translates to:
  /// **'Ή γράψε το όνομα της στάσης'**
  String get addStopSearchHintOr;

  /// No description provided for @addStopNone.
  ///
  /// In el, this message translates to:
  /// **'Δεν βρέθηκε στάση. Γράψε το όνομά της.'**
  String get addStopNone;

  /// A distance in metres.
  ///
  /// In el, this message translates to:
  /// **'{m} μ.'**
  String addStopMeters(int m);

  /// No description provided for @addStopWhichLines.
  ///
  /// In el, this message translates to:
  /// **'Ποιες γραμμές σε νοιάζουν εδώ;'**
  String get addStopWhichLines;

  /// No description provided for @addStopMaxLines.
  ///
  /// In el, this message translates to:
  /// **'Ως {n} γραμμές συνολικά.'**
  String addStopMaxLines(int n);

  /// A disabled button says what is missing.
  ///
  /// In el, this message translates to:
  /// **'Διάλεξε στάση'**
  String get addStopPickStop;

  /// A disabled button says what is missing.
  ///
  /// In el, this message translates to:
  /// **'Διάλεξε τουλάχιστον μία γραμμή'**
  String get addStopPickLine;

  /// No description provided for @linesPickerMax.
  ///
  /// In el, this message translates to:
  /// **'Ως {n} γραμμές σε όλη την εφαρμογή.'**
  String linesPickerMax(int n);

  /// A loop line heading back to {place}.
  ///
  /// In el, this message translates to:
  /// **'{place} (επιστροφή)'**
  String stopReturn(String place);

  /// A button tooltip.
  ///
  /// In el, this message translates to:
  /// **'Ειδοποίηση για το {line}: ενεργή'**
  String stopBellOn(String line);

  /// A button tooltip.
  ///
  /// In el, this message translates to:
  /// **'Ειδοποίησέ με για το {line}'**
  String stopBellOff(String line);

  /// No description provided for @stopLinesCount.
  ///
  /// In el, this message translates to:
  /// **'{n, plural, =1{{n} γραμμή} other{{n} γραμμές}}'**
  String stopLinesCount(int n);

  /// No description provided for @stopAcross.
  ///
  /// In el, this message translates to:
  /// **'Απέναντι στάση · {m} μ.'**
  String stopAcross(int m);

  /// A button tooltip.
  ///
  /// In el, this message translates to:
  /// **'Αποθήκευση στάσης'**
  String get stopSave;

  /// A button tooltip.
  ///
  /// In el, this message translates to:
  /// **'Αποθηκευμένη στάση'**
  String get stopSaved;

  /// A button: plan a trip to this stop.
  ///
  /// In el, this message translates to:
  /// **'Πώς πάω εκεί'**
  String get stopHowToGet;

  /// A button: plan a trip from this stop.
  ///
  /// In el, this message translates to:
  /// **'Ταξίδι από εδώ'**
  String get stopTripFrom;

  /// No description provided for @stopEstimate.
  ///
  /// In el, this message translates to:
  /// **'Οι χρόνοι είναι εκτίμηση από τα τελευταία δεδομένα και την ταχύτητα που έχει συνήθως η γραμμή. Διορθώνονται μόλις βρεθεί σήμα.'**
  String get stopEstimate;

  /// No description provided for @stopNoBus.
  ///
  /// In el, this message translates to:
  /// **'Κανένα λεωφορείο με GPS δεν έρχεται τώρα.'**
  String get stopNoBus;

  /// Section heading.
  ///
  /// In el, this message translates to:
  /// **'Οι γραμμές σου'**
  String get stopYourLines;

  /// Section heading.
  ///
  /// In el, this message translates to:
  /// **'Περνούν επίσης'**
  String get stopAlsoHere;

  /// No description provided for @stopAllLines.
  ///
  /// In el, this message translates to:
  /// **'Όλες οι γραμμές · +{n} ›'**
  String stopAllLines(int n);

  /// No description provided for @stopMissed.
  ///
  /// In el, this message translates to:
  /// **'Δεν ξεκίνησαν · δεν φάνηκε λεωφορείο να φεύγει από την αφετηρία'**
  String get stopMissed;

  /// No description provided for @stopMissedRun.
  ///
  /// In el, this message translates to:
  /// **'→ {headsign} · των {time}'**
  String stopMissedRun(String headsign, String time);

  /// A button: plan another way.
  ///
  /// In el, this message translates to:
  /// **'Άλλη επιλογή'**
  String get stopOtherOption;

  /// No description provided for @stopPlanned.
  ///
  /// In el, this message translates to:
  /// **'Δεν ξεκίνησαν ακόμη · από το πρόγραμμα'**
  String get stopPlanned;

  /// No description provided for @stopPlannedNote.
  ///
  /// In el, this message translates to:
  /// **'Ώρα αναχώρησης από την αφετηρία + η διαδρομή ως εδώ με μέση ταχύτητα. Όχι live.'**
  String get stopPlannedNote;

  /// No description provided for @stopQuiet.
  ///
  /// In el, this message translates to:
  /// **'Χωρίς λεωφορείο κοντά τώρα: {lines}'**
  String stopQuiet(String lines);

  /// No description provided for @stopFixSent.
  ///
  /// In el, this message translates to:
  /// **'Έστειλες διόρθωση θέσης για αυτή τη στάση. Ευχαριστούμε!'**
  String get stopFixSent;

  /// A button: report that the stop is in the wrong place on the map.
  ///
  /// In el, this message translates to:
  /// **'Λάθος θέση;'**
  String get stopWrongPlace;

  /// No description provided for @vehicleOffline.
  ///
  /// In el, this message translates to:
  /// **'Δεν φορτώνει το λεωφορείο: χωρίς σύνδεση. Νέα προσπάθεια σε λίγο.'**
  String get vehicleOffline;

  /// No description provided for @vehicleGone.
  ///
  /// In el, this message translates to:
  /// **'Το λεωφορείο #{id} δεν στέλνει θέση τώρα: μάλλον τελείωσε το δρομολόγιό του.'**
  String vehicleGone(String id);

  /// No description provided for @vehicleSeeLine.
  ///
  /// In el, this message translates to:
  /// **'Δες τα λεωφορεία του {line}'**
  String vehicleSeeLine(String line);

  /// No description provided for @vehicleAtYourStop.
  ///
  /// In el, this message translates to:
  /// **'στη στάση σου · {stop}'**
  String vehicleAtYourStop(String stop);

  /// No description provided for @vehicleAtNextStop.
  ///
  /// In el, this message translates to:
  /// **'στην επόμενη στάση · {stop}'**
  String vehicleAtNextStop(String stop);

  /// A button.
  ///
  /// In el, this message translates to:
  /// **'Ειδοποίησέ με'**
  String get vehicleNotify;

  /// A button.
  ///
  /// In el, this message translates to:
  /// **'Πού κατεβαίνω;'**
  String get vehicleWhereGetOff;

  /// No description provided for @vehicleDetails.
  ///
  /// In el, this message translates to:
  /// **'Λεπτομέρειες'**
  String get vehicleDetails;

  /// No description provided for @vehicleNoSpeed.
  ///
  /// In el, this message translates to:
  /// **'— χλμ/ώ'**
  String get vehicleNoSpeed;

  /// No description provided for @vehicleSpeed.
  ///
  /// In el, this message translates to:
  /// **'{speed} χλμ/ώ'**
  String vehicleSpeed(int speed);

  /// A link to the speeds of the line.
  ///
  /// In el, this message translates to:
  /// **'ταχύτητες γραμμής'**
  String get vehicleLineSpeeds;

  /// The usual speed in km/h.
  ///
  /// In el, this message translates to:
  /// **'συνήθως {usual}'**
  String vehicleUsually(int usual);

  /// {ago} is a short age such as 20″ or 2′.
  ///
  /// In el, this message translates to:
  /// **'θέση πριν {ago}'**
  String vehicleFixAge(String ago);

  /// No description provided for @vehicleId.
  ///
  /// In el, this message translates to:
  /// **'όχημα {id}'**
  String vehicleId(String id);

  /// No description provided for @vehicleTrip.
  ///
  /// In el, this message translates to:
  /// **'δρομολόγιο {trip}'**
  String vehicleTrip(String trip);

  /// Section heading.
  ///
  /// In el, this message translates to:
  /// **'Επόμενες στάσεις'**
  String get vehicleNextStops;

  /// No description provided for @vehicleAllNext.
  ///
  /// In el, this message translates to:
  /// **'Όλες οι επόμενες ({n})'**
  String vehicleAllNext(int n);

  /// No description provided for @vehicleUnknownTrip.
  ///
  /// In el, this message translates to:
  /// **'Δεν ξέρουμε ακόμη ποιο δρομολόγιο κάνει το λεωφορείο.'**
  String get vehicleUnknownTrip;

  /// No description provided for @vehicleYourStop.
  ///
  /// In el, this message translates to:
  /// **'{stop} · η στάση σου'**
  String vehicleYourStop(String stop);

  /// No description provided for @vehicleWhichStop.
  ///
  /// In el, this message translates to:
  /// **'Σε ποια στάση;'**
  String get vehicleWhichStop;

  /// No description provided for @vehicleWhichStopSub.
  ///
  /// In el, this message translates to:
  /// **'Θα σε ειδοποιήσουμε πριν φτάσει εκεί το λεωφορείο.'**
  String get vehicleWhichStopSub;

  /// A kicker in capitals above a card title; keep it in capitals.
  ///
  /// In el, this message translates to:
  /// **'ΓΥΡΝΑΣ ΣΠΙΤΙ'**
  String get goHomeKickerHome;

  /// A kicker in capitals above a card title; keep it in capitals.
  ///
  /// In el, this message translates to:
  /// **'ΠΑΜΕ ΔΟΥΛΕΙΑ'**
  String get goHomeKickerWork;

  /// A kicker in capitals; {stop} is already in capitals.
  ///
  /// In el, this message translates to:
  /// **'ΑΠΟ {stop}'**
  String goHomeKickerFrom(String stop);

  /// No description provided for @goHomeAskHomeSub.
  ///
  /// In el, this message translates to:
  /// **'Αρκεί μια περιοχή. Μένει μόνο στο κινητό σου.'**
  String get goHomeAskHomeSub;

  /// No description provided for @goHomeNoneComing.
  ///
  /// In el, this message translates to:
  /// **'Κανένα από {lines} δεν έρχεται τώρα'**
  String goHomeNoneComing(String lines);

  /// No description provided for @goHomeNext.
  ///
  /// In el, this message translates to:
  /// **'Το {line} → {toward}'**
  String goHomeNext(String line, String toward);

  /// No description provided for @goHomeWith.
  ///
  /// In el, this message translates to:
  /// **'Με το {line} από {stop}'**
  String goHomeWith(String line, String stop);

  /// No description provided for @goHomeNoDirect.
  ///
  /// In el, this message translates to:
  /// **'Χωρίς απευθείας λεωφορείο'**
  String get goHomeNoDirect;

  /// The start of a trip: where the phone is.
  ///
  /// In el, this message translates to:
  /// **'Η θέση μου'**
  String get goHomeMyLocation;

  /// {mins} is a short time such as 5′.
  ///
  /// In el, this message translates to:
  /// **'περνά σε {mins}'**
  String goHomePassesIn(String mins);

  /// No description provided for @goHomeTapForRoute.
  ///
  /// In el, this message translates to:
  /// **'Πάτα για διαδρομή με αλλαγή ή μετρό.'**
  String get goHomeTapForRoute;

  /// Small label above a minutes value.
  ///
  /// In el, this message translates to:
  /// **'φύγε σε'**
  String get goHomeLeaveIn;

  /// The last runs home today; {runs} is a list of goHomeRunAt.
  ///
  /// In el, this message translates to:
  /// **'{n, plural, =1{τελευταίο} other{τελευταία}}: {runs}'**
  String goHomeLast(int n, String runs);

  /// No description provided for @goHomeRunAt.
  ///
  /// In el, this message translates to:
  /// **'{line} στις {time}'**
  String goHomeRunAt(String line, String time);

  /// No description provided for @stopfixThanks.
  ///
  /// In el, this message translates to:
  /// **'Ευχαριστούμε, το λάβαμε!'**
  String get stopfixThanks;

  /// No description provided for @stopfixNotImmediate.
  ///
  /// In el, this message translates to:
  /// **'Η στάση δεν αλλάζει αμέσως: κάθε πρόταση ελέγχεται με το GPS των λεωφορείων.'**
  String get stopfixNotImmediate;

  /// No description provided for @stopfixTapMap.
  ///
  /// In el, this message translates to:
  /// **'Πάτα στον χάρτη εκεί που είναι το κολωνάκι'**
  String get stopfixTapMap;

  /// No description provided for @stopfixTooFar.
  ///
  /// In el, this message translates to:
  /// **'Πάνω από {m} μ. από τη στάση. Φέρε την πιο κοντά.'**
  String stopfixTooFar(int m);

  /// No description provided for @stopfixFailed.
  ///
  /// In el, this message translates to:
  /// **'Δεν στάλθηκε. Έλεγξε τη σύνδεση και ξαναδοκίμασε.'**
  String get stopfixFailed;

  /// No description provided for @stopfixKnown.
  ///
  /// In el, this message translates to:
  /// **'Η μικρή τελεία είναι η θέση που ξέρουμε.'**
  String get stopfixKnown;

  /// No description provided for @stopfixMoved.
  ///
  /// In el, this message translates to:
  /// **'Μετακίνηση {m} μ.'**
  String stopfixMoved(int m);

  /// No description provided for @stopfixSending.
  ///
  /// In el, this message translates to:
  /// **'Αποστολή…'**
  String get stopfixSending;

  /// A button.
  ///
  /// In el, this message translates to:
  /// **'Αποστολή'**
  String get stopfixSend;

  /// No description provided for @stopfixStreetView.
  ///
  /// In el, this message translates to:
  /// **'Δες το σημείο στο Street View ›'**
  String get stopfixStreetView;

  /// No description provided for @stopfixPrivacy.
  ///
  /// In el, this message translates to:
  /// **'Στέλνεται η θέση της πινέζας, η στάση και ένας τυχαίος κωδικός συσκευής.'**
  String get stopfixPrivacy;

  /// No description provided for @menuCity.
  ///
  /// In el, this message translates to:
  /// **'Πόλη'**
  String get menuCity;

  /// Menu item and page title: the trip planner.
  ///
  /// In el, this message translates to:
  /// **'Διαδρομή'**
  String get menuPlanner;

  /// No description provided for @menuLines.
  ///
  /// In el, this message translates to:
  /// **'Γραμμές'**
  String get menuLines;

  /// Menu item: the operator's announcements (strikes, changed routes).
  ///
  /// In el, this message translates to:
  /// **'Ενημερώσεις'**
  String get menuUpdates;

  /// Menu item: the user's alert rules.
  ///
  /// In el, this message translates to:
  /// **'Ειδοποιήσεις'**
  String get menuAlerts;

  /// No description provided for @menuPlaces.
  ///
  /// In el, this message translates to:
  /// **'Μέρη'**
  String get menuPlaces;

  /// Menu item: the Android home-screen widgets.
  ///
  /// In el, this message translates to:
  /// **'Widgets'**
  String get menuWidgets;

  /// No description provided for @menuStats.
  ///
  /// In el, this message translates to:
  /// **'Στατιστικά'**
  String get menuStats;

  /// No description provided for @menuSettings.
  ///
  /// In el, this message translates to:
  /// **'Ρυθμίσεις'**
  String get menuSettings;

  /// No description provided for @menuAbout.
  ///
  /// In el, this message translates to:
  /// **'Σχετικά'**
  String get menuAbout;

  /// No description provided for @menuHowItWorks.
  ///
  /// In el, this message translates to:
  /// **'Πώς δουλεύει'**
  String get menuHowItWorks;

  /// After the agency in the city picker: «ΟΣΕΘ · λεωφορεία».
  ///
  /// In el, this message translates to:
  /// **'λεωφορεία'**
  String get menuCityBuses;

  /// A button: the list of lines failed to load.
  ///
  /// In el, this message translates to:
  /// **'Δεν φόρτωσαν. Δοκίμασε ξανά'**
  String get menuLinesError;

  /// No description provided for @menuLinesHint.
  ///
  /// In el, this message translates to:
  /// **'Αριθμός ή όνομα γραμμής'**
  String get menuLinesHint;

  /// No description provided for @menuUpdatesSoon.
  ///
  /// In el, this message translates to:
  /// **'Εδώ θα βλέπεις τις ανακοινώσεις του ΟΑΣΑ: απεργίες, αλλαγές γραμμών. Έρχεται σύντομα.'**
  String get menuUpdatesSoon;

  /// No description provided for @menuPlaceAdd.
  ///
  /// In el, this message translates to:
  /// **'Πρόσθεσε διεύθυνση ή περιοχή'**
  String get menuPlaceAdd;

  /// After a saved place's label: the place is an area, not an exact address.
  ///
  /// In el, this message translates to:
  /// **'περίπου'**
  String get menuPlaceApprox;

  /// No description provided for @menuOtherPlace.
  ///
  /// In el, this message translates to:
  /// **'Άλλο μέρος'**
  String get menuOtherPlace;

  /// No description provided for @menuPlacesNote.
  ///
  /// In el, this message translates to:
  /// **'Αρκεί μια περιοχή. Δεν κρατάμε κανένα δεδομένο: τα μέρη μένουν μόνο στο κινητό σου. Με το «Σπίτι» βλέπεις πώς γυρνάς· με τη «Δουλειά», πώς πας το πρωί.'**
  String get menuPlacesNote;

  /// No description provided for @menuNewPlace.
  ///
  /// In el, this message translates to:
  /// **'Νέο μέρος'**
  String get menuNewPlace;

  /// No description provided for @menuNewPlaceHint.
  ///
  /// In el, this message translates to:
  /// **'Όνομα, π.χ. Σχολείο'**
  String get menuNewPlaceHint;

  /// The name of a home-screen widget.
  ///
  /// In el, this message translates to:
  /// **'«Η στάση μου»'**
  String get menuWidgetStop;

  /// No description provided for @menuWidgetStopBody.
  ///
  /// In el, this message translates to:
  /// **'Οι επόμενες αφίξεις στην αγαπημένη σου στάση.'**
  String get menuWidgetStopBody;

  /// The name of a home-screen widget.
  ///
  /// In el, this message translates to:
  /// **'«Γυρνάς σπίτι»'**
  String get menuWidgetHome;

  /// No description provided for @menuWidgetHomeBody.
  ///
  /// In el, this message translates to:
  /// **'Τα τελευταία λεωφορεία για το σπίτι σήμερα. Γεμίζει όταν ανοίξεις την εφαρμογή μακριά από το σπίτι.'**
  String get menuWidgetHomeBody;

  /// No description provided for @menuLinkIdea.
  ///
  /// In el, this message translates to:
  /// **'Πρότεινε μια ιδέα'**
  String get menuLinkIdea;

  /// No description provided for @menuLinkWrongStop.
  ///
  /// In el, this message translates to:
  /// **'Λάθος θέση στάσης; Πες μας'**
  String get menuLinkWrongStop;

  /// No description provided for @menuLinkAbout.
  ///
  /// In el, this message translates to:
  /// **'Σχετικά · δεδομένα · ανοιχτό API'**
  String get menuLinkAbout;

  /// No description provided for @menuLinkWeb.
  ///
  /// In el, this message translates to:
  /// **'Ο χάρτης στο web'**
  String get menuLinkWeb;

  /// In About and on the welcome: the app must not pass as an operator's official app.
  ///
  /// In el, this message translates to:
  /// **'Ανεπίσημη εφαρμογή. Δεν έχει σχέση με τον ΟΑΣΑ, τον ΟΑΣΘ, τη ΣΤΑΣΥ ή την Hellenic Train, και δεν εκπροσωπεί κανέναν από αυτούς.'**
  String get menuUnofficialNote;

  /// No description provided for @menuVersion.
  ///
  /// In el, this message translates to:
  /// **'Έκδοση {version}'**
  String menuVersion(String version);

  /// No description provided for @menuTerms.
  ///
  /// In el, this message translates to:
  /// **'Όροι χρήσης'**
  String get menuTerms;

  /// No description provided for @menuPrivacy.
  ///
  /// In el, this message translates to:
  /// **'Πολιτική απορρήτου'**
  String get menuPrivacy;

  /// No description provided for @menuLicenses.
  ///
  /// In el, this message translates to:
  /// **'Άδειες ανοιχτού κώδικα'**
  String get menuLicenses;

  /// No description provided for @menuDataSources.
  ///
  /// In el, this message translates to:
  /// **'Πηγές δεδομένων: ΟΑΣΑ (GTFS, άδεια CC BY-NC, και δημόσια δεδομένα telematics) · ΟΑΣΘ (δημόσια δεδομένα, data.gov.gr) · ΣΤΑΣΥ (GTFS) · Hellenic Train (railway.gov.gr). Χάρτης: OpenFreeMap, © OpenStreetMap contributors. Αναζήτηση διευθύνσεων: Photon (komoot), © OpenStreetMap contributors.'**
  String get menuDataSources;

  /// No description provided for @settingsTheme.
  ///
  /// In el, this message translates to:
  /// **'Θέμα'**
  String get settingsTheme;

  /// Theme choice: follow the phone.
  ///
  /// In el, this message translates to:
  /// **'Σύστημα'**
  String get settingsThemeSystem;

  /// Theme choice.
  ///
  /// In el, this message translates to:
  /// **'Ανοιχτό'**
  String get settingsThemeLight;

  /// Theme choice.
  ///
  /// In el, this message translates to:
  /// **'Σκούρο'**
  String get settingsThemeDark;

  /// No description provided for @settingsWalk.
  ///
  /// In el, this message translates to:
  /// **'Περπάτημα ως τη στάση του σπιτιού'**
  String get settingsWalk;

  /// No description provided for @settingsWalkNote.
  ///
  /// In el, this message translates to:
  /// **'Για τον κανόνα «πότε να φύγω».'**
  String get settingsWalkNote;

  /// No description provided for @settingsLiveCard.
  ///
  /// In el, this message translates to:
  /// **'Live κάρτα στις νέες ειδοποιήσεις'**
  String get settingsLiveCard;

  /// No description provided for @settingsLiveCardBody.
  ///
  /// In el, this message translates to:
  /// **'Η πορεία του λεωφορείου στην οθόνη κλειδώματος. Αλλάζει και σε κάθε ειδοποίηση.'**
  String get settingsLiveCardBody;

  /// No description provided for @settingsLastBus.
  ///
  /// In el, this message translates to:
  /// **'Παρασκευή και Σάββατο βράδυ: το τελευταίο για το σπίτι'**
  String get settingsLastBus;

  /// No description provided for @settingsLastBusBody.
  ///
  /// In el, this message translates to:
  /// **'Στις 21:00 μια ειδοποίηση με το τελευταίο λεωφορείο της στάσης «Σπίτι»'**
  String get settingsLastBusBody;

  /// No description provided for @settingsMapHelp.
  ///
  /// In el, this message translates to:
  /// **'Πώς διαβάζεται ο χάρτης'**
  String get settingsMapHelp;

  /// No description provided for @settingsMapHelpBody.
  ///
  /// In el, this message translates to:
  /// **'Χρώματα, σύμβολα, από πού έρχονται οι χρόνοι'**
  String get settingsMapHelpBody;

  /// No description provided for @settingsDeleteAll.
  ///
  /// In el, this message translates to:
  /// **'Διαγραφή όλων των δεδομένων'**
  String get settingsDeleteAll;

  /// No description provided for @settingsDeleteAllBody.
  ///
  /// In el, this message translates to:
  /// **'Αγαπημένα, μέρη, ειδοποιήσεις, ρυθμίσεις. Η εφαρμογή ξεκινά από την αρχή.'**
  String get settingsDeleteAllBody;

  /// No description provided for @settingsDeleteAllTitle.
  ///
  /// In el, this message translates to:
  /// **'Διαγραφή όλων των δεδομένων;'**
  String get settingsDeleteAllTitle;

  /// No description provided for @settingsDeleteAllWarning.
  ///
  /// In el, this message translates to:
  /// **'Θα διαγραφούν από αυτό το κινητό τα αγαπημένα, τα μέρη, οι ειδοποιήσεις και οι ρυθμίσεις. Δεν αναιρείται.'**
  String get settingsDeleteAllWarning;

  /// No description provided for @welcomeHomeTitle.
  ///
  /// In el, this message translates to:
  /// **'Καλώς ήρθες στις Στάσεις'**
  String get welcomeHomeTitle;

  /// No description provided for @welcomeHomeBody.
  ///
  /// In el, this message translates to:
  /// **'Κάθε λεωφορείο της πόλης στον χάρτη, ζωντανά. Το χρώμα του δείχνει αν αργεί σε σχέση με το πρόγραμμα.'**
  String get welcomeHomeBody;

  /// No description provided for @welcomeStopTitle.
  ///
  /// In el, this message translates to:
  /// **'Στάσεις και αγαπημένα'**
  String get welcomeStopTitle;

  /// No description provided for @welcomeStopBody.
  ///
  /// In el, this message translates to:
  /// **'Πάτα μια στάση για να δεις τι έρχεται και σε πόσα λεπτά. Με το αστέρι την κρατάς στα αγαπημένα.'**
  String get welcomeStopBody;

  /// No description provided for @welcomeAlertTitle.
  ///
  /// In el, this message translates to:
  /// **'Πες μου πότε να φύγω'**
  String get welcomeAlertTitle;

  /// No description provided for @welcomeAlertBody.
  ///
  /// In el, this message translates to:
  /// **'Πάτα το καμπανάκι δίπλα σε ένα λεωφορείο και θα σε ειδοποιήσουμε λίγο πριν φτάσει. Ή φτιάξε κανόνα για κάθε πρωί.'**
  String get welcomeAlertBody;

  /// No description provided for @welcomePlanTitle.
  ///
  /// In el, this message translates to:
  /// **'Από εδώ ως εκεί'**
  String get welcomePlanTitle;

  /// No description provided for @welcomePlanBody.
  ///
  /// In el, this message translates to:
  /// **'Η «Διαδρομή» στο μενού βρίσκει πώς πας κάπου, με τις αλλαγές και τους χρόνους από τα λεωφορεία που κινούνται τώρα.'**
  String get welcomePlanBody;

  /// No description provided for @welcomeSkip.
  ///
  /// In el, this message translates to:
  /// **'Παράλειψη'**
  String get welcomeSkip;

  /// The last welcome button: opens the map.
  ///
  /// In el, this message translates to:
  /// **'Ξεκίνα'**
  String get welcomeStart;

  /// No description provided for @welcomePermissionsTitle.
  ///
  /// In el, this message translates to:
  /// **'Δύο άδειες'**
  String get welcomePermissionsTitle;

  /// No description provided for @welcomePermissionsBody.
  ///
  /// In el, this message translates to:
  /// **'Και οι δύο είναι προαιρετικές. Τις αλλάζεις όποτε θέλεις από τις ρυθμίσεις του κινητού.'**
  String get welcomePermissionsBody;

  /// No description provided for @welcomePrivacyTitle.
  ///
  /// In el, this message translates to:
  /// **'Χωρίς λογαριασμό, διαφημίσεις ή tracking'**
  String get welcomePrivacyTitle;

  /// No description provided for @welcomePrivacyBody.
  ///
  /// In el, this message translates to:
  /// **'Η θέση σου, το σπίτι, η δουλειά και τα αγαπημένα μένουν μόνο στο κινητό σου.'**
  String get welcomePrivacyBody;

  /// A permission card.
  ///
  /// In el, this message translates to:
  /// **'Τοποθεσία'**
  String get welcomeLocationTitle;

  /// No description provided for @welcomeLocationBody.
  ///
  /// In el, this message translates to:
  /// **'Για τις στάσεις κοντά σου και τον χρόνο περπατήματος. Η θέση μένει στο κινητό.'**
  String get welcomeLocationBody;

  /// A permission card.
  ///
  /// In el, this message translates to:
  /// **'Ειδοποιήσεις'**
  String get welcomeNotificationsTitle;

  /// No description provided for @welcomeNotificationsBody.
  ///
  /// In el, this message translates to:
  /// **'Για να σου λέμε πότε να φύγεις και πότε φτάνει το λεωφορείο σου.'**
  String get welcomeNotificationsBody;

  /// A permission was granted.
  ///
  /// In el, this message translates to:
  /// **'Δόθηκε'**
  String get welcomeGranted;

  /// A button: a permission was refused; ask again.
  ///
  /// In el, this message translates to:
  /// **'Δεν δόθηκε · δοκίμασε ξανά'**
  String get welcomeDenied;

  /// A button: ask for the permission.
  ///
  /// In el, this message translates to:
  /// **'Επίτρεψε'**
  String get welcomeAllow;

  /// A weekday's full name, in a date such as «Δευτέρα 24 Νοεμβρίου».
  ///
  /// In el, this message translates to:
  /// **'{day, select, mon{Δευτέρα} tue{Τρίτη} wed{Τετάρτη} thu{Πέμπτη} fri{Παρασκευή} sat{Σάββατο} other{Κυριακή}}'**
  String statsDayName(String day);

  /// A month's name as it reads in a date (Greek: the genitive, «24 Νοεμβρίου»).
  ///
  /// In el, this message translates to:
  /// **'{month, select, jan{Ιανουαρίου} feb{Φεβρουαρίου} mar{Μαρτίου} apr{Απριλίου} may{Μαΐου} jun{Ιουνίου} jul{Ιουλίου} aug{Αυγούστου} sep{Σεπτεμβρίου} oct{Οκτωβρίου} nov{Νοεμβρίου} other{Δεκεμβρίου}}'**
  String statsMonthName(String month);

  /// A date: «Δευτέρα 24 Νοεμβρίου», “Monday 24 November”.
  ///
  /// In el, this message translates to:
  /// **'{weekday} {day} {month}'**
  String statsDate(String weekday, int day, String month);

  /// No description provided for @statsTitle.
  ///
  /// In el, this message translates to:
  /// **'Στατιστικά δικτύου'**
  String get statsTitle;

  /// A tab: the newest full day.
  ///
  /// In el, this message translates to:
  /// **'Χθες'**
  String get statsTabYesterday;

  /// A tab: the stored days together.
  ///
  /// In el, this message translates to:
  /// **'Τάσεις'**
  String get statsTabTrends;

  /// No description provided for @statsLongError.
  ///
  /// In el, this message translates to:
  /// **'Δεν φόρτωσαν οι προηγούμενες μέρες.'**
  String get statsLongError;

  /// No description provided for @statsNeedDays.
  ///
  /// In el, this message translates to:
  /// **'Χρειάζονται τουλάχιστον 2 πλήρεις μέρες.'**
  String get statsNeedDays;

  /// No description provided for @statsLastDays.
  ///
  /// In el, this message translates to:
  /// **'Οι τελευταίες {count} πλήρεις μέρες'**
  String statsLastDays(int count);

  /// No description provided for @statsSpeedByHour.
  ///
  /// In el, this message translates to:
  /// **'Μέση ταχύτητα ανά ώρα'**
  String get statsSpeedByHour;

  /// No description provided for @statsSpeedNote.
  ///
  /// In el, this message translates to:
  /// **'Η μπάρα: από την πιο αργή ως την πιο γρήγορη μέρα. Η τελεία: όλες μαζί.'**
  String get statsSpeedNote;

  /// No description provided for @statsWeekdaysWeekends.
  ///
  /// In el, this message translates to:
  /// **'Καθημερινές και Σαββατοκύριακα'**
  String get statsWeekdaysWeekends;

  /// Under a speed; count: the number of days.
  ///
  /// In el, this message translates to:
  /// **'χλμ/ώ καθημερινές ({count})'**
  String statsKmhWeekdays(int count);

  /// Under a speed; count: the number of days.
  ///
  /// In el, this message translates to:
  /// **'χλμ/ώ Σ/Κ ({count})'**
  String statsKmhWeekends(int count);

  /// No description provided for @statsBusesByHour.
  ///
  /// In el, this message translates to:
  /// **'Λεωφορεία ανά ώρα'**
  String get statsBusesByHour;

  /// A chart legend.
  ///
  /// In el, this message translates to:
  /// **'καθημερινή'**
  String get statsLegendWeekday;

  /// A chart legend.
  ///
  /// In el, this message translates to:
  /// **'Σαββατοκύριακο'**
  String get statsLegendWeekend;

  /// No description provided for @statsChanged.
  ///
  /// In el, this message translates to:
  /// **'Γραμμές που άλλαξαν ({date})'**
  String statsChanged(String date);

  /// No description provided for @statsComparedWeekdays.
  ///
  /// In el, this message translates to:
  /// **'Σε σχέση με {count} προηγούμενες καθημερινές.'**
  String statsComparedWeekdays(int count);

  /// No description provided for @statsComparedWeekends.
  ///
  /// In el, this message translates to:
  /// **'Σε σχέση με {count} προηγούμενες μέρες Σαββατοκύριακου.'**
  String statsComparedWeekends(int count);

  /// No description provided for @statsLongSource.
  ///
  /// In el, this message translates to:
  /// **'Μόνο πλήρεις μέρες (χωρίς κενά στις καταγραφές). Πηγή: καταγραφές θέσεων του ΟΑΣΑ από τον server μας.'**
  String get statsLongSource;

  /// No description provided for @statsWorst.
  ///
  /// In el, this message translates to:
  /// **'Χειρότερες γραμμές'**
  String get statsWorst;

  /// No description provided for @statsDaysCount.
  ///
  /// In el, this message translates to:
  /// **'{count, plural, =1{1 μέρα} other{{count} μέρες}}'**
  String statsDaysCount(int count);

  /// No description provided for @statsMissedTitle.
  ///
  /// In el, this message translates to:
  /// **'Δρομολόγια που δεν έγιναν'**
  String get statsMissedTitle;

  /// No description provided for @statsNoLines.
  ///
  /// In el, this message translates to:
  /// **'Καμία γραμμή με αρκετά δρομολόγια.'**
  String get statsNoLines;

  /// No description provided for @statsMissedOf.
  ///
  /// In el, this message translates to:
  /// **'{missed} από {measured} δεν έγιναν'**
  String statsMissedOf(int missed, int measured);

  /// No description provided for @statsExpiredDays.
  ///
  /// In el, this message translates to:
  /// **'{expired} από τις {count} μέρες μετρήθηκαν με παλιό πρόγραμμα: κάποια «χαμένα» δρομολόγια μπορεί να μην υπάρχουν πια.'**
  String statsExpiredDays(int expired, int count);

  /// No description provided for @statsSlowest.
  ///
  /// In el, this message translates to:
  /// **'Πιο αργές'**
  String get statsSlowest;

  /// A speed, already formatted: «12,3 χλμ/ώ».
  ///
  /// In el, this message translates to:
  /// **'{speed} χλμ/ώ'**
  String statsKmh(String speed);

  /// Vehicle-hours measured on a line.
  ///
  /// In el, this message translates to:
  /// **'{count} ώρες'**
  String statsHours(int count);

  /// No description provided for @statsNoDelayNote.
  ///
  /// In el, this message translates to:
  /// **'Καθυστέρηση ανά δρομολόγιο δεν καταγράφεται ακόμη· εδώ μετράνε τα χαμένα δρομολόγια και η ταχύτητα.'**
  String get statsNoDelayNote;

  /// No description provided for @statsTrend.
  ///
  /// In el, this message translates to:
  /// **'{speed} χλμ/ώ (συνήθως {usual})'**
  String statsTrend(String speed, String usual);

  /// No description provided for @statsDayError.
  ///
  /// In el, this message translates to:
  /// **'Δεν φόρτωσαν τα στατιστικά.'**
  String get statsDayError;

  /// Under a number in a tile.
  ///
  /// In el, this message translates to:
  /// **'λεωφορεία'**
  String get statsBuses;

  /// Under a number in a tile.
  ///
  /// In el, this message translates to:
  /// **'γραμμές'**
  String get statsLines;

  /// Under a speed in a tile.
  ///
  /// In el, this message translates to:
  /// **'μέση χλμ/ώ'**
  String get statsAvgKmh;

  /// No description provided for @statsSlowLines.
  ///
  /// In el, this message translates to:
  /// **'Πιο αργές γραμμές'**
  String get statsSlowLines;

  /// No description provided for @statsFastLines.
  ///
  /// In el, this message translates to:
  /// **'Πιο γρήγορες γραμμές'**
  String get statsFastLines;

  /// No description provided for @statsDaySource.
  ///
  /// In el, this message translates to:
  /// **'Πηγή: καταγραφές θέσεων του ΟΑΣΑ από τον server μας. Ανανεώνεται μία φορά τη μέρα.'**
  String get statsDaySource;

  /// No description provided for @statsTrips.
  ///
  /// In el, this message translates to:
  /// **'Δρομολόγια'**
  String get statsTrips;

  /// No description provided for @statsTripsShare.
  ///
  /// In el, this message translates to:
  /// **'Έγινε το {percent}% των δρομολογίων'**
  String statsTripsShare(int percent);

  /// No description provided for @statsRunOf.
  ///
  /// In el, this message translates to:
  /// **'{run} από {measured}'**
  String statsRunOf(int run, int measured);

  /// date: d/m/yyyy.
  ///
  /// In el, this message translates to:
  /// **'Η σύγκριση γίνεται με το πρόγραμμα του ΟΑΣΑ της {date}, γιατί νεότερο δεν έχει δημοσιευτεί. Μερικά δρομολόγια που λείπουν μπορεί να μην υπάρχουν πια.'**
  String statsExpired(String date);

  /// No description provided for @statsUnseen.
  ///
  /// In el, this message translates to:
  /// **'{count} γραμμές χωρίς κανένα δρομολόγιο'**
  String statsUnseen(int count);

  /// No description provided for @statsKmHours.
  ///
  /// In el, this message translates to:
  /// **'{km} χλμ · {hours} ώρες'**
  String statsKmHours(int km, int hours);

  /// Screen-reader label of a live arrival time.
  ///
  /// In el, this message translates to:
  /// **'ζωντανά: {time}'**
  String widgetsLive(String time);

  /// No description provided for @widgetsLate.
  ///
  /// In el, this message translates to:
  /// **'αργεί {minutes}′'**
  String widgetsLate(int minutes);

  /// No description provided for @widgetsEarly.
  ///
  /// In el, this message translates to:
  /// **'νωρίτερα {minutes}′'**
  String widgetsEarly(int minutes);

  /// Under a headsign: the time is from the timetable, no GPS.
  ///
  /// In el, this message translates to:
  /// **'από το πρόγραμμα'**
  String get widgetsFromTimetable;

  /// Under a headsign: offline, the time is estimated from the last data.
  ///
  /// In el, this message translates to:
  /// **'εκτίμηση'**
  String get widgetsEstimate;

  /// No description provided for @widgetsStopsAway.
  ///
  /// In el, this message translates to:
  /// **'{count, plural, =1{1 στάση μακριά} other{{count} στάσεις μακριά}}'**
  String widgetsStopsAway(int count);

  /// The next arrivals after the first: «μετά 12′, 25′».
  ///
  /// In el, this message translates to:
  /// **'μετά {times}'**
  String widgetsThen(String times);

  /// A loop line on its way back.
  ///
  /// In el, this message translates to:
  /// **'{headsign} (επιστροφή)'**
  String widgetsReturn(String headsign);

  /// No description provided for @widgetsOffline.
  ///
  /// In el, this message translates to:
  /// **'Χωρίς σύνδεση'**
  String get widgetsOffline;

  /// After «Offline ·»; ago: «5′».
  ///
  /// In el, this message translates to:
  /// **'τελευταία δεδομένα πριν {ago}'**
  String widgetsLastData(String ago);

  /// Live data, before the first update time is known.
  ///
  /// In el, this message translates to:
  /// **'Live'**
  String get widgetsLiveNote;

  /// No description provided for @widgetsUpdatedAt.
  ///
  /// In el, this message translates to:
  /// **'Τελευταία ενημέρωση {time}'**
  String widgetsUpdatedAt(String time);

  /// No description provided for @widgetsLineTooltip.
  ///
  /// In el, this message translates to:
  /// **'Η γραμμή {line}'**
  String widgetsLineTooltip(String line);

  /// No description provided for @lineRemoveMine.
  ///
  /// In el, this message translates to:
  /// **'Βγάλε από τις γραμμές μου'**
  String get lineRemoveMine;

  /// No description provided for @lineAddMine.
  ///
  /// In el, this message translates to:
  /// **'Στις γραμμές μου'**
  String get lineAddMine;

  /// No description provided for @lineMaxMine.
  ///
  /// In el, this message translates to:
  /// **'Ως 5 γραμμές. Βγάλε μία από τις γραμμές σου πρώτα.'**
  String get lineMaxMine;

  /// A tab of a line: its buses now.
  ///
  /// In el, this message translates to:
  /// **'Τώρα'**
  String get lineNow;

  /// A tab of a line: today's runs.
  ///
  /// In el, this message translates to:
  /// **'Δρομολόγια'**
  String get lineTimetable;

  /// No description provided for @lineTo.
  ///
  /// In el, this message translates to:
  /// **'προς {stop}'**
  String lineTo(String stop);

  /// No description provided for @lineFrom.
  ///
  /// In el, this message translates to:
  /// **'από {stop}'**
  String lineFrom(String stop);

  /// No description provided for @lineOtherDirection.
  ///
  /// In el, this message translates to:
  /// **'Η άλλη κατεύθυνση: προς {stop}'**
  String lineOtherDirection(String stop);

  /// A chip: every direction of the line.
  ///
  /// In el, this message translates to:
  /// **'Όλες'**
  String get lineAll;

  /// Beside a direction: opens its stops.
  ///
  /// In el, this message translates to:
  /// **'στάσεις'**
  String get lineStopsLink;

  /// No description provided for @lineStopsTitle.
  ///
  /// In el, this message translates to:
  /// **'Στάσεις'**
  String get lineStopsTitle;

  /// gaps: numbers of stops between buses, «3 · 5 · 2».
  ///
  /// In el, this message translates to:
  /// **'Κενά από το μπροστινό: {gaps} στάσεις'**
  String lineGaps(String gaps);

  /// No description provided for @lineBigGap.
  ///
  /// In el, this message translates to:
  /// **'μεγάλο κενό μετά το {n}ο λεωφορείο'**
  String lineBigGap(int n);

  /// No description provided for @lineScheduleError.
  ///
  /// In el, this message translates to:
  /// **'Δεν φόρτωσαν τα δρομολόγια.'**
  String get lineScheduleError;

  /// No description provided for @lineScheduleMissing.
  ///
  /// In el, this message translates to:
  /// **'Τα δρομολόγια δεν είναι ακόμη διαθέσιμα.'**
  String get lineScheduleMissing;

  /// No description provided for @lineNoRunsToday.
  ///
  /// In el, this message translates to:
  /// **'Κανένα δρομολόγιο σήμερα.'**
  String get lineNoRunsToday;

  /// No description provided for @lineExpired.
  ///
  /// In el, this message translates to:
  /// **'Το πρόγραμμα του ΟΑΣΑ έχει λήξει: δείχνουμε τις ώρες του παλιού για την ίδια μέρα της εβδομάδας.'**
  String get lineExpired;

  /// No description provided for @lineRunsToday.
  ///
  /// In el, this message translates to:
  /// **'{count} δρομολόγια σήμερα'**
  String lineRunsToday(int count);

  /// No description provided for @lineRanSoFar.
  ///
  /// In el, this message translates to:
  /// **'έγιναν {seen} από {known} ως τώρα'**
  String lineRanSoFar(int seen, int known);

  /// No description provided for @lineSourceDaily.
  ///
  /// In el, this message translates to:
  /// **'Πρόγραμμα ημέρας ΟΑΣΑ, ώρα αναχώρησης από την αφετηρία.'**
  String get lineSourceDaily;

  /// No description provided for @lineSource.
  ///
  /// In el, this message translates to:
  /// **'Πρόγραμμα ΟΑΣΑ, ώρα αναχώρησης από την αφετηρία. Διαγραμμένη: δεν φάνηκε λεωφορείο.'**
  String get lineSource;

  /// No description provided for @lineNoGps.
  ///
  /// In el, this message translates to:
  /// **'Κανένα λεωφορείο με GPS τώρα.'**
  String get lineNoGps;

  /// No description provided for @lineEnRoute.
  ///
  /// In el, this message translates to:
  /// **'στη διαδρομή'**
  String get lineEnRoute;

  /// No description provided for @lineNextStop.
  ///
  /// In el, this message translates to:
  /// **'επόμενη: {stop}'**
  String lineNextStop(String stop);

  /// No description provided for @lineLoading.
  ///
  /// In el, this message translates to:
  /// **'Φόρτωση…'**
  String get lineLoading;

  /// No description provided for @lineNoneOnWay.
  ///
  /// In el, this message translates to:
  /// **'Κανένα καθ’ οδόν τώρα'**
  String get lineNoneOnWay;

  /// No description provided for @lineAlertTooltip.
  ///
  /// In el, this message translates to:
  /// **'Ειδοποίηση για το {line} στη στάση {stop}'**
  String lineAlertTooltip(String line, String stop);

  /// No description provided for @lineWalkDirections.
  ///
  /// In el, this message translates to:
  /// **'Οδηγίες με τα πόδια ως τη στάση'**
  String get lineWalkDirections;

  /// Android notification channel name: alerts when a bus nears the stop
  ///
  /// In el, this message translates to:
  /// **'Το λεωφορείο έρχεται'**
  String get serviceHitChannelName;

  /// Android notification channel description
  ///
  /// In el, this message translates to:
  /// **'Ειδοποίηση όταν το λεωφορείο πλησιάζει στη στάση σου'**
  String get serviceHitChannelDescription;

  /// Android notification channel name: the ongoing live card
  ///
  /// In el, this message translates to:
  /// **'Live πορεία λεωφορείου'**
  String get serviceLiveChannelName;

  /// Android notification channel description
  ///
  /// In el, this message translates to:
  /// **'Η πορεία του λεωφορείου σου ως τη στάση'**
  String get serviceLiveChannelDescription;

  /// Dialog title: ask for the exact-alarm permission so a weekly alert starts on time
  ///
  /// In el, this message translates to:
  /// **'Να ξεκινά ακριβώς στην ώρα του;'**
  String get serviceExactAlarmTitle;

  /// No description provided for @serviceExactAlarmBody.
  ///
  /// In el, this message translates to:
  /// **'Το Android θέλει την άδεια «Ξυπνητήρια και υπενθυμίσεις» για αυτό. Θα ανοίξουν οι ρυθμίσεις: άνοιξε τον διακόπτη και γύρνα πίσω. Χωρίς αυτήν, ο κανόνας ξεκινά, αλλά ίσως λίγα λεπτά αργότερα.'**
  String get serviceExactAlarmBody;

  /// Button
  ///
  /// In el, this message translates to:
  /// **'Όχι τώρα'**
  String get serviceExactAlarmLater;

  /// Button
  ///
  /// In el, this message translates to:
  /// **'Άνοιξε τις ρυθμίσεις'**
  String get serviceExactAlarmOpenSettings;

  /// Title of the foreground-service notification while alerts run
  ///
  /// In el, this message translates to:
  /// **'Στάσεις · live'**
  String get serviceRunningTitle;

  /// No description provided for @serviceRunningText.
  ///
  /// In el, this message translates to:
  /// **'Οι ειδοποιήσεις σου είναι ενεργές'**
  String get serviceRunningText;

  /// Notification when a weekly alert rule starts and the app must be opened
  ///
  /// In el, this message translates to:
  /// **'Ξεκινά ο κανόνας σου'**
  String get serviceRuleStartsTitle;

  /// No description provided for @serviceRuleStartsBody.
  ///
  /// In el, this message translates to:
  /// **'Άνοιξε την εφαρμογή για live ειδοποιήσεις.'**
  String get serviceRuleStartsBody;

  /// Friday-evening notification title about the last bus home
  ///
  /// In el, this message translates to:
  /// **'Βράδυ Παρασκευής · το τελευταίο για το σπίτι'**
  String get serviceNudgeTitleFriday;

  /// Saturday-evening notification title about the last bus home
  ///
  /// In el, this message translates to:
  /// **'Βράδυ Σαββάτου · το τελευταίο για το σπίτι'**
  String get serviceNudgeTitleSaturday;

  /// No description provided for @serviceNudgeBody.
  ///
  /// In el, this message translates to:
  /// **'Δες πότε φεύγει το τελευταίο {line} για {stop} και βάλε ειδοποίηση.'**
  String serviceNudgeBody(String line, String stop);

  /// time: 24 h H:mm; from: the first stop
  ///
  /// In el, this message translates to:
  /// **'Το τελευταίο {line} φεύγει {time} από {from}. Θες ειδοποίηση;'**
  String serviceNudgeLastRun(String line, String time, String from);

  /// No description provided for @serviceBoardedTitle.
  ///
  /// In el, this message translates to:
  /// **'Είσαι στο {line}'**
  String serviceBoardedTitle(String line);

  /// No description provided for @serviceOneStopBefore.
  ///
  /// In el, this message translates to:
  /// **'Θα σε ειδοποιήσουμε μία στάση πριν από {stop}.'**
  String serviceOneStopBefore(String stop);

  /// No description provided for @serviceTripTitle.
  ///
  /// In el, this message translates to:
  /// **'Ταξίδι με το {line}'**
  String serviceTripTitle(String line);

  /// No description provided for @serviceTripText.
  ///
  /// In el, this message translates to:
  /// **'Μόλις ανέβεις, θα σε ειδοποιήσουμε μία στάση πριν από {stop}.'**
  String serviceTripText(String stop);

  /// No description provided for @serviceIdleText.
  ///
  /// In el, this message translates to:
  /// **'Θα σε ειδοποιήσουμε όταν πλησιάσει το λεωφορείο.'**
  String get serviceIdleText;

  /// No description provided for @serviceNoBusYet.
  ///
  /// In el, this message translates to:
  /// **'Δεν φαίνεται ακόμη λεωφορείο με GPS.'**
  String get serviceNoBusYet;

  /// Live card title
  ///
  /// In el, this message translates to:
  /// **'{line} · φτάνει τώρα στο {stop}'**
  String serviceArrivingNow(String line, String stop);

  /// Live card title; eta like 3′ or ~3′
  ///
  /// In el, this message translates to:
  /// **'{line} · {stop} σε {eta}'**
  String serviceArrivingIn(String line, String stop, String eta);

  /// time: 24 h H:mm, maybe with a leading ~
  ///
  /// In el, this message translates to:
  /// **'φτάνει {time}'**
  String serviceArrivesAt(String time);

  /// Live card: the bus is one stop away
  ///
  /// In el, this message translates to:
  /// **'επόμενη στάση'**
  String get serviceNextStop;

  /// No description provided for @serviceOfflineEstimate.
  ///
  /// In el, this message translates to:
  /// **'χωρίς σήμα, εκτίμηση'**
  String get serviceOfflineEstimate;

  /// Live card subtitle when the phone has no network
  ///
  /// In el, this message translates to:
  /// **'χωρίς σήμα'**
  String get serviceOffline;

  /// Live card button: stop this alert for today
  ///
  /// In el, this message translates to:
  /// **'Σταμάτα'**
  String get serviceStop;

  /// Home-screen widget: a saved stop that is neither home nor work
  ///
  /// In el, this message translates to:
  /// **'Η στάση μου'**
  String get homeWidgetMyStop;

  /// Home-screen widget subtitle
  ///
  /// In el, this message translates to:
  /// **'{place} · κανένα λεωφορείο με GPS'**
  String homeWidgetNoBus(String place);

  /// Shown in brackets after the stop
  ///
  /// In el, this message translates to:
  /// **'καθυστέρηση {min}′'**
  String ruleHitDelay(int min);

  /// No description provided for @ruleHitIn.
  ///
  /// In el, this message translates to:
  /// **'σε ~{min}′'**
  String ruleHitIn(int min);

  /// late: empty or ' (3 min late)'
  ///
  /// In el, this message translates to:
  /// **'Το {line} έρχεται: επόμενη στάση {stop}{late}.'**
  String ruleHitNextStop(String line, String stop, String late);

  /// late: empty or ' (3 min late)'; eta: empty or ' in ~5 min'
  ///
  /// In el, this message translates to:
  /// **'Το {line} φτάνει στη στάση {stop}{late}{eta}.'**
  String ruleHitArrives(String line, String stop, String late, String eta);

  /// stops: '3 stops'; late: empty or ' (3 min late)'; eta: empty or ', in ~5 min'
  ///
  /// In el, this message translates to:
  /// **'Το {line} είναι {stops} πριν από {stop}{late}{eta}.'**
  String ruleHitStopsAway(
    String line,
    String stops,
    String stop,
    String late,
    String eta,
  );

  /// No description provided for @ruleHitLateTitle.
  ///
  /// In el, this message translates to:
  /// **'{line} αργεί {min}′'**
  String ruleHitLateTitle(String line, int min);

  /// eta: empty or ': arrives in ~5 min'; stops: empty or ' (3 stops)'
  ///
  /// In el, this message translates to:
  /// **'Για τη στάση {stop}{eta}{stops}.'**
  String ruleHitLateBody(String stop, String eta, String stops);

  /// No description provided for @ruleHitLateEta.
  ///
  /// In el, this message translates to:
  /// **'φτάνει σε ~{min}′'**
  String ruleHitLateEta(int min);

  /// No description provided for @ruleHitLeaveTitle.
  ///
  /// In el, this message translates to:
  /// **'Φύγε τώρα για το {line}'**
  String ruleHitLeaveTitle(String line);

  /// eta: empty or ' (in ~5 min)'
  ///
  /// In el, this message translates to:
  /// **'Για να είσαι στη στάση {stop} πριν έρθει{eta}.'**
  String ruleHitLeaveBody(String stop, String eta);

  /// No description provided for @ruleHitRideTitle.
  ///
  /// In el, this message translates to:
  /// **'Κατέβα στην επόμενη'**
  String get ruleHitRideTitle;

  /// No description provided for @ruleHitRideBody.
  ///
  /// In el, this message translates to:
  /// **'Επόμενη στάση: {stop}.'**
  String ruleHitRideBody(String stop);

  /// No description provided for @cityAthensName.
  ///
  /// In el, this message translates to:
  /// **'Αθήνα'**
  String get cityAthensName;

  /// The transit agency of Athens
  ///
  /// In el, this message translates to:
  /// **'ΟΑΣΑ'**
  String get cityAthensAgency;

  /// No description provided for @cityAthensIn.
  ///
  /// In el, this message translates to:
  /// **'στην Αθήνα'**
  String get cityAthensIn;

  /// No description provided for @cityThessalonikiName.
  ///
  /// In el, this message translates to:
  /// **'Θεσσαλονίκη'**
  String get cityThessalonikiName;

  /// The transit agency of Thessaloniki
  ///
  /// In el, this message translates to:
  /// **'ΟΣΕΘ'**
  String get cityThessalonikiAgency;

  /// No description provided for @cityThessalonikiIn.
  ///
  /// In el, this message translates to:
  /// **'στη Θεσσαλονίκη'**
  String get cityThessalonikiIn;

  /// No description provided for @coreKindBusStop.
  ///
  /// In el, this message translates to:
  /// **'στάση λεωφορείων'**
  String get coreKindBusStop;

  /// No description provided for @coreKindMetro.
  ///
  /// In el, this message translates to:
  /// **'σταθμός μετρό'**
  String get coreKindMetro;

  /// No description provided for @coreKindTram.
  ///
  /// In el, this message translates to:
  /// **'στάση τραμ'**
  String get coreKindTram;

  /// No description provided for @coreKindRail.
  ///
  /// In el, this message translates to:
  /// **'σταθμός προαστιακού'**
  String get coreKindRail;

  /// The day of a last run: «the last 040 passes on Thursday ~0:40»
  ///
  /// In el, this message translates to:
  /// **'τη Δευτέρα'**
  String get coreLastRunOnMonday;

  /// The day of a last run: «the last 040 passes on Thursday ~0:40»
  ///
  /// In el, this message translates to:
  /// **'την Τρίτη'**
  String get coreLastRunOnTuesday;

  /// The day of a last run: «the last 040 passes on Thursday ~0:40»
  ///
  /// In el, this message translates to:
  /// **'την Τετάρτη'**
  String get coreLastRunOnWednesday;

  /// The day of a last run: «the last 040 passes on Thursday ~0:40»
  ///
  /// In el, this message translates to:
  /// **'την Πέμπτη'**
  String get coreLastRunOnThursday;

  /// The day of a last run: «the last 040 passes on Thursday ~0:40»
  ///
  /// In el, this message translates to:
  /// **'την Παρασκευή'**
  String get coreLastRunOnFriday;

  /// The day of a last run: «the last 040 passes on Thursday ~0:40»
  ///
  /// In el, this message translates to:
  /// **'το Σάββατο'**
  String get coreLastRunOnSaturday;

  /// The day of a last run: «the last 040 passes on Thursday ~0:40»
  ///
  /// In el, this message translates to:
  /// **'την Κυριακή'**
  String get coreLastRunOnSunday;

  /// A place in the trip planner
  ///
  /// In el, this message translates to:
  /// **'Κοντινότερος σταθμός μετρό'**
  String get coreNearestMetro;

  /// The direction of a stop: its next stops' names
  ///
  /// In el, this message translates to:
  /// **'προς {names}'**
  String coreToward(String names);

  /// No description provided for @coreDistanceM.
  ///
  /// In el, this message translates to:
  /// **'{m} μ.'**
  String coreDistanceM(int m);

  /// km: a number with one decimal, formatted by the app
  ///
  /// In el, this message translates to:
  /// **'{km} χλμ.'**
  String coreDistanceKm(String km);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['el', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
