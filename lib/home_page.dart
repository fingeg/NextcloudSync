import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
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
  bool initialized = false;

  @override
  void afterFirstLayout(BuildContext context) async {
    Static.sharedPreferences = await SharedPreferences.getInstance();
    if (Static.sharedPreferences.getString(Keys.username) == null) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
    setState(() {
      initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      return Container();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Nextcloud Sync'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'bla bla',
            ),
          ],
        ),
      ),
    );
  }
}
