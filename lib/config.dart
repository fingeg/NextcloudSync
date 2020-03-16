import 'dart:io';

class Config {
  Config({
    this.username,
    this.password,
    this.localBaseDir,
    this.cloudSyncBaseDir,
    this.syncDirs,
    this.watchDir,
  });

  factory Config.fromJson(Map<String, dynamic> json) {
    final baseDir = Directory(json['localBaseDir']);
    return Config(
      username: json['username'],
      password: json['password'],
      localBaseDir: baseDir,
      cloudSyncBaseDir: json['cloudSyncBaseDir'],
      syncDirs: json['sync'].map<Directory, String>(
        (local, remote) => MapEntry(
          Directory(baseDir.path + local),
          remote.toString(),
        ),
      ),
      watchDir: json['watch'].cast<String>(),
    );
  }

  final String username;
  final String password;
  final Directory localBaseDir;
  final String cloudSyncBaseDir;
  final Map<Directory, String> syncDirs;
  final List<String> watchDir;
}
