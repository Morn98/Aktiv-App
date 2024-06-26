import 'package:aktiv_app_flutter/Provider/event_provider.dart';
import 'package:aktiv_app_flutter/Provider/search_behavior_provider.dart';
import 'package:aktiv_app_flutter/Views/defaults/color_palette.dart';
import 'package:aktiv_app_flutter/Views/defaults/error_preview_box.dart';
import 'package:aktiv_app_flutter/Views/discover/environment_placeholder.dart';
import 'package:aktiv_app_flutter/util/rest_api_service.dart';
import 'package:flappy_search_bar/flappy_search_bar.dart';
import 'package:flappy_search_bar/scaled_tile.dart';
import 'package:flappy_search_bar/search_bar_style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

// class EnvironmentView extends StatelessWidget {
class DiscoverView extends StatefulWidget {
  const DiscoverView();

  @override
  _DiscoverViewState createState() => _DiscoverViewState();
}

final List<bool> isSelected = [true, false, false];

class _DiscoverViewState extends State<DiscoverView> {
  Widget _getPlaceHolder() {
    return EnvironmentPlaceholder();
  }

  var toggleButtons =
      Consumer<SearchBehaviorProvider>(builder: (context, value, child) {
    return value.getToggleButtons();
  });

  static String tooSpecific =
      "Es konnte keine passende Veranstaltung, zu der von Ihnen gewählten Sucheingabe, gefunden werden. Für eine allgemeinere Suche verwenden Sie Tags. Mögliche Tags währen z.B.: Musik, Sport oder Flohmarkt";

  @override
  void initState() {
    super.initState();
  }


  bool _showSearchBehaviorProviderButtons = true;

  // Entdecken View mit Suchfeld 
  @override
  Widget build(BuildContext context) {
    final SearchBarController<Widget> _searchBarController =
        SearchBarController();

    return Container(
        child: SearchBar<Widget>(
      searchBarPadding: EdgeInsets.only(left: 15, right: 15, top: 15),

      listPadding: EdgeInsets.symmetric(horizontal: 10),
      textStyle: TextStyle(
        decoration: TextDecoration.none,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      icon: Icon(Icons.search_rounded, size: 35),
      onSearch: Provider.of<EventProvider>(context, listen: false)
          .loadEventsAsPreviewBoxContaining,
      searchBarStyle: SearchBarStyle(
          backgroundColor: ColorPalette.malibu.rgb,
          borderRadius: BorderRadius.all(Radius.circular(60.0)),
          padding: EdgeInsets.all(10.0)),
      searchBarController: _searchBarController,
      placeHolder: _getPlaceHolder(),
      // iconActiveColor: ,
      // suggestions: [toggleButtons],

      cancellationWidget: Container(
          padding: const EdgeInsets.all(17.0),
          height: 70,
          decoration: BoxDecoration(
              color: ColorPalette.french_pass.rgb,
              borderRadius: BorderRadius.all(Radius.circular(36.0))),
          child: Icon(Icons.close_rounded, size: 35)),
      emptyWidget: ErrorPreviewBox(tooSpecific),
      indexedScaledTileBuilder: (int index) => ScaledTile.count(1, 0.475),
      header: Center(
        child: Visibility(
            visible: _showSearchBehaviorProviderButtons, child: toggleButtons),
      ),
      minimumChars: 1,

      onCancelled: () {
        // print("Cancelled triggered");

        FocusScope.of(context)
            .requestFocus(new FocusNode()); // Schließt Tastatur
      },
      onItemFound: (Widget widget, int index) {
        return widget;
      },
    ));
  }
}
