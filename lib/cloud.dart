import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_event_bus/flutter_event_bus.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:nextcloud_sync/keys.dart';
import 'package:nextcloud_sync/static.dart';

const possibleDirs = [
  'Eigene Dateien/Geteilte Dateien',
  'Eigene Dateien/Geteilte Dateien/vs-material/',
];

enum FileState {
  none,
  watching,
  selected,
}

class Dir extends WebDavFile {
  Dir(WebDavFile file, this.isNew)
      : super(
          file.path,
          file.mimeType,
          file.size,
          file.lastModified,
        ) {
    state = _state;
  }

  FileState state;
  final bool isNew;
  List<String> changedFiles = [];
  bool get isChanged => changedFiles.length > 0;
  bool isLoading = false;
  String failMsg;
  bool get failedDownload => failMsg != null;

  FileState get _state => FileState
      .values[Static.sharedPreferences.getInt(Keys.selection + path) ?? 0];

  set _state(FileState state) =>
      Static.sharedPreferences.setInt(Keys.selection + path, state.index);

  void toggleSelection() {
    state = FileState.values[(state.index + 1) % FileState.values.length];
    _state = state;
  }
}

class Cloud {
  List<List<Dir>> allPossibleDirs = [null, null, null];
  List<bool> _isLoading = [false, false, false];
  bool get isLoading =>
      _isLoading.reduce((value, element) => value || element) ||
      allPossibleDirs
          .expand((element) => element)
          .map((e) => e.isLoading)
          .reduce((v1, v2) => v1 || v2);

  NextCloudClient client;
  void init() {
    final username = Static.sharedPreferences.getString(Keys.username);
    final password = Static.sharedPreferences.getString(Keys.password);
    client = NextCloudClient(
      'nextcloud.aachen-vsa.logoip.de',
      username,
      password,
    );
  }

  List<String> getPaths() {
    final grade = Static.sharedPreferences.getString(Keys.grade);
    return [
      'Eigene Dateien/Geteilte Dateien',
      'Eigene Dateien/Geteilte Dateien/vs-material/${int.tryParse(grade[0]) == null ? grade.toUpperCase() : grade.toLowerCase()}',
      'Tausch/Klasse $grade',
    ];
  }

  Future load(int index, EventBus eventBus) async {
    if (_isLoading[index]) {
      return;
    }
    print('Load: $index');
    _isLoading[index] = true;
    final dirs = await getSubDirs(getPaths()[index]);
    allPossibleDirs[index] =
        dirs.where((d) => !d.name.startsWith('vs-')).toList();
    _isLoading[index] = false;
    eventBus.publish(index);
  }

  Future<List<int>> loadZip(String path, {int count = 0}) async {
    if (count >= 3) {
      return null;
    }
    try {
      return await client.webDav.downloadDirectoryAsZip(path);
    } catch (e) {
      print('Failed to download zip: $path ($count)\n$e');
      return await loadZip(path, count: ++count);
    }
  }

  String _trimPath(String path) {
    path = path.replaceAll('\\', '/').replaceAll(RegExp(r'\\/+'), '/');
    if (path.split('').last != '/') {
      path += '/';
    }
    return path;
  }

  Future loadDir(Dir directory, bool asFile, EventBus eventBus) async {
    if (directory.isLoading) {
      return;
    }
    directory.isLoading = true;
    eventBus.publish(directory);

    final dir = await loadZip(directory.path);
    if (dir == null) {
      print('Failed to download: ${directory.name}');
      directory.isLoading = false;
      directory.failMsg = "Fehler auf der Cloud";
      eventBus.publish(directory);
      return;
    }
    print('downloaded: ${directory.name}');

    String path =
        _trimPath(Static.sharedPreferences.getString(Keys.rootDirLocal));

    final archive = ZipDecoder().decodeBytes(dir);

    try {
      if (asFile && Directory('$path${directory.name}').existsSync()) {
        Directory('$path${directory.name}').deleteSync(recursive: true);
      }
    } catch (e) {
      print('Failed to delete: $e');
      directory.failMsg =
          'Kann den Ordner nicht löschen. Schließe bitte alle Programme'
          ' in dem der Ordner verwendet wird';
      directory.isLoading = false;
      eventBus.publish(dir);
      return;
    }

    final key = Keys.summary + directory.path;
    final isFirstTime = Static.sharedPreferences.getString(key) == null;
    final last = json.decode(Static.sharedPreferences.getString(key) ?? '{}');
    Map<String, String> summary = {};
    List<String> changed = [];
    String failMsg;

    // Extract the contents of the Zip archive to disk.
    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;

        // Check if the file changed or is new
        summary[filename] = sha256.convert(data).toString();
        if (!isFirstTime &&
            (!last.keys.contains(filename) ||
                last[filename] != summary[filename])) {
          changed.add(filename);
        }

        if (asFile) {
          try {
            File(path + filename)
              ..createSync(recursive: true)
              ..writeAsBytesSync(data);
          } catch (e) {
            print('Failed to store file: $e');
            failMsg = 'Fehler beim erstellen der Datei $filename';
          }
        }
      } else if (asFile) {
        try {
          Directory(path + filename)..create(recursive: true);
        } catch (e) {
          print('Failed to store file: $e');
          failMsg = 'Fehler beim erstellen des Ordners $filename';
        }
      }
    }

    Static.sharedPreferences.setString(key, json.encode(summary));

    directory.changedFiles = changed;
    directory.isLoading = false;
    directory.failMsg = failMsg;
    eventBus.publish(directory);
  }

  Future<List<Dir>> getSubDirs(String path, {int retryCount = 0}) async {
    print('Get sub dirs of $path ($retryCount)');
    final folders = Static.sharedPreferences.getStringList(Keys.folders + path);
    List<Dir> directories = [];
    try {
      directories = (await client.webDav.ls(path))
          .where((f) => f.isDirectory)
          .map<Dir>((f) {
        final isNew = folders != null && !folders.contains(f.path);
        return Dir(f, isNew);
      }).toList();
    } catch (e) {
      print('Failed to get sub dirs: $e');
      if (retryCount < 5) {
        directories = await getSubDirs(path, retryCount: ++retryCount);
      }
    }
    Static.sharedPreferences.setStringList(
        Keys.folders + path, directories.map((e) => e.path).toList());
    directories = directories
      ..sort((d1, d2) => (d1.isNew ? 0 : 1).compareTo(d2.isNew ? 0 : 1))
      ..sort((d1, d2) => d2.state.index.compareTo(d1.state.index));
    return directories ?? [];
  }
}
