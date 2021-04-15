import 'package:aktiv_app_flutter/Views/defaults/color_palette.dart';
import 'package:aktiv_app_flutter/components/rounded_input_field.dart';
import 'package:flutter/material.dart';

import '../profile_screen.dart';

class ProfilePersoenlich extends StatefulWidget {
  ProfilePersoenlich({Key key}) : super(key: key);

  @override
  _ProfilePersoenlichState createState() => _ProfilePersoenlichState();
}

class _ProfilePersoenlichState extends State<ProfilePersoenlich> {
  int currentStep = 0; //startIndex für Stepper
  bool complete = false; //Ausfüllen abgeschlossen?

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            complete
                ? Center(
                    child: AlertDialog(
                      title: Text("Angaben vollständig"),
                      content: SingleChildScrollView(
                        child: ListBody(
                          children: <Widget>[
                            RichText(
                              text: TextSpan(
                                text:
                                    "Vielen Dank für die vervollständigung Ihrer angaben. \nSie haben nun die Möglichkeit, Veranstaltungen anzulegen.",
                                style: TextStyle(color: ColorPalette.white.rgb),
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                            onPressed: () {
                              complete = false;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    return ProfileScreen();
                                  },
                                ),
                              );
                            },
                            child: Text("Weiterleiten"))
                      ],
                    ),
                  )
                : Stepper(
                    steps: steps,
                    currentStep: currentStep,
                    onStepContinue: nextStep,
                    onStepCancel: cancelStep,
                    onStepTapped: (step) => goToStep(step),
                  ),
          ],
        ),
      ),
    );
  }

  nextStep() {
    currentStep + 1 != steps.length
        ? goToStep(currentStep + 1)
        : setState(() => complete = true);
  }

  cancelStep() {
    if (currentStep > 0) {
      goToStep(currentStep - 1);
    }
  }

  goToStep(int step) {
    setState(() => currentStep = step);
  }

  List<Step> steps = [
    Step(
      title: Text("Person"),
      content: Column(
        children: <Widget>[
          RoundedInputField(
            hintText: "Vorname",
            onChanged: (value) {},
          ),
          RoundedInputField(
            hintText: "Nachname",
            onChanged: (value) {},
          ),
          RoundedInputField(
            hintText: "Telefonnummer",
            icon: Icons.phone,
            onChanged: (value) {},
          ),
        ],
      ),
    ),
    Step(
      title: Text("Anschrift"),
      content: Column(
        children: <Widget>[
          RoundedInputField(
            hintText: "Straße, Hausnummer",
            icon: Icons.home,
            onChanged: (value) {},
          ),
          RoundedInputField(
            hintText: "PLZ, Ort",
            icon: Icons.gps_fixed_outlined,
            onChanged: (value) {},
          ),
        ],
      ),
    ),
  ];
}
