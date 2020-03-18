import 'package:flutter/material.dart';
import 'package:flutter_event_bus/flutter_event_bus/EventBus.dart';
import 'package:flutter_event_bus/flutter_event_bus/Interactor.dart';
import 'package:flutter_event_bus/flutter_event_bus/Subscription.dart';

import '../cloud.dart';
import 'changes.dart';

class DirectoryWidget extends StatefulWidget {
  final Dir directory;

  const DirectoryWidget({Key key, this.directory}) : super(key: key);

  @override
  _DirectoryWidgetState createState() => _DirectoryWidgetState();
}

class _DirectoryWidgetState extends Interactor<DirectoryWidget> {
  @override
  Widget build(BuildContext context) {
    final dir = widget.directory;
    final name = dir.name;
    String msg = '';
    if (dir.isChanged) {
      msg = 'Klicke zum Anschauen der Änderungen';
    } else if (dir.failedDownload) {
      msg = dir.failMsg;
    } else if (dir.isLoading) {
      msg = 'Atualisiert derzeit';
    } else if (dir.isNew) {
      msg = 'Neu erschienener Ordner';
    } else {
      switch (dir.state) {
        case FileState.none:
          msg = 'Klicke zum beobachten';
          break;
        case FileState.watching:
          msg = 'Klicke um zu Downloads hinzuzufügen';
          break;
        case FileState.selected:
          msg = 'Klicke um den Ordner zu irnorieren';
          break;
      }
    }
    return Tooltip(
      message: msg,
      child: Container(
        height: 40,
        child: Stack(
          children: <Widget>[
            if (dir.isChanged)
              Positioned(
                right: 10,
                top: 10,
                child: Icon(
                  Icons.update,
                  color: Colors.orange,
                  size: 16,
                ),
              )
            else if (dir.failedDownload)
              Positioned(
                right: 10,
                top: 10,
                child: Icon(
                  Icons.warning,
                  color: Colors.red,
                  size: 16,
                ),
              )
            else if (dir.isLoading)
              Positioned(
                right: 10,
                top: 10,
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 1,
                    backgroundColor: Colors.white,
                  ),
                ),
              )
            else if (dir.isNew)
              Positioned(
                right: 10,
                top: 10,
                child: Icon(
                  Icons.plus_one,
                  color: Colors.green,
                  size: 16,
                ),
              ),
            if (dir.state != FileState.none)
              Positioned(
                left: 0,
                top: 12,
                child: Icon(
                  dir.state == FileState.selected
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  color: Colors.green,
                  size: 16,
                ),
              ),
            Positioned.fill(
              child: FlatButton(
                padding: EdgeInsets.all(0),
                onPressed: () {
                  if (dir.isChanged) {
                    showChanges(context, dir);
                  } else {
                    setState(() {
                      dir.toggleSelection();
                    });
                  }
                },
                child: Text(name),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Subscription subscribeEvents(EventBus eventBus) =>
      eventBus.respond<Dir>((event) => setState(() => null));
}
