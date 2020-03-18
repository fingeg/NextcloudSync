import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:nextcloud_sync/keys.dart';
import 'package:nextcloud_sync/static.dart';

Future syncUsage() async {
  final username = Static.sharedPreferences.getString(Keys.username);
  final password = Static.sharedPreferences.getString(Keys.password);
  final dio = Dio()
    ..options = BaseOptions(
      headers: {
        'authorization':
            'Basic ${base64.encode(utf8.encode('$username:$password'))}',
      },
      responseType: ResponseType.plain,
      connectTimeout: 3000,
      receiveTimeout: 3000,
    );

  final data = {
    'device': {
      'firebaseId': '-',
      'appVersion': '-',
      'os': Platform.operatingSystem,
      'package': 'netcloud.sync',
    },
  };
  print('Send usage data: $data');
  await dio.post(
    'https://api.app.vs-ac.de/tags',
    data: data,
  );
}
