import 'package:flutter/material.dart';
import 'package:flutter_event_bus/flutter_event_bus.dart';
import 'package:nextcloud_sync/views/home_page.dart';
import 'package:nextcloud_sync/views/login_page.dart';

Future main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EventBusWidget(
      child: MaterialApp(
        title: 'Nextcloud Sync',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Roboto',
        ),
        routes: {
          '/': (context) => HomePage(),
          '/login': (context) => LoginPageWrapper(),
        },
      ),
    );
  }
}
