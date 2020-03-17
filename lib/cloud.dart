import 'package:nextcloud/nextcloud.dart';
import 'package:nextcloud_sync/keys.dart';
import 'package:nextcloud_sync/static.dart';

const possibleDirs = [
  'Eigene Dateien/Geteilte Dateien',
  'Eigene Dateien/Geteilte Dateien/vs-material/',
];

enum FileState {
  none,
  selected,
  watching,
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
      'Eigene Dateien/Geteilte Dateien/vs-material/${grade.toUpperCase()}',
      'Tausch/Klasse $grade',
    ];
  }

  Future load(int index) async =>
      allPossibleDirs[index] = await getSubDirs(getPaths()[index]);

  Future<List<Dir>> getSubDirs(String path, {int retryCount = 0}) async {
    print('Get sub dirs of $path ($retryCount)');
    final selection =
        Static.sharedPreferences.getStringList(Keys.selection) ?? [];
    final folders =
        Static.sharedPreferences.getStringList(Keys.folders + path) ?? [];
    List<Dir> directories = [];
    try {
      directories = (await client.webDav.ls(path))
          .where((f) => f.isDirectory)
          .map<Dir>((f) {
        final isNew = !folders.contains(f.path);
        return Dir(f, isNew);
      }).toList();
    } on RequestException {
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
