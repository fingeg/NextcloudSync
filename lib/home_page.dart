import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:folder_picker/folder_picker.dart';
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

class _HomePageState extends State<HomePage> with AfterLayoutMixin<HomePage> {
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
  }

  void update({isInit = false}) {
    if (!isInit) {
      setState(() {
        cloud.allPossibleDirs = [null, null, null];
      });
    }
    cloud.load(0).then((_) => setState(() => null));
    cloud.load(1).then((_) => setState(() => null));
    cloud.load(2).then((_) => setState(() => null));
  }

  void sync() {}

  void info() => showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Anleitung'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                      'Die drei Listen sind die möglichen Orte an denen Aufgaben zu finden sein können. '
                      'Damit Ordner in den angegebenen Zielordner herunter geladen werden einfach auf die gewüschten '
                      'Ordner klicken. '
                      'Ein erneuter klick sorgt dafür, dass der Ordner nicht heruntergeladen wird, aber dir trotztdem '
                      'angezeigt wird ob sich dessen Inhalt verändert hat.'),
                  Container(height: 20),
                  Text(
                      'Wenn ein Ordner neu erschienen ist, siehst du rechts neben dem Ordner eine \'+1\' und oben in der '
                      'Überschrift die Anzahl der neuen Ordner.'),
                  Container(height: 20),
                  Text(
                      'Wenn du auf einen der Ordner klickst, wird der nach ein paar sekunden automatisch herunter '
                      'geladen. Ein aktuell laufender Ladeprozess kann immer an einer Prozenanzeige und einem Ladeindikator '
                      'in einer Spaltenünberschrift gesehen werden.'),
                  Container(height: 20),
                  Text(
                      'Um nach einer Zeit die Ordner neu zu laden und damit auch die ausgewählten Ordner'
                      ' herunterzuladen gibt es oben den download Button'),
                  Container(height: 20),
                  Text(
                      'Bei Fragen und Fehlern einfach an cloud-sync@fingeg.de wenden')
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
                              if (dir.isNew)
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
                                  onPressed: () => setState(() {
                                    dir.toggleSelection();
                                  }),
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
                child: Text('Für eine Anleitung oben auf das i klicken'),
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
}
