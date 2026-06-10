import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'migrations/migration_strategy.dart';

part 'app_database.g.dart';

// ─── Enums ───────────────────────────────────────────────────────────────────

enum AccountType { cash, bank, savings, creditCard, investment }

enum TransactionType { income, expense, transfer }

enum CategoryType { income, expense, both }

// ─── Tables ──────────────────────────────────────────────────────────────────

@DataClassName('AccountData')
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get type => textEnum<AccountType>()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();

  /// Amount in smallest currency unit (paise for INR). Always ≥ 0 for assets.
  IntColumn get openingBalance => integer().withDefault(const Constant(0))();

  /// Maintained by transaction writes — never compute from transaction history.
  IntColumn get currentBalance => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CategoryData')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();

  /// Null = root category. Non-null = sub-category (PBI-011).
  TextColumn get parentId => text().nullable().references(Categories, #id)();
  TextColumn get type => textEnum<CategoryType>()();
  IntColumn get iconCode => integer().nullable()();
  TextColumn get colorHex => text().nullable()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionData')
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => textEnum<TransactionType>()();

  /// Amount in smallest currency unit (paise). Always > 0.
  IntColumn get amount => integer()();

  /// Account whose balance decreases (expense) or is the source (transfer).
  @ReferenceName('debitTransactions')
  TextColumn get debitAccountId => text().references(Accounts, #id)();

  /// Account whose balance increases (income) or is the destination (transfer).
  @ReferenceName('creditTransactions')
  TextColumn get creditAccountId => text().references(Accounts, #id)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get description =>
      text().withLength(min: 0, max: 255).withDefault(const Constant(''))();
  TextColumn get notes => text().withLength(min: 0, max: 1000).nullable()();
  TextColumn get transactionDate => text()(); // ISO-8601 date
  TextColumn get createdAt => text()();
  BoolColumn get isBookmarked => boolean().withDefault(const Constant(false))();

  /// Populated in Sprint 5 (PBI-015).
  TextColumn get receiptImagePath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MonthlyAggregateData')
class MonthlyAggregates extends Table {
  TextColumn get accountId => text().references(Accounts, #id)();
  IntColumn get year => integer()();
  IntColumn get month => integer()(); // 1–12
  IntColumn get totalIncome => integer().withDefault(const Constant(0))();
  IntColumn get totalExpense => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {accountId, year, month};
}

@DataClassName('SecurityConfigData')
class SecurityConfigs extends Table {
  /// Singleton row — always id = 1.
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get pinHash => text().nullable()();
  BoolColumn get biometricEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get lockOnBackground =>
      boolean().withDefault(const Constant(true))();
  IntColumn get lockDelaySeconds => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Database ────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Transactions,
    MonthlyAggregates,
    SecurityConfigs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'finpal_db');
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => buildMigrationStrategy(this);

  // ─── Transactions DAL ──────────────────────────────────────────────────────

  /// Atomic double-entry write: inserts transaction + updates both account
  /// balances + upserts monthly aggregate. Rolls back entirely on any error.
  Future<void> writeTransaction(
    TransactionsCompanion tx,
    String debitAccountId,
    String creditAccountId,
  ) => transaction(() async {
    await into(transactions).insert(tx);

    final amount = tx.amount.value;
    final date = DateTime.parse(tx.transactionDate.value);

    // Debit account: balance decreases by amount
    await (update(accounts)..where((a) => a.id.equals(debitAccountId))).write(
      AccountsCompanion.custom(
        currentBalance: accounts.currentBalance - Variable(amount),
      ),
    );

    // Credit account: balance increases by amount
    await (update(accounts)..where((a) => a.id.equals(creditAccountId))).write(
      AccountsCompanion.custom(
        currentBalance: accounts.currentBalance + Variable(amount),
      ),
    );

    // Pre-compute monthly aggregates
    await _upsertMonthlyAggregates(
      debitAccountId: debitAccountId,
      creditAccountId: creditAccountId,
      amount: amount,
      txType: tx.type.value,
      year: date.year,
      month: date.month,
    );
  });
  // FTS5 is kept in sync by the transactions_ai trigger in createFtsSchema().

  Future<void> _upsertMonthlyAggregates({
    required String debitAccountId,
    required String creditAccountId,
    required int amount,
    required TransactionType txType,
    required int year,
    required int month,
  }) async {
    switch (txType) {
      case TransactionType.income:
        await _addToAggregate(creditAccountId, year, month, income: amount);
      case TransactionType.expense:
        await _addToAggregate(debitAccountId, year, month, expense: amount);
      case TransactionType.transfer:
        await _addToAggregate(debitAccountId, year, month, expense: amount);
        await _addToAggregate(creditAccountId, year, month, income: amount);
    }
  }

  Future<void> _addToAggregate(
    String accountId,
    int year,
    int month, {
    int income = 0,
    int expense = 0,
  }) async {
    final existing =
        await (select(monthlyAggregates)..where(
              (m) =>
                  m.accountId.equals(accountId) &
                  m.year.equals(year) &
                  m.month.equals(month),
            ))
            .getSingleOrNull();

    if (existing == null) {
      await into(monthlyAggregates).insert(
        MonthlyAggregatesCompanion.insert(
          accountId: accountId,
          year: year,
          month: month,
          totalIncome: Value(income),
          totalExpense: Value(expense),
        ),
      );
    } else {
      await (update(monthlyAggregates)..where(
            (m) =>
                m.accountId.equals(accountId) &
                m.year.equals(year) &
                m.month.equals(month),
          ))
          .write(
            MonthlyAggregatesCompanion(
              totalIncome: Value(existing.totalIncome + income),
              totalExpense: Value(existing.totalExpense + expense),
            ),
          );
    }
  }

  /// FTS5 full-text search across description and notes.
  Future<List<TransactionData>> searchTransactions(String query) async {
    final escapedQuery = query.replaceAll('"', '""');
    final rows = await customSelect(
      'SELECT t.* FROM transactions t '
      'INNER JOIN transactions_fts fts ON t.rowid = fts.rowid '
      'WHERE transactions_fts MATCH ? '
      'ORDER BY rank',
      variables: [Variable.withString('"$escapedQuery"')],
      readsFrom: {transactions},
    ).get();

    return Future.wait(rows.map((r) => transactions.mapFromRow(r)));
  }

  /// One-time FTS5 virtual table + triggers creation (called in v1 migration).
  Future<void> createFtsSchema() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS transactions_fts USING fts5(
        description, notes,
        content=transactions,
        content_rowid=rowid
      )
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS transactions_ai
      AFTER INSERT ON transactions BEGIN
        INSERT INTO transactions_fts(rowid, description, notes)
        VALUES (new.rowid, new.description, new.notes);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS transactions_au
      AFTER UPDATE ON transactions BEGIN
        INSERT INTO transactions_fts(transactions_fts, rowid, description, notes)
        VALUES ('delete', old.rowid, old.description, old.notes);
        INSERT INTO transactions_fts(rowid, description, notes)
        VALUES (new.rowid, new.description, new.notes);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS transactions_ad
      AFTER DELETE ON transactions BEGIN
        INSERT INTO transactions_fts(transactions_fts, rowid, description, notes)
        VALUES ('delete', old.rowid, old.description, old.notes);
      END
    ''');
  }
}
