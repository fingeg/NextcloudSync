import 'package:flutter/material.dart';
import 'package:nextcloud_sync/home_page.dart';
import 'package:nextcloud_sync/login_page.dart';
import 'package:nextcloud_sync/static.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nextcloud Sync',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      routes: {
        '/': (context) => HomePage(),
        '/login': (context) => LoginPageWrapper(),
      },
    );
  }
}
