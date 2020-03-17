import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_event_bus/flutter_event_bus.dart';
import 'package:nextcloud_sync/cloud.dart';
import 'package:nextcloud_sync/keys.dart';
import 'package:nextcloud_sync/static.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  HomePage({
    Key key,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends Interactor<HomePage>
    with AfterLayoutMixin<HomePage> {
  Cloud cloud = Cloud();
  TextEditingController _localRootDirectory = TextEditingController();
  bool initialized = false;

  @override
  void afterFirstLayout(BuildContext context) async {
    print(Directory.current.absolute.path);
    Static.sharedPreferences = await SharedPreferences.getInstance();
    if (Static.sharedPreferences.getString(Keys.username) == null) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
    cloud.init();
    setState(() {
      _localRootDirectory.text =
          Static.sharedPreferences.getString(Keys.rootDirLocal);
      initialized = true;
    });
    update(isInit: true);
    if (Static.sharedPreferences.getBool(Keys.showInfo) ?? true) {
      info();
    }
  }

  void update({isInit = false}) {
    if (!isInit) {
      if (cloud.isLoading) {
        return;
      }
      setState(() {
        cloud.allPossibleDirs =
            List.generate(cloud.getPaths().length, (index) => null);
      });
    }
    for (int i = 0; i < cloud.allPossibleDirs.length; i++) {
      cloud.load(i).then((_) {
        setState(() => null);
        sync(i);
      });
    }
  }

  void sync(int index) {
    final eventBus = EventBus.of(context);
    final all = (cloud.allPossibleDirs[index] ?? []);
    all
        .where((i) => i.state == FileState.selected)
        .forEach((i) => cloud.loadDir(i, true, eventBus));
    all
        .where((i) => i.state == FileState.watching)
        .forEach((i) => cloud.loadDir(i, false, eventBus));
  }

  void showChanges(Dir dir) => showDialog<void>(
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

  void info() => showDialog<void>(
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
                    'Die drei Listen sind die möglichen Orte an denen Aufgaben zu finden sein können. '
                    'Damit Ordner in den angegebenen Zielordner herunter geladen werden einfach auf die gewüschten '
                    'Ordner klicken. '
                    'Ein erneuter klick sorgt dafür, dass der Ordner nicht heruntergeladen wird, aber dir trotztdem '
                    'angezeigt wird ob sich dessen Inhalt verändert hat.',
                    overflow: TextOverflow.visible,
                  ),
                  Container(height: 20),
                  Row(children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.plus_one,
                        color: Colors.green,
                        size: 16,
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width - 200,
                      child: Text(
                        'Ein Ordner ist neu in der Cloud erschinen',
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ]),
                  Container(height: 20),
                  Row(children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 1,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width - 200,
                      child: Text(
                        'Ein Ordner wird gerade heruntergeladen oder verglichen',
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ]),
                  Container(height: 20),
                  Row(children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.update,
                        color: Colors.orange,
                        size: 16,
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width - 200,
                      child: Text(
                        'Dateien im Ordner haben sich verändert. Durch einen klick auf den'
                        ' Ordner können die Änderungen angesehen werden. Danach verschwinden'
                        ' die Änderungen wieder.',
                        overflow: TextOverflow.visible,
                        softWrap: true,
                      ),
                    ),
                  ]),
                  Container(height: 20),
                  Row(children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width - 200,
                      child: Text(
                        'Ordner soll verglichen und heruntergeladen werden',
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ]),
                  Container(height: 20),
                  Row(children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 16,
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width - 200,
                      child: Text(
                        'Ordner soll nur verglichen werden',
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ]),
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

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      return Container();
    }
    final columns = List.generate(
        3,
        (index) => Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (cloud.allPossibleDirs[index] == null)
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        backgroundColor: Theme.of(context).backgroundColor,
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: cloud.allPossibleDirs[index].length + 1,
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          final newCount = cloud.allPossibleDirs[index]
                              .where((i) => i.isNew)
                              .length;
                          final subs = cloud.getPaths()[index].split('/');
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
                        final dir = cloud.allPossibleDirs[index][i - 1];
                        final name = dir.name;
                        return Container(
                          height: 40,
                          child: Stack(
                            children: <Widget>[
                              if (dir.failedDownload)
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
                              else if (dir.isChanged)
                                Positioned(
                                  right: 10,
                                  top: 10,
                                  child: Icon(
                                    Icons.update,
                                    color: Colors.orange,
                                    size: 16,
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
                                      showChanges(dir);
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
                        );
                      },
                    ),
                ],
              ),
            ));
    return Scaffold(
      appBar: AppBar(
        title: Text('Nextcloud Sync'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.info),
            onPressed: info,
          ),
          IconButton(
            icon: Icon(Icons.cloud_download),
            onPressed: update,
          ),
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Zielordner:'),
                  Container(
                    padding: EdgeInsets.all(20),
                    width: constraints.maxWidth - 200,
                    child: TextField(
                      controller: _localRootDirectory,
                      decoration: InputDecoration(
                        hintText: 'Zielorder',
                      ),
                      onChanged: (value) => Static.sharedPreferences
                          .setString(Keys.rootDirLocal, value),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(left: 20),
                child: Row(
                  children: <Widget>[
                    Text('Für eine Anleitung oben auf das'),
                    Icon(
                      Icons.info,
                      color: Colors.blue,
                      size: 17,
                    ),
                    Text('klicken'),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  'Keine Dateien im Zielornder speicher, '
                  'die werden bei syncronisieren Überschrieben!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: columns,
                ),
              )
            ],
          ),
        );
      }),
    );
  }

  @override
  Subscription subscribeEvents(EventBus eventBus) =>
      eventBus.respond<Dir>((event) => setState(() => null));
}
