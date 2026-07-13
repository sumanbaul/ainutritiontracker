import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  TextColumn get userId => text()();
  TextColumn get payloadJson => text()();
  TextColumn get idempotencyKey => text()();
  TextColumn get dependencyGroup => text()();
  TextColumn get status => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  TextColumn get serverVersion => text().nullable()();
  TextColumn get lastError => text().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [AppSettings, SyncQueues])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase(super.executor);
  LocalDatabase.inMemory() : super(NativeDatabase.memory());
  @override
  int get schemaVersion => 2;
  @override
  MigrationStrategy get migration => MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        if (from < 2) await m.deleteTable('sync_queues');
        if (from < 2) await m.createTable(syncQueues);
      });
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
          required String userId,
          required String payloadJson,
          required String idempotencyKey,
          String? dependencyGroup}) =>
      into(syncQueues).insert(SyncQueuesCompanion.insert(
          id: id,
          operationType: operationType,
          entityType: entityType,
          entityId: entityId,
          userId: userId,
          payloadJson: payloadJson,
          idempotencyKey: idempotencyKey,
          dependencyGroup: dependencyGroup ?? '$entityType:$entityId',
          status: 'Pending',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc()));
  Future<List<SyncQueue>> pendingSync(String userId) => (select(syncQueues)
        ..where((row) =>
            row.userId.equals(userId) & row.status.isIn(['Pending', 'Failed']))
        ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
      .get();
  Future<void> markSyncSucceeded(String id) =>
      (update(syncQueues)..where((row) => row.id.equals(id))).write(
          SyncQueuesCompanion(
              status: const Value('Succeeded'),
              updatedAt: Value(DateTime.now().toUtc())));
  Future<void> markSyncFailed(String id, String message) =>
      (update(syncQueues)..where((row) => row.id.equals(id))).write(
          SyncQueuesCompanion(
              status: const Value('Failed'),
              lastError: Value(message),
              updatedAt: Value(DateTime.now().toUtc())));
  Future<void> updateSyncStatus(String id, String status,
          {String? error, DateTime? nextRetryAt, int? retryCount}) =>
      (update(syncQueues)..where((row) => row.id.equals(id))).write(
          SyncQueuesCompanion(
              status: Value(status),
              lastError: Value(error),
              nextRetryAt: Value(nextRetryAt),
              retryCount:
                  retryCount == null ? const Value.absent() : Value(retryCount),
              updatedAt: Value(DateTime.now().toUtc())));
  Future<void> clearUserData(String userId) =>
      (delete(syncQueues)..where((row) => row.userId.equals(userId))).go();
  Future<void> recoverInterrupted(String userId) => (update(syncQueues)
        ..where((row) =>
            row.userId.equals(userId) & row.status.equals('Processing')))
      .write(SyncQueuesCompanion(
          status: const Value('Pending'),
          updatedAt: Value(DateTime.now().toUtc())));
  Future<void> cancelSync(String id, String userId) => (update(syncQueues)
        ..where((row) => row.id.equals(id) & row.userId.equals(userId)))
      .write(SyncQueuesCompanion(
          status: const Value('Cancelled'),
          updatedAt: Value(DateTime.now().toUtc())));
}

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final database = LocalDatabase(openLocalDatabase());
  ref.onDispose(database.close);
  return database;
});

LazyDatabase openLocalDatabase() => LazyDatabase(() async {
      final directory = await getApplicationDocumentsDirectory();
      return NativeDatabase(File(p.join(directory.path, 'nutrilens.sqlite')));
    });
