import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_event_bus/flutter_event_bus.dart';
import 'package:nextcloud_sync/cloud.dart';
import 'package:nextcloud_sync/keys.dart';
import 'package:nextcloud_sync/static.dart';
import 'package:nextcloud_sync/usersync.dart';
import 'package:nextcloud_sync/views/directoryColumn.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'info.dart';

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
      info(context);
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
      cloud.load(i, EventBus.of(context)).then((_) {
        setState(() => null);
        sync(i);
      });
    }
    syncUsage();
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
                    DirectoryColumn(
                      index: index,
                      cloud: cloud,
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
            onPressed: () => info(context),
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
                        hintText: 'Zielordner',
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
                  'Keine Dateien im Zielordner speichern, '
                  'da diese bei Synchronisierungen überschrieben werden!',
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
