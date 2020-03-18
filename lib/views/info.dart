import 'package:flutter/material.dart';

import '../keys.dart';
import '../static.dart';

/// Explain all icons
const icons = {
  'Ein Ordner ist neu in der Cloud erschienen': Icon(
    Icons.plus_one,
    color: Colors.green,
    size: 16,
  ),
  'Ein Ordner wird gerade heruntergeladen oder verglichen': SizedBox(
    height: 16,
    width: 16,
    child: CircularProgressIndicator(
      strokeWidth: 1,
      backgroundColor: Colors.white,
    ),
  ),
  'Dateien im Ordner haben sich verändert. Durch einen Klick auf den'
      ' Ordner können die Änderungen angesehen werden. Danach verschwinden'
      ' die Änderungen wieder.': Icon(
    Icons.update,
    color: Colors.orange,
    size: 16,
  ),
  'Der Ordner soll verglichen und heruntergeladen werden': Icon(
    Icons.check_circle,
    color: Colors.green,
    size: 16,
  ),
  'Der Ordner soll nur verglichen werden': Icon(
    Icons.check_circle_outline,
    color: Colors.green,
    size: 16,
  ),
};

void info(BuildContext context) => showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        Static.sharedPreferences.setBool(Keys.showInfo, false);
        return AlertDialog(
          title: Text('Anleitung'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Text(
                  'Die drei Listen sind die Orte an denen alle Aufgaben zu finden sein sollten. '
                  'Um den Modus eines Ordners umzustellen, reicht ein einfacher Klick auf den gewünschten Ordner. '
                  'Es gibt folgende Symbole:',
                  overflow: TextOverflow.visible,
                ),
                Container(height: 20),
                ...icons.keys.map(
                  (infoText) => Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: icons[infoText],
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width - 200,
                        child: Text(
                          infoText,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 20),
                Text(
                  'Bei Fragen und Fehlern einfach an cloud-sync@fingeg.de wenden',
                  overflow: TextOverflow.visible,
                )
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Okay'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
