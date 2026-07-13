// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const AppSetting(
      {required this.key, required this.value, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSetting copyWith({String? key, String? value, DateTime? updatedAt}) =>
      AppSetting(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value),
        updatedAt = Value(updatedAt);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<String>? key,
      Value<String>? value,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueuesTable extends SyncQueues
    with TableInfo<$SyncQueuesTable, SyncQueue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationTypeMeta =
      const VerificationMeta('operationType');
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
      'operation_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _idempotencyKeyMeta =
      const VerificationMeta('idempotencyKey');
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
      'idempotency_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dependencyGroupMeta =
      const VerificationMeta('dependencyGroup');
  @override
  late final GeneratedColumn<String> dependencyGroup = GeneratedColumn<String>(
      'dependency_group', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _nextRetryAtMeta =
      const VerificationMeta('nextRetryAt');
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
      'next_retry_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _serverVersionMeta =
      const VerificationMeta('serverVersion');
  @override
  late final GeneratedColumn<String> serverVersion = GeneratedColumn<String>(
      'server_version', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        operationType,
        entityType,
        entityId,
        userId,
        payloadJson,
        idempotencyKey,
        dependencyGroup,
        status,
        retryCount,
        createdAt,
        updatedAt,
        nextRetryAt,
        serverVersion,
        lastError
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queues';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueue> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
          _operationTypeMeta,
          operationType.isAcceptableOrUnknown(
              data['operation_type']!, _operationTypeMeta));
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
          _idempotencyKeyMeta,
          idempotencyKey.isAcceptableOrUnknown(
              data['idempotency_key']!, _idempotencyKeyMeta));
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('dependency_group')) {
      context.handle(
          _dependencyGroupMeta,
          dependencyGroup.isAcceptableOrUnknown(
              data['dependency_group']!, _dependencyGroupMeta));
    } else if (isInserting) {
      context.missing(_dependencyGroupMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
          _nextRetryAtMeta,
          nextRetryAt.isAcceptableOrUnknown(
              data['next_retry_at']!, _nextRetryAtMeta));
    }
    if (data.containsKey('server_version')) {
      context.handle(
          _serverVersionMeta,
          serverVersion.isAcceptableOrUnknown(
              data['server_version']!, _serverVersionMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueue(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      operationType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation_type'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      idempotencyKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}idempotency_key'])!,
      dependencyGroup: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}dependency_group'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      nextRetryAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}next_retry_at']),
      serverVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_version']),
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
    );
  }

  @override
  $SyncQueuesTable createAlias(String alias) {
    return $SyncQueuesTable(attachedDatabase, alias);
  }
}

class SyncQueue extends DataClass implements Insertable<SyncQueue> {
  final String id;
  final String operationType;
  final String entityType;
  final String entityId;
  final String userId;
  final String payloadJson;
  final String idempotencyKey;
  final String dependencyGroup;
  final String status;
  final int retryCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? nextRetryAt;
  final String? serverVersion;
  final String? lastError;
  const SyncQueue(
      {required this.id,
      required this.operationType,
      required this.entityType,
      required this.entityId,
      required this.userId,
      required this.payloadJson,
      required this.idempotencyKey,
      required this.dependencyGroup,
      required this.status,
      required this.retryCount,
      required this.createdAt,
      required this.updatedAt,
      this.nextRetryAt,
      this.serverVersion,
      this.lastError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['operation_type'] = Variable<String>(operationType);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['user_id'] = Variable<String>(userId);
    map['payload_json'] = Variable<String>(payloadJson);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['dependency_group'] = Variable<String>(dependencyGroup);
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<String>(serverVersion);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncQueuesCompanion toCompanion(bool nullToAbsent) {
    return SyncQueuesCompanion(
      id: Value(id),
      operationType: Value(operationType),
      entityType: Value(entityType),
      entityId: Value(entityId),
      userId: Value(userId),
      payloadJson: Value(payloadJson),
      idempotencyKey: Value(idempotencyKey),
      dependencyGroup: Value(dependencyGroup),
      status: Value(status),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncQueue.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueue(
      id: serializer.fromJson<String>(json['id']),
      operationType: serializer.fromJson<String>(json['operationType']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      userId: serializer.fromJson<String>(json['userId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      dependencyGroup: serializer.fromJson<String>(json['dependencyGroup']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
      serverVersion: serializer.fromJson<String?>(json['serverVersion']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'operationType': serializer.toJson<String>(operationType),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'userId': serializer.toJson<String>(userId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'dependencyGroup': serializer.toJson<String>(dependencyGroup),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
      'serverVersion': serializer.toJson<String?>(serverVersion),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncQueue copyWith(
          {String? id,
          String? operationType,
          String? entityType,
          String? entityId,
          String? userId,
          String? payloadJson,
          String? idempotencyKey,
          String? dependencyGroup,
          String? status,
          int? retryCount,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> nextRetryAt = const Value.absent(),
          Value<String?> serverVersion = const Value.absent(),
          Value<String?> lastError = const Value.absent()}) =>
      SyncQueue(
        id: id ?? this.id,
        operationType: operationType ?? this.operationType,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        userId: userId ?? this.userId,
        payloadJson: payloadJson ?? this.payloadJson,
        idempotencyKey: idempotencyKey ?? this.idempotencyKey,
        dependencyGroup: dependencyGroup ?? this.dependencyGroup,
        status: status ?? this.status,
        retryCount: retryCount ?? this.retryCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
        serverVersion:
            serverVersion.present ? serverVersion.value : this.serverVersion,
        lastError: lastError.present ? lastError.value : this.lastError,
      );
  SyncQueue copyWithCompanion(SyncQueuesCompanion data) {
    return SyncQueue(
      id: data.id.present ? data.id.value : this.id,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      userId: data.userId.present ? data.userId.value : this.userId,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      dependencyGroup: data.dependencyGroup.present
          ? data.dependencyGroup.value
          : this.dependencyGroup,
      status: data.status.present ? data.status.value : this.status,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      nextRetryAt:
          data.nextRetryAt.present ? data.nextRetryAt.value : this.nextRetryAt,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueue(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('userId: $userId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('dependencyGroup: $dependencyGroup, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      operationType,
      entityType,
      entityId,
      userId,
      payloadJson,
      idempotencyKey,
      dependencyGroup,
      status,
      retryCount,
      createdAt,
      updatedAt,
      nextRetryAt,
      serverVersion,
      lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueue &&
          other.id == this.id &&
          other.operationType == this.operationType &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.userId == this.userId &&
          other.payloadJson == this.payloadJson &&
          other.idempotencyKey == this.idempotencyKey &&
          other.dependencyGroup == this.dependencyGroup &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.nextRetryAt == this.nextRetryAt &&
          other.serverVersion == this.serverVersion &&
          other.lastError == this.lastError);
}

class SyncQueuesCompanion extends UpdateCompanion<SyncQueue> {
  final Value<String> id;
  final Value<String> operationType;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> userId;
  final Value<String> payloadJson;
  final Value<String> idempotencyKey;
  final Value<String> dependencyGroup;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> nextRetryAt;
  final Value<String?> serverVersion;
  final Value<String?> lastError;
  final Value<int> rowid;
  const SyncQueuesCompanion({
    this.id = const Value.absent(),
    this.operationType = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.userId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.dependencyGroup = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueuesCompanion.insert({
    required String id,
    required String operationType,
    required String entityType,
    required String entityId,
    required String userId,
    required String payloadJson,
    required String idempotencyKey,
    required String dependencyGroup,
    required String status,
    this.retryCount = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.nextRetryAt = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        operationType = Value(operationType),
        entityType = Value(entityType),
        entityId = Value(entityId),
        userId = Value(userId),
        payloadJson = Value(payloadJson),
        idempotencyKey = Value(idempotencyKey),
        dependencyGroup = Value(dependencyGroup),
        status = Value(status),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<SyncQueue> custom({
    Expression<String>? id,
    Expression<String>? operationType,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? userId,
    Expression<String>? payloadJson,
    Expression<String>? idempotencyKey,
    Expression<String>? dependencyGroup,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? nextRetryAt,
    Expression<String>? serverVersion,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operationType != null) 'operation_type': operationType,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (userId != null) 'user_id': userId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (dependencyGroup != null) 'dependency_group': dependencyGroup,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (serverVersion != null) 'server_version': serverVersion,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueuesCompanion copyWith(
      {Value<String>? id,
      Value<String>? operationType,
      Value<String>? entityType,
      Value<String>? entityId,
      Value<String>? userId,
      Value<String>? payloadJson,
      Value<String>? idempotencyKey,
      Value<String>? dependencyGroup,
      Value<String>? status,
      Value<int>? retryCount,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? nextRetryAt,
      Value<String?>? serverVersion,
      Value<String?>? lastError,
      Value<int>? rowid}) {
    return SyncQueuesCompanion(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      userId: userId ?? this.userId,
      payloadJson: payloadJson ?? this.payloadJson,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      dependencyGroup: dependencyGroup ?? this.dependencyGroup,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      serverVersion: serverVersion ?? this.serverVersion,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (dependencyGroup.present) {
      map['dependency_group'] = Variable<String>(dependencyGroup.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<String>(serverVersion.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueuesCompanion(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('userId: $userId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('dependencyGroup: $dependencyGroup, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalUsersTable extends LocalUsers
    with TableInfo<$LocalUsersTable, LocalUser> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalUsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastAuthenticatedAtMeta =
      const VerificationMeta('lastAuthenticatedAt');
  @override
  late final GeneratedColumn<DateTime> lastAuthenticatedAt =
      GeneratedColumn<DateTime>('last_authenticated_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastServerSyncAtMeta =
      const VerificationMeta('lastServerSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastServerSyncAt =
      GeneratedColumn<DateTime>('last_server_sync_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _sessionStateMeta =
      const VerificationMeta('sessionState');
  @override
  late final GeneratedColumn<String> sessionState = GeneratedColumn<String>(
      'session_state', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('LocallyAuthenticated'));
  @override
  List<GeneratedColumn> get $columns => [
        userId,
        displayName,
        lastAuthenticatedAt,
        lastServerSyncAt,
        sessionState
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_users';
  @override
  VerificationContext validateIntegrity(Insertable<LocalUser> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    }
    if (data.containsKey('last_authenticated_at')) {
      context.handle(
          _lastAuthenticatedAtMeta,
          lastAuthenticatedAt.isAcceptableOrUnknown(
              data['last_authenticated_at']!, _lastAuthenticatedAtMeta));
    } else if (isInserting) {
      context.missing(_lastAuthenticatedAtMeta);
    }
    if (data.containsKey('last_server_sync_at')) {
      context.handle(
          _lastServerSyncAtMeta,
          lastServerSyncAt.isAcceptableOrUnknown(
              data['last_server_sync_at']!, _lastServerSyncAtMeta));
    }
    if (data.containsKey('session_state')) {
      context.handle(
          _sessionStateMeta,
          sessionState.isAcceptableOrUnknown(
              data['session_state']!, _sessionStateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  LocalUser map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalUser(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name']),
      lastAuthenticatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}last_authenticated_at'])!,
      lastServerSyncAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_server_sync_at']),
      sessionState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_state'])!,
    );
  }

  @override
  $LocalUsersTable createAlias(String alias) {
    return $LocalUsersTable(attachedDatabase, alias);
  }
}

class LocalUser extends DataClass implements Insertable<LocalUser> {
  final String userId;
  final String? displayName;
  final DateTime lastAuthenticatedAt;
  final DateTime? lastServerSyncAt;
  final String sessionState;
  const LocalUser(
      {required this.userId,
      this.displayName,
      required this.lastAuthenticatedAt,
      this.lastServerSyncAt,
      required this.sessionState});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    map['last_authenticated_at'] = Variable<DateTime>(lastAuthenticatedAt);
    if (!nullToAbsent || lastServerSyncAt != null) {
      map['last_server_sync_at'] = Variable<DateTime>(lastServerSyncAt);
    }
    map['session_state'] = Variable<String>(sessionState);
    return map;
  }

  LocalUsersCompanion toCompanion(bool nullToAbsent) {
    return LocalUsersCompanion(
      userId: Value(userId),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      lastAuthenticatedAt: Value(lastAuthenticatedAt),
      lastServerSyncAt: lastServerSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastServerSyncAt),
      sessionState: Value(sessionState),
    );
  }

  factory LocalUser.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalUser(
      userId: serializer.fromJson<String>(json['userId']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      lastAuthenticatedAt:
          serializer.fromJson<DateTime>(json['lastAuthenticatedAt']),
      lastServerSyncAt:
          serializer.fromJson<DateTime?>(json['lastServerSyncAt']),
      sessionState: serializer.fromJson<String>(json['sessionState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'displayName': serializer.toJson<String?>(displayName),
      'lastAuthenticatedAt': serializer.toJson<DateTime>(lastAuthenticatedAt),
      'lastServerSyncAt': serializer.toJson<DateTime?>(lastServerSyncAt),
      'sessionState': serializer.toJson<String>(sessionState),
    };
  }

  LocalUser copyWith(
          {String? userId,
          Value<String?> displayName = const Value.absent(),
          DateTime? lastAuthenticatedAt,
          Value<DateTime?> lastServerSyncAt = const Value.absent(),
          String? sessionState}) =>
      LocalUser(
        userId: userId ?? this.userId,
        displayName: displayName.present ? displayName.value : this.displayName,
        lastAuthenticatedAt: lastAuthenticatedAt ?? this.lastAuthenticatedAt,
        lastServerSyncAt: lastServerSyncAt.present
            ? lastServerSyncAt.value
            : this.lastServerSyncAt,
        sessionState: sessionState ?? this.sessionState,
      );
  LocalUser copyWithCompanion(LocalUsersCompanion data) {
    return LocalUser(
      userId: data.userId.present ? data.userId.value : this.userId,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      lastAuthenticatedAt: data.lastAuthenticatedAt.present
          ? data.lastAuthenticatedAt.value
          : this.lastAuthenticatedAt,
      lastServerSyncAt: data.lastServerSyncAt.present
          ? data.lastServerSyncAt.value
          : this.lastServerSyncAt,
      sessionState: data.sessionState.present
          ? data.sessionState.value
          : this.sessionState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalUser(')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName, ')
          ..write('lastAuthenticatedAt: $lastAuthenticatedAt, ')
          ..write('lastServerSyncAt: $lastServerSyncAt, ')
          ..write('sessionState: $sessionState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      userId, displayName, lastAuthenticatedAt, lastServerSyncAt, sessionState);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalUser &&
          other.userId == this.userId &&
          other.displayName == this.displayName &&
          other.lastAuthenticatedAt == this.lastAuthenticatedAt &&
          other.lastServerSyncAt == this.lastServerSyncAt &&
          other.sessionState == this.sessionState);
}

class LocalUsersCompanion extends UpdateCompanion<LocalUser> {
  final Value<String> userId;
  final Value<String?> displayName;
  final Value<DateTime> lastAuthenticatedAt;
  final Value<DateTime?> lastServerSyncAt;
  final Value<String> sessionState;
  final Value<int> rowid;
  const LocalUsersCompanion({
    this.userId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.lastAuthenticatedAt = const Value.absent(),
    this.lastServerSyncAt = const Value.absent(),
    this.sessionState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalUsersCompanion.insert({
    required String userId,
    this.displayName = const Value.absent(),
    required DateTime lastAuthenticatedAt,
    this.lastServerSyncAt = const Value.absent(),
    this.sessionState = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : userId = Value(userId),
        lastAuthenticatedAt = Value(lastAuthenticatedAt);
  static Insertable<LocalUser> custom({
    Expression<String>? userId,
    Expression<String>? displayName,
    Expression<DateTime>? lastAuthenticatedAt,
    Expression<DateTime>? lastServerSyncAt,
    Expression<String>? sessionState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (displayName != null) 'display_name': displayName,
      if (lastAuthenticatedAt != null)
        'last_authenticated_at': lastAuthenticatedAt,
      if (lastServerSyncAt != null) 'last_server_sync_at': lastServerSyncAt,
      if (sessionState != null) 'session_state': sessionState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalUsersCompanion copyWith(
      {Value<String>? userId,
      Value<String?>? displayName,
      Value<DateTime>? lastAuthenticatedAt,
      Value<DateTime?>? lastServerSyncAt,
      Value<String>? sessionState,
      Value<int>? rowid}) {
    return LocalUsersCompanion(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      lastAuthenticatedAt: lastAuthenticatedAt ?? this.lastAuthenticatedAt,
      lastServerSyncAt: lastServerSyncAt ?? this.lastServerSyncAt,
      sessionState: sessionState ?? this.sessionState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (lastAuthenticatedAt.present) {
      map['last_authenticated_at'] =
          Variable<DateTime>(lastAuthenticatedAt.value);
    }
    if (lastServerSyncAt.present) {
      map['last_server_sync_at'] = Variable<DateTime>(lastServerSyncAt.value);
    }
    if (sessionState.present) {
      map['session_state'] = Variable<String>(sessionState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalUsersCompanion(')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName, ')
          ..write('lastAuthenticatedAt: $lastAuthenticatedAt, ')
          ..write('lastServerSyncAt: $lastServerSyncAt, ')
          ..write('sessionState: $sessionState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalProfilesTable extends LocalProfiles
    with TableInfo<$LocalProfilesTable, LocalProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serverVersionMeta =
      const VerificationMeta('serverVersion');
  @override
  late final GeneratedColumn<String> serverVersion = GeneratedColumn<String>(
      'server_version', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _localUpdatedAtMeta =
      const VerificationMeta('localUpdatedAt');
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>('local_updated_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncStateMeta =
      const VerificationMeta('syncState');
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
      'sync_state', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Synced'));
  @override
  List<GeneratedColumn> get $columns => [
        userId,
        payloadJson,
        serverVersion,
        updatedAt,
        localUpdatedAt,
        syncState
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_profiles';
  @override
  VerificationContext validateIntegrity(Insertable<LocalProfile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('server_version')) {
      context.handle(
          _serverVersionMeta,
          serverVersion.isAcceptableOrUnknown(
              data['server_version']!, _serverVersionMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
          _localUpdatedAtMeta,
          localUpdatedAt.isAcceptableOrUnknown(
              data['local_updated_at']!, _localUpdatedAtMeta));
    } else if (isInserting) {
      context.missing(_localUpdatedAtMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(_syncStateMeta,
          syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  LocalProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProfile(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      serverVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_version']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      localUpdatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}local_updated_at'])!,
      syncState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_state'])!,
    );
  }

  @override
  $LocalProfilesTable createAlias(String alias) {
    return $LocalProfilesTable(attachedDatabase, alias);
  }
}

class LocalProfile extends DataClass implements Insertable<LocalProfile> {
  final String userId;
  final String payloadJson;
  final String? serverVersion;
  final DateTime updatedAt;
  final DateTime localUpdatedAt;
  final String syncState;
  const LocalProfile(
      {required this.userId,
      required this.payloadJson,
      this.serverVersion,
      required this.updatedAt,
      required this.localUpdatedAt,
      required this.syncState});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<String>(serverVersion);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    map['sync_state'] = Variable<String>(syncState);
    return map;
  }

  LocalProfilesCompanion toCompanion(bool nullToAbsent) {
    return LocalProfilesCompanion(
      userId: Value(userId),
      payloadJson: Value(payloadJson),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      updatedAt: Value(updatedAt),
      localUpdatedAt: Value(localUpdatedAt),
      syncState: Value(syncState),
    );
  }

  factory LocalProfile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProfile(
      userId: serializer.fromJson<String>(json['userId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      serverVersion: serializer.fromJson<String?>(json['serverVersion']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
      syncState: serializer.fromJson<String>(json['syncState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'serverVersion': serializer.toJson<String?>(serverVersion),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
      'syncState': serializer.toJson<String>(syncState),
    };
  }

  LocalProfile copyWith(
          {String? userId,
          String? payloadJson,
          Value<String?> serverVersion = const Value.absent(),
          DateTime? updatedAt,
          DateTime? localUpdatedAt,
          String? syncState}) =>
      LocalProfile(
        userId: userId ?? this.userId,
        payloadJson: payloadJson ?? this.payloadJson,
        serverVersion:
            serverVersion.present ? serverVersion.value : this.serverVersion,
        updatedAt: updatedAt ?? this.updatedAt,
        localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
        syncState: syncState ?? this.syncState,
      );
  LocalProfile copyWithCompanion(LocalProfilesCompanion data) {
    return LocalProfile(
      userId: data.userId.present ? data.userId.value : this.userId,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalProfile(')
          ..write('userId: $userId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      userId, payloadJson, serverVersion, updatedAt, localUpdatedAt, syncState);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProfile &&
          other.userId == this.userId &&
          other.payloadJson == this.payloadJson &&
          other.serverVersion == this.serverVersion &&
          other.updatedAt == this.updatedAt &&
          other.localUpdatedAt == this.localUpdatedAt &&
          other.syncState == this.syncState);
}

class LocalProfilesCompanion extends UpdateCompanion<LocalProfile> {
  final Value<String> userId;
  final Value<String> payloadJson;
  final Value<String?> serverVersion;
  final Value<DateTime> updatedAt;
  final Value<DateTime> localUpdatedAt;
  final Value<String> syncState;
  final Value<int> rowid;
  const LocalProfilesCompanion({
    this.userId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalProfilesCompanion.insert({
    required String userId,
    required String payloadJson,
    this.serverVersion = const Value.absent(),
    required DateTime updatedAt,
    required DateTime localUpdatedAt,
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : userId = Value(userId),
        payloadJson = Value(payloadJson),
        updatedAt = Value(updatedAt),
        localUpdatedAt = Value(localUpdatedAt);
  static Insertable<LocalProfile> custom({
    Expression<String>? userId,
    Expression<String>? payloadJson,
    Expression<String>? serverVersion,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? localUpdatedAt,
    Expression<String>? syncState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (serverVersion != null) 'server_version': serverVersion,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (syncState != null) 'sync_state': syncState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalProfilesCompanion copyWith(
      {Value<String>? userId,
      Value<String>? payloadJson,
      Value<String?>? serverVersion,
      Value<DateTime>? updatedAt,
      Value<DateTime>? localUpdatedAt,
      Value<String>? syncState,
      Value<int>? rowid}) {
    return LocalProfilesCompanion(
      userId: userId ?? this.userId,
      payloadJson: payloadJson ?? this.payloadJson,
      serverVersion: serverVersion ?? this.serverVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      syncState: syncState ?? this.syncState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<String>(serverVersion.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProfilesCompanion(')
          ..write('userId: $userId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalNutritionTargetsTable extends LocalNutritionTargets
    with TableInfo<$LocalNutritionTargetsTable, LocalNutritionTarget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalNutritionTargetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _effectiveDateMeta =
      const VerificationMeta('effectiveDate');
  @override
  late final GeneratedColumn<String> effectiveDate = GeneratedColumn<String>(
      'effective_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serverVersionMeta =
      const VerificationMeta('serverVersion');
  @override
  late final GeneratedColumn<String> serverVersion = GeneratedColumn<String>(
      'server_version', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [userId, effectiveDate, payloadJson, serverVersion, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_nutrition_targets';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalNutritionTarget> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('effective_date')) {
      context.handle(
          _effectiveDateMeta,
          effectiveDate.isAcceptableOrUnknown(
              data['effective_date']!, _effectiveDateMeta));
    } else if (isInserting) {
      context.missing(_effectiveDateMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('server_version')) {
      context.handle(
          _serverVersionMeta,
          serverVersion.isAcceptableOrUnknown(
              data['server_version']!, _serverVersionMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, effectiveDate};
  @override
  LocalNutritionTarget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalNutritionTarget(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      effectiveDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}effective_date'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      serverVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_version']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalNutritionTargetsTable createAlias(String alias) {
    return $LocalNutritionTargetsTable(attachedDatabase, alias);
  }
}

class LocalNutritionTarget extends DataClass
    implements Insertable<LocalNutritionTarget> {
  final String userId;
  final String effectiveDate;
  final String payloadJson;
  final String? serverVersion;
  final DateTime updatedAt;
  const LocalNutritionTarget(
      {required this.userId,
      required this.effectiveDate,
      required this.payloadJson,
      this.serverVersion,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['effective_date'] = Variable<String>(effectiveDate);
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<String>(serverVersion);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalNutritionTargetsCompanion toCompanion(bool nullToAbsent) {
    return LocalNutritionTargetsCompanion(
      userId: Value(userId),
      effectiveDate: Value(effectiveDate),
      payloadJson: Value(payloadJson),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalNutritionTarget.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalNutritionTarget(
      userId: serializer.fromJson<String>(json['userId']),
      effectiveDate: serializer.fromJson<String>(json['effectiveDate']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      serverVersion: serializer.fromJson<String?>(json['serverVersion']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'effectiveDate': serializer.toJson<String>(effectiveDate),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'serverVersion': serializer.toJson<String?>(serverVersion),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalNutritionTarget copyWith(
          {String? userId,
          String? effectiveDate,
          String? payloadJson,
          Value<String?> serverVersion = const Value.absent(),
          DateTime? updatedAt}) =>
      LocalNutritionTarget(
        userId: userId ?? this.userId,
        effectiveDate: effectiveDate ?? this.effectiveDate,
        payloadJson: payloadJson ?? this.payloadJson,
        serverVersion:
            serverVersion.present ? serverVersion.value : this.serverVersion,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalNutritionTarget copyWithCompanion(LocalNutritionTargetsCompanion data) {
    return LocalNutritionTarget(
      userId: data.userId.present ? data.userId.value : this.userId,
      effectiveDate: data.effectiveDate.present
          ? data.effectiveDate.value
          : this.effectiveDate,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalNutritionTarget(')
          ..write('userId: $userId, ')
          ..write('effectiveDate: $effectiveDate, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(userId, effectiveDate, payloadJson, serverVersion, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalNutritionTarget &&
          other.userId == this.userId &&
          other.effectiveDate == this.effectiveDate &&
          other.payloadJson == this.payloadJson &&
          other.serverVersion == this.serverVersion &&
          other.updatedAt == this.updatedAt);
}

class LocalNutritionTargetsCompanion
    extends UpdateCompanion<LocalNutritionTarget> {
  final Value<String> userId;
  final Value<String> effectiveDate;
  final Value<String> payloadJson;
  final Value<String?> serverVersion;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalNutritionTargetsCompanion({
    this.userId = const Value.absent(),
    this.effectiveDate = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalNutritionTargetsCompanion.insert({
    required String userId,
    required String effectiveDate,
    required String payloadJson,
    this.serverVersion = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : userId = Value(userId),
        effectiveDate = Value(effectiveDate),
        payloadJson = Value(payloadJson),
        updatedAt = Value(updatedAt);
  static Insertable<LocalNutritionTarget> custom({
    Expression<String>? userId,
    Expression<String>? effectiveDate,
    Expression<String>? payloadJson,
    Expression<String>? serverVersion,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (effectiveDate != null) 'effective_date': effectiveDate,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (serverVersion != null) 'server_version': serverVersion,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalNutritionTargetsCompanion copyWith(
      {Value<String>? userId,
      Value<String>? effectiveDate,
      Value<String>? payloadJson,
      Value<String?>? serverVersion,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocalNutritionTargetsCompanion(
      userId: userId ?? this.userId,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      payloadJson: payloadJson ?? this.payloadJson,
      serverVersion: serverVersion ?? this.serverVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (effectiveDate.present) {
      map['effective_date'] = Variable<String>(effectiveDate.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<String>(serverVersion.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalNutritionTargetsCompanion(')
          ..write('userId: $userId, ')
          ..write('effectiveDate: $effectiveDate, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalDailySummariesTable extends LocalDailySummaries
    with TableInfo<$LocalDailySummariesTable, LocalDailySummary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDailySummariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _summaryDateMeta =
      const VerificationMeta('summaryDate');
  @override
  late final GeneratedColumn<String> summaryDate = GeneratedColumn<String>(
      'summary_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncStateMeta =
      const VerificationMeta('syncState');
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
      'sync_state', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Synced'));
  @override
  List<GeneratedColumn> get $columns =>
      [userId, summaryDate, payloadJson, updatedAt, syncState];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_daily_summaries';
  @override
  VerificationContext validateIntegrity(Insertable<LocalDailySummary> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('summary_date')) {
      context.handle(
          _summaryDateMeta,
          summaryDate.isAcceptableOrUnknown(
              data['summary_date']!, _summaryDateMeta));
    } else if (isInserting) {
      context.missing(_summaryDateMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(_syncStateMeta,
          syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, summaryDate};
  @override
  LocalDailySummary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDailySummary(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      summaryDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}summary_date'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      syncState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_state'])!,
    );
  }

  @override
  $LocalDailySummariesTable createAlias(String alias) {
    return $LocalDailySummariesTable(attachedDatabase, alias);
  }
}

class LocalDailySummary extends DataClass
    implements Insertable<LocalDailySummary> {
  final String userId;
  final String summaryDate;
  final String payloadJson;
  final DateTime updatedAt;
  final String syncState;
  const LocalDailySummary(
      {required this.userId,
      required this.summaryDate,
      required this.payloadJson,
      required this.updatedAt,
      required this.syncState});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['summary_date'] = Variable<String>(summaryDate);
    map['payload_json'] = Variable<String>(payloadJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['sync_state'] = Variable<String>(syncState);
    return map;
  }

  LocalDailySummariesCompanion toCompanion(bool nullToAbsent) {
    return LocalDailySummariesCompanion(
      userId: Value(userId),
      summaryDate: Value(summaryDate),
      payloadJson: Value(payloadJson),
      updatedAt: Value(updatedAt),
      syncState: Value(syncState),
    );
  }

  factory LocalDailySummary.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDailySummary(
      userId: serializer.fromJson<String>(json['userId']),
      summaryDate: serializer.fromJson<String>(json['summaryDate']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncState: serializer.fromJson<String>(json['syncState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'summaryDate': serializer.toJson<String>(summaryDate),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncState': serializer.toJson<String>(syncState),
    };
  }

  LocalDailySummary copyWith(
          {String? userId,
          String? summaryDate,
          String? payloadJson,
          DateTime? updatedAt,
          String? syncState}) =>
      LocalDailySummary(
        userId: userId ?? this.userId,
        summaryDate: summaryDate ?? this.summaryDate,
        payloadJson: payloadJson ?? this.payloadJson,
        updatedAt: updatedAt ?? this.updatedAt,
        syncState: syncState ?? this.syncState,
      );
  LocalDailySummary copyWithCompanion(LocalDailySummariesCompanion data) {
    return LocalDailySummary(
      userId: data.userId.present ? data.userId.value : this.userId,
      summaryDate:
          data.summaryDate.present ? data.summaryDate.value : this.summaryDate,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDailySummary(')
          ..write('userId: $userId, ')
          ..write('summaryDate: $summaryDate, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(userId, summaryDate, payloadJson, updatedAt, syncState);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDailySummary &&
          other.userId == this.userId &&
          other.summaryDate == this.summaryDate &&
          other.payloadJson == this.payloadJson &&
          other.updatedAt == this.updatedAt &&
          other.syncState == this.syncState);
}

class LocalDailySummariesCompanion extends UpdateCompanion<LocalDailySummary> {
  final Value<String> userId;
  final Value<String> summaryDate;
  final Value<String> payloadJson;
  final Value<DateTime> updatedAt;
  final Value<String> syncState;
  final Value<int> rowid;
  const LocalDailySummariesCompanion({
    this.userId = const Value.absent(),
    this.summaryDate = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDailySummariesCompanion.insert({
    required String userId,
    required String summaryDate,
    required String payloadJson,
    required DateTime updatedAt,
    this.syncState = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : userId = Value(userId),
        summaryDate = Value(summaryDate),
        payloadJson = Value(payloadJson),
        updatedAt = Value(updatedAt);
  static Insertable<LocalDailySummary> custom({
    Expression<String>? userId,
    Expression<String>? summaryDate,
    Expression<String>? payloadJson,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (summaryDate != null) 'summary_date': summaryDate,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncState != null) 'sync_state': syncState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDailySummariesCompanion copyWith(
      {Value<String>? userId,
      Value<String>? summaryDate,
      Value<String>? payloadJson,
      Value<DateTime>? updatedAt,
      Value<String>? syncState,
      Value<int>? rowid}) {
    return LocalDailySummariesCompanion(
      userId: userId ?? this.userId,
      summaryDate: summaryDate ?? this.summaryDate,
      payloadJson: payloadJson ?? this.payloadJson,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (summaryDate.present) {
      map['summary_date'] = Variable<String>(summaryDate.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDailySummariesCompanion(')
          ..write('userId: $userId, ')
          ..write('summaryDate: $summaryDate, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMealsTable extends LocalMeals
    with TableInfo<$LocalMealsTable, LocalMeal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMealsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
      'local_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serverIdMeta =
      const VerificationMeta('serverId');
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
      'server_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _consumedAtMeta =
      const VerificationMeta('consumedAt');
  @override
  late final GeneratedColumn<DateTime> consumedAt = GeneratedColumn<DateTime>(
      'consumed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncStateMeta =
      const VerificationMeta('syncState');
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
      'sync_state', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Synced'));
  static const VerificationMeta _deletedLocallyMeta =
      const VerificationMeta('deletedLocally');
  @override
  late final GeneratedColumn<bool> deletedLocally = GeneratedColumn<bool>(
      'deleted_locally', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("deleted_locally" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        serverId,
        userId,
        payloadJson,
        consumedAt,
        syncState,
        deletedLocally,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_meals';
  @override
  VerificationContext validateIntegrity(Insertable<LocalMeal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(_serverIdMeta,
          serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('consumed_at')) {
      context.handle(
          _consumedAtMeta,
          consumedAt.isAcceptableOrUnknown(
              data['consumed_at']!, _consumedAtMeta));
    } else if (isInserting) {
      context.missing(_consumedAtMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(_syncStateMeta,
          syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta));
    }
    if (data.containsKey('deleted_locally')) {
      context.handle(
          _deletedLocallyMeta,
          deletedLocally.isAcceptableOrUnknown(
              data['deleted_locally']!, _deletedLocallyMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  LocalMeal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMeal(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_id'])!,
      serverId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}server_id']),
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      consumedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}consumed_at'])!,
      syncState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_state'])!,
      deletedLocally: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted_locally'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LocalMealsTable createAlias(String alias) {
    return $LocalMealsTable(attachedDatabase, alias);
  }
}

class LocalMeal extends DataClass implements Insertable<LocalMeal> {
  final String localId;
  final String? serverId;
  final String userId;
  final String payloadJson;
  final DateTime consumedAt;
  final String syncState;
  final bool deletedLocally;
  final DateTime updatedAt;
  const LocalMeal(
      {required this.localId,
      this.serverId,
      required this.userId,
      required this.payloadJson,
      required this.consumedAt,
      required this.syncState,
      required this.deletedLocally,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['user_id'] = Variable<String>(userId);
    map['payload_json'] = Variable<String>(payloadJson);
    map['consumed_at'] = Variable<DateTime>(consumedAt);
    map['sync_state'] = Variable<String>(syncState);
    map['deleted_locally'] = Variable<bool>(deletedLocally);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalMealsCompanion toCompanion(bool nullToAbsent) {
    return LocalMealsCompanion(
      localId: Value(localId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      userId: Value(userId),
      payloadJson: Value(payloadJson),
      consumedAt: Value(consumedAt),
      syncState: Value(syncState),
      deletedLocally: Value(deletedLocally),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalMeal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMeal(
      localId: serializer.fromJson<String>(json['localId']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      userId: serializer.fromJson<String>(json['userId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      consumedAt: serializer.fromJson<DateTime>(json['consumedAt']),
      syncState: serializer.fromJson<String>(json['syncState']),
      deletedLocally: serializer.fromJson<bool>(json['deletedLocally']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'serverId': serializer.toJson<String?>(serverId),
      'userId': serializer.toJson<String>(userId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'consumedAt': serializer.toJson<DateTime>(consumedAt),
      'syncState': serializer.toJson<String>(syncState),
      'deletedLocally': serializer.toJson<bool>(deletedLocally),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalMeal copyWith(
          {String? localId,
          Value<String?> serverId = const Value.absent(),
          String? userId,
          String? payloadJson,
          DateTime? consumedAt,
          String? syncState,
          bool? deletedLocally,
          DateTime? updatedAt}) =>
      LocalMeal(
        localId: localId ?? this.localId,
        serverId: serverId.present ? serverId.value : this.serverId,
        userId: userId ?? this.userId,
        payloadJson: payloadJson ?? this.payloadJson,
        consumedAt: consumedAt ?? this.consumedAt,
        syncState: syncState ?? this.syncState,
        deletedLocally: deletedLocally ?? this.deletedLocally,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalMeal copyWithCompanion(LocalMealsCompanion data) {
    return LocalMeal(
      localId: data.localId.present ? data.localId.value : this.localId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      userId: data.userId.present ? data.userId.value : this.userId,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      consumedAt:
          data.consumedAt.present ? data.consumedAt.value : this.consumedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      deletedLocally: data.deletedLocally.present
          ? data.deletedLocally.value
          : this.deletedLocally,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMeal(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('consumedAt: $consumedAt, ')
          ..write('syncState: $syncState, ')
          ..write('deletedLocally: $deletedLocally, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(localId, serverId, userId, payloadJson,
      consumedAt, syncState, deletedLocally, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMeal &&
          other.localId == this.localId &&
          other.serverId == this.serverId &&
          other.userId == this.userId &&
          other.payloadJson == this.payloadJson &&
          other.consumedAt == this.consumedAt &&
          other.syncState == this.syncState &&
          other.deletedLocally == this.deletedLocally &&
          other.updatedAt == this.updatedAt);
}

class LocalMealsCompanion extends UpdateCompanion<LocalMeal> {
  final Value<String> localId;
  final Value<String?> serverId;
  final Value<String> userId;
  final Value<String> payloadJson;
  final Value<DateTime> consumedAt;
  final Value<String> syncState;
  final Value<bool> deletedLocally;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalMealsCompanion({
    this.localId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.userId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.consumedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.deletedLocally = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMealsCompanion.insert({
    required String localId,
    this.serverId = const Value.absent(),
    required String userId,
    required String payloadJson,
    required DateTime consumedAt,
    this.syncState = const Value.absent(),
    this.deletedLocally = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : localId = Value(localId),
        userId = Value(userId),
        payloadJson = Value(payloadJson),
        consumedAt = Value(consumedAt),
        updatedAt = Value(updatedAt);
  static Insertable<LocalMeal> custom({
    Expression<String>? localId,
    Expression<String>? serverId,
    Expression<String>? userId,
    Expression<String>? payloadJson,
    Expression<DateTime>? consumedAt,
    Expression<String>? syncState,
    Expression<bool>? deletedLocally,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (serverId != null) 'server_id': serverId,
      if (userId != null) 'user_id': userId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (consumedAt != null) 'consumed_at': consumedAt,
      if (syncState != null) 'sync_state': syncState,
      if (deletedLocally != null) 'deleted_locally': deletedLocally,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMealsCompanion copyWith(
      {Value<String>? localId,
      Value<String?>? serverId,
      Value<String>? userId,
      Value<String>? payloadJson,
      Value<DateTime>? consumedAt,
      Value<String>? syncState,
      Value<bool>? deletedLocally,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocalMealsCompanion(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      userId: userId ?? this.userId,
      payloadJson: payloadJson ?? this.payloadJson,
      consumedAt: consumedAt ?? this.consumedAt,
      syncState: syncState ?? this.syncState,
      deletedLocally: deletedLocally ?? this.deletedLocally,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (consumedAt.present) {
      map['consumed_at'] = Variable<DateTime>(consumedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (deletedLocally.present) {
      map['deleted_locally'] = Variable<bool>(deletedLocally.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMealsCompanion(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('consumedAt: $consumedAt, ')
          ..write('syncState: $syncState, ')
          ..write('deletedLocally: $deletedLocally, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $SyncQueuesTable syncQueues = $SyncQueuesTable(this);
  late final $LocalUsersTable localUsers = $LocalUsersTable(this);
  late final $LocalProfilesTable localProfiles = $LocalProfilesTable(this);
  late final $LocalNutritionTargetsTable localNutritionTargets =
      $LocalNutritionTargetsTable(this);
  late final $LocalDailySummariesTable localDailySummaries =
      $LocalDailySummariesTable(this);
  late final $LocalMealsTable localMeals = $LocalMealsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        appSettings,
        syncQueues,
        localUsers,
        localProfiles,
        localNutritionTargets,
        localDailySummaries,
        localMeals
      ];
}

typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  required String key,
  required String value,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$AppSettingsTableFilterComposer
    extends Composer<_$LocalDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$LocalDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (
      AppSetting,
      BaseReferences<_$LocalDatabase, $AppSettingsTable, AppSetting>
    ),
    AppSetting,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$LocalDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion.insert(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (
      AppSetting,
      BaseReferences<_$LocalDatabase, $AppSettingsTable, AppSetting>
    ),
    AppSetting,
    PrefetchHooks Function()>;
typedef $$SyncQueuesTableCreateCompanionBuilder = SyncQueuesCompanion Function({
  required String id,
  required String operationType,
  required String entityType,
  required String entityId,
  required String userId,
  required String payloadJson,
  required String idempotencyKey,
  required String dependencyGroup,
  required String status,
  Value<int> retryCount,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> nextRetryAt,
  Value<String?> serverVersion,
  Value<String?> lastError,
  Value<int> rowid,
});
typedef $$SyncQueuesTableUpdateCompanionBuilder = SyncQueuesCompanion Function({
  Value<String> id,
  Value<String> operationType,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> userId,
  Value<String> payloadJson,
  Value<String> idempotencyKey,
  Value<String> dependencyGroup,
  Value<String> status,
  Value<int> retryCount,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> nextRetryAt,
  Value<String?> serverVersion,
  Value<String?> lastError,
  Value<int> rowid,
});

class $$SyncQueuesTableFilterComposer
    extends Composer<_$LocalDatabase, $SyncQueuesTable> {
  $$SyncQueuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operationType => $composableBuilder(
      column: $table.operationType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dependencyGroup => $composableBuilder(
      column: $table.dependencyGroup,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverVersion => $composableBuilder(
      column: $table.serverVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));
}

class $$SyncQueuesTableOrderingComposer
    extends Composer<_$LocalDatabase, $SyncQueuesTable> {
  $$SyncQueuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operationType => $composableBuilder(
      column: $table.operationType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dependencyGroup => $composableBuilder(
      column: $table.dependencyGroup,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverVersion => $composableBuilder(
      column: $table.serverVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueuesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $SyncQueuesTable> {
  $$SyncQueuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operationType => $composableBuilder(
      column: $table.operationType, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey, builder: (column) => column);

  GeneratedColumn<String> get dependencyGroup => $composableBuilder(
      column: $table.dependencyGroup, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => column);

  GeneratedColumn<String> get serverVersion => $composableBuilder(
      column: $table.serverVersion, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncQueuesTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $SyncQueuesTable,
    SyncQueue,
    $$SyncQueuesTableFilterComposer,
    $$SyncQueuesTableOrderingComposer,
    $$SyncQueuesTableAnnotationComposer,
    $$SyncQueuesTableCreateCompanionBuilder,
    $$SyncQueuesTableUpdateCompanionBuilder,
    (SyncQueue, BaseReferences<_$LocalDatabase, $SyncQueuesTable, SyncQueue>),
    SyncQueue,
    PrefetchHooks Function()> {
  $$SyncQueuesTableTableManager(_$LocalDatabase db, $SyncQueuesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> operationType = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<String> idempotencyKey = const Value.absent(),
            Value<String> dependencyGroup = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> nextRetryAt = const Value.absent(),
            Value<String?> serverVersion = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueuesCompanion(
            id: id,
            operationType: operationType,
            entityType: entityType,
            entityId: entityId,
            userId: userId,
            payloadJson: payloadJson,
            idempotencyKey: idempotencyKey,
            dependencyGroup: dependencyGroup,
            status: status,
            retryCount: retryCount,
            createdAt: createdAt,
            updatedAt: updatedAt,
            nextRetryAt: nextRetryAt,
            serverVersion: serverVersion,
            lastError: lastError,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String operationType,
            required String entityType,
            required String entityId,
            required String userId,
            required String payloadJson,
            required String idempotencyKey,
            required String dependencyGroup,
            required String status,
            Value<int> retryCount = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> nextRetryAt = const Value.absent(),
            Value<String?> serverVersion = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueuesCompanion.insert(
            id: id,
            operationType: operationType,
            entityType: entityType,
            entityId: entityId,
            userId: userId,
            payloadJson: payloadJson,
            idempotencyKey: idempotencyKey,
            dependencyGroup: dependencyGroup,
            status: status,
            retryCount: retryCount,
            createdAt: createdAt,
            updatedAt: updatedAt,
            nextRetryAt: nextRetryAt,
            serverVersion: serverVersion,
            lastError: lastError,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueuesTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $SyncQueuesTable,
    SyncQueue,
    $$SyncQueuesTableFilterComposer,
    $$SyncQueuesTableOrderingComposer,
    $$SyncQueuesTableAnnotationComposer,
    $$SyncQueuesTableCreateCompanionBuilder,
    $$SyncQueuesTableUpdateCompanionBuilder,
    (SyncQueue, BaseReferences<_$LocalDatabase, $SyncQueuesTable, SyncQueue>),
    SyncQueue,
    PrefetchHooks Function()>;
typedef $$LocalUsersTableCreateCompanionBuilder = LocalUsersCompanion Function({
  required String userId,
  Value<String?> displayName,
  required DateTime lastAuthenticatedAt,
  Value<DateTime?> lastServerSyncAt,
  Value<String> sessionState,
  Value<int> rowid,
});
typedef $$LocalUsersTableUpdateCompanionBuilder = LocalUsersCompanion Function({
  Value<String> userId,
  Value<String?> displayName,
  Value<DateTime> lastAuthenticatedAt,
  Value<DateTime?> lastServerSyncAt,
  Value<String> sessionState,
  Value<int> rowid,
});

class $$LocalUsersTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalUsersTable> {
  $$LocalUsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastAuthenticatedAt => $composableBuilder(
      column: $table.lastAuthenticatedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastServerSyncAt => $composableBuilder(
      column: $table.lastServerSyncAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionState => $composableBuilder(
      column: $table.sessionState, builder: (column) => ColumnFilters(column));
}

class $$LocalUsersTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalUsersTable> {
  $$LocalUsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastAuthenticatedAt => $composableBuilder(
      column: $table.lastAuthenticatedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastServerSyncAt => $composableBuilder(
      column: $table.lastServerSyncAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionState => $composableBuilder(
      column: $table.sessionState,
      builder: (column) => ColumnOrderings(column));
}

class $$LocalUsersTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalUsersTable> {
  $$LocalUsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAuthenticatedAt => $composableBuilder(
      column: $table.lastAuthenticatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastServerSyncAt => $composableBuilder(
      column: $table.lastServerSyncAt, builder: (column) => column);

  GeneratedColumn<String> get sessionState => $composableBuilder(
      column: $table.sessionState, builder: (column) => column);
}

class $$LocalUsersTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalUsersTable,
    LocalUser,
    $$LocalUsersTableFilterComposer,
    $$LocalUsersTableOrderingComposer,
    $$LocalUsersTableAnnotationComposer,
    $$LocalUsersTableCreateCompanionBuilder,
    $$LocalUsersTableUpdateCompanionBuilder,
    (LocalUser, BaseReferences<_$LocalDatabase, $LocalUsersTable, LocalUser>),
    LocalUser,
    PrefetchHooks Function()> {
  $$LocalUsersTableTableManager(_$LocalDatabase db, $LocalUsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalUsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalUsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalUsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<String?> displayName = const Value.absent(),
            Value<DateTime> lastAuthenticatedAt = const Value.absent(),
            Value<DateTime?> lastServerSyncAt = const Value.absent(),
            Value<String> sessionState = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalUsersCompanion(
            userId: userId,
            displayName: displayName,
            lastAuthenticatedAt: lastAuthenticatedAt,
            lastServerSyncAt: lastServerSyncAt,
            sessionState: sessionState,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String userId,
            Value<String?> displayName = const Value.absent(),
            required DateTime lastAuthenticatedAt,
            Value<DateTime?> lastServerSyncAt = const Value.absent(),
            Value<String> sessionState = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalUsersCompanion.insert(
            userId: userId,
            displayName: displayName,
            lastAuthenticatedAt: lastAuthenticatedAt,
            lastServerSyncAt: lastServerSyncAt,
            sessionState: sessionState,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalUsersTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $LocalUsersTable,
    LocalUser,
    $$LocalUsersTableFilterComposer,
    $$LocalUsersTableOrderingComposer,
    $$LocalUsersTableAnnotationComposer,
    $$LocalUsersTableCreateCompanionBuilder,
    $$LocalUsersTableUpdateCompanionBuilder,
    (LocalUser, BaseReferences<_$LocalDatabase, $LocalUsersTable, LocalUser>),
    LocalUser,
    PrefetchHooks Function()>;
typedef $$LocalProfilesTableCreateCompanionBuilder = LocalProfilesCompanion
    Function({
  required String userId,
  required String payloadJson,
  Value<String?> serverVersion,
  required DateTime updatedAt,
  required DateTime localUpdatedAt,
  Value<String> syncState,
  Value<int> rowid,
});
typedef $$LocalProfilesTableUpdateCompanionBuilder = LocalProfilesCompanion
    Function({
  Value<String> userId,
  Value<String> payloadJson,
  Value<String?> serverVersion,
  Value<DateTime> updatedAt,
  Value<DateTime> localUpdatedAt,
  Value<String> syncState,
  Value<int> rowid,
});

class $$LocalProfilesTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalProfilesTable> {
  $$LocalProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverVersion => $composableBuilder(
      column: $table.serverVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
      column: $table.localUpdatedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnFilters(column));
}

class $$LocalProfilesTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalProfilesTable> {
  $$LocalProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverVersion => $composableBuilder(
      column: $table.serverVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
      column: $table.localUpdatedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnOrderings(column));
}

class $$LocalProfilesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalProfilesTable> {
  $$LocalProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<String> get serverVersion => $composableBuilder(
      column: $table.serverVersion, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
      column: $table.localUpdatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);
}

class $$LocalProfilesTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalProfilesTable,
    LocalProfile,
    $$LocalProfilesTableFilterComposer,
    $$LocalProfilesTableOrderingComposer,
    $$LocalProfilesTableAnnotationComposer,
    $$LocalProfilesTableCreateCompanionBuilder,
    $$LocalProfilesTableUpdateCompanionBuilder,
    (
      LocalProfile,
      BaseReferences<_$LocalDatabase, $LocalProfilesTable, LocalProfile>
    ),
    LocalProfile,
    PrefetchHooks Function()> {
  $$LocalProfilesTableTableManager(
      _$LocalDatabase db, $LocalProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<String?> serverVersion = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime> localUpdatedAt = const Value.absent(),
            Value<String> syncState = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalProfilesCompanion(
            userId: userId,
            payloadJson: payloadJson,
            serverVersion: serverVersion,
            updatedAt: updatedAt,
            localUpdatedAt: localUpdatedAt,
            syncState: syncState,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String userId,
            required String payloadJson,
            Value<String?> serverVersion = const Value.absent(),
            required DateTime updatedAt,
            required DateTime localUpdatedAt,
            Value<String> syncState = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalProfilesCompanion.insert(
            userId: userId,
            payloadJson: payloadJson,
            serverVersion: serverVersion,
            updatedAt: updatedAt,
            localUpdatedAt: localUpdatedAt,
            syncState: syncState,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalProfilesTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $LocalProfilesTable,
    LocalProfile,
    $$LocalProfilesTableFilterComposer,
    $$LocalProfilesTableOrderingComposer,
    $$LocalProfilesTableAnnotationComposer,
    $$LocalProfilesTableCreateCompanionBuilder,
    $$LocalProfilesTableUpdateCompanionBuilder,
    (
      LocalProfile,
      BaseReferences<_$LocalDatabase, $LocalProfilesTable, LocalProfile>
    ),
    LocalProfile,
    PrefetchHooks Function()>;
typedef $$LocalNutritionTargetsTableCreateCompanionBuilder
    = LocalNutritionTargetsCompanion Function({
  required String userId,
  required String effectiveDate,
  required String payloadJson,
  Value<String?> serverVersion,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$LocalNutritionTargetsTableUpdateCompanionBuilder
    = LocalNutritionTargetsCompanion Function({
  Value<String> userId,
  Value<String> effectiveDate,
  Value<String> payloadJson,
  Value<String?> serverVersion,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocalNutritionTargetsTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalNutritionTargetsTable> {
  $$LocalNutritionTargetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get effectiveDate => $composableBuilder(
      column: $table.effectiveDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverVersion => $composableBuilder(
      column: $table.serverVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalNutritionTargetsTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalNutritionTargetsTable> {
  $$LocalNutritionTargetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get effectiveDate => $composableBuilder(
      column: $table.effectiveDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverVersion => $composableBuilder(
      column: $table.serverVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalNutritionTargetsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalNutritionTargetsTable> {
  $$LocalNutritionTargetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get effectiveDate => $composableBuilder(
      column: $table.effectiveDate, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<String> get serverVersion => $composableBuilder(
      column: $table.serverVersion, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalNutritionTargetsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalNutritionTargetsTable,
    LocalNutritionTarget,
    $$LocalNutritionTargetsTableFilterComposer,
    $$LocalNutritionTargetsTableOrderingComposer,
    $$LocalNutritionTargetsTableAnnotationComposer,
    $$LocalNutritionTargetsTableCreateCompanionBuilder,
    $$LocalNutritionTargetsTableUpdateCompanionBuilder,
    (
      LocalNutritionTarget,
      BaseReferences<_$LocalDatabase, $LocalNutritionTargetsTable,
          LocalNutritionTarget>
    ),
    LocalNutritionTarget,
    PrefetchHooks Function()> {
  $$LocalNutritionTargetsTableTableManager(
      _$LocalDatabase db, $LocalNutritionTargetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalNutritionTargetsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalNutritionTargetsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalNutritionTargetsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<String> effectiveDate = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<String?> serverVersion = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalNutritionTargetsCompanion(
            userId: userId,
            effectiveDate: effectiveDate,
            payloadJson: payloadJson,
            serverVersion: serverVersion,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String userId,
            required String effectiveDate,
            required String payloadJson,
            Value<String?> serverVersion = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalNutritionTargetsCompanion.insert(
            userId: userId,
            effectiveDate: effectiveDate,
            payloadJson: payloadJson,
            serverVersion: serverVersion,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalNutritionTargetsTableProcessedTableManager
    = ProcessedTableManager<
        _$LocalDatabase,
        $LocalNutritionTargetsTable,
        LocalNutritionTarget,
        $$LocalNutritionTargetsTableFilterComposer,
        $$LocalNutritionTargetsTableOrderingComposer,
        $$LocalNutritionTargetsTableAnnotationComposer,
        $$LocalNutritionTargetsTableCreateCompanionBuilder,
        $$LocalNutritionTargetsTableUpdateCompanionBuilder,
        (
          LocalNutritionTarget,
          BaseReferences<_$LocalDatabase, $LocalNutritionTargetsTable,
              LocalNutritionTarget>
        ),
        LocalNutritionTarget,
        PrefetchHooks Function()>;
typedef $$LocalDailySummariesTableCreateCompanionBuilder
    = LocalDailySummariesCompanion Function({
  required String userId,
  required String summaryDate,
  required String payloadJson,
  required DateTime updatedAt,
  Value<String> syncState,
  Value<int> rowid,
});
typedef $$LocalDailySummariesTableUpdateCompanionBuilder
    = LocalDailySummariesCompanion Function({
  Value<String> userId,
  Value<String> summaryDate,
  Value<String> payloadJson,
  Value<DateTime> updatedAt,
  Value<String> syncState,
  Value<int> rowid,
});

class $$LocalDailySummariesTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalDailySummariesTable> {
  $$LocalDailySummariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get summaryDate => $composableBuilder(
      column: $table.summaryDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnFilters(column));
}

class $$LocalDailySummariesTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalDailySummariesTable> {
  $$LocalDailySummariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get summaryDate => $composableBuilder(
      column: $table.summaryDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnOrderings(column));
}

class $$LocalDailySummariesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalDailySummariesTable> {
  $$LocalDailySummariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get summaryDate => $composableBuilder(
      column: $table.summaryDate, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);
}

class $$LocalDailySummariesTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalDailySummariesTable,
    LocalDailySummary,
    $$LocalDailySummariesTableFilterComposer,
    $$LocalDailySummariesTableOrderingComposer,
    $$LocalDailySummariesTableAnnotationComposer,
    $$LocalDailySummariesTableCreateCompanionBuilder,
    $$LocalDailySummariesTableUpdateCompanionBuilder,
    (
      LocalDailySummary,
      BaseReferences<_$LocalDatabase, $LocalDailySummariesTable,
          LocalDailySummary>
    ),
    LocalDailySummary,
    PrefetchHooks Function()> {
  $$LocalDailySummariesTableTableManager(
      _$LocalDatabase db, $LocalDailySummariesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDailySummariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalDailySummariesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalDailySummariesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> userId = const Value.absent(),
            Value<String> summaryDate = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String> syncState = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalDailySummariesCompanion(
            userId: userId,
            summaryDate: summaryDate,
            payloadJson: payloadJson,
            updatedAt: updatedAt,
            syncState: syncState,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String userId,
            required String summaryDate,
            required String payloadJson,
            required DateTime updatedAt,
            Value<String> syncState = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalDailySummariesCompanion.insert(
            userId: userId,
            summaryDate: summaryDate,
            payloadJson: payloadJson,
            updatedAt: updatedAt,
            syncState: syncState,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalDailySummariesTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $LocalDailySummariesTable,
    LocalDailySummary,
    $$LocalDailySummariesTableFilterComposer,
    $$LocalDailySummariesTableOrderingComposer,
    $$LocalDailySummariesTableAnnotationComposer,
    $$LocalDailySummariesTableCreateCompanionBuilder,
    $$LocalDailySummariesTableUpdateCompanionBuilder,
    (
      LocalDailySummary,
      BaseReferences<_$LocalDatabase, $LocalDailySummariesTable,
          LocalDailySummary>
    ),
    LocalDailySummary,
    PrefetchHooks Function()>;
typedef $$LocalMealsTableCreateCompanionBuilder = LocalMealsCompanion Function({
  required String localId,
  Value<String?> serverId,
  required String userId,
  required String payloadJson,
  required DateTime consumedAt,
  Value<String> syncState,
  Value<bool> deletedLocally,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$LocalMealsTableUpdateCompanionBuilder = LocalMealsCompanion Function({
  Value<String> localId,
  Value<String?> serverId,
  Value<String> userId,
  Value<String> payloadJson,
  Value<DateTime> consumedAt,
  Value<String> syncState,
  Value<bool> deletedLocally,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocalMealsTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalMealsTable> {
  $$LocalMealsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get consumedAt => $composableBuilder(
      column: $table.consumedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deletedLocally => $composableBuilder(
      column: $table.deletedLocally,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalMealsTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalMealsTable> {
  $$LocalMealsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serverId => $composableBuilder(
      column: $table.serverId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get consumedAt => $composableBuilder(
      column: $table.consumedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncState => $composableBuilder(
      column: $table.syncState, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deletedLocally => $composableBuilder(
      column: $table.deletedLocally,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalMealsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalMealsTable> {
  $$LocalMealsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<DateTime> get consumedAt => $composableBuilder(
      column: $table.consumedAt, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<bool> get deletedLocally => $composableBuilder(
      column: $table.deletedLocally, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalMealsTableTableManager extends RootTableManager<
    _$LocalDatabase,
    $LocalMealsTable,
    LocalMeal,
    $$LocalMealsTableFilterComposer,
    $$LocalMealsTableOrderingComposer,
    $$LocalMealsTableAnnotationComposer,
    $$LocalMealsTableCreateCompanionBuilder,
    $$LocalMealsTableUpdateCompanionBuilder,
    (LocalMeal, BaseReferences<_$LocalDatabase, $LocalMealsTable, LocalMeal>),
    LocalMeal,
    PrefetchHooks Function()> {
  $$LocalMealsTableTableManager(_$LocalDatabase db, $LocalMealsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMealsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMealsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMealsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> localId = const Value.absent(),
            Value<String?> serverId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<DateTime> consumedAt = const Value.absent(),
            Value<String> syncState = const Value.absent(),
            Value<bool> deletedLocally = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalMealsCompanion(
            localId: localId,
            serverId: serverId,
            userId: userId,
            payloadJson: payloadJson,
            consumedAt: consumedAt,
            syncState: syncState,
            deletedLocally: deletedLocally,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String localId,
            Value<String?> serverId = const Value.absent(),
            required String userId,
            required String payloadJson,
            required DateTime consumedAt,
            Value<String> syncState = const Value.absent(),
            Value<bool> deletedLocally = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalMealsCompanion.insert(
            localId: localId,
            serverId: serverId,
            userId: userId,
            payloadJson: payloadJson,
            consumedAt: consumedAt,
            syncState: syncState,
            deletedLocally: deletedLocally,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalMealsTableProcessedTableManager = ProcessedTableManager<
    _$LocalDatabase,
    $LocalMealsTable,
    LocalMeal,
    $$LocalMealsTableFilterComposer,
    $$LocalMealsTableOrderingComposer,
    $$LocalMealsTableAnnotationComposer,
    $$LocalMealsTableCreateCompanionBuilder,
    $$LocalMealsTableUpdateCompanionBuilder,
    (LocalMeal, BaseReferences<_$LocalDatabase, $LocalMealsTable, LocalMeal>),
    LocalMeal,
    PrefetchHooks Function()>;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$SyncQueuesTableTableManager get syncQueues =>
      $$SyncQueuesTableTableManager(_db, _db.syncQueues);
  $$LocalUsersTableTableManager get localUsers =>
      $$LocalUsersTableTableManager(_db, _db.localUsers);
  $$LocalProfilesTableTableManager get localProfiles =>
      $$LocalProfilesTableTableManager(_db, _db.localProfiles);
  $$LocalNutritionTargetsTableTableManager get localNutritionTargets =>
      $$LocalNutritionTargetsTableTableManager(_db, _db.localNutritionTargets);
  $$LocalDailySummariesTableTableManager get localDailySummaries =>
      $$LocalDailySummariesTableTableManager(_db, _db.localDailySummaries);
  $$LocalMealsTableTableManager get localMeals =>
      $$LocalMealsTableTableManager(_db, _db.localMeals);
}
