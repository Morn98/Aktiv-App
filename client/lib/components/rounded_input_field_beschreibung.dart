import 'package:aktiv_app_flutter/components/text_field_container.dart';
import 'package:aktiv_app_flutter/Views/defaults/color_palette.dart';
import 'package:flutter/material.dart';

class RoundedInputFieldBeschreibung extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final TextEditingController controller;
  const RoundedInputFieldBeschreibung({
    Key key,
    this.hintText,
    this.icon = Icons.person,
    this.onChanged,
    this.controller,
  }) : super(key: key);

  //Abgerundetes InputField mit vordefiniertem Design und begrenzter Eingabe mit 420 Zeichen
  @override
  Widget build(BuildContext context) {
    return TextFieldContainer(
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          icon: Padding(
            //Icon des InputFields
            padding:
                const EdgeInsets.only(left: 0, top: 8, right: 0, bottom: 100),
            child: Icon(
              icon,
              color: ColorPalette.torea_bay.rgb,
            ),
          ),
          hintText: hintText,
          border: InputBorder.none,
        ),
        maxLines: 6,
        maxLength: 420,
      ),
    );
  }
}
