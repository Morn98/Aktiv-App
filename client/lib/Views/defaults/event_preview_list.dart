import 'dart:developer';
import 'dart:math';
// import 'dart:html';

import 'package:aktiv_app_flutter/Models/veranstaltung.dart';
import 'package:aktiv_app_flutter/Provider/event_provider.dart';
import 'package:aktiv_app_flutter/Views/defaults/error_preview_box.dart';
import 'package:provider/provider.dart';

import 'event_preview_box.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class EventPreviewList extends StatefulWidget {
  // EventPreviewList(this.widgetList, this.bottomReached);
  EventListType type;
  AdditiveFormat additiveFormat;
  EventPreviewList(this.type, this.additiveFormat);

  @override
  _EventPreviewListState createState() => _EventPreviewListState();
}

class _EventPreviewListState extends State<EventPreviewList> {
  _EventPreviewListState();

  ScrollController _controller;

  _scrollListener() {
    if (_controller.offset >= _controller.position.maxScrollExtent &&
        !_controller.position.outOfRange) {
      //
      setState(() {
        /// Wenn aufgerufen sollte Liste durch Provider automatisch erweitert werden, tut aber nicht ¯\_(ツ)_/¯
      });
    }
  }

  @override
  void initState() {
    _controller = ScrollController(keepScrollOffset: true);
    _controller.addListener(_scrollListener);
    // Provider.of<EventProvider>(context, listen: false)
    //       .resetEventListType(widget.type);
    super.initState();
  }

  Future<List<Veranstaltung>> getEventsFromProvider() async {
    return await Provider.of<EventProvider>(context, listen: false)
        .loadEventListOfType(widget.type);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Veranstaltung>>(
        future: getEventsFromProvider(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data;

          return Container(
              child: events.length > 0
                  ? RefreshIndicator(
                      child: ListView.builder(
                          key: new PageStorageKey(widget.type.toString()),
                          physics: const AlwaysScrollableScrollPhysics(),
                          controller: _controller,
                          padding: const EdgeInsets.all(8),
                          itemCount: events.length,
                          itemBuilder: (BuildContext context, int index) {
                            return EventPreviewBox.load(
                                events[index], widget.additiveFormat);
                          }),
                      onRefresh: _refreshData)
                  : ErrorPreviewBox("Es konnten keine passenden Veranstaltungen aus der Datenbank geladen werden."));
        });
  }

  Future<void> _refreshData() async {
    setState(() {
      Provider.of<EventProvider>(context, listen: false)
          .resetEventListType(widget.type);
    });
  }
}
