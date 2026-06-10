// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, AccountData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AccountType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AccountType>($AccountsTable.$convertertype);
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  static const VerificationMeta _openingBalanceMeta = const VerificationMeta(
    'openingBalance',
  );
  @override
  late final GeneratedColumn<int> openingBalance = GeneratedColumn<int>(
    'opening_balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentBalanceMeta = const VerificationMeta(
    'currentBalance',
  );
  @override
  late final GeneratedColumn<int> currentBalance = GeneratedColumn<int>(
    'current_balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    currency,
    openingBalance,
    currentBalance,
    isArchived,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('opening_balance')) {
      context.handle(
        _openingBalanceMeta,
        openingBalance.isAcceptableOrUnknown(
          data['opening_balance']!,
          _openingBalanceMeta,
        ),
      );
    }
    if (data.containsKey('current_balance')) {
      context.handle(
        _currentBalanceMeta,
        currentBalance.isAcceptableOrUnknown(
          data['current_balance']!,
          _currentBalanceMeta,
        ),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $AccountsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      openingBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_balance'],
      )!,
      currentBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_balance'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AccountType, String, String> $convertertype =
      const EnumNameConverter<AccountType>(AccountType.values);
}

class AccountData extends DataClass implements Insertable<AccountData> {
  final String id;
  final String name;
  final AccountType type;
  final String currency;

  /// Amount in smallest currency unit (paise for INR). Always ≥ 0 for assets.
  final int openingBalance;

  /// Maintained by transaction writes — never compute from transaction history.
  final int currentBalance;
  final bool isArchived;
  final int sortOrder;
  final String createdAt;
  const AccountData({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.openingBalance,
    required this.currentBalance,
    required this.isArchived,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>($AccountsTable.$convertertype.toSql(type));
    }
    map['currency'] = Variable<String>(currency);
    map['opening_balance'] = Variable<int>(openingBalance);
    map['current_balance'] = Variable<int>(currentBalance);
    map['is_archived'] = Variable<bool>(isArchived);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      currency: Value(currency),
      openingBalance: Value(openingBalance),
      currentBalance: Value(currentBalance),
      isArchived: Value(isArchived),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory AccountData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: $AccountsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      currency: serializer.fromJson<String>(json['currency']),
      openingBalance: serializer.fromJson<int>(json['openingBalance']),
      currentBalance: serializer.fromJson<int>(json['currentBalance']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(
        $AccountsTable.$convertertype.toJson(type),
      ),
      'currency': serializer.toJson<String>(currency),
      'openingBalance': serializer.toJson<int>(openingBalance),
      'currentBalance': serializer.toJson<int>(currentBalance),
      'isArchived': serializer.toJson<bool>(isArchived),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  AccountData copyWith({
    String? id,
    String? name,
    AccountType? type,
    String? currency,
    int? openingBalance,
    int? currentBalance,
    bool? isArchived,
    int? sortOrder,
    String? createdAt,
  }) => AccountData(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    currency: currency ?? this.currency,
    openingBalance: openingBalance ?? this.openingBalance,
    currentBalance: currentBalance ?? this.currentBalance,
    isArchived: isArchived ?? this.isArchived,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  AccountData copyWithCompanion(AccountsCompanion data) {
    return AccountData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      currency: data.currency.present ? data.currency.value : this.currency,
      openingBalance: data.openingBalance.present
          ? data.openingBalance.value
          : this.openingBalance,
      currentBalance: data.currentBalance.present
          ? data.currentBalance.value
          : this.currentBalance,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('currency: $currency, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    currency,
    openingBalance,
    currentBalance,
    isArchived,
    sortOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountData &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.currency == this.currency &&
          other.openingBalance == this.openingBalance &&
          other.currentBalance == this.currentBalance &&
          other.isArchived == this.isArchived &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class AccountsCompanion extends UpdateCompanion<AccountData> {
  final Value<String> id;
  final Value<String> name;
  final Value<AccountType> type;
  final Value<String> currency;
  final Value<int> openingBalance;
  final Value<int> currentBalance;
  final Value<bool> isArchived;
  final Value<int> sortOrder;
  final Value<String> createdAt;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.currency = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String name,
    required AccountType type,
    this.currency = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       createdAt = Value(createdAt);
  static Insertable<AccountData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? currency,
    Expression<int>? openingBalance,
    Expression<int>? currentBalance,
    Expression<bool>? isArchived,
    Expression<int>? sortOrder,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (currency != null) 'currency': currency,
      if (openingBalance != null) 'opening_balance': openingBalance,
      if (currentBalance != null) 'current_balance': currentBalance,
      if (isArchived != null) 'is_archived': isArchived,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<AccountType>? type,
    Value<String>? currency,
    Value<int>? openingBalance,
    Value<int>? currentBalance,
    Value<bool>? isArchived,
    Value<int>? sortOrder,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $AccountsTable.$convertertype.toSql(type.value),
      );
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (openingBalance.present) {
      map['opening_balance'] = Variable<int>(openingBalance.value);
    }
    if (currentBalance.present) {
      map['current_balance'] = Variable<int>(currentBalance.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('currency: $currency, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CategoryType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CategoryType>($CategoriesTable.$convertertype);
  static const VerificationMeta _iconCodeMeta = const VerificationMeta(
    'iconCode',
  );
  @override
  late final GeneratedColumn<int> iconCode = GeneratedColumn<int>(
    'icon_code',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSystemMeta = const VerificationMeta(
    'isSystem',
  );
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
    'is_system',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    parentId,
    type,
    iconCode,
    icon,
    colorHex,
    isSystem,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('icon_code')) {
      context.handle(
        _iconCodeMeta,
        iconCode.isAcceptableOrUnknown(data['icon_code']!, _iconCodeMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('is_system')) {
      context.handle(
        _isSystemMeta,
        isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      type: $CategoriesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      iconCode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon_code'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      ),
      isSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CategoryType, String, String> $convertertype =
      const EnumNameConverter<CategoryType>(CategoryType.values);
}

class CategoryData extends DataClass implements Insertable<CategoryData> {
  final String id;
  final String name;

  /// Null = root category. Non-null = sub-category (PBI-011).
  final String? parentId;
  final CategoryType type;

  /// Legacy int codepoint from v1 — kept for migration compatibility.
  /// Use [icon] instead. Will be removed in a future schema version.
  final int? iconCode;

  /// CategoryIcon enum name — tree-shakeable. Added in schema v2.
  final String? icon;
  final String? colorHex;
  final bool isSystem;
  final int sortOrder;
  const CategoryData({
    required this.id,
    required this.name,
    this.parentId,
    required this.type,
    this.iconCode,
    this.icon,
    this.colorHex,
    required this.isSystem,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    {
      map['type'] = Variable<String>(
        $CategoriesTable.$convertertype.toSql(type),
      );
    }
    if (!nullToAbsent || iconCode != null) {
      map['icon_code'] = Variable<int>(iconCode);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    map['is_system'] = Variable<bool>(isSystem);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      type: Value(type),
      iconCode: iconCode == null && nullToAbsent
          ? const Value.absent()
          : Value(iconCode),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      isSystem: Value(isSystem),
      sortOrder: Value(sortOrder),
    );
  }

  factory CategoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      type: $CategoriesTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      iconCode: serializer.fromJson<int?>(json['iconCode']),
      icon: serializer.fromJson<String?>(json['icon']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<String?>(parentId),
      'type': serializer.toJson<String>(
        $CategoriesTable.$convertertype.toJson(type),
      ),
      'iconCode': serializer.toJson<int?>(iconCode),
      'icon': serializer.toJson<String?>(icon),
      'colorHex': serializer.toJson<String?>(colorHex),
      'isSystem': serializer.toJson<bool>(isSystem),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CategoryData copyWith({
    String? id,
    String? name,
    Value<String?> parentId = const Value.absent(),
    CategoryType? type,
    Value<int?> iconCode = const Value.absent(),
    Value<String?> icon = const Value.absent(),
    Value<String?> colorHex = const Value.absent(),
    bool? isSystem,
    int? sortOrder,
  }) => CategoryData(
    id: id ?? this.id,
    name: name ?? this.name,
    parentId: parentId.present ? parentId.value : this.parentId,
    type: type ?? this.type,
    iconCode: iconCode.present ? iconCode.value : this.iconCode,
    icon: icon.present ? icon.value : this.icon,
    colorHex: colorHex.present ? colorHex.value : this.colorHex,
    isSystem: isSystem ?? this.isSystem,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CategoryData copyWithCompanion(CategoriesCompanion data) {
    return CategoryData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      type: data.type.present ? data.type.value : this.type,
      iconCode: data.iconCode.present ? data.iconCode.value : this.iconCode,
      icon: data.icon.present ? data.icon.value : this.icon,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('type: $type, ')
          ..write('iconCode: $iconCode, ')
          ..write('icon: $icon, ')
          ..write('colorHex: $colorHex, ')
          ..write('isSystem: $isSystem, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    parentId,
    type,
    iconCode,
    icon,
    colorHex,
    isSystem,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryData &&
          other.id == this.id &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.type == this.type &&
          other.iconCode == this.iconCode &&
          other.icon == this.icon &&
          other.colorHex == this.colorHex &&
          other.isSystem == this.isSystem &&
          other.sortOrder == this.sortOrder);
}

class CategoriesCompanion extends UpdateCompanion<CategoryData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<CategoryType> type;
  final Value<int?> iconCode;
  final Value<String?> icon;
  final Value<String?> colorHex;
  final Value<bool> isSystem;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.type = const Value.absent(),
    this.iconCode = const Value.absent(),
    this.icon = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    this.parentId = const Value.absent(),
    required CategoryType type,
    this.iconCode = const Value.absent(),
    this.icon = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type);
  static Insertable<CategoryData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<String>? type,
    Expression<int>? iconCode,
    Expression<String>? icon,
    Expression<String>? colorHex,
    Expression<bool>? isSystem,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (type != null) 'type': type,
      if (iconCode != null) 'icon_code': iconCode,
      if (icon != null) 'icon': icon,
      if (colorHex != null) 'color_hex': colorHex,
      if (isSystem != null) 'is_system': isSystem,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? parentId,
    Value<CategoryType>? type,
    Value<int?>? iconCode,
    Value<String?>? icon,
    Value<String?>? colorHex,
    Value<bool>? isSystem,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      type: type ?? this.type,
      iconCode: iconCode ?? this.iconCode,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      isSystem: isSystem ?? this.isSystem,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $CategoriesTable.$convertertype.toSql(type.value),
      );
    }
    if (iconCode.present) {
      map['icon_code'] = Variable<int>(iconCode.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('type: $type, ')
          ..write('iconCode: $iconCode, ')
          ..write('icon: $icon, ')
          ..write('colorHex: $colorHex, ')
          ..write('isSystem: $isSystem, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransactionType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TransactionType>($TransactionsTable.$convertertype);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _debitAccountIdMeta = const VerificationMeta(
    'debitAccountId',
  );
  @override
  late final GeneratedColumn<String> debitAccountId = GeneratedColumn<String>(
    'debit_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _creditAccountIdMeta = const VerificationMeta(
    'creditAccountId',
  );
  @override
  late final GeneratedColumn<String> creditAccountId = GeneratedColumn<String>(
    'credit_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 1000,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionDateMeta = const VerificationMeta(
    'transactionDate',
  );
  @override
  late final GeneratedColumn<String> transactionDate = GeneratedColumn<String>(
    'transaction_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isBookmarkedMeta = const VerificationMeta(
    'isBookmarked',
  );
  @override
  late final GeneratedColumn<bool> isBookmarked = GeneratedColumn<bool>(
    'is_bookmarked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_bookmarked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _receiptImagePathMeta = const VerificationMeta(
    'receiptImagePath',
  );
  @override
  late final GeneratedColumn<String> receiptImagePath = GeneratedColumn<String>(
    'receipt_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    amount,
    debitAccountId,
    creditAccountId,
    categoryId,
    description,
    notes,
    transactionDate,
    createdAt,
    isBookmarked,
    receiptImagePath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('debit_account_id')) {
      context.handle(
        _debitAccountIdMeta,
        debitAccountId.isAcceptableOrUnknown(
          data['debit_account_id']!,
          _debitAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_debitAccountIdMeta);
    }
    if (data.containsKey('credit_account_id')) {
      context.handle(
        _creditAccountIdMeta,
        creditAccountId.isAcceptableOrUnknown(
          data['credit_account_id']!,
          _creditAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_creditAccountIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('transaction_date')) {
      context.handle(
        _transactionDateMeta,
        transactionDate.isAcceptableOrUnknown(
          data['transaction_date']!,
          _transactionDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_bookmarked')) {
      context.handle(
        _isBookmarkedMeta,
        isBookmarked.isAcceptableOrUnknown(
          data['is_bookmarked']!,
          _isBookmarkedMeta,
        ),
      );
    }
    if (data.containsKey('receipt_image_path')) {
      context.handle(
        _receiptImagePathMeta,
        receiptImagePath.isAcceptableOrUnknown(
          data['receipt_image_path']!,
          _receiptImagePathMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: $TransactionsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      debitAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}debit_account_id'],
      )!,
      creditAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credit_account_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      transactionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_date'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      isBookmarked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_bookmarked'],
      )!,
      receiptImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_image_path'],
      ),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransactionType, String, String> $convertertype =
      const EnumNameConverter<TransactionType>(TransactionType.values);
}

class TransactionData extends DataClass implements Insertable<TransactionData> {
  final String id;
  final TransactionType type;

  /// Amount in smallest currency unit (paise). Always > 0.
  final int amount;

  /// Account whose balance decreases (expense) or is the source (transfer).
  final String debitAccountId;

  /// Account whose balance increases (income) or is the destination (transfer).
  final String creditAccountId;
  final String? categoryId;
  final String description;
  final String? notes;
  final String transactionDate;
  final String createdAt;
  final bool isBookmarked;

  /// Populated in Sprint 5 (PBI-015).
  final String? receiptImagePath;
  const TransactionData({
    required this.id,
    required this.type,
    required this.amount,
    required this.debitAccountId,
    required this.creditAccountId,
    this.categoryId,
    required this.description,
    this.notes,
    required this.transactionDate,
    required this.createdAt,
    required this.isBookmarked,
    this.receiptImagePath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['type'] = Variable<String>(
        $TransactionsTable.$convertertype.toSql(type),
      );
    }
    map['amount'] = Variable<int>(amount);
    map['debit_account_id'] = Variable<String>(debitAccountId);
    map['credit_account_id'] = Variable<String>(creditAccountId);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['transaction_date'] = Variable<String>(transactionDate);
    map['created_at'] = Variable<String>(createdAt);
    map['is_bookmarked'] = Variable<bool>(isBookmarked);
    if (!nullToAbsent || receiptImagePath != null) {
      map['receipt_image_path'] = Variable<String>(receiptImagePath);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      type: Value(type),
      amount: Value(amount),
      debitAccountId: Value(debitAccountId),
      creditAccountId: Value(creditAccountId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      description: Value(description),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      transactionDate: Value(transactionDate),
      createdAt: Value(createdAt),
      isBookmarked: Value(isBookmarked),
      receiptImagePath: receiptImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptImagePath),
    );
  }

  factory TransactionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionData(
      id: serializer.fromJson<String>(json['id']),
      type: $TransactionsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      amount: serializer.fromJson<int>(json['amount']),
      debitAccountId: serializer.fromJson<String>(json['debitAccountId']),
      creditAccountId: serializer.fromJson<String>(json['creditAccountId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      description: serializer.fromJson<String>(json['description']),
      notes: serializer.fromJson<String?>(json['notes']),
      transactionDate: serializer.fromJson<String>(json['transactionDate']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      isBookmarked: serializer.fromJson<bool>(json['isBookmarked']),
      receiptImagePath: serializer.fromJson<String?>(json['receiptImagePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(
        $TransactionsTable.$convertertype.toJson(type),
      ),
      'amount': serializer.toJson<int>(amount),
      'debitAccountId': serializer.toJson<String>(debitAccountId),
      'creditAccountId': serializer.toJson<String>(creditAccountId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'description': serializer.toJson<String>(description),
      'notes': serializer.toJson<String?>(notes),
      'transactionDate': serializer.toJson<String>(transactionDate),
      'createdAt': serializer.toJson<String>(createdAt),
      'isBookmarked': serializer.toJson<bool>(isBookmarked),
      'receiptImagePath': serializer.toJson<String?>(receiptImagePath),
    };
  }

  TransactionData copyWith({
    String? id,
    TransactionType? type,
    int? amount,
    String? debitAccountId,
    String? creditAccountId,
    Value<String?> categoryId = const Value.absent(),
    String? description,
    Value<String?> notes = const Value.absent(),
    String? transactionDate,
    String? createdAt,
    bool? isBookmarked,
    Value<String?> receiptImagePath = const Value.absent(),
  }) => TransactionData(
    id: id ?? this.id,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    debitAccountId: debitAccountId ?? this.debitAccountId,
    creditAccountId: creditAccountId ?? this.creditAccountId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    description: description ?? this.description,
    notes: notes.present ? notes.value : this.notes,
    transactionDate: transactionDate ?? this.transactionDate,
    createdAt: createdAt ?? this.createdAt,
    isBookmarked: isBookmarked ?? this.isBookmarked,
    receiptImagePath: receiptImagePath.present
        ? receiptImagePath.value
        : this.receiptImagePath,
  );
  TransactionData copyWithCompanion(TransactionsCompanion data) {
    return TransactionData(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      debitAccountId: data.debitAccountId.present
          ? data.debitAccountId.value
          : this.debitAccountId,
      creditAccountId: data.creditAccountId.present
          ? data.creditAccountId.value
          : this.creditAccountId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      description: data.description.present
          ? data.description.value
          : this.description,
      notes: data.notes.present ? data.notes.value : this.notes,
      transactionDate: data.transactionDate.present
          ? data.transactionDate.value
          : this.transactionDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isBookmarked: data.isBookmarked.present
          ? data.isBookmarked.value
          : this.isBookmarked,
      receiptImagePath: data.receiptImagePath.present
          ? data.receiptImagePath.value
          : this.receiptImagePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionData(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('debitAccountId: $debitAccountId, ')
          ..write('creditAccountId: $creditAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('description: $description, ')
          ..write('notes: $notes, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('isBookmarked: $isBookmarked, ')
          ..write('receiptImagePath: $receiptImagePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    amount,
    debitAccountId,
    creditAccountId,
    categoryId,
    description,
    notes,
    transactionDate,
    createdAt,
    isBookmarked,
    receiptImagePath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionData &&
          other.id == this.id &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.debitAccountId == this.debitAccountId &&
          other.creditAccountId == this.creditAccountId &&
          other.categoryId == this.categoryId &&
          other.description == this.description &&
          other.notes == this.notes &&
          other.transactionDate == this.transactionDate &&
          other.createdAt == this.createdAt &&
          other.isBookmarked == this.isBookmarked &&
          other.receiptImagePath == this.receiptImagePath);
}

class TransactionsCompanion extends UpdateCompanion<TransactionData> {
  final Value<String> id;
  final Value<TransactionType> type;
  final Value<int> amount;
  final Value<String> debitAccountId;
  final Value<String> creditAccountId;
  final Value<String?> categoryId;
  final Value<String> description;
  final Value<String?> notes;
  final Value<String> transactionDate;
  final Value<String> createdAt;
  final Value<bool> isBookmarked;
  final Value<String?> receiptImagePath;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.debitAccountId = const Value.absent(),
    this.creditAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.description = const Value.absent(),
    this.notes = const Value.absent(),
    this.transactionDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isBookmarked = const Value.absent(),
    this.receiptImagePath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required TransactionType type,
    required int amount,
    required String debitAccountId,
    required String creditAccountId,
    this.categoryId = const Value.absent(),
    this.description = const Value.absent(),
    this.notes = const Value.absent(),
    required String transactionDate,
    required String createdAt,
    this.isBookmarked = const Value.absent(),
    this.receiptImagePath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       amount = Value(amount),
       debitAccountId = Value(debitAccountId),
       creditAccountId = Value(creditAccountId),
       transactionDate = Value(transactionDate),
       createdAt = Value(createdAt);
  static Insertable<TransactionData> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<int>? amount,
    Expression<String>? debitAccountId,
    Expression<String>? creditAccountId,
    Expression<String>? categoryId,
    Expression<String>? description,
    Expression<String>? notes,
    Expression<String>? transactionDate,
    Expression<String>? createdAt,
    Expression<bool>? isBookmarked,
    Expression<String>? receiptImagePath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (debitAccountId != null) 'debit_account_id': debitAccountId,
      if (creditAccountId != null) 'credit_account_id': creditAccountId,
      if (categoryId != null) 'category_id': categoryId,
      if (description != null) 'description': description,
      if (notes != null) 'notes': notes,
      if (transactionDate != null) 'transaction_date': transactionDate,
      if (createdAt != null) 'created_at': createdAt,
      if (isBookmarked != null) 'is_bookmarked': isBookmarked,
      if (receiptImagePath != null) 'receipt_image_path': receiptImagePath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<TransactionType>? type,
    Value<int>? amount,
    Value<String>? debitAccountId,
    Value<String>? creditAccountId,
    Value<String?>? categoryId,
    Value<String>? description,
    Value<String?>? notes,
    Value<String>? transactionDate,
    Value<String>? createdAt,
    Value<bool>? isBookmarked,
    Value<String?>? receiptImagePath,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      debitAccountId: debitAccountId ?? this.debitAccountId,
      creditAccountId: creditAccountId ?? this.creditAccountId,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $TransactionsTable.$convertertype.toSql(type.value),
      );
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (debitAccountId.present) {
      map['debit_account_id'] = Variable<String>(debitAccountId.value);
    }
    if (creditAccountId.present) {
      map['credit_account_id'] = Variable<String>(creditAccountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (transactionDate.present) {
      map['transaction_date'] = Variable<String>(transactionDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (isBookmarked.present) {
      map['is_bookmarked'] = Variable<bool>(isBookmarked.value);
    }
    if (receiptImagePath.present) {
      map['receipt_image_path'] = Variable<String>(receiptImagePath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('debitAccountId: $debitAccountId, ')
          ..write('creditAccountId: $creditAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('description: $description, ')
          ..write('notes: $notes, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('isBookmarked: $isBookmarked, ')
          ..write('receiptImagePath: $receiptImagePath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MonthlyAggregatesTable extends MonthlyAggregates
    with TableInfo<$MonthlyAggregatesTable, MonthlyAggregateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonthlyAggregatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalIncomeMeta = const VerificationMeta(
    'totalIncome',
  );
  @override
  late final GeneratedColumn<int> totalIncome = GeneratedColumn<int>(
    'total_income',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalExpenseMeta = const VerificationMeta(
    'totalExpense',
  );
  @override
  late final GeneratedColumn<int> totalExpense = GeneratedColumn<int>(
    'total_expense',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    year,
    month,
    totalIncome,
    totalExpense,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'monthly_aggregates';
  @override
  VerificationContext validateIntegrity(
    Insertable<MonthlyAggregateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('total_income')) {
      context.handle(
        _totalIncomeMeta,
        totalIncome.isAcceptableOrUnknown(
          data['total_income']!,
          _totalIncomeMeta,
        ),
      );
    }
    if (data.containsKey('total_expense')) {
      context.handle(
        _totalExpenseMeta,
        totalExpense.isAcceptableOrUnknown(
          data['total_expense']!,
          _totalExpenseMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, year, month};
  @override
  MonthlyAggregateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonthlyAggregateData(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month'],
      )!,
      totalIncome: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_income'],
      )!,
      totalExpense: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_expense'],
      )!,
    );
  }

  @override
  $MonthlyAggregatesTable createAlias(String alias) {
    return $MonthlyAggregatesTable(attachedDatabase, alias);
  }
}

class MonthlyAggregateData extends DataClass
    implements Insertable<MonthlyAggregateData> {
  final String accountId;
  final int year;
  final int month;
  final int totalIncome;
  final int totalExpense;
  const MonthlyAggregateData({
    required this.accountId,
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['year'] = Variable<int>(year);
    map['month'] = Variable<int>(month);
    map['total_income'] = Variable<int>(totalIncome);
    map['total_expense'] = Variable<int>(totalExpense);
    return map;
  }

  MonthlyAggregatesCompanion toCompanion(bool nullToAbsent) {
    return MonthlyAggregatesCompanion(
      accountId: Value(accountId),
      year: Value(year),
      month: Value(month),
      totalIncome: Value(totalIncome),
      totalExpense: Value(totalExpense),
    );
  }

  factory MonthlyAggregateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonthlyAggregateData(
      accountId: serializer.fromJson<String>(json['accountId']),
      year: serializer.fromJson<int>(json['year']),
      month: serializer.fromJson<int>(json['month']),
      totalIncome: serializer.fromJson<int>(json['totalIncome']),
      totalExpense: serializer.fromJson<int>(json['totalExpense']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'year': serializer.toJson<int>(year),
      'month': serializer.toJson<int>(month),
      'totalIncome': serializer.toJson<int>(totalIncome),
      'totalExpense': serializer.toJson<int>(totalExpense),
    };
  }

  MonthlyAggregateData copyWith({
    String? accountId,
    int? year,
    int? month,
    int? totalIncome,
    int? totalExpense,
  }) => MonthlyAggregateData(
    accountId: accountId ?? this.accountId,
    year: year ?? this.year,
    month: month ?? this.month,
    totalIncome: totalIncome ?? this.totalIncome,
    totalExpense: totalExpense ?? this.totalExpense,
  );
  MonthlyAggregateData copyWithCompanion(MonthlyAggregatesCompanion data) {
    return MonthlyAggregateData(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      year: data.year.present ? data.year.value : this.year,
      month: data.month.present ? data.month.value : this.month,
      totalIncome: data.totalIncome.present
          ? data.totalIncome.value
          : this.totalIncome,
      totalExpense: data.totalExpense.present
          ? data.totalExpense.value
          : this.totalExpense,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonthlyAggregateData(')
          ..write('accountId: $accountId, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('totalIncome: $totalIncome, ')
          ..write('totalExpense: $totalExpense')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(accountId, year, month, totalIncome, totalExpense);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthlyAggregateData &&
          other.accountId == this.accountId &&
          other.year == this.year &&
          other.month == this.month &&
          other.totalIncome == this.totalIncome &&
          other.totalExpense == this.totalExpense);
}

class MonthlyAggregatesCompanion extends UpdateCompanion<MonthlyAggregateData> {
  final Value<String> accountId;
  final Value<int> year;
  final Value<int> month;
  final Value<int> totalIncome;
  final Value<int> totalExpense;
  final Value<int> rowid;
  const MonthlyAggregatesCompanion({
    this.accountId = const Value.absent(),
    this.year = const Value.absent(),
    this.month = const Value.absent(),
    this.totalIncome = const Value.absent(),
    this.totalExpense = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MonthlyAggregatesCompanion.insert({
    required String accountId,
    required int year,
    required int month,
    this.totalIncome = const Value.absent(),
    this.totalExpense = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       year = Value(year),
       month = Value(month);
  static Insertable<MonthlyAggregateData> custom({
    Expression<String>? accountId,
    Expression<int>? year,
    Expression<int>? month,
    Expression<int>? totalIncome,
    Expression<int>? totalExpense,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (year != null) 'year': year,
      if (month != null) 'month': month,
      if (totalIncome != null) 'total_income': totalIncome,
      if (totalExpense != null) 'total_expense': totalExpense,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MonthlyAggregatesCompanion copyWith({
    Value<String>? accountId,
    Value<int>? year,
    Value<int>? month,
    Value<int>? totalIncome,
    Value<int>? totalExpense,
    Value<int>? rowid,
  }) {
    return MonthlyAggregatesCompanion(
      accountId: accountId ?? this.accountId,
      year: year ?? this.year,
      month: month ?? this.month,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (totalIncome.present) {
      map['total_income'] = Variable<int>(totalIncome.value);
    }
    if (totalExpense.present) {
      map['total_expense'] = Variable<int>(totalExpense.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonthlyAggregatesCompanion(')
          ..write('accountId: $accountId, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('totalIncome: $totalIncome, ')
          ..write('totalExpense: $totalExpense, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, BudgetData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _limitPaiseMeta = const VerificationMeta(
    'limitPaise',
  );
  @override
  late final GeneratedColumn<int> limitPaise = GeneratedColumn<int>(
    'limit_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    categoryId,
    year,
    month,
    limitPaise,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('limit_paise')) {
      context.handle(
        _limitPaiseMeta,
        limitPaise.isAcceptableOrUnknown(data['limit_paise']!, _limitPaiseMeta),
      );
    } else if (isInserting) {
      context.missing(_limitPaiseMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month'],
      )!,
      limitPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limit_paise'],
      )!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class BudgetData extends DataClass implements Insertable<BudgetData> {
  final String id;
  final String categoryId;
  final int year;
  final int month;

  /// Budget limit in paise (smallest currency unit).
  final int limitPaise;
  const BudgetData({
    required this.id,
    required this.categoryId,
    required this.year,
    required this.month,
    required this.limitPaise,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category_id'] = Variable<String>(categoryId);
    map['year'] = Variable<int>(year);
    map['month'] = Variable<int>(month);
    map['limit_paise'] = Variable<int>(limitPaise);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      year: Value(year),
      month: Value(month),
      limitPaise: Value(limitPaise),
    );
  }

  factory BudgetData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetData(
      id: serializer.fromJson<String>(json['id']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      year: serializer.fromJson<int>(json['year']),
      month: serializer.fromJson<int>(json['month']),
      limitPaise: serializer.fromJson<int>(json['limitPaise']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'categoryId': serializer.toJson<String>(categoryId),
      'year': serializer.toJson<int>(year),
      'month': serializer.toJson<int>(month),
      'limitPaise': serializer.toJson<int>(limitPaise),
    };
  }

  BudgetData copyWith({
    String? id,
    String? categoryId,
    int? year,
    int? month,
    int? limitPaise,
  }) => BudgetData(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    year: year ?? this.year,
    month: month ?? this.month,
    limitPaise: limitPaise ?? this.limitPaise,
  );
  BudgetData copyWithCompanion(BudgetsCompanion data) {
    return BudgetData(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      year: data.year.present ? data.year.value : this.year,
      month: data.month.present ? data.month.value : this.month,
      limitPaise: data.limitPaise.present
          ? data.limitPaise.value
          : this.limitPaise,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetData(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('limitPaise: $limitPaise')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, categoryId, year, month, limitPaise);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetData &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.year == this.year &&
          other.month == this.month &&
          other.limitPaise == this.limitPaise);
}

class BudgetsCompanion extends UpdateCompanion<BudgetData> {
  final Value<String> id;
  final Value<String> categoryId;
  final Value<int> year;
  final Value<int> month;
  final Value<int> limitPaise;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.year = const Value.absent(),
    this.month = const Value.absent(),
    this.limitPaise = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    required String id,
    required String categoryId,
    required int year,
    required int month,
    required int limitPaise,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       categoryId = Value(categoryId),
       year = Value(year),
       month = Value(month),
       limitPaise = Value(limitPaise);
  static Insertable<BudgetData> custom({
    Expression<String>? id,
    Expression<String>? categoryId,
    Expression<int>? year,
    Expression<int>? month,
    Expression<int>? limitPaise,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (year != null) 'year': year,
      if (month != null) 'month': month,
      if (limitPaise != null) 'limit_paise': limitPaise,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith({
    Value<String>? id,
    Value<String>? categoryId,
    Value<int>? year,
    Value<int>? month,
    Value<int>? limitPaise,
    Value<int>? rowid,
  }) {
    return BudgetsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      year: year ?? this.year,
      month: month ?? this.month,
      limitPaise: limitPaise ?? this.limitPaise,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (limitPaise.present) {
      map['limit_paise'] = Variable<int>(limitPaise.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('limitPaise: $limitPaise, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SecurityConfigsTable extends SecurityConfigs
    with TableInfo<$SecurityConfigsTable, SecurityConfigData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SecurityConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _pinHashMeta = const VerificationMeta(
    'pinHash',
  );
  @override
  late final GeneratedColumn<String> pinHash = GeneratedColumn<String>(
    'pin_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _biometricEnabledMeta = const VerificationMeta(
    'biometricEnabled',
  );
  @override
  late final GeneratedColumn<bool> biometricEnabled = GeneratedColumn<bool>(
    'biometric_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("biometric_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lockOnBackgroundMeta = const VerificationMeta(
    'lockOnBackground',
  );
  @override
  late final GeneratedColumn<bool> lockOnBackground = GeneratedColumn<bool>(
    'lock_on_background',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("lock_on_background" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lockDelaySecondsMeta = const VerificationMeta(
    'lockDelaySeconds',
  );
  @override
  late final GeneratedColumn<int> lockDelaySeconds = GeneratedColumn<int>(
    'lock_delay_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pinHash,
    biometricEnabled,
    lockOnBackground,
    lockDelaySeconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'security_configs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SecurityConfigData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pin_hash')) {
      context.handle(
        _pinHashMeta,
        pinHash.isAcceptableOrUnknown(data['pin_hash']!, _pinHashMeta),
      );
    }
    if (data.containsKey('biometric_enabled')) {
      context.handle(
        _biometricEnabledMeta,
        biometricEnabled.isAcceptableOrUnknown(
          data['biometric_enabled']!,
          _biometricEnabledMeta,
        ),
      );
    }
    if (data.containsKey('lock_on_background')) {
      context.handle(
        _lockOnBackgroundMeta,
        lockOnBackground.isAcceptableOrUnknown(
          data['lock_on_background']!,
          _lockOnBackgroundMeta,
        ),
      );
    }
    if (data.containsKey('lock_delay_seconds')) {
      context.handle(
        _lockDelaySecondsMeta,
        lockDelaySeconds.isAcceptableOrUnknown(
          data['lock_delay_seconds']!,
          _lockDelaySecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SecurityConfigData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SecurityConfigData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      pinHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_hash'],
      ),
      biometricEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}biometric_enabled'],
      )!,
      lockOnBackground: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}lock_on_background'],
      )!,
      lockDelaySeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lock_delay_seconds'],
      )!,
    );
  }

  @override
  $SecurityConfigsTable createAlias(String alias) {
    return $SecurityConfigsTable(attachedDatabase, alias);
  }
}

class SecurityConfigData extends DataClass
    implements Insertable<SecurityConfigData> {
  /// Singleton row — always id = 1.
  final int id;
  final String? pinHash;
  final bool biometricEnabled;
  final bool lockOnBackground;
  final int lockDelaySeconds;
  const SecurityConfigData({
    required this.id,
    this.pinHash,
    required this.biometricEnabled,
    required this.lockOnBackground,
    required this.lockDelaySeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || pinHash != null) {
      map['pin_hash'] = Variable<String>(pinHash);
    }
    map['biometric_enabled'] = Variable<bool>(biometricEnabled);
    map['lock_on_background'] = Variable<bool>(lockOnBackground);
    map['lock_delay_seconds'] = Variable<int>(lockDelaySeconds);
    return map;
  }

  SecurityConfigsCompanion toCompanion(bool nullToAbsent) {
    return SecurityConfigsCompanion(
      id: Value(id),
      pinHash: pinHash == null && nullToAbsent
          ? const Value.absent()
          : Value(pinHash),
      biometricEnabled: Value(biometricEnabled),
      lockOnBackground: Value(lockOnBackground),
      lockDelaySeconds: Value(lockDelaySeconds),
    );
  }

  factory SecurityConfigData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SecurityConfigData(
      id: serializer.fromJson<int>(json['id']),
      pinHash: serializer.fromJson<String?>(json['pinHash']),
      biometricEnabled: serializer.fromJson<bool>(json['biometricEnabled']),
      lockOnBackground: serializer.fromJson<bool>(json['lockOnBackground']),
      lockDelaySeconds: serializer.fromJson<int>(json['lockDelaySeconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'pinHash': serializer.toJson<String?>(pinHash),
      'biometricEnabled': serializer.toJson<bool>(biometricEnabled),
      'lockOnBackground': serializer.toJson<bool>(lockOnBackground),
      'lockDelaySeconds': serializer.toJson<int>(lockDelaySeconds),
    };
  }

  SecurityConfigData copyWith({
    int? id,
    Value<String?> pinHash = const Value.absent(),
    bool? biometricEnabled,
    bool? lockOnBackground,
    int? lockDelaySeconds,
  }) => SecurityConfigData(
    id: id ?? this.id,
    pinHash: pinHash.present ? pinHash.value : this.pinHash,
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    lockOnBackground: lockOnBackground ?? this.lockOnBackground,
    lockDelaySeconds: lockDelaySeconds ?? this.lockDelaySeconds,
  );
  SecurityConfigData copyWithCompanion(SecurityConfigsCompanion data) {
    return SecurityConfigData(
      id: data.id.present ? data.id.value : this.id,
      pinHash: data.pinHash.present ? data.pinHash.value : this.pinHash,
      biometricEnabled: data.biometricEnabled.present
          ? data.biometricEnabled.value
          : this.biometricEnabled,
      lockOnBackground: data.lockOnBackground.present
          ? data.lockOnBackground.value
          : this.lockOnBackground,
      lockDelaySeconds: data.lockDelaySeconds.present
          ? data.lockDelaySeconds.value
          : this.lockDelaySeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SecurityConfigData(')
          ..write('id: $id, ')
          ..write('pinHash: $pinHash, ')
          ..write('biometricEnabled: $biometricEnabled, ')
          ..write('lockOnBackground: $lockOnBackground, ')
          ..write('lockDelaySeconds: $lockDelaySeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pinHash,
    biometricEnabled,
    lockOnBackground,
    lockDelaySeconds,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SecurityConfigData &&
          other.id == this.id &&
          other.pinHash == this.pinHash &&
          other.biometricEnabled == this.biometricEnabled &&
          other.lockOnBackground == this.lockOnBackground &&
          other.lockDelaySeconds == this.lockDelaySeconds);
}

class SecurityConfigsCompanion extends UpdateCompanion<SecurityConfigData> {
  final Value<int> id;
  final Value<String?> pinHash;
  final Value<bool> biometricEnabled;
  final Value<bool> lockOnBackground;
  final Value<int> lockDelaySeconds;
  const SecurityConfigsCompanion({
    this.id = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.biometricEnabled = const Value.absent(),
    this.lockOnBackground = const Value.absent(),
    this.lockDelaySeconds = const Value.absent(),
  });
  SecurityConfigsCompanion.insert({
    this.id = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.biometricEnabled = const Value.absent(),
    this.lockOnBackground = const Value.absent(),
    this.lockDelaySeconds = const Value.absent(),
  });
  static Insertable<SecurityConfigData> custom({
    Expression<int>? id,
    Expression<String>? pinHash,
    Expression<bool>? biometricEnabled,
    Expression<bool>? lockOnBackground,
    Expression<int>? lockDelaySeconds,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pinHash != null) 'pin_hash': pinHash,
      if (biometricEnabled != null) 'biometric_enabled': biometricEnabled,
      if (lockOnBackground != null) 'lock_on_background': lockOnBackground,
      if (lockDelaySeconds != null) 'lock_delay_seconds': lockDelaySeconds,
    });
  }

  SecurityConfigsCompanion copyWith({
    Value<int>? id,
    Value<String?>? pinHash,
    Value<bool>? biometricEnabled,
    Value<bool>? lockOnBackground,
    Value<int>? lockDelaySeconds,
  }) {
    return SecurityConfigsCompanion(
      id: id ?? this.id,
      pinHash: pinHash ?? this.pinHash,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      lockOnBackground: lockOnBackground ?? this.lockOnBackground,
      lockDelaySeconds: lockDelaySeconds ?? this.lockDelaySeconds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (pinHash.present) {
      map['pin_hash'] = Variable<String>(pinHash.value);
    }
    if (biometricEnabled.present) {
      map['biometric_enabled'] = Variable<bool>(biometricEnabled.value);
    }
    if (lockOnBackground.present) {
      map['lock_on_background'] = Variable<bool>(lockOnBackground.value);
    }
    if (lockDelaySeconds.present) {
      map['lock_delay_seconds'] = Variable<int>(lockDelaySeconds.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SecurityConfigsCompanion(')
          ..write('id: $id, ')
          ..write('pinHash: $pinHash, ')
          ..write('biometricEnabled: $biometricEnabled, ')
          ..write('lockOnBackground: $lockOnBackground, ')
          ..write('lockDelaySeconds: $lockDelaySeconds')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $MonthlyAggregatesTable monthlyAggregates =
      $MonthlyAggregatesTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $SecurityConfigsTable securityConfigs = $SecurityConfigsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    categories,
    transactions,
    monthlyAggregates,
    budgets,
    securityConfigs,
  ];
}

typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      required String id,
      required String name,
      required AccountType type,
      Value<String> currency,
      Value<int> openingBalance,
      Value<int> currentBalance,
      Value<bool> isArchived,
      Value<int> sortOrder,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<AccountType> type,
      Value<String> currency,
      Value<int> openingBalance,
      Value<int> currentBalance,
      Value<bool> isArchived,
      Value<int> sortOrder,
      Value<String> createdAt,
      Value<int> rowid,
    });

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, AccountData> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<TransactionData>>
  _debitTransactionsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(
      db.accounts.id,
      db.transactions.debitAccountId,
    ),
  );

  $$TransactionsTableProcessedTableManager get debitTransactions {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.debitAccountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_debitTransactionsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<TransactionData>>
  _creditTransactionsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(
      db.accounts.id,
      db.transactions.creditAccountId,
    ),
  );

  $$TransactionsTableProcessedTableManager get creditTransactions {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter(
          (f) => f.creditAccountId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_creditTransactionsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $MonthlyAggregatesTable,
    List<MonthlyAggregateData>
  >
  _monthlyAggregatesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.monthlyAggregates,
        aliasName: $_aliasNameGenerator(
          db.accounts.id,
          db.monthlyAggregates.accountId,
        ),
      );

  $$MonthlyAggregatesTableProcessedTableManager get monthlyAggregatesRefs {
    final manager = $$MonthlyAggregatesTableTableManager(
      $_db,
      $_db.monthlyAggregates,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _monthlyAggregatesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AccountType, AccountType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> debitTransactions(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.debitAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> creditTransactions(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.creditAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> monthlyAggregatesRefs(
    Expression<bool> Function($$MonthlyAggregatesTableFilterComposer f) f,
  ) {
    final $$MonthlyAggregatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.monthlyAggregates,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MonthlyAggregatesTableFilterComposer(
            $db: $db,
            $table: $db.monthlyAggregates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AccountType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> debitTransactions<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.debitAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> creditTransactions<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.creditAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> monthlyAggregatesRefs<T extends Object>(
    Expression<T> Function($$MonthlyAggregatesTableAnnotationComposer a) f,
  ) {
    final $$MonthlyAggregatesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.monthlyAggregates,
          getReferencedColumn: (t) => t.accountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$MonthlyAggregatesTableAnnotationComposer(
                $db: $db,
                $table: $db.monthlyAggregates,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          AccountData,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (AccountData, $$AccountsTableReferences),
          AccountData,
          PrefetchHooks Function({
            bool debitTransactions,
            bool creditTransactions,
            bool monthlyAggregatesRefs,
          })
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<AccountType> type = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<int> openingBalance = const Value.absent(),
                Value<int> currentBalance = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                name: name,
                type: type,
                currency: currency,
                openingBalance: openingBalance,
                currentBalance: currentBalance,
                isArchived: isArchived,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required AccountType type,
                Value<String> currency = const Value.absent(),
                Value<int> openingBalance = const Value.absent(),
                Value<int> currentBalance = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                name: name,
                type: type,
                currency: currency,
                openingBalance: openingBalance,
                currentBalance: currentBalance,
                isArchived: isArchived,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                debitTransactions = false,
                creditTransactions = false,
                monthlyAggregatesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (debitTransactions) db.transactions,
                    if (creditTransactions) db.transactions,
                    if (monthlyAggregatesRefs) db.monthlyAggregates,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (debitTransactions)
                        await $_getPrefetchedData<
                          AccountData,
                          $AccountsTable,
                          TransactionData
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._debitTransactionsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).debitTransactions,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.debitAccountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (creditTransactions)
                        await $_getPrefetchedData<
                          AccountData,
                          $AccountsTable,
                          TransactionData
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._creditTransactionsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).creditTransactions,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.creditAccountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (monthlyAggregatesRefs)
                        await $_getPrefetchedData<
                          AccountData,
                          $AccountsTable,
                          MonthlyAggregateData
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._monthlyAggregatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).monthlyAggregatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      AccountData,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (AccountData, $$AccountsTableReferences),
      AccountData,
      PrefetchHooks Function({
        bool debitTransactions,
        bool creditTransactions,
        bool monthlyAggregatesRefs,
      })
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      required String id,
      required String name,
      Value<String?> parentId,
      required CategoryType type,
      Value<int?> iconCode,
      Value<String?> icon,
      Value<String?> colorHex,
      Value<bool> isSystem,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> parentId,
      Value<CategoryType> type,
      Value<int?> iconCode,
      Value<String?> icon,
      Value<String?> colorHex,
      Value<bool> isSystem,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, CategoryData> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _parentIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(db.categories.parentId, db.categories.id),
      );

  $$CategoriesTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<TransactionData>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(
      db.categories.id,
      db.transactions.categoryId,
    ),
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BudgetsTable, List<BudgetData>> _budgetsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.budgets,
    aliasName: $_aliasNameGenerator(db.categories.id, db.budgets.categoryId),
  );

  $$BudgetsTableProcessedTableManager get budgetsRefs {
    final manager = $$BudgetsTableTableManager(
      $_db,
      $_db.budgets,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_budgetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CategoryType, CategoryType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get iconCode => $composableBuilder(
    column: $table.iconCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get parentId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> budgetsRefs(
    Expression<bool> Function($$BudgetsTableFilterComposer f) f,
  ) {
    final $$BudgetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableFilterComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iconCode => $composableBuilder(
    column: $table.iconCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get parentId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CategoryType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get iconCode =>
      $composableBuilder(column: $table.iconCode, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<bool> get isSystem =>
      $composableBuilder(column: $table.isSystem, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get parentId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> budgetsRefs<T extends Object>(
    Expression<T> Function($$BudgetsTableAnnotationComposer a) f,
  ) {
    final $$BudgetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryData,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (CategoryData, $$CategoriesTableReferences),
          CategoryData,
          PrefetchHooks Function({
            bool parentId,
            bool transactionsRefs,
            bool budgetsRefs,
          })
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<CategoryType> type = const Value.absent(),
                Value<int?> iconCode = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                parentId: parentId,
                type: type,
                iconCode: iconCode,
                icon: icon,
                colorHex: colorHex,
                isSystem: isSystem,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> parentId = const Value.absent(),
                required CategoryType type,
                Value<int?> iconCode = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                parentId: parentId,
                type: type,
                iconCode: iconCode,
                icon: icon,
                colorHex: colorHex,
                isSystem: isSystem,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                parentId = false,
                transactionsRefs = false,
                budgetsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionsRefs) db.transactions,
                    if (budgetsRefs) db.budgets,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (parentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.parentId,
                                    referencedTable: $$CategoriesTableReferences
                                        ._parentIdTable(db),
                                    referencedColumn:
                                        $$CategoriesTableReferences
                                            ._parentIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionsRefs)
                        await $_getPrefetchedData<
                          CategoryData,
                          $CategoriesTable,
                          TransactionData
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (budgetsRefs)
                        await $_getPrefetchedData<
                          CategoryData,
                          $CategoriesTable,
                          BudgetData
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._budgetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).budgetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryData,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (CategoryData, $$CategoriesTableReferences),
      CategoryData,
      PrefetchHooks Function({
        bool parentId,
        bool transactionsRefs,
        bool budgetsRefs,
      })
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required TransactionType type,
      required int amount,
      required String debitAccountId,
      required String creditAccountId,
      Value<String?> categoryId,
      Value<String> description,
      Value<String?> notes,
      required String transactionDate,
      required String createdAt,
      Value<bool> isBookmarked,
      Value<String?> receiptImagePath,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<TransactionType> type,
      Value<int> amount,
      Value<String> debitAccountId,
      Value<String> creditAccountId,
      Value<String?> categoryId,
      Value<String> description,
      Value<String?> notes,
      Value<String> transactionDate,
      Value<String> createdAt,
      Value<bool> isBookmarked,
      Value<String?> receiptImagePath,
      Value<int> rowid,
    });

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, TransactionData> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _debitAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
        $_aliasNameGenerator(db.transactions.debitAccountId, db.accounts.id),
      );

  $$AccountsTableProcessedTableManager get debitAccountId {
    final $_column = $_itemColumn<String>('debit_account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_debitAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _creditAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
        $_aliasNameGenerator(db.transactions.creditAccountId, db.accounts.id),
      );

  $$AccountsTableProcessedTableManager get creditAccountId {
    final $_column = $_itemColumn<String>('credit_account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_creditAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(db.transactions.categoryId, db.categories.id),
      );

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TransactionType, TransactionType, String>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBookmarked => $composableBuilder(
    column: $table.isBookmarked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptImagePath => $composableBuilder(
    column: $table.receiptImagePath,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get debitAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.debitAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get creditAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creditAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBookmarked => $composableBuilder(
    column: $table.isBookmarked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptImagePath => $composableBuilder(
    column: $table.receiptImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get debitAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.debitAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get creditAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creditAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransactionType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isBookmarked => $composableBuilder(
    column: $table.isBookmarked,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptImagePath => $composableBuilder(
    column: $table.receiptImagePath,
    builder: (column) => column,
  );

  $$AccountsTableAnnotationComposer get debitAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.debitAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get creditAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creditAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionData,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (TransactionData, $$TransactionsTableReferences),
          TransactionData,
          PrefetchHooks Function({
            bool debitAccountId,
            bool creditAccountId,
            bool categoryId,
          })
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<TransactionType> type = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> debitAccountId = const Value.absent(),
                Value<String> creditAccountId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> transactionDate = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<bool> isBookmarked = const Value.absent(),
                Value<String?> receiptImagePath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                type: type,
                amount: amount,
                debitAccountId: debitAccountId,
                creditAccountId: creditAccountId,
                categoryId: categoryId,
                description: description,
                notes: notes,
                transactionDate: transactionDate,
                createdAt: createdAt,
                isBookmarked: isBookmarked,
                receiptImagePath: receiptImagePath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required TransactionType type,
                required int amount,
                required String debitAccountId,
                required String creditAccountId,
                Value<String?> categoryId = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required String transactionDate,
                required String createdAt,
                Value<bool> isBookmarked = const Value.absent(),
                Value<String?> receiptImagePath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                type: type,
                amount: amount,
                debitAccountId: debitAccountId,
                creditAccountId: creditAccountId,
                categoryId: categoryId,
                description: description,
                notes: notes,
                transactionDate: transactionDate,
                createdAt: createdAt,
                isBookmarked: isBookmarked,
                receiptImagePath: receiptImagePath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                debitAccountId = false,
                creditAccountId = false,
                categoryId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (debitAccountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.debitAccountId,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._debitAccountIdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._debitAccountIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (creditAccountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.creditAccountId,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._creditAccountIdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._creditAccountIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (categoryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryId,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._categoryIdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._categoryIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionData,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (TransactionData, $$TransactionsTableReferences),
      TransactionData,
      PrefetchHooks Function({
        bool debitAccountId,
        bool creditAccountId,
        bool categoryId,
      })
    >;
typedef $$MonthlyAggregatesTableCreateCompanionBuilder =
    MonthlyAggregatesCompanion Function({
      required String accountId,
      required int year,
      required int month,
      Value<int> totalIncome,
      Value<int> totalExpense,
      Value<int> rowid,
    });
typedef $$MonthlyAggregatesTableUpdateCompanionBuilder =
    MonthlyAggregatesCompanion Function({
      Value<String> accountId,
      Value<int> year,
      Value<int> month,
      Value<int> totalIncome,
      Value<int> totalExpense,
      Value<int> rowid,
    });

final class $$MonthlyAggregatesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $MonthlyAggregatesTable,
          MonthlyAggregateData
        > {
  $$MonthlyAggregatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
        $_aliasNameGenerator(db.monthlyAggregates.accountId, db.accounts.id),
      );

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MonthlyAggregatesTableFilterComposer
    extends Composer<_$AppDatabase, $MonthlyAggregatesTable> {
  $$MonthlyAggregatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalIncome => $composableBuilder(
    column: $table.totalIncome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalExpense => $composableBuilder(
    column: $table.totalExpense,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MonthlyAggregatesTableOrderingComposer
    extends Composer<_$AppDatabase, $MonthlyAggregatesTable> {
  $$MonthlyAggregatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalIncome => $composableBuilder(
    column: $table.totalIncome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalExpense => $composableBuilder(
    column: $table.totalExpense,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MonthlyAggregatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MonthlyAggregatesTable> {
  $$MonthlyAggregatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get totalIncome => $composableBuilder(
    column: $table.totalIncome,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalExpense => $composableBuilder(
    column: $table.totalExpense,
    builder: (column) => column,
  );

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MonthlyAggregatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MonthlyAggregatesTable,
          MonthlyAggregateData,
          $$MonthlyAggregatesTableFilterComposer,
          $$MonthlyAggregatesTableOrderingComposer,
          $$MonthlyAggregatesTableAnnotationComposer,
          $$MonthlyAggregatesTableCreateCompanionBuilder,
          $$MonthlyAggregatesTableUpdateCompanionBuilder,
          (MonthlyAggregateData, $$MonthlyAggregatesTableReferences),
          MonthlyAggregateData,
          PrefetchHooks Function({bool accountId})
        > {
  $$MonthlyAggregatesTableTableManager(
    _$AppDatabase db,
    $MonthlyAggregatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MonthlyAggregatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MonthlyAggregatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MonthlyAggregatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<int> month = const Value.absent(),
                Value<int> totalIncome = const Value.absent(),
                Value<int> totalExpense = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MonthlyAggregatesCompanion(
                accountId: accountId,
                year: year,
                month: month,
                totalIncome: totalIncome,
                totalExpense: totalExpense,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required int year,
                required int month,
                Value<int> totalIncome = const Value.absent(),
                Value<int> totalExpense = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MonthlyAggregatesCompanion.insert(
                accountId: accountId,
                year: year,
                month: month,
                totalIncome: totalIncome,
                totalExpense: totalExpense,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MonthlyAggregatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable:
                                    $$MonthlyAggregatesTableReferences
                                        ._accountIdTable(db),
                                referencedColumn:
                                    $$MonthlyAggregatesTableReferences
                                        ._accountIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MonthlyAggregatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MonthlyAggregatesTable,
      MonthlyAggregateData,
      $$MonthlyAggregatesTableFilterComposer,
      $$MonthlyAggregatesTableOrderingComposer,
      $$MonthlyAggregatesTableAnnotationComposer,
      $$MonthlyAggregatesTableCreateCompanionBuilder,
      $$MonthlyAggregatesTableUpdateCompanionBuilder,
      (MonthlyAggregateData, $$MonthlyAggregatesTableReferences),
      MonthlyAggregateData,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$BudgetsTableCreateCompanionBuilder =
    BudgetsCompanion Function({
      required String id,
      required String categoryId,
      required int year,
      required int month,
      required int limitPaise,
      Value<int> rowid,
    });
typedef $$BudgetsTableUpdateCompanionBuilder =
    BudgetsCompanion Function({
      Value<String> id,
      Value<String> categoryId,
      Value<int> year,
      Value<int> month,
      Value<int> limitPaise,
      Value<int> rowid,
    });

final class $$BudgetsTableReferences
    extends BaseReferences<_$AppDatabase, $BudgetsTable, BudgetData> {
  $$BudgetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(db.budgets.categoryId, db.categories.id),
      );

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get limitPaise => $composableBuilder(
    column: $table.limitPaise,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get limitPaise => $composableBuilder(
    column: $table.limitPaise,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get limitPaise => $composableBuilder(
    column: $table.limitPaise,
    builder: (column) => column,
  );

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetsTable,
          BudgetData,
          $$BudgetsTableFilterComposer,
          $$BudgetsTableOrderingComposer,
          $$BudgetsTableAnnotationComposer,
          $$BudgetsTableCreateCompanionBuilder,
          $$BudgetsTableUpdateCompanionBuilder,
          (BudgetData, $$BudgetsTableReferences),
          BudgetData,
          PrefetchHooks Function({bool categoryId})
        > {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<int> month = const Value.absent(),
                Value<int> limitPaise = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion(
                id: id,
                categoryId: categoryId,
                year: year,
                month: month,
                limitPaise: limitPaise,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String categoryId,
                required int year,
                required int month,
                required int limitPaise,
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion.insert(
                id: id,
                categoryId: categoryId,
                year: year,
                month: month,
                limitPaise: limitPaise,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BudgetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.categoryId,
                                referencedTable: $$BudgetsTableReferences
                                    ._categoryIdTable(db),
                                referencedColumn: $$BudgetsTableReferences
                                    ._categoryIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetsTable,
      BudgetData,
      $$BudgetsTableFilterComposer,
      $$BudgetsTableOrderingComposer,
      $$BudgetsTableAnnotationComposer,
      $$BudgetsTableCreateCompanionBuilder,
      $$BudgetsTableUpdateCompanionBuilder,
      (BudgetData, $$BudgetsTableReferences),
      BudgetData,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$SecurityConfigsTableCreateCompanionBuilder =
    SecurityConfigsCompanion Function({
      Value<int> id,
      Value<String?> pinHash,
      Value<bool> biometricEnabled,
      Value<bool> lockOnBackground,
      Value<int> lockDelaySeconds,
    });
typedef $$SecurityConfigsTableUpdateCompanionBuilder =
    SecurityConfigsCompanion Function({
      Value<int> id,
      Value<String?> pinHash,
      Value<bool> biometricEnabled,
      Value<bool> lockOnBackground,
      Value<int> lockDelaySeconds,
    });

class $$SecurityConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $SecurityConfigsTable> {
  $$SecurityConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get biometricEnabled => $composableBuilder(
    column: $table.biometricEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lockOnBackground => $composableBuilder(
    column: $table.lockOnBackground,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lockDelaySeconds => $composableBuilder(
    column: $table.lockDelaySeconds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SecurityConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $SecurityConfigsTable> {
  $$SecurityConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get biometricEnabled => $composableBuilder(
    column: $table.biometricEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lockOnBackground => $composableBuilder(
    column: $table.lockOnBackground,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lockDelaySeconds => $composableBuilder(
    column: $table.lockDelaySeconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SecurityConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SecurityConfigsTable> {
  $$SecurityConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pinHash =>
      $composableBuilder(column: $table.pinHash, builder: (column) => column);

  GeneratedColumn<bool> get biometricEnabled => $composableBuilder(
    column: $table.biometricEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get lockOnBackground => $composableBuilder(
    column: $table.lockOnBackground,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lockDelaySeconds => $composableBuilder(
    column: $table.lockDelaySeconds,
    builder: (column) => column,
  );
}

class $$SecurityConfigsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SecurityConfigsTable,
          SecurityConfigData,
          $$SecurityConfigsTableFilterComposer,
          $$SecurityConfigsTableOrderingComposer,
          $$SecurityConfigsTableAnnotationComposer,
          $$SecurityConfigsTableCreateCompanionBuilder,
          $$SecurityConfigsTableUpdateCompanionBuilder,
          (
            SecurityConfigData,
            BaseReferences<
              _$AppDatabase,
              $SecurityConfigsTable,
              SecurityConfigData
            >,
          ),
          SecurityConfigData,
          PrefetchHooks Function()
        > {
  $$SecurityConfigsTableTableManager(
    _$AppDatabase db,
    $SecurityConfigsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SecurityConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SecurityConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SecurityConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> pinHash = const Value.absent(),
                Value<bool> biometricEnabled = const Value.absent(),
                Value<bool> lockOnBackground = const Value.absent(),
                Value<int> lockDelaySeconds = const Value.absent(),
              }) => SecurityConfigsCompanion(
                id: id,
                pinHash: pinHash,
                biometricEnabled: biometricEnabled,
                lockOnBackground: lockOnBackground,
                lockDelaySeconds: lockDelaySeconds,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> pinHash = const Value.absent(),
                Value<bool> biometricEnabled = const Value.absent(),
                Value<bool> lockOnBackground = const Value.absent(),
                Value<int> lockDelaySeconds = const Value.absent(),
              }) => SecurityConfigsCompanion.insert(
                id: id,
                pinHash: pinHash,
                biometricEnabled: biometricEnabled,
                lockOnBackground: lockOnBackground,
                lockDelaySeconds: lockDelaySeconds,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SecurityConfigsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SecurityConfigsTable,
      SecurityConfigData,
      $$SecurityConfigsTableFilterComposer,
      $$SecurityConfigsTableOrderingComposer,
      $$SecurityConfigsTableAnnotationComposer,
      $$SecurityConfigsTableCreateCompanionBuilder,
      $$SecurityConfigsTableUpdateCompanionBuilder,
      (
        SecurityConfigData,
        BaseReferences<
          _$AppDatabase,
          $SecurityConfigsTable,
          SecurityConfigData
        >,
      ),
      SecurityConfigData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$MonthlyAggregatesTableTableManager get monthlyAggregates =>
      $$MonthlyAggregatesTableTableManager(_db, _db.monthlyAggregates);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$SecurityConfigsTableTableManager get securityConfigs =>
      $$SecurityConfigsTableTableManager(_db, _db.securityConfigs);
}
