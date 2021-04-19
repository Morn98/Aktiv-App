import 'dart:developer';

import 'package:aktiv_app_flutter/Models/veranstaltung.dart';
import 'package:aktiv_app_flutter/Provider/event_provider.dart';

import 'package:aktiv_app_flutter/Views/defaults/color_palette.dart';
import 'package:aktiv_app_flutter/Views/defaults/event_preview_box.dart';
import 'package:aktiv_app_flutter/util/rest_api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarView extends StatefulWidget {
  const CalendarView();

  @override
  _CalendarViewState createState() => _CalendarViewState();
}

// TODO: Namen der Monate auf Deutsch ändern
class _CalendarViewState extends State<CalendarView> {
  Map<DateTime, List<Veranstaltung>> _groupedEvents = {
    DateTime.now(): [
      Veranstaltung.create('titel', 'beschreibung', 'kontakt', 'ortBeschr',
          DateTime.now(), DateTime.now(), 0, 0)
    ]
  };

  //late final
  ValueNotifier<List<Veranstaltung>> _selectedEvents;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay;

  final List<bool> isSelected = [true, false];

  @override
  void initState() {
    super.initState();
    // _groupedEvents = {};
    // _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_focusedDay));

    // Muss zu beginn ausgeführt werden um die Veransatltungen erstmals zu laden
    // Können anfangs einfach nur die veransatltung von diesem Monat sein

    // _groupEvents(Provider.of<EventProvider>(context, listen: false).getLoadedEvents());

    for (var event in Provider.of<EventProvider>(context, listen: false)
        .getLoadedEvents()) {
      DateTime date = DateTime.utc(
          event.beginnTs.year, event.beginnTs.month, event.beginnTs.day);

      if (_groupedEvents[date] == null) {
        _groupedEvents[date] = [event];
      } else {
        _groupedEvents[date].add(event);
      }
    }
  }

  // @override
  // void dispose() {
  //   _selectedEvents.dispose();
  //   super.dispose();
  // }

  _groupEvents(List<Veranstaltung> events) {
    // _groupedEvents = {};
    events.forEach((event) {
      DateTime date = DateTime.utc(
          event.beginnTs.year, event.beginnTs.month, event.beginnTs.day);
      if (_groupedEvents[date] == null) _groupedEvents[date] = [];
      _groupedEvents[date].add(event);
    });
    setState(() {});
  }

  List<Veranstaltung> _getEventsForDay(DateTime day) {
    if (isSelected[0])
      return _groupedEvents[day] ?? [];
    else if (_groupedEvents[day] != null) {
       List<Veranstaltung> favoritesOfTheDay = [];
       for(Veranstaltung event in _groupedEvents[day]) 
          // if() TODO: if Abfrage, ob Event geliket ist
          favoritesOfTheDay.add(event);
       
      return favoritesOfTheDay;
    } else
      return [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(10.0),
          child: ToggleButtons(
            children: [
              Container(
                  padding: const EdgeInsets.all(10.0),
                  child: Text('Allgemein')),
              Container(
                  padding: const EdgeInsets.all(10.0),
                  child: Text('Persönlich')),
            ],
            isSelected: isSelected,
            onPressed: (int index) async {
              setState(() {
                // TODO: Persnlicher Kalender soll nur ausgeführt werden können, wenn man registrierter user ist

                for (int buttonIndex = 0;
                    buttonIndex < isSelected.length;
                    buttonIndex++) {
                  if (buttonIndex == index) {
                    isSelected[buttonIndex] = true;
                  } else {
                    isSelected[buttonIndex] = false;
                  }
                }

                // List<Veranstaltung> events;
                // Provider.of<EventProvider>(context, listen: false)
                //     .loadAllEvents();

                // log(events.length.toString());

                //

                /// TODO: Die verwendeten Events austauschen (Zwischen Persönlich und allgemein wechseln)
              });
            },
            borderRadius: BorderRadius.circular(30),
            borderWidth: 1,
            selectedColor: ColorPalette.white.rgb,
            fillColor: ColorPalette.endeavour.rgb,
            disabledBorderColor: ColorPalette.french_pass.rgb,
          ),
        ),
        Container(
            padding: const EdgeInsets.all(10.0),
            child: TableCalendar(
              // firstDay: DateTime.now(),
              firstDay: DateTime.utc(200),
              focusedDay: _focusedDay,
              lastDay: DateTime(_focusedDay.year + 10),
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarFormat: _calendarFormat,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
              ),
              calendarBuilders: calendarBuilder(),
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              eventLoader: (day) {
                return _getEventsForDay(day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;

                    _selectedEvents.value = _getEventsForDay(selectedDay);
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;

                /// TODO: Events für entsprechenden Monat dynamisch laden
              },
            )),
        Expanded(
            child: ValueListenableBuilder<List<Veranstaltung>>(
          valueListenable: _selectedEvents,
          builder: (context, value, _) {
            return ListView.builder(
              itemCount: value.length,
              itemBuilder: (context, index) {
                return EventPreviewBox(value[index].id, value[index].titel,
                    value[index].beschreibung, value[index].titel, false);
              },
            );
          },
        ))
      ],
    );
  }

  // Farbschema des Kalenders festlegen
  CalendarBuilders calendarBuilder() {
    return CalendarBuilders(
      selectedBuilder: (context, date, _) {
        return CalendarDay(date.day.toString(), ColorPalette.french_pass.rgb,
            ColorPalette.torea_bay.rgb);
      },
      todayBuilder: (context, date, _) {
        return CalendarDay(date.day.toString(), ColorPalette.dark_grey.rgb,
            ColorPalette.french_pass.rgb);
      },
      defaultBuilder: (context, date, _) {
        return CalendarDay(date.day.toString(), ColorPalette.endeavour.rgb);
      },
      outsideBuilder: (context, date, _) {
        return CalendarDay(date.day.toString(), ColorPalette.dark_grey.rgb);
      },
      disabledBuilder: (context, date, _) {
        return CalendarDay(date.day.toString(), ColorPalette.light_grey.rgb);
      },
      singleMarkerBuilder: (context, date, _) {
        return SingleMarkerDay(
            isSelected[1] ? ColorPalette.orange.rgb : ColorPalette.malibu.rgb);
      },
    );
  }
}

// ignore: must_be_immutable
class SingleMarkerDay extends StatelessWidget {
  Color backgroundColor;

  SingleMarkerDay(this.backgroundColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      width: 10,
      margin: const EdgeInsets.all(2),
      decoration: new BoxDecoration(
          color: backgroundColor,
          borderRadius: new BorderRadius.circular(40.0)),
    );
  }
}

// ignore: must_be_immutable
class CalendarDay extends StatelessWidget {
  String content;
  Color backgroundColor;
  Color textColor;

  CalendarDay(this.content, this.textColor, [this.backgroundColor]);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      width: 45,
      decoration: new BoxDecoration(
          color: backgroundColor,
          borderRadius: new BorderRadius.circular(40.0)),
      child: Center(
        child: Text(content,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
