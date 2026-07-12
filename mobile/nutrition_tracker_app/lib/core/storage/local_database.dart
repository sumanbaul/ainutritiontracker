import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'local_database.g.dart';

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {key};
}

class SyncQueues extends Table {
  TextColumn get id => text()();
  TextColumn get operationType => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get payloadJson => text()();
  TextColumn get status => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get lastError => text().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [AppSettings, SyncQueues])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase(super.executor);
  LocalDatabase.inMemory() : super(NativeDatabase.memory());
  @override
  int get schemaVersion => 1;
  @override
  MigrationStrategy get migration => MigrationStrategy(
      onCreate: (m) => m.createAll(), onUpgrade: (m, from, to) async {});
  Future<void> saveSetting(String key, String value) =>
      into(appSettings).insertOnConflictUpdate(AppSettingsCompanion.insert(
          key: key, value: value, updatedAt: DateTime.now().toUtc()));
  Future<String?> readSetting(String key) async =>
      (await (select(appSettings)..where((row) => row.key.equals(key)))
              .getSingleOrNull())
          ?.value;
  Future<void> enqueueSync(
          {required String id,
          required String operationType,
          required String entityType,
          required String entityId,
          required String payloadJson}) =>
      into(syncQueues).insert(SyncQueuesCompanion.insert(
          id: id,
          operationType: operationType,
          entityType: entityType,
          entityId: entityId,
          payloadJson: payloadJson,
          status: 'pending',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc()));
}

LazyDatabase openLocalDatabase() => LazyDatabase(() async {
      final directory = await getApplicationDocumentsDirectory();
      return NativeDatabase(File(p.join(directory.path, 'nutrilens.sqlite')));
    });
