import 'package:flutter/material.dart';
import 'package:flutter_event_bus/flutter_event_bus.dart';
import 'package:nextcloud_sync/views/directory.dart';

import '../cloud.dart';

class DirectoryColumn extends StatefulWidget {
  final int index;
  final Cloud cloud;

  const DirectoryColumn({Key key, this.index, this.cloud}) : super(key: key);

  @override
  _DirectoryColumnState createState() => _DirectoryColumnState();
}

class _DirectoryColumnState extends Interactor<DirectoryColumn> {
  @override
  Subscription subscribeEvents(EventBus eventBus) =>
      eventBus.respond<int>((event) => setState(() => null));

  @override
  Widget build(BuildContext context) => ListView.builder(
        shrinkWrap: true,
        itemCount: widget.cloud.allPossibleDirs[widget.index].length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            final newCount = widget.cloud.allPossibleDirs[widget.index]
                .where((i) => i.isNew)
                .length;
            final subs = widget.cloud.getPaths()[widget.index].split('/');
            final name = subs.sublist(subs.length - 2).join('/');
            return Container(
              width: double.infinity,
              child: Stack(
                children: <Widget>[
                  Container(
                    color: Colors.blue,
                    width: double.infinity,
                    padding: EdgeInsets.all(15),
                    margin: EdgeInsets.only(right: 5, left: 5),
                    child: Text(
                      'Alle Ordner:\n$name',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (newCount > 0)
                    Positioned(
                      right: 30,
                      top: 10,
                      child: Text('+$newCount'),
                    ),
                ],
              ),
            );
          }
          return DirectoryWidget(
            directory: widget.cloud.allPossibleDirs[widget.index][i - 1],
          );
        },
      );
}
