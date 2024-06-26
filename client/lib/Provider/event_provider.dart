import 'dart:developer';

import 'package:aktiv_app_flutter/Models/veranstaltung.dart';
import 'package:aktiv_app_flutter/Provider/search_behavior_provider.dart';
import 'package:aktiv_app_flutter/Provider/user_provider.dart';
import 'package:aktiv_app_flutter/Models/role_permissions.dart';
import 'package:aktiv_app_flutter/Views/defaults/error_preview_box.dart';
import 'package:aktiv_app_flutter/Views/defaults/event_preview_box.dart';
import 'package:aktiv_app_flutter/util/rest_api_service.dart';
import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:http/http.dart';
import 'package:provider/provider.dart';

enum EventListType { UP_COMING, FAVORITES, NEAR_BY, APPROVE }

class EventProvider extends ChangeNotifier {
  /// Map aller Event Instanzen die zu ihrer ID hinterlegt sind
  static final Map<int, Veranstaltung> loaded = Map<int, Veranstaltung>();

  /// Map aller Event ID's die zu ihrem Beginn Zeitstempel hinterlegt sind
  static final Map<DateTime, List<int>> dated = Map<DateTime, List<int>>();

  /// Map aller Veranstaltungs Zeitstempel die zu ihrem Beginn Event ID's hinterlegt sind
  static final Map<int, DateTime> loadedTs = Map<int, DateTime>();

  /// Map aller Veranstaltungs Vorschau(/Institution) Bildern
  static final Map<int, String> previewImage = Map<int, String>();

  /// Map aller Event ID's die zu ihrem Beginn Zeitstempel hinterlegt sind
  static final Map<int, double> distance = Map<int, double>();

  /// Liste aller Event ID's die in der nähe statt finden
  static final List<int> nearby = [];

  /// Liste aller Event ID's die als nächstes statt finden (sortiert)
  static final List<int> upComing = [];

  /// Liste aller Event ID's die als favorisiert markiert sind.
  static final List<int> favorites = [];

  /// Liste aller Event ID's die als genehmigt markiert sind.
  // static final List<int> pendingApproval = [];

  /// Die Standard Menge an events, die von EINEM attempt Aufruf geladen werden sollen
  static final int pageSize = 25;

  /// Behinhaltet BIS zu welche SEITE die entsprechenden Events bereits geladen wurden
  static final Map<EventListType, int> nextPageToLoad =
      Map<EventListType, int>();

  /// Behinhaltet WANN die entsprechenden Events zuletzt gespeichert wurden
  static final Map<EventListType, DateTime> lastUpdate =
      Map<EventListType, DateTime>();

  /// Gibt eine Liste aller Events zurück die bereits geladen wurden
  List<Veranstaltung> getLoadedEvents() {
    return loaded.values.toList();
  }

  /// Löscht ein Event, falls es geladen ist
  void removeEventIfLoaded(int id) {
    if (loaded.containsKey(id)) {
      dated[loaded[id].beginnTs].remove(id);
      loaded.remove(id);
    }

    if (favorites.contains(id)) favorites.remove(id);
    if (upComing.contains(id)) upComing.remove(id);
    if (nearby.contains(id)) nearby.remove(id);
  }

  /// Gibt eine Liste aller Events mit ausstehender genehmigung zurück
  // List<Veranstaltung> getEventWithPendingApproval() {
  //   return pendingApproval.map((id) => getLoadedEventById(id)).toList();
  // }

  /// Gibt eine Liste aller Events zurück die als favorisiert markiert sind
  List<Veranstaltung> getLoadedFavoritesEvents() {
    return favorites.map((id) => getLoadedEventById(id)).toList();
  }

  /// Gibt eine Liste aller Events zurück die als "nearby" markiert sind
  List<Veranstaltung> getLoadedEventsNearBy() {
    return nearby.map((id) => getLoadedEventById(id)).toList();
  }

  /// Gibt eine Liste aller Events zurück die als "upcoming" markiert sind
  List<Veranstaltung> getLoadedUpComingEvents() {
    return upComing.map((id) => getLoadedEventById(id)).toList();
  }

  /// Lädt eine Liste an Events aus der Datenbank. Abhängig vom im SearchBehaviorProvider
  /// Suchverhalten wird nach anderen events in der DB gesucht. Bei FULLTEXT wir nach Events
  /// gesucht, die in irgendeiner Art und eise den übergebenen Text beinhalten. (Titel,
  /// Beschriebung, Tags,Veranstalter). Bei DATE wird nach Events an einem speziellen
  /// Tag gesucht und bei PERIOD nach allen events BIS zu einem speziellen Tag
  Future<List<Widget>> loadEventsAsPreviewBoxContaining(String text) async {
    List<Widget> eventPreviews = [];

    switch (SearchBehaviorProvider.style) {
      case SearchStyle.FULLTEXT:
        List<Veranstaltung> events = await loadEventsContainingText(text) ?? [];

        List<EventPreviewBox> boxes = events
            .map((event) =>
                EventPreviewBox.load(event, AdditiveFormat.HOLE_DATETIME))
            .toList();

        return boxes;
      case SearchStyle.DATE:

        /// Suche nach Events, die an dem Datum statt finden

        DateTime dateTime = isValidDate(text);
        if (dateTime != null) {
          List<Veranstaltung> events = await loadEventsAtDate(dateTime);
          return events
              .map((event) =>
                  EventPreviewBox.load(event, AdditiveFormat.HOLE_DATETIME))
              .toList();

          // return getLoadedEventsOfDay(dateTime)
          //     .map((event) =>
          //         EventPreviewBox.load(event, AdditiveFormat.HOLE_DATETIME))
          //     .toList();
        } else {
          eventPreviews.add(ErrorPreviewBox(
              "Bei der von Ihnen getätigten Suchanfrage \"" +
                  text +
                  "\" handelt es sich um kein gültiges Datum Format. Bitte Datum im Format Tag.Monat.Jahr (DD.MM.YYYY) angeben."));
        }

        if (eventPreviews.length == 0) {
          // attemptGetTags();
          eventPreviews.add(ErrorPreviewBox(
              "Es konnten keine Veranstaltungen für den " +
                  text +
                  " gefunden werden. Bitte versuchen sie einen aderes Datum.",
              "Eingabe zu spezifisch"));
        }

        return eventPreviews;
      case SearchStyle.PERIOD:

        /// Suche nach Events, die bis zum Datum statt finden

        DateTime dateTime = isValidDate(text);
        if (dateTime != null) {
          List<EventPreviewBox> boxes = (await loadAllEventsUntil(dateTime))
              .map((event) =>
                  EventPreviewBox.load(event, AdditiveFormat.HOLE_DATETIME))
              .toList();

          return boxes;
        } else {
          eventPreviews.add(ErrorPreviewBox(
              "Bei der von Ihnen getätigten Suchanfrage \"" +
                  text +
                  "\" handelt es sich um kein gültiges Datum Format. Bitte Datum im Format Tag.Monat.Jahr angeben."));
        }

        return eventPreviews;
      default:
        return eventPreviews;
    }
  }

  /// Lädt durch Fulltext suche Events aus der Datenbank
  Future<List<Veranstaltung>> loadEventsContainingText(String text) async {
    List<Veranstaltung> foundEvents = [];

    /// Da in der Regel für jede Suche andere Ergebnisse zurück kommen
    /// startet die Suche immer bei Seite 1 und Endet bei max Seite 4
    for (int page = 1; page < 4; page++) {
      var response = await attemptGetAllVeranstaltungen(
          "-1",
          "1", // nur zugelassene Events == 0, alle == 1
          pageSize.toString(),
          page.toString(),
          UserProvider.istEingeloggt ? UserProvider.userId.toString() : "-1",
          text);
      if (response.statusCode == 200) {
        var parsedJson = json.decode(response.body);

        final List<dynamic> dynamicList = await parsedJson
            .map((item) => getEventFromJson(item, false))
            .toList();

        final List<Veranstaltung> responseList =
            List<Veranstaltung>.from(dynamicList).toList();

        foundEvents.addAll(responseList);

        /// Abbruch wenn keine neuen Events geladen wurden
        if (responseList == null || responseList.length == 0) break;
      } else {
        log("Fehler bei der Suche nach dem Schlüsselwort:" +
            text +
            " auf Seite: " +
            page.toString() +
            ", response.statusCode:" +
            response.statusCode.toString());
        break;

        /// Abbruch weil fehler geworfen
      }
    }
    return foundEvents;
  }

  /// Lädt durch Datumsuche suche Events aus der Datenbank
  Future<List<Veranstaltung>> loadEventsAtDate(DateTime date) async {
    List<Veranstaltung> foundEvents = [];

    /// Da in der Regel für jede Suche andere Ergebnisse zurück kommen
    /// startet die Suche immer bei Seite 1 und Endet bei max Seite 4
    for (int page = 1; page < 4; page++) {
      var response = await attemptGetAllVeranstaltungen(
          "-1", //bis datum
          "1", // nur zugelassene Events == 0, alle == 1
          pageSize.toString(),
          page.toString(),
          UserProvider.istEingeloggt ? UserProvider.userId.toString() : "-1",
          "-1", //volltext
          "-1", //entfernung
          "-1", //sorting
          date.toString());
      if (response.statusCode == 200) {
        var parsedJson = json.decode(response.body);

        final List<dynamic> dynamicList = await parsedJson
            .map((item) => getEventFromJson(item, false))
            .toList();

        final List<Veranstaltung> responseList =
            List<Veranstaltung>.from(dynamicList).toList();

        foundEvents.addAll(responseList);

        /// Abbruch wenn keine neuen Events geladen wurden
        if (responseList == null || responseList.length == 0) break;
      } else {
        log("Fehler bei der Suche nach Events an folgendem Datum:" +
            date.toString() +
            " auf Seite: " +
            page.toString() +
            ", response.statusCode:" +
            response.statusCode.toString());
        break;

        /// Abbruch weil fehler geworfen
      }
    }
    return foundEvents;
  }

  /// Lädt alle Events von neu bis zu einem gewissen Datum
  Future<List<Veranstaltung>> loadAllEventsUntil(DateTime until) {
    until = DateTime.utc(until.year, until.month, until.day + 1);

    /// 16 pages begrenzt das Laden der Events auf max 400 Events
    return loadEventsUntil(1, 16, null, until);
  }

  /// Lädt Events aus Datenbank, die vor dem übergebenen Datum stattfinden
  Future<List<Veranstaltung>> loadEventsUntil(
      int startPage, int maxPages, EventListType type, DateTime until) async {
    String entfernung =
        EventListType.NEAR_BY == type ? UserProvider.naehe.toString() : "-1";
    String sorting = EventListType.NEAR_BY == type
        ? "entfernung"
        : EventListType.UP_COMING == type
            ? "beginn_ts"
            : "-1";

    String userId =
        UserProvider.istEingeloggt ? UserProvider.userId.toString() : "-1";

    List<Veranstaltung> foundEvents = [];

    for (int page = startPage; page < (startPage + maxPages); page++) {
      var response = await attemptGetAllVeranstaltungen(
          // until.toString(),
          type == EventListType.FAVORITES ? "-1" : until.toString(),
          "1", // nur genehmigte Events == 0, alle == 1
          pageSize.toString(),
          page.toString(),
          userId,
          "-1", // weil keine volltext Suche
          entfernung,
          sorting);
          
      if (response.statusCode == 200) {
        var parsedJson = json.decode(response.body);

        final List<dynamic> dynamicList = await parsedJson
            .map((item) => getEventFromJson(item, false))
            .toList();

        final List<Veranstaltung> responseList =
            List<Veranstaltung>.from(dynamicList).toList();

        foundEvents.addAll(responseList);

        // Markiere welche seite als nächstes geladen werden muss
        if (type != null && responseList.length > 0)
          nextPageToLoad[type] = page + 1;

        /// Wenn durch aktuelle page keine neuen Events geladen wurden: break;
        if (responseList == null || responseList.length == 0) break;
      } else {
        log("Fehler bei der Suche nach Veranstaltungen  bis zum " +
            until.toString() +
            " auf Seite: " +
            page.toString() +
            ", response.statusCode:" +
            response.statusCode.toString());
      }
    }

    return foundEvents;
  }

  void resetEventListType(EventListType type) {
    nextPageToLoad[type] = 1;
    switch (type) {
      case EventListType.UP_COMING:
        upComing.clear();
        return;
      case EventListType.NEAR_BY:
        nearby.clear();
        return;
      case EventListType.FAVORITES:
        // NIX RESETTEN! Favorites regelt sich durch getEventFromJson
        break;
      case EventListType.APPROVE:
        // NIX RESETTEN! Favorites regelt sich durch getEventFromJson
        break;
    }
  }

  int order(int a, int b) {
    Veranstaltung eventA = loaded[a];
    Veranstaltung eventB = loaded[b];
    if (eventA != null && eventB != null)
      return eventA.beginnTs.compareTo(eventB.beginnTs);
    return 0;
  }

  bool shouldSortFavorites = true;

  void sortLoadedFavoriteEvents() {
    favorites.sort((a, b) => order(a, b));
  }

  void sortLoadedUpComingEvents() {
    upComing.sort((a, b) => order(a, b));
  }

  static double getDistanceToEvent(int id) {
    return distance[id] ?? -1;
  }

  /// Methode ruft attemptGetAllVeranstaltungen auf uns sortiert die Rückgabe
  /// in die, der übergebenen EventListType, entsprechend ein. Wenn das letzte
  /// laden des Types über eine Stunde her ist lädt er Alle Events neu, ansonsten
  /// fängt er da an, wo dass letzte mal aufgehört hat (nextPageToLoad)
  Future<List<Veranstaltung>> loadEventListOfType(EventListType type) async {
    int startPage = nextPageToLoad[type] ?? 1;
    // int startPage = 1;
    DateTime now = DateTime.now();
    DateTime lastUpdated = lastUpdate[type] ?? now;

    /// Wenn letztes Update über eine Stunde zurück liegt: fang von Vorne an
    if (lastUpdated.difference(now).inHours > 1) startPage = 1;

    DateTime until =
        DateTime.utc(now.year, now.month, now.day + UserProvider.bald);

    List<Veranstaltung> loaded =
        await loadEventsUntil(startPage, 1, type, until);

    if (loaded == null) return [];

    lastUpdate[type] = now;

    /// Geladene Events werden dem EventListType entsprechend einsortiert
    switch (type) {
      case EventListType.FAVORITES:
        if (shouldSortFavorites) sortLoadedFavoriteEvents();
        return getLoadedFavoritesEvents();
      case EventListType.NEAR_BY:

        /// Denkfehler, weil near by nicht auf GetAll zurück greift
        /// Wenn von Anfang an geladen (Page=1) dann bisher geladenes löschen
        if (startPage == 1) nearby.clear();

        for (Veranstaltung event in loaded)
          if (/*!pendingApproval.contains(event.id) && */ !nearby
              .contains(event.id)) nearby.add(event.id);

        return nearby.map((id) => getLoadedEventById(id)).toList();
      case EventListType.UP_COMING:

        /// Wenn von Anfang an geladen (startPage=1) dann bisher geladenes upComing verwerfen
        if (startPage == 1) upComing.clear();

        for (Veranstaltung event in loaded)
          if (/*!pendingApproval.contains(event.id) &&*/
              !upComing.contains(event.id)) upComing.add(event.id);

        return upComing.map((id) => getLoadedEventById(id)).toList();
      // case EventListType.APPROVE:
      //   // if (startPage == 1) pendingApproval.clear();

      //   var response = await attemptGetPLZs(UserProvider.userId.toString());

      //   if (response.statusCode == 200) {
      //     log("plzs: " + response.body);
      //     //
      //     //
      //   }

      //   List<int> allowedToApprove = pendingApproval.toList();

      //   for (int i = 0; i < allowedToApprove.length; i++) {
      //     Veranstaltung event = loaded[allowedToApprove[i]];
      //     // if(event.)
      //
      //   }

      //   return allowedToApprove.map((id) => getLoadedEventById(id)).toList();
      default:
        return [];
    }
  }

  /// Überprüft ob dass angegebene Datum (im Suchfeld) im richtigen Format ist
  /// Wenn ja, wird das Datum als Datetime Objekt zurückgegeben
  DateTime isValidDate(String possiblyDate) {
    List<String> args = possiblyDate.split(".");
    if (args.length > 2 &&
        args[0].length == 2 &&
        args[1].length == 2 &&
        args[2].length == 4)
      return DateTime.parse(args[2] + '-' + args[1] + '-' + args[0]);
    return null;
  }

  /// Bekommt DateTime und eine Liste mit Veranstaltungen & löscht
  /// alle Veranstaltungen aus der Liste, die nicht im selben Monat wie
  /// Datetime stattfinden.
  List<Veranstaltung> removeEventsOutsideMonth(
      DateTime month, List<Veranstaltung> events) {
    int year = month.year;

    DateTime start = DateTime.utc(year, month.month, 1);
    DateTime end =
        DateTime.utc(year, month.month + 1, 1); //0); wegen 00:00 Uhr evtl.

    for (int index = 0; index < events.length; index++) {
      Veranstaltung event = events[index];
      if (event.beginnTs.isBefore(start) || end.isBefore(event.beginnTs))
        events.remove(event);
    }
    return events;
  }

  /// Gibt eine Liste an Events zurück, die einerseits bereits geladen sind und die
  /// an dem selben Tag wie die übergebene Datetime statt finden
  List<Veranstaltung> getLoadedEventsOfDay(DateTime day) {
    DateTime start = DateTime.utc(day.year, day.month, day.day);
    DateTime end = DateTime.utc(day.year, day.month, day.day + 1);

    List<Veranstaltung> eventsOfMonth = [];

    for (DateTime date in dated.keys)
      if (start.isBefore(date) && date.isBefore(end))
        for (int eventId in dated[date]) eventsOfMonth.add(loaded[eventId]);

    return eventsOfMonth;
  }

  /// Gibt eine Liste an Events zurück, die einerseits bereits geladen sind, die
  /// an dem selben Tag wie die übergebene Datetime statt finden und die als
  /// favorisiert markiert sind
  List<Veranstaltung> getLoadedAndLikedEventsOfDay(DateTime day) {
    List<Veranstaltung> events = getLoadedEventsOfDay(day);
    for (int index = 0; index < events.length; index++) {
      Veranstaltung event = events[index];
      if (!favorites.contains(event.id)) events.removeAt(index--);
    }
    return events;
  }

  /// Gibt eine Liste an Events zurück, die einerseits bereits geladen sind und die
  /// im selben Monat wie die übergebene Datetime statt finden
  List<Veranstaltung> getLoadedEventsOfMonth(DateTime month) {
    int year = month.year;

    DateTime start = DateTime.utc(year, month.month, 1);
    DateTime end = DateTime.utc(year, month.month + 1, 0);

    List<Veranstaltung> eventsOfMonth = [];

    for (DateTime date in dated.keys)
      if (start.isBefore(date) && date.isBefore(end))
        for (int eventId in dated[date]) eventsOfMonth.add(loaded[eventId]);

    return eventsOfMonth;
  }

  Veranstaltung getLoadedEventById(int id) {
    if (isEventLoaded(id)) return loaded[id];

    return null;
  }

  Future<Veranstaltung> loadEventById(int id) async {
    // if (isEventLoaded(id)) return loaded[id];
    // log("versuche veranstaltung zu laden: " + id.toString());
    var response = await attemptGetVeranstaltungByID(id);
    // log("response.body.toString(): " + response.body.toString());
    if (response.statusCode == 200) {
      var parsedJson = json.decode(response.body);
      // log("parsedJson.toString(): " + parsedJson.toString());
      Veranstaltung event = getEventFromJson(parsedJson, true);

      return event;
    }
    return null;
    // return Veranstaltung.;
  }

  Future<Veranstaltung> createEvent(
      String titel,
      String beschreibung,
      String email,
      String start,
      String ende,
      String adresse,
      String plz,
      int institutionsid,
      int istGehnemigt,
      List<String> imageIds,
      List<String> selectedTags) async {
    int userId = UserProvider.userId;

    Response resp = await attemptCreateVeranstaltung(
        titel,
        beschreibung,
        email,
        start,
        ende,
        adresse,
        plz,
        userId.toString(),
        istGehnemigt.toString(),
        institutionsid.toString(),
        imageIds,
        selectedTags);

    if (resp.statusCode == 200) {
      var parsedJson = json.decode(resp.body);

      log('parsedJson attemptCreateVeranstaltung:' + json.toString());

      int eventId = parsedJson['insertId'];

      DateTime startTs = DateTime.parse(start);
      DateTime endeTs = DateTime.parse(ende);
      DateTime erstelltTs = DateTime.now();

      int erstellerId = UserProvider.userId;

      Veranstaltung veranstaltung = Veranstaltung.load(
          eventId,
          titel,
          beschreibung,
          email,
          adresse,
          startTs,
          endeTs,
          erstelltTs,
          1,
          [],
          [],
          null,
          null,
          erstellerId);

      loadEvent(veranstaltung);

      return veranstaltung;
    } else {
      var parsedJson = json.decode(resp.body);
      var error = parsedJson['error'];
      log(error);
    }
    return null;
  }

  void loadFirstPages() {
    DateTime nextMonth =
        DateTime.utc(DateTime.now().year, DateTime.now().month + 2, 0);
    loadAllEventsUntil(nextMonth);
  }

  void loadEvent(Veranstaltung event) {
    if (event == null || isEventLoaded(event.id)) return;
    loaded[event.id] = event;
    if (dated[event.beginnTs] != null)
      dated[event.beginnTs].add(event.id);
    else
      dated[event.beginnTs] = [event.id];

    notifyListeners();
  }

  void deleteEvent(BuildContext context, event) {
    String accessToken = Provider.of<UserProvider>(context).getAccessToken();
    attemptDeleteVeranstaltung(event.id, accessToken);
  }

  bool isEventLoaded(int id) {
    return loaded.containsKey(id);
  }

  bool isEventFavorite(int id) {
    return favorites.contains(id);
  }

  /// Ändert (toggelt) den Favorisierungs Zustand eines events sowohl im EventProvider,
  /// als auch in der Datenbank
  Future<bool> toggleEventsFavoriteState(
      BuildContext context, int eventId) async {
    if (isEventFavorite(eventId)) {
      favorites.remove(eventId);
    } else {
      favorites.add(eventId);
      shouldSortFavorites = true;
    }

    if (UserProvider.getUserRole().allowedToFavEvents) {
      String accessToken =
          await Provider.of<UserProvider>(context, listen: false)
              .getAccessToken();
      attemptFavor(
          UserProvider.userId.toString(), eventId.toString(), accessToken);
    }

    return isEventFavorite(eventId);
  }

  Veranstaltung getEventFromJson(Map<String, dynamic> json, bool forceNew) {
    // if(forceNew)
    // log('json:' + json.toString());

    int id = json['id'];

    if (json['favorit'].toString() == "1" && !favorites.contains(id)) {
      favorites.add(id);
      shouldSortFavorites = true;
    } else if (json['favorit'].toString() == "0" && favorites.contains(id))
      favorites.remove(id);

    // if (json['istGenehmigt'].toString() == "0" && !pendingApproval.contains(id))
    //   pendingApproval.add(id);
    // else if (json['istGenehmigt'].toString() == "1" &&
    //     pendingApproval.contains(id)) pendingApproval.remove(id);

    if (json['istGenehmigt'].toString() != "1")
      log("Nicht genehmigte Veranstaltung geladen. (id: " +
          id.toString() +
          ")");

    if (json['entfernung'] != null)
      distance[id] = double.parse(json['entfernung'].toString());

    if (isEventLoaded(id) && !forceNew) return loaded[id];

    String titel = json['titel'];
    String description = json['beschreibung'];
    String contact = json['kontakt'];
    DateTime start = DateTime.parse(json['beginn_ts']);
    DateTime end = DateTime.parse(json['ende_ts']);
    String place = json['ortBeschreibung'];

    var institutionImage = json['institutionImage'];

    if (institutionImage != null) previewImage[id] = institutionImage;

    List<String> fileList;

    if (json['files'] != null) {
      final List<dynamic> dynamicList =
          json['files'].map((item) => item['pfad']).toList();

      fileList = List<String>.from(dynamicList).toList();

      // log("tolle Liste: " + fileList.toString());
    }

    List<String> tagList;

    if (json['tags'] != null) {
      final List<dynamic> dynamicList =
          json['tags'].map((item) => item['name']).toList();

      // log("tags" + json['tags'].toString());
      tagList = List<String>.from(dynamicList).toList();

      // log("tolle Liste: " + fileList.toString());
    }

    DateTime created = DateTime.parse(json['erstellt_ts']);

    String institutionName = json['institutionName'];
    String institutBeschreibung = json['institutBeschreibung'];

    int erstellerId = json['ersteller'] ?? -1;

    Veranstaltung event = Veranstaltung.load(
        id,
        titel,
        description,
        contact,
        place,
        start,
        end,
        created,
        1,
        fileList ?? [],
        tagList ?? [],
        institutionName,
        institutBeschreibung,
        erstellerId);

    loadEvent(event);

    return event;
  }

  CircleAvatar getPreviewImage(int eventId) {
    if (previewImage[eventId] == null)
      return CircleAvatar(
        backgroundImage:
            AssetImage("assets/images/wir_hier_logo_transparent.png"),
      );
    else
      return CircleAvatar(
          backgroundImage: NetworkImage(
              "https://app.lebensqualitaet-burgrieden.de/" +
                  previewImage[eventId]));
  }
}
