// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Staseis';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonLess => 'Less';

  @override
  String get commonMore => 'More';

  @override
  String get commonClose => 'Close';

  @override
  String get commonNext => 'Next';

  @override
  String get commonOk => 'OK';

  @override
  String get commonNow => 'now';

  @override
  String get commonOnTime => 'on time';

  @override
  String get commonSearching => 'Searching…';

  @override
  String get commonLocating => 'Finding your location…';

  @override
  String get commonHome => 'Home';

  @override
  String get commonWork => 'Work';

  @override
  String get commonMetro => 'Metro';

  @override
  String get commonTram => 'Tram';

  @override
  String get commonSuburban => 'Suburban rail';

  @override
  String get commonBuses => 'Buses';

  @override
  String get commonNoNotificationPermission =>
      'To notify you, the app needs permission to send notifications.';

  @override
  String stopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops',
      one: '1 stop',
    );
    return '$_temp0';
  }

  @override
  String minutesShort(int n) {
    return '$n′';
  }

  @override
  String mapOnBusSnack(String line) {
    return 'On the $line? Pick where you get off.';
  }

  @override
  String get mapOnBusSnackAction => 'Open it';

  @override
  String get mapLayersMine => 'Map: my lines';

  @override
  String get mapLayers => 'What the map shows';

  @override
  String get mapWhereAmI => 'Where am I';

  @override
  String get mapMenu => 'Menu';

  @override
  String get mapTitle => 'Map';

  @override
  String get mapLegend => 'What each symbol means';

  @override
  String get mapBusesAllHint => 'Buses: all. Star a line to see only yours.';

  @override
  String get mapAllBuses => 'All buses';

  @override
  String get mapMyLines => 'My lines';

  @override
  String get mapAdvanced => 'Advanced';

  @override
  String get mapOthersWhenSelected =>
      'When you tap a bus or a line, the others:';

  @override
  String get mapOthersNormal => 'Show';

  @override
  String get mapOthersDim => 'Dim';

  @override
  String get mapOthersHide => 'Hide';

  @override
  String get mapRecentOnly => 'Recent position only';

  @override
  String get mapRecentOnlyHint => 'Sent a position in the last 1½ min.';

  @override
  String get mapOnTimeOnly => 'On time only';

  @override
  String get mapOnTimeOnlyHint => 'Up to 5 min late.';

  @override
  String get mapShowAge => 'How old the position is';

  @override
  String get mapShowAgeHint => 'Next to each bus. Old ones always show it.';

  @override
  String get mapAttribution =>
      'Map: © OpenStreetMap contributors · OpenFreeMap';

  @override
  String mapLastData(String time, String ago) {
    return 'Last data $time · $ago ago';
  }

  @override
  String get mapOffline => 'Offline';

  @override
  String get mapSeeNearby => 'See what passes near you';

  @override
  String get mapLocationPitch =>
      'With your location you see the nearest stops and when the bus is coming. Your location stays on your phone.';

  @override
  String get mapUseMyLocation => 'Use my location';

  @override
  String get mapOrSearch => 'Or type a stop or line in the search.';

  @override
  String get mapLoadingStops => 'Loading stops…';

  @override
  String get mapNoStopWithin => 'No stops within 2.5 km.';

  @override
  String get mapDragForMore => 'drag for more stops';

  @override
  String get mapNoSavedStops =>
      'No saved stops yet. Open a stop and tap the star.';

  @override
  String get mapFavorites => 'Favourites';

  @override
  String get mapAllFavorites => 'All favourites · add, home, work';

  @override
  String get mapNearYou => 'Near you';

  @override
  String mapQuietLines(String lines) {
    return '$lines: no bus with GPS right now';
  }

  @override
  String get mapWalkDirections => 'Walking directions';

  @override
  String mapWalkDirectionsMin(int m) {
    return 'Walking directions, $m min';
  }

  @override
  String get mapCancelled => 'cancelled';

  @override
  String get mapRailLive => 'live from railway.gov.gr';

  @override
  String get mapMetroSchedule => 'STASY timetable, not live';

  @override
  String get mapStopsNear => 'Stops nearby';

  @override
  String get mapNoStopWithin600 => 'No stops within 600 m.';

  @override
  String mapStopDistLines(int dist, String lines) {
    return '$dist m · $lines';
  }

  @override
  String mapBusesOnRoad(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count buses on the road',
      one: '1 bus on the road',
    );
    return '$_temp0';
  }

  @override
  String get mapAllOnTime => 'all on time';

  @override
  String mapLateCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count are over 5′ late',
      one: '1 is over 5′ late',
    );
    return '$_temp0';
  }

  @override
  String get mapMyLinesNow => 'My lines now';

  @override
  String get mapMyLinesHint => 'other buses hidden · tap a line for its route';

  @override
  String get mapNoLineSelected =>
      'No line selected. Pick one from the map button (drag the panel down).';

  @override
  String get plannerTitle => 'Directions';

  @override
  String get plannerMyLocation => 'My location';

  @override
  String get plannerFrom => 'From';

  @override
  String get plannerTo => 'To';

  @override
  String get plannerWhereAreYou => 'Where are you?';

  @override
  String get plannerWhereTo => 'Where to? stop, area, shop, address';

  @override
  String get plannerSwap => 'Swap';

  @override
  String get plannerNow => 'Now';

  @override
  String get plannerLater => 'Later';

  @override
  String plannerLeaveAt(String time) {
    return 'Leave $time';
  }

  @override
  String get plannerWithMetro => 'With metro';

  @override
  String get plannerLinesFailed =>
      'The lines didn\'t load. You need a connection the first time.';

  @override
  String get plannerPickFrom =>
      'Pick where you leave from or allow location: that is how your walk to the stop is worked out.';

  @override
  String get plannerPickTo =>
      'Pick where you\'re going. You\'ll see buses with no change or one, and the metro when it suits you.';

  @override
  String get plannerNoBus =>
      'No bus within 500 m of your start and destination, not even with one change. Try a nearby stop or the metro.';

  @override
  String get plannerDirect => 'No change';

  @override
  String get plannerOneChange => 'One change';

  @override
  String get plannerTimesLive =>
      'Times: walking 4.5 km/h, bus 15 km/h with stops; the wait is live from the buses’ GPS.';

  @override
  String get plannerTimesLater =>
      'For later we don\'t know which bus will come: the times leave out the wait.';

  @override
  String plannerMetroWalk(int walk) {
    return '$walk′ walk in total · a train every few minutes (timetable, not live)';
  }

  @override
  String get plannerMetroWait => 'Metro by the timetable (not live), wait ~5′.';

  @override
  String plannerBoardChange(String board, String change) {
    return 'Board: $board · change: $change';
  }

  @override
  String plannerTransferWalk(int m) {
    return ' ($m m on foot)';
  }

  @override
  String plannerStopsWalk(int stops, int walk) {
    return '$stops stops · $walk′ walk';
  }

  @override
  String plannerBoard(String stop) {
    return 'Board: $stop';
  }

  @override
  String plannerGetOff(String stop) {
    return 'Get off: $stop';
  }

  @override
  String get plannerNearMyLocation => 'near your location';

  @override
  String plannerNearStop(String stop) {
    return 'near $stop';
  }

  @override
  String get plannerNearMeApprox => 'Near my location (approximate)';

  @override
  String plannerPlaceHint(String name) {
    return '$name: address or area';
  }

  @override
  String get plannerFromHint => 'From: stop, area, address';

  @override
  String get plannerToHint => 'To: stop, area, shop, address';

  @override
  String get plannerPlacePrivacy =>
      'An area nearby is enough. We keep nothing: the place stays only on your phone.';

  @override
  String get plannerNoLocation =>
      'Couldn\'t find your location. Turn on location or pick a place.';

  @override
  String routeArrive(String time) {
    return 'arrive ~$time';
  }

  @override
  String routeEstimateMetro(int wait) {
    return 'Estimate with a ~$wait′ wait for the train.';
  }

  @override
  String get routeEstimateLive =>
      'Estimate without the wait for the first bus; the wait shows live in its step.';

  @override
  String get routeEstimateLater => 'For later: estimate without the wait.';

  @override
  String get routeWalkToDest => 'Walk to your destination';

  @override
  String routeWalkToStation(String name) {
    return 'Walk to $name station';
  }

  @override
  String routeWalkToStop(String name) {
    return 'Walk to the $name stop';
  }

  @override
  String routeWalkTo(String name) {
    return 'Walk to $name';
  }

  @override
  String routeBoard(String line) {
    return 'Board the $line';
  }

  @override
  String routeBoardToward(String line, String toward) {
    return 'Board the $line toward $toward';
  }

  @override
  String routeStop(String name) {
    return 'Stop: $name';
  }

  @override
  String routeGetOff(String name) {
    return 'Get off: $name';
  }

  @override
  String routeChangeWait(int wait) {
    return 'Change: wait ~$wait′';
  }

  @override
  String routeTrainEvery(int wait) {
    return 'A train every few minutes (timetable, not live), wait ~$wait′';
  }

  @override
  String get routeWhereGetOff => 'Where do I get off?';

  @override
  String get routeLeaveInTime => 'Leave on time';

  @override
  String get routeNoBusNear => 'No bus with GPS nearby right now';

  @override
  String get routeCantCatch => 'You can\'t catch the ones coming now';

  @override
  String get routeSearchingNext => 'Looking for the next bus…';

  @override
  String routeNextCatch(String eta, String clock) {
    return 'Next one you can catch: $eta ($clock)';
  }

  @override
  String get routeLeaveNow => 'leave now';

  @override
  String routeLeaveIn(int n) {
    return 'leave in $n′';
  }

  @override
  String get mapSelBack => 'Back';

  @override
  String mapSelLine(String line) {
    return 'Line $line';
  }

  @override
  String get mapSelStop => 'Stop';

  @override
  String get searchClear => 'Clear';

  @override
  String get searchHint => 'Stop, line or place';

  @override
  String searchHiddenResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results in hidden modes',
      one: '1 result in hidden modes',
    );
    return '$_temp0';
  }

  @override
  String get searchShow => 'Show';

  @override
  String searchMunicipal(String municipality) {
    return 'Municipal · $municipality';
  }

  @override
  String get stationRail => 'Suburban rail station';

  @override
  String get stationMetroTram => 'Metro / tram station';

  @override
  String get stationDeparturesFailed =>
      'The departures didn\'t load. Trying again shortly.';

  @override
  String get stationBusStopsNear => 'Bus stops nearby';

  @override
  String get stationNoTrain => 'No trains in the next few hours.';

  @override
  String stationTrain(String train) {
    return 'Train $train';
  }

  @override
  String stationDelay(int n) {
    return '+$n′ late';
  }

  @override
  String get stationLine => 'line';

  @override
  String get stationRailNote =>
      'Live from railway.gov.gr. The board only gives the next stop; “toward” is the end of the line.';

  @override
  String stationToward(String name) {
    return 'toward $name';
  }

  @override
  String stationNextStop(String name) {
    return 'next stop $name';
  }

  @override
  String get stationNoMetroTimes =>
      'Metro and tram times are not available yet.';

  @override
  String get stationNoDeparture => 'No departures in the next hour.';

  @override
  String get stationIndicative =>
      'Indicative, from the STASY timetable (not live).';

  @override
  String get stationSchedule => 'From the STASY timetable (not live).';

  @override
  String get muniBadge => 'M';

  @override
  String muniFromStop(String stop) {
    return ' from $stop';
  }

  @override
  String get muniScheduled => 'Scheduled · not live';

  @override
  String muniLine(String municipality) {
    return 'Municipal line · $municipality';
  }

  @override
  String get muniNoTimetable =>
      'We don\'t have a checked timetable for this line.';

  @override
  String get muniTimetableLink => 'Municipality\'s timetable';

  @override
  String get muniNextDepartures => 'Next departures';

  @override
  String get muniNoMoreToday =>
      'No more trips today, according to the timetable.';

  @override
  String get muniApproxNote =>
      '≈: the municipality gives a frequency, not exact times.';

  @override
  String muniTimetableChecked(String municipality, String date) {
    return 'Timetable: $municipality, checked $date.';
  }

  @override
  String get muniPageLink => 'Municipality\'s page';

  @override
  String muniRouteSource(String source) {
    return 'Route and stops: $source';
  }

  @override
  String get muniStopKicker => 'Municipal line stop';

  @override
  String get muniLinesFailed =>
      'The municipal lines didn\'t load. Try again shortly.';

  @override
  String get muniNoCheckedTimetable => 'No checked timetable';

  @override
  String get muniNoMoreTodayShort => 'No more trips today';

  @override
  String get muniTimesFromStart =>
      'The times are from the first stop the municipality gives, not from this stop.';

  @override
  String get helpDelayUpTo2 => 'up to 2′ or early';

  @override
  String get helpDelayOver10 => 'over 10′';

  @override
  String get helpDelayNoTrip => 'no scheduled trip';

  @override
  String get helpDelayTitle => 'Delay against the timetable';

  @override
  String get helpBus =>
      'A bus. Its colour shows how late it is against the timetable.';

  @override
  String get helpMyBus =>
      'A bus on one of your lines: it has the line’s colour, and the ring around it shows the delay.';

  @override
  String get helpDirection =>
      'The direction it is heading. Missing when unknown.';

  @override
  String get helpFaded =>
      'Faded: its position is old, over 1½ min. Next to it you see how old (e.g. 2′).';

  @override
  String get helpBlueRing => 'Blue ring: the bus or line you opened.';

  @override
  String get helpRoute =>
      'The route, with arrows showing the way it goes. Each direction has its own lane.';

  @override
  String get helpStop => 'A stop. Tap it to see what\'s coming.';

  @override
  String get helpTapEmpty =>
      'Tap an empty spot on the map to close whatever is open.';

  @override
  String get helpDataTitle => 'Where the data comes from';

  @override
  String get helpPosition => 'Position';

  @override
  String get helpPositionText =>
      'Every bus sends its GPS to OASA. Our server reads it about every 30″. Between two positions the app moves the bus along its route at its own speed.';

  @override
  String get helpEta => 'Arrival time';

  @override
  String get helpEtaText =>
      'The app works it out from where the bus is and the typical speed on each stretch of road (from the positions of the last 14 days). It isn\'t OASA\'s prediction.';

  @override
  String get helpDelay => 'Delay';

  @override
  String get helpDelayText =>
      'Compared with OASA\'s timetable for the trip the bus is running.';

  @override
  String get helpTilde => '“~” before a time';

  @override
  String get helpTildeText =>
      'Offline: an estimate from the latest data. It corrects itself once there is signal.';

  @override
  String get lineSpeedTitle => 'Line speed';

  @override
  String get lineSpeedDaysFailed => 'The daily statistics didn\'t load.';

  @override
  String get lineSpeedNext2km => 'The next 2 km';

  @override
  String lineSpeedAheadHint(int kmh) {
    return 'The usual speed per 200 m on this day and time; the line is the bus now ($kmh km/h).';
  }

  @override
  String get lineSpeedNoData =>
      'No measurements for this line in the last few days.';

  @override
  String lineSpeedLastDays(int n) {
    return 'The last $n days';
  }

  @override
  String get lineSpeedKmhWeekdays => 'km/h weekdays';

  @override
  String get lineSpeedKmhWeekends => 'km/h weekends';

  @override
  String lineSpeedRank(int place, int total) {
    return 'Yesterday: #$place slowest of $total lines.';
  }

  @override
  String lineSpeedDayKmh(String date, String kmh) {
    return '$date: $kmh km/h';
  }

  @override
  String get lineSpeedWeekday => 'weekday';

  @override
  String get lineSpeedWeekend => 'weekend';

  @override
  String get lineSpeedFooter =>
      'Mean speed over the whole day, stops included. Source: OASA position logs from our server.';

  @override
  String get lineSpeedMon => 'Mo';

  @override
  String get lineSpeedTue => 'Tu';

  @override
  String get lineSpeedWed => 'We';

  @override
  String get lineSpeedThu => 'Th';

  @override
  String get lineSpeedFri => 'Fr';

  @override
  String get lineSpeedSat => 'Sa';

  @override
  String get lineSpeedSun => 'Su';

  @override
  String alertNoSchedule(String line) {
    return 'No timetable found for the $line.';
  }

  @override
  String alertLastGone(String line, String time) {
    return 'The last $line has already gone (~$time).';
  }

  @override
  String alertLastNoteTitle(String line) {
    return 'The last $line is coming soon';
  }

  @override
  String alertLastNoteBody(String stop, String time, String departs) {
    return 'At $stop ~$time (leaves the first stop at $departs).';
  }

  @override
  String alertLastSet(int before, String line, String time) {
    return 'We\'ll notify you $before min before: the last $line passes at ~$time.';
  }

  @override
  String alertLastSetDay(int before, String line, String day, String time) {
    return 'We\'ll notify you $before min before: the last $line passes $day at ~$time.';
  }

  @override
  String get alertOnMonday => 'on Monday';

  @override
  String get alertOnTuesday => 'on Tuesday';

  @override
  String get alertOnWednesday => 'on Wednesday';

  @override
  String get alertOnThursday => 'on Thursday';

  @override
  String get alertOnFriday => 'on Friday';

  @override
  String get alertOnSaturday => 'on Saturday';

  @override
  String get alertOnSunday => 'on Sunday';

  @override
  String get alertScheduleOffline =>
      'The timetable didn\'t load. Try again when you\'re online.';

  @override
  String get alertNoLocation =>
      'Couldn\'t find your location (permission or GPS). Set the walking time by hand.';

  @override
  String get alertWeeklySet => 'Rule: Mon–Fri at this time.';

  @override
  String get alertWeeklyInexact =>
      'Without permission for exact alarms it may start a few minutes late.';

  @override
  String alertLeaveSet(String line) {
    return 'We\'ll tell you when to leave for the $line.';
  }

  @override
  String alertSet(String line) {
    return 'We\'ll notify you about the $line.';
  }

  @override
  String get alertWalkQuestion => 'How far are you from the stop?';

  @override
  String get alertWalkExplain =>
      'Your location is used to work out your walk to the stop and when to set off, so you get there in time. Your location stays on your phone.';

  @override
  String get alertUseMyLocation => 'Use my location';

  @override
  String get alertLeaveNow => 'Leave now';

  @override
  String alertLeaveIn(int n) {
    return 'Leave in $n min';
  }

  @override
  String alertAtClock(String time) {
    return 'at $time';
  }

  @override
  String alertWalkTo(int n, String stop) {
    return '$n min walk to $stop';
  }

  @override
  String get alertTooLate => 'you probably won\'t make this one';

  @override
  String alertBarNow(int n) {
    return 'now · $n′';
  }

  @override
  String alertBarWalk(int n) {
    return 'walk $n′';
  }

  @override
  String alertBarWait(int n) {
    return 'wait $n′';
  }

  @override
  String get alertBeAtStop => 'Be at the stop';

  @override
  String alertMarginBefore(int n) {
    return '$n′ early';
  }

  @override
  String get alertWalk => 'Walk';

  @override
  String get alertLeaveLateHint =>
      'If the bus runs late, we tell you to leave later: the time updates with every new position of the bus.';

  @override
  String get alertBeforeArrives => 'before it arrives';

  @override
  String alertStopsBefore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'stops before',
      one: 'stop before',
    );
    return '$_temp0';
  }

  @override
  String alertTitle(String stop) {
    return 'Alert for $stop';
  }

  @override
  String alertToward(String headsign) {
    return 'to $headsign';
  }

  @override
  String get alertNearStart =>
      'Your stop is near the start of the line: we\'ll notify you as soon as the bus sets off.';

  @override
  String get alertMeansNow => 'Right now that means';

  @override
  String get alertWhenAt => 'when it\'s at ';

  @override
  String alertWhenAtTail(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n stops before',
      one: '1 stop before',
    );
    return ', $_temp0';
  }

  @override
  String get alertTimeUpdates =>
      'The time updates with every new position of the bus.';

  @override
  String get alertLeaveButton => 'Tell me when to leave';

  @override
  String alertNotifyMinutes(int n) {
    return 'Notify me $n min before';
  }

  @override
  String alertNotifyStops(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n stops',
      one: '1 stop',
    );
    return 'Notify me $_temp0 before';
  }

  @override
  String get alertMoreOptions => 'More options';

  @override
  String get alertModeMinutes => 'Minutes before';

  @override
  String get alertModeStops => 'Stops before';

  @override
  String get alertModeLeave => 'Leave on time';

  @override
  String get alertLiveLockScreen => 'Live on the lock screen';

  @override
  String get alertLiveLockScreenSub => 'Shows the bus\'s progress to your stop';

  @override
  String get alertLateToo => 'Also tell me if it\'s late';

  @override
  String alertLateTooSub(int n) {
    return 'One alert when a bus to your stop is $n min late or more';
  }

  @override
  String get alertWeekdays => 'Every weekday at this time?';

  @override
  String get alertLastOfDay => 'For the last one of the day';

  @override
  String get alertLastOfDaySub =>
      'An alert 15 min before it passes here, from the timetable';

  @override
  String ruleEditMinutesBefore(int n) {
    return '$n′ before it arrives';
  }

  @override
  String ruleEditStopsBefore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n stops before it arrives',
      one: '1 stop before it arrives',
    );
    return '$_temp0';
  }

  @override
  String get ruleEditWhenLeave => 'when to leave';

  @override
  String get ruleEditTitle => 'Rule';

  @override
  String get ruleEditNoStop => 'Save a stop first (Stops tab).';

  @override
  String get ruleEditEvery => 'Every';

  @override
  String get ruleEditFrom => 'from';

  @override
  String get ruleEditUntil => 'to';

  @override
  String get ruleEditTellMe => 'tell me';

  @override
  String get ruleEditForThe => 'for the';

  @override
  String get ruleEditAt => 'at';

  @override
  String ruleEditNotServed(String line) {
    return 'The $line doesn\'t stop here (or this is its last stop).';
  }

  @override
  String ruleEditLeaveMath(int walk, int n) {
    return '$walk′ walk + 5′ early at the stop = an alert $n′ before it arrives.';
  }

  @override
  String get ruleEditEndAfterStart => 'The end must be after the start.';

  @override
  String ruleEditLateSub(int n) {
    return 'When the delay reaches $n min';
  }

  @override
  String get ruleEditEarlier => '15 min earlier';

  @override
  String get ruleEditLater => '15 min later';

  @override
  String get ruleEditPickStopFirst => 'Pick a stop first.';

  @override
  String get rulesDayMon => 'Mo';

  @override
  String get rulesDayTue => 'Tu';

  @override
  String get rulesDayWed => 'We';

  @override
  String get rulesDayThu => 'Th';

  @override
  String get rulesDayFri => 'Fr';

  @override
  String get rulesDaySat => 'Sa';

  @override
  String get rulesDaySun => 'Su';

  @override
  String get rulesMonFri => 'Mon–Fri';

  @override
  String get rulesEveryDay => 'Every day';

  @override
  String get rulesWeekend => 'Sat–Sun';

  @override
  String rulesMinutesBefore(int n) {
    return '$n′ before';
  }

  @override
  String rulesStopsBefore(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n stops before',
      one: '1 stop before',
    );
    return '$_temp0';
  }

  @override
  String get rulesAndIfLate => 'and if it\'s late';

  @override
  String get rulesNewRule => 'New rule';

  @override
  String get rulesNow => 'Now';

  @override
  String get rulesNowEmpty => 'Tap the bell next to a line at your stop.';

  @override
  String rulesTrip(String line, String stop) {
    return 'Riding the $line · getting off at $stop';
  }

  @override
  String get rulesStoppedFromCard => 'Stopped from the live card';

  @override
  String rulesUntil(String time) {
    return 'until $time';
  }

  @override
  String get rulesWeekly => 'Every week';

  @override
  String get rulesWeeklyEmpty =>
      'E.g. “Mon–Fri 08:00–08:40, 5′ before the 602 at your stop”.';

  @override
  String get rulesPaused => 'Paused';

  @override
  String get rulesStoppedToday => 'Stopped for today';

  @override
  String get rulesRunningNow => 'Running now';

  @override
  String rulesNext(String when, String time) {
    return 'Next: $when $time';
  }

  @override
  String get rulesToday => 'today';

  @override
  String get rulesTomorrow => 'tomorrow';

  @override
  String rulesInDays(int n) {
    return 'in $n days';
  }

  @override
  String get rulesResume => 'Resume';

  @override
  String get rulesExactHint =>
      'Rules may start a few minutes late: Android hasn\'t given us permission for exact alarms.';

  @override
  String get rulesGrant => 'Allow';

  @override
  String get followNoLocation =>
      'Location permission is needed so the app can tell when you get on.';

  @override
  String get followStopNotOnLine => 'The stop isn\'t on this line.';

  @override
  String get followNotStarted =>
      'The alert didn\'t start. Tap again with the app open.';

  @override
  String get followLineNotLoaded =>
      'The line didn\'t load. Try again when you\'re online.';

  @override
  String followReady(String line, String stop) {
    return 'All set. Get on the $line and we\'ll notify you one stop before $stop, even with the app closed.';
  }

  @override
  String get followStop => 'Stop';

  @override
  String get followButton => 'Tell me when to get off';

  @override
  String get rideNoBus =>
      'No bus found near you. Pick it on the map and tap “Where do I get off?”.';

  @override
  String get rideAtTerminus =>
      'The bus is at its last stop: no stops after it.';

  @override
  String get rideWhere => 'Where are you getting off?';

  @override
  String get rideVibrate =>
      'Your phone will vibrate one stop before: “Get off at the next stop”.';

  @override
  String get rideVibrateAlerts =>
      'Your phone will vibrate one stop before: “Get off at the next stop”. You can also see it in Alerts.';

  @override
  String get rideOnBoard => 'You\'re on board · we\'ll notify you';

  @override
  String get rideNoPermission => 'No notification permission';

  @override
  String get rideGetOffAt => 'Getting off at';

  @override
  String rideAbout(String mins) {
    return 'about $mins';
  }

  @override
  String get favsAddStop => 'Stop';

  @override
  String get favsWhereHome => 'Where\'s your home?';

  @override
  String get favsPlacesSub =>
      'Places: home, work and more · they stay on your phone';

  @override
  String get favsPlaces => 'Places';

  @override
  String get favsMorning => 'Morning: home stop first';

  @override
  String get favsAfternoon => 'Afternoon: work stop first';

  @override
  String get favsEmpty => 'No saved stops yet. Tap “+ Stop”.';

  @override
  String get favsStops => 'Stops';

  @override
  String get favsLines => 'Lines';

  @override
  String get favsLinesEmpty =>
      'No lines yet. Tap the star on a line to see it here.';

  @override
  String favsLastHome(String line) {
    return 'The last $line home';
  }

  @override
  String favsLastHomeBody(
    String departs,
    String from,
    String time,
    String stop,
  ) {
    return 'Leaves $from at $departs and passes $stop at ~$time. Timetable, not live.';
  }

  @override
  String get favsWillNotify => 'We\'ll notify you';

  @override
  String get favsNoGpsBus => 'no buses with GPS right now';

  @override
  String favsOnRoad(int n) {
    return '$n on the road';
  }

  @override
  String get favsAllOnTime => 'all on time';

  @override
  String favsLate(int n) {
    return '$n late';
  }

  @override
  String get favsOptions => 'Options';

  @override
  String get favsIsHome => 'This is home';

  @override
  String get favsIsWork => 'This is work';

  @override
  String get favsNeither => 'Neither home nor work';

  @override
  String get favsRemove => 'Remove';

  @override
  String favsQuiet(String lines) {
    return 'No bus with GPS right now: $lines';
  }

  @override
  String favsAllLines(int n) {
    return 'All lines here ($n) ›';
  }

  @override
  String get addStopTitle => 'Which stop do you want to keep?';

  @override
  String get addStopSub =>
      'You\'ll find it in your favourites, with the lines you pick.';

  @override
  String get addStopSearchHint => 'Type the stop\'s name';

  @override
  String get addStopSearchHintOr => 'Or type the stop\'s name';

  @override
  String get addStopNone => 'No stop found. Type its name.';

  @override
  String addStopMeters(int m) {
    return '$m m';
  }

  @override
  String get addStopWhichLines => 'Which lines do you care about here?';

  @override
  String addStopMaxLines(int n) {
    return 'Up to $n lines in total.';
  }

  @override
  String get addStopPickStop => 'Pick a stop';

  @override
  String get addStopPickLine => 'Pick at least one line';

  @override
  String linesPickerMax(int n) {
    return 'Up to $n lines across the app.';
  }

  @override
  String stopReturn(String place) {
    return '$place (return)';
  }

  @override
  String stopBellOn(String line) {
    return 'Alert for the $line: on';
  }

  @override
  String stopBellOff(String line) {
    return 'Notify me about the $line';
  }

  @override
  String stopLinesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n lines',
      one: '1 line',
    );
    return '$_temp0';
  }

  @override
  String stopAcross(int m) {
    return 'Stop across the road · $m m';
  }

  @override
  String get stopSave => 'Save stop';

  @override
  String get stopSaved => 'Saved stop';

  @override
  String get stopHowToGet => 'Get there';

  @override
  String get stopTripFrom => 'Trip from here';

  @override
  String get stopEstimate =>
      'Times are estimated from the latest data and the line\'s usual speed. They update as soon as there\'s signal.';

  @override
  String get stopNoBus => 'No bus with GPS is coming right now.';

  @override
  String get stopYourLines => 'Your lines';

  @override
  String get stopAlsoHere => 'Also stopping here';

  @override
  String stopAllLines(int n) {
    return 'All lines · +$n ›';
  }

  @override
  String get stopMissed =>
      'Didn\'t start · no bus was seen leaving the first stop';

  @override
  String stopMissedRun(String headsign, String time) {
    return '→ $headsign · the $time run';
  }

  @override
  String get stopOtherOption => 'Alternatives';

  @override
  String get stopPlanned => 'Not started yet · from the timetable';

  @override
  String get stopPlannedNote =>
      'Departure time from the first stop + the ride to here at average speed. Not live.';

  @override
  String stopQuiet(String lines) {
    return 'No bus nearby right now: $lines';
  }

  @override
  String get stopFixSent => 'You sent a location fix for this stop. Thank you!';

  @override
  String get stopWrongPlace => 'Wrong location?';

  @override
  String get vehicleOffline =>
      'Can\'t load the bus: no connection. Trying again shortly.';

  @override
  String vehicleGone(String id) {
    return 'Bus #$id isn\'t sending its position right now: it has probably finished its run.';
  }

  @override
  String vehicleSeeLine(String line) {
    return 'See the $line buses';
  }

  @override
  String vehicleAtYourStop(String stop) {
    return 'at your stop · $stop';
  }

  @override
  String vehicleAtNextStop(String stop) {
    return 'at the next stop · $stop';
  }

  @override
  String get vehicleNotify => 'Notify me';

  @override
  String get vehicleWhereGetOff => 'Where do I get off?';

  @override
  String get vehicleDetails => 'Details';

  @override
  String get vehicleNoSpeed => '— km/h';

  @override
  String vehicleSpeed(int speed) {
    return '$speed km/h';
  }

  @override
  String get vehicleLineSpeeds => 'line speeds';

  @override
  String vehicleUsually(int usual) {
    return 'usually $usual';
  }

  @override
  String vehicleFixAge(String ago) {
    return 'position $ago ago';
  }

  @override
  String vehicleId(String id) {
    return 'vehicle $id';
  }

  @override
  String vehicleTrip(String trip) {
    return 'trip $trip';
  }

  @override
  String get vehicleNextStops => 'Next stops';

  @override
  String vehicleAllNext(int n) {
    return 'All next stops ($n)';
  }

  @override
  String get vehicleUnknownTrip =>
      'We don\'t know yet which trip this bus is running.';

  @override
  String vehicleYourStop(String stop) {
    return '$stop · your stop';
  }

  @override
  String get vehicleWhichStop => 'Which stop?';

  @override
  String get vehicleWhichStopSub =>
      'We\'ll notify you before the bus gets there.';

  @override
  String get goHomeKickerHome => 'HEADING HOME';

  @override
  String get goHomeKickerWork => 'OFF TO WORK';

  @override
  String goHomeKickerFrom(String stop) {
    return 'FROM $stop';
  }

  @override
  String get goHomeAskHomeSub => 'An area is enough. It stays on your phone.';

  @override
  String goHomeNoneComing(String lines) {
    return 'None of $lines coming right now';
  }

  @override
  String goHomeNext(String line, String toward) {
    return 'The $line → $toward';
  }

  @override
  String goHomeWith(String line, String stop) {
    return 'Take the $line from $stop';
  }

  @override
  String get goHomeNoDirect => 'No direct bus';

  @override
  String get goHomeMyLocation => 'My location';

  @override
  String goHomePassesIn(String mins) {
    return 'comes in $mins';
  }

  @override
  String get goHomeTapForRoute => 'Tap for a route with a change or the metro.';

  @override
  String get goHomeLeaveIn => 'leave in';

  @override
  String goHomeLast(int n, String runs) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'last',
      one: 'last',
    );
    return '$_temp0: $runs';
  }

  @override
  String goHomeRunAt(String line, String time) {
    return '$line at $time';
  }

  @override
  String get stopfixThanks => 'Thanks, we got it!';

  @override
  String get stopfixNotImmediate =>
      'The stop doesn\'t move right away: every suggestion is checked against the buses\' GPS.';

  @override
  String get stopfixTapMap => 'Tap the map where the stop pole is';

  @override
  String stopfixTooFar(int m) {
    return 'More than $m m from the stop. Bring it closer.';
  }

  @override
  String get stopfixFailed => 'Not sent. Check your connection and try again.';

  @override
  String get stopfixKnown => 'The small dot is where we have it now.';

  @override
  String stopfixMoved(int m) {
    return 'Moved $m m';
  }

  @override
  String get stopfixSending => 'Sending…';

  @override
  String get stopfixSend => 'Send';

  @override
  String get stopfixStreetView => 'See the spot in Street View ›';

  @override
  String get stopfixPrivacy =>
      'We send the pin\'s position, the stop and a random device code.';

  @override
  String get menuCity => 'City';

  @override
  String get menuPlanner => 'Directions';

  @override
  String get menuLines => 'Lines';

  @override
  String get menuUpdates => 'Service updates';

  @override
  String get menuAlerts => 'Alerts';

  @override
  String get menuPlaces => 'Places';

  @override
  String get menuWidgets => 'Widgets';

  @override
  String get menuStats => 'Statistics';

  @override
  String get menuSettings => 'Settings';

  @override
  String get menuAbout => 'About';

  @override
  String get menuHowItWorks => 'How it works';

  @override
  String get menuCityBuses => 'buses';

  @override
  String get menuLinesError => 'Couldn’t load. Try again';

  @override
  String get menuLinesHint => 'Line number or name';

  @override
  String get menuUpdatesSoon =>
      'OASA’s announcements will show here: strikes, route changes. Coming soon.';

  @override
  String get menuPlaceAdd => 'Add an address or area';

  @override
  String get menuPlaceApprox => 'approximate';

  @override
  String get menuOtherPlace => 'Another place';

  @override
  String get menuPlacesNote =>
      'An area is enough. We keep no data: your places stay on your phone. With “Home” you see how to get back; with “Work”, how to get there in the morning.';

  @override
  String get menuNewPlace => 'New place';

  @override
  String get menuNewPlaceHint => 'Name, e.g. School';

  @override
  String get menuWidgetStop => '“My stop”';

  @override
  String get menuWidgetStopBody => 'The next arrivals at your favourite stop.';

  @override
  String get menuWidgetHome => '“Going home”';

  @override
  String get menuWidgetHomeBody =>
      'Today’s last buses home. It fills in when you open the app away from home.';

  @override
  String get menuLinkIdea => 'Suggest an idea';

  @override
  String get menuLinkWrongStop => 'Stop in the wrong place? Tell us';

  @override
  String get menuLinkAbout => 'About · data · open API';

  @override
  String get menuLinkWeb => 'The map on the web';

  @override
  String get menuUnofficialNote =>
      'Unofficial app. It is not affiliated with OASA, OASTH, STASY or Hellenic Train, and does not represent any of them.';

  @override
  String menuVersion(String version) {
    return 'Version $version';
  }

  @override
  String get menuTerms => 'Terms of use';

  @override
  String get menuPrivacy => 'Privacy policy';

  @override
  String get menuLicenses => 'Open-source licences';

  @override
  String get menuDataSources =>
      'Data sources: OASA (GTFS, CC BY-NC licence, and public telematics data) · OASTH (public data, data.gov.gr) · STASY (GTFS) · Hellenic Train (railway.gov.gr). Map: OpenFreeMap, © OpenStreetMap contributors. Address search: Photon (komoot), © OpenStreetMap contributors.';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsWalk => 'Walk to your home stop';

  @override
  String get settingsWalkNote => 'For the “when to leave” alert.';

  @override
  String get settingsLiveCard => 'Live card on new alerts';

  @override
  String get settingsLiveCardBody =>
      'The bus’s progress on your lock screen. You can also change it on each alert.';

  @override
  String get settingsLastBus => 'Friday and Saturday night: the last bus home';

  @override
  String get settingsLastBusBody =>
      'At 21:00, a notification with the last bus from your “Home” stop';

  @override
  String get settingsMapHelp => 'How to read the map';

  @override
  String get settingsMapHelpBody =>
      'Colours, symbols, where the times come from';

  @override
  String get settingsDeleteAll => 'Delete all data';

  @override
  String get settingsDeleteAllBody =>
      'Favourites, places, alerts, settings. The app starts over.';

  @override
  String get settingsDeleteAllTitle => 'Delete all data?';

  @override
  String get settingsDeleteAllWarning =>
      'Your favourites, places, alerts and settings will be deleted from this phone. This can’t be undone.';

  @override
  String get welcomeHomeTitle => 'Welcome to Staseis';

  @override
  String get welcomeHomeBody =>
      'Every bus in the city on the map, live. Its colour shows whether it’s running late against the timetable.';

  @override
  String get welcomeStopTitle => 'Stops and favourites';

  @override
  String get welcomeStopBody =>
      'Tap a stop to see what’s coming and in how many minutes. Tap the star to keep it in your favourites.';

  @override
  String get welcomeAlertTitle => 'Tell me when to leave';

  @override
  String get welcomeAlertBody =>
      'Tap the bell next to a bus and we’ll notify you just before it arrives. Or set up an alert for every morning.';

  @override
  String get welcomePlanTitle => 'From here to there';

  @override
  String get welcomePlanBody =>
      '“Directions” in the menu finds how to get somewhere, with transfers and times from the buses running right now.';

  @override
  String get welcomeSkip => 'Skip';

  @override
  String get welcomeStart => 'Get started';

  @override
  String get welcomePermissionsTitle => 'Two permissions';

  @override
  String get welcomePermissionsBody =>
      'Both are optional. You can change them any time in your phone’s settings.';

  @override
  String get welcomePrivacyTitle => 'No account, ads or tracking';

  @override
  String get welcomePrivacyBody =>
      'Your location, home, work and favourites stay only on your phone.';

  @override
  String get welcomeLocationTitle => 'Location';

  @override
  String get welcomeLocationBody =>
      'For the stops near you and walking times. Your location stays on your phone.';

  @override
  String get welcomeNotificationsTitle => 'Notifications';

  @override
  String get welcomeNotificationsBody =>
      'So we can tell you when to leave and when your bus is coming.';

  @override
  String get welcomeGranted => 'Allowed';

  @override
  String get welcomeDenied => 'Not allowed · try again';

  @override
  String get welcomeAllow => 'Allow';

  @override
  String statsDayName(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'mon': 'Monday',
      'tue': 'Tuesday',
      'wed': 'Wednesday',
      'thu': 'Thursday',
      'fri': 'Friday',
      'sat': 'Saturday',
      'other': 'Sunday',
    });
    return '$_temp0';
  }

  @override
  String statsMonthName(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'jan': 'January',
      'feb': 'February',
      'mar': 'March',
      'apr': 'April',
      'may': 'May',
      'jun': 'June',
      'jul': 'July',
      'aug': 'August',
      'sep': 'September',
      'oct': 'October',
      'nov': 'November',
      'other': 'December',
    });
    return '$_temp0';
  }

  @override
  String statsDate(String weekday, int day, String month) {
    return '$weekday $day $month';
  }

  @override
  String get statsTitle => 'Network statistics';

  @override
  String get statsTabYesterday => 'Yesterday';

  @override
  String get statsTabTrends => 'Trends';

  @override
  String get statsLongError => 'Couldn’t load the previous days.';

  @override
  String get statsNeedDays => 'At least 2 full days are needed.';

  @override
  String statsLastDays(int count) {
    return 'The last $count full days';
  }

  @override
  String get statsSpeedByHour => 'Average speed by hour';

  @override
  String get statsSpeedNote =>
      'The bar: from the slowest to the fastest day. The dot: all days together.';

  @override
  String get statsWeekdaysWeekends => 'Weekdays and weekends';

  @override
  String statsKmhWeekdays(int count) {
    return 'km/h weekdays ($count)';
  }

  @override
  String statsKmhWeekends(int count) {
    return 'km/h weekends ($count)';
  }

  @override
  String get statsBusesByHour => 'Buses by hour';

  @override
  String get statsLegendWeekday => 'weekday';

  @override
  String get statsLegendWeekend => 'weekend';

  @override
  String statsChanged(String date) {
    return 'Lines that changed ($date)';
  }

  @override
  String statsComparedWeekdays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Compared with the $count previous weekdays.',
      one: 'Compared with the previous weekday.',
    );
    return '$_temp0';
  }

  @override
  String statsComparedWeekends(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Compared with the $count previous weekend days.',
      one: 'Compared with the previous weekend day.',
    );
    return '$_temp0';
  }

  @override
  String get statsLongSource =>
      'Full days only (no gaps in the records). Source: OASA vehicle positions recorded by our server.';

  @override
  String get statsWorst => 'Worst lines';

  @override
  String statsDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get statsMissedTitle => 'Trips that didn’t run';

  @override
  String get statsNoLines => 'No line with enough trips.';

  @override
  String statsMissedOf(int missed, int measured) {
    return '$missed of $measured didn’t run';
  }

  @override
  String statsExpiredDays(int expired, int count) {
    return '$expired of the $count days were measured against an old timetable: some “missed” trips may no longer exist.';
  }

  @override
  String get statsSlowest => 'Slowest';

  @override
  String statsKmh(String speed) {
    return '$speed km/h';
  }

  @override
  String statsHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String get statsNoDelayNote =>
      'Delays per trip aren’t recorded yet, so this counts missed trips and speed.';

  @override
  String statsTrend(String speed, String usual) {
    return '$speed km/h (usually $usual)';
  }

  @override
  String get statsDayError => 'Couldn’t load the statistics.';

  @override
  String get statsBuses => 'buses';

  @override
  String get statsLines => 'lines';

  @override
  String get statsAvgKmh => 'avg km/h';

  @override
  String get statsSlowLines => 'Slowest lines';

  @override
  String get statsFastLines => 'Fastest lines';

  @override
  String get statsDaySource =>
      'Source: OASA vehicle positions recorded by our server. Updated once a day.';

  @override
  String get statsTrips => 'Trips';

  @override
  String statsTripsShare(int percent) {
    return '$percent% of trips ran';
  }

  @override
  String statsRunOf(int run, int measured) {
    return '$run of $measured';
  }

  @override
  String statsExpired(String date) {
    return 'Compared with OASA’s timetable of $date, because no newer one has been published. Some missing trips may no longer exist.';
  }

  @override
  String statsUnseen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines with no trips',
      one: '1 line with no trips',
    );
    return '$_temp0';
  }

  @override
  String statsKmHours(int km, int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return '$km km · $_temp0';
  }

  @override
  String widgetsLive(String time) {
    return 'live: $time';
  }

  @override
  String widgetsLate(int minutes) {
    return '$minutes′ late';
  }

  @override
  String widgetsEarly(int minutes) {
    return '$minutes′ early';
  }

  @override
  String get widgetsFromTimetable => 'scheduled';

  @override
  String get widgetsEstimate => 'estimate';

  @override
  String widgetsStopsAway(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops away',
      one: '1 stop away',
    );
    return '$_temp0';
  }

  @override
  String widgetsThen(String times) {
    return 'then $times';
  }

  @override
  String widgetsReturn(String headsign) {
    return '$headsign (return)';
  }

  @override
  String get widgetsOffline => 'Offline';

  @override
  String widgetsLastData(String ago) {
    return 'last data $ago ago';
  }

  @override
  String get widgetsLiveNote => 'Live';

  @override
  String widgetsUpdatedAt(String time) {
    return 'Last updated $time';
  }

  @override
  String widgetsLineTooltip(String line) {
    return 'Line $line';
  }

  @override
  String get lineRemoveMine => 'Remove from my lines';

  @override
  String get lineAddMine => 'Add to my lines';

  @override
  String get lineMaxMine => 'Up to 5 lines. Remove one of your lines first.';

  @override
  String get lineNow => 'Now';

  @override
  String get lineTimetable => 'Timetable';

  @override
  String lineTo(String stop) {
    return 'to $stop';
  }

  @override
  String lineFrom(String stop) {
    return 'from $stop';
  }

  @override
  String lineOtherDirection(String stop) {
    return 'Other direction: to $stop';
  }

  @override
  String get lineAll => 'All';

  @override
  String get lineStopsLink => 'stops';

  @override
  String get lineStopsTitle => 'Stops';

  @override
  String lineGaps(String gaps) {
    return 'Gaps to the bus ahead: $gaps stops';
  }

  @override
  String lineBigGap(int n) {
    return 'big gap after bus $n';
  }

  @override
  String get lineScheduleError => 'Couldn’t load the timetable.';

  @override
  String get lineScheduleMissing => 'The timetable isn’t available yet.';

  @override
  String get lineNoRunsToday => 'No trips today.';

  @override
  String get lineExpired =>
      'OASA’s timetable has expired: these are the old one’s times for the same day of the week.';

  @override
  String lineRunsToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips today',
      one: '1 trip today',
    );
    return '$_temp0';
  }

  @override
  String lineRanSoFar(int seen, int known) {
    return '$seen of $known ran so far';
  }

  @override
  String get lineSourceDaily =>
      'OASA’s timetable for today, departure times from the first stop.';

  @override
  String get lineSource =>
      'OASA timetable, departure times from the first stop. Struck through: no bus was seen.';

  @override
  String get lineNoGps => 'No buses with GPS right now.';

  @override
  String get lineEnRoute => 'en route';

  @override
  String lineNextStop(String stop) {
    return 'next: $stop';
  }

  @override
  String get lineLoading => 'Loading…';

  @override
  String get lineNoneOnWay => 'None on the way now';

  @override
  String lineAlertTooltip(String line, String stop) {
    return 'Alert for $line at $stop';
  }

  @override
  String get lineWalkDirections => 'Walking directions to the stop';

  @override
  String get serviceHitChannelName => 'Bus approaching';

  @override
  String get serviceHitChannelDescription =>
      'A notification when your bus nears your stop';

  @override
  String get serviceLiveChannelName => 'Live bus progress';

  @override
  String get serviceLiveChannelDescription =>
      'Your bus\'s progress to the stop';

  @override
  String get serviceExactAlarmTitle => 'Start exactly on time?';

  @override
  String get serviceExactAlarmBody =>
      'Android needs the “Alarms & reminders” permission for this. Settings will open: turn the switch on and come back. Without it, the alert still starts, but maybe a few minutes late.';

  @override
  String get serviceExactAlarmLater => 'Not now';

  @override
  String get serviceExactAlarmOpenSettings => 'Open settings';

  @override
  String get serviceRunningTitle => 'Staseis · live';

  @override
  String get serviceRunningText => 'Your alerts are on';

  @override
  String get serviceRuleStartsTitle => 'Your alert is starting';

  @override
  String get serviceRuleStartsBody => 'Open the app for live alerts.';

  @override
  String get serviceNudgeTitleFriday => 'Friday night · the last one home';

  @override
  String get serviceNudgeTitleSaturday => 'Saturday night · the last one home';

  @override
  String serviceNudgeBody(String line, String stop) {
    return 'See when the last $line to $stop leaves and set an alert.';
  }

  @override
  String serviceNudgeLastRun(String line, String time, String from) {
    return 'The last $line leaves $from at $time. Want an alert?';
  }

  @override
  String serviceBoardedTitle(String line) {
    return 'You\'re on the $line';
  }

  @override
  String serviceOneStopBefore(String stop) {
    return 'We\'ll notify you one stop before $stop.';
  }

  @override
  String serviceTripTitle(String line) {
    return 'Trip on the $line';
  }

  @override
  String serviceTripText(String stop) {
    return 'Once you board, we\'ll notify you one stop before $stop.';
  }

  @override
  String get serviceIdleText => 'We\'ll notify you when the bus gets close.';

  @override
  String get serviceNoBusYet => 'No bus with GPS in sight yet.';

  @override
  String serviceArrivingNow(String line, String stop) {
    return '$line · arriving now at $stop';
  }

  @override
  String serviceArrivingIn(String line, String stop, String eta) {
    return '$line · $stop in $eta';
  }

  @override
  String serviceArrivesAt(String time) {
    return 'arrives $time';
  }

  @override
  String get serviceNextStop => 'next stop';

  @override
  String get serviceOfflineEstimate => 'no signal, estimate';

  @override
  String get serviceOffline => 'no signal';

  @override
  String get serviceStop => 'Stop';

  @override
  String get homeWidgetMyStop => 'My stop';

  @override
  String homeWidgetNoBus(String place) {
    return '$place · no buses with GPS';
  }

  @override
  String ruleHitDelay(int min) {
    return '$min min late';
  }

  @override
  String ruleHitIn(int min) {
    return 'in ~$min min';
  }

  @override
  String ruleHitNextStop(String line, String stop, String late) {
    return 'The $line is coming: next stop $stop$late.';
  }

  @override
  String ruleHitArrives(String line, String stop, String late, String eta) {
    return 'The $line reaches $stop$late$eta.';
  }

  @override
  String ruleHitStopsAway(
    String line,
    String stops,
    String stop,
    String late,
    String eta,
  ) {
    return 'The $line is $stops away from $stop$late$eta.';
  }

  @override
  String ruleHitLateTitle(String line, int min) {
    return '$line is running $min min late';
  }

  @override
  String ruleHitLateBody(String stop, String eta, String stops) {
    return 'For $stop$eta$stops.';
  }

  @override
  String ruleHitLateEta(int min) {
    return 'arrives in ~$min min';
  }

  @override
  String ruleHitLeaveTitle(String line) {
    return 'Leave now for the $line';
  }

  @override
  String ruleHitLeaveBody(String stop, String eta) {
    return 'To be at $stop before it arrives$eta.';
  }

  @override
  String get ruleHitRideTitle => 'Get off at the next stop';

  @override
  String ruleHitRideBody(String stop) {
    return 'Next stop: $stop.';
  }

  @override
  String get cityAthensName => 'Athens';

  @override
  String get cityAthensAgency => 'OASA';

  @override
  String get cityAthensIn => 'in Athens';

  @override
  String get cityThessalonikiName => 'Thessaloniki';

  @override
  String get cityThessalonikiAgency => 'OSETh';

  @override
  String get cityThessalonikiIn => 'in Thessaloniki';

  @override
  String get coreKindBusStop => 'bus stop';

  @override
  String get coreKindMetro => 'metro station';

  @override
  String get coreKindTram => 'tram stop';

  @override
  String get coreKindRail => 'suburban rail station';

  @override
  String get coreLastRunOnMonday => 'on Monday';

  @override
  String get coreLastRunOnTuesday => 'on Tuesday';

  @override
  String get coreLastRunOnWednesday => 'on Wednesday';

  @override
  String get coreLastRunOnThursday => 'on Thursday';

  @override
  String get coreLastRunOnFriday => 'on Friday';

  @override
  String get coreLastRunOnSaturday => 'on Saturday';

  @override
  String get coreLastRunOnSunday => 'on Sunday';

  @override
  String get coreNearestMetro => 'Nearest metro station';

  @override
  String coreToward(String names) {
    return 'to $names';
  }

  @override
  String coreDistanceM(int m) {
    return '$m m';
  }

  @override
  String coreDistanceKm(String km) {
    return '$km km';
  }
}
