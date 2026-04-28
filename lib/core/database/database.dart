import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'database.g.dart';

/// 收藏直播间表
class FavoriteRooms extends Table {
  TextColumn get platform => text()();
  TextColumn get roomId => text()();
  TextColumn get title => text()();
  TextColumn get cover => text()();
  TextColumn get userName => text()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {platform, roomId};
}

/// 观看历史表
class WatchHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get platform => text()();
  TextColumn get roomId => text()();
  TextColumn get title => text()();
  TextColumn get cover => text()();
  TextColumn get userName => text()();
  DateTimeColumn get watchedAt => dateTime()();
}

@DriftDatabase(tables: [FavoriteRooms, WatchHistory])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'onelive.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});
