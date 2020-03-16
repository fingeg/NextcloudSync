import 'dart:convert';
import 'dart:io';

import 'package:nextcloud/nextcloud.dart';
import 'package:nextcloud_sync/config.dart';

void main() {
  final parsed = json.decode(File('config.json').readAsStringSync());
  final config = Config.fromJson(parsed);
}
