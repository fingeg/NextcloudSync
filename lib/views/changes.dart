import 'package:flutter/material.dart';
import 'package:flutter_event_bus/flutter_event_bus/EventBus.dart';

import '../cloud.dart';

void showChanges(BuildContext context, Dir dir) => showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Geänderte Dateien'),
          content: SingleChildScrollView(
            child: ListBody(
              children: List.generate(
                dir.changedFiles.length,
                (index) => Container(
                  padding: EdgeInsets.all(10),
                  child: Text(dir.changedFiles[index]),
                ),
              ),
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Okay'),
              onPressed: () {
                dir.changedFiles = [];
                EventBus.of(context).publish(dir);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
