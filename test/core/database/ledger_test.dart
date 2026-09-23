import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finpal_pro/core/database/app_database.dart';
import 'package:finpal_pro/features/transactions/infrastructure/drift_transaction_repository.dart';

void main() {
  late AppDatabase db;
  late DriftTransactionRepository repo;

  group('ledger operations', () {
    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = DriftTransactionRepository(db);
      await _addAccounts(db);
    });

    tearDown(() => db.close());

    test(
      'income and expense affect their single account; transfers move money',
      () async {
        await repo.create(_entry('expense', TransactionType.expense, 1200));
        expect(await _balance(db, 'a'), 8800);
        await repo.create(_entry('income', TransactionType.income, 3000));
        expect(await _balance(db, 'a'), 11800);
        await repo.create(
          _entry('transfer', TransactionType.transfer, 2500, credit: 'b'),
        );
        expect(await _balance(db, 'a'), 9300);
        expect(await _balance(db, 'b'), 7500);
        final totals = await _totals(db, 'a', 6);
        expect(totals.totalIncome, 3000);
        expect(totals.totalExpense, 3700);
      },
    );

    test(
      'editing type, amount, accounts, month and text preserves entry identity',
      () async {
        await repo.create(_entry('edit', TransactionType.expense, 1200));
        await repo.toggleBookmark('edit', true);
        await repo.update(
          'edit',
          const TransactionsCompanion(
            type: Value(TransactionType.transfer),
            amount: Value(2700),
            debitAccountId: Value('b'),
            creditAccountId: Value('a'),
            description: Value('Revised entry'),
            notes: Value('Corrected note'),
            transactionDate: Value('2026-07-12'),
          ),
        );
        expect(await _balance(db, 'a'), 12700);
        expect(await _balance(db, 'b'), 2300);
        expect((await _totals(db, 'a', 6)).totalExpense, 0);
        expect((await _totals(db, 'a', 7)).totalIncome, 2700);
        expect((await _totals(db, 'b', 7)).totalExpense, 2700);
        final entries = await db.select(db.transactions).get();
        expect(entries, hasLength(1));
        expect(entries.single.id, 'edit');
        expect(entries.single.description, 'Revised entry');
        expect(entries.single.notes, 'Corrected note');
        expect(entries.single.isBookmarked, isTrue);
        expect(entries.single.createdAt, '2026-06-10T12:00:00');
      },
    );

    test(
      'failed edit rolls back the row, balances and monthly totals',
      () async {
        await repo.create(_entry('edit', TransactionType.expense, 1200));
        await expectLater(
          repo.update(
            'edit',
            const TransactionsCompanion(
              amount: Value(-100),
              description: Value('Invalid edit'),
            ),
          ),
          throwsArgumentError,
        );
        expect((await repo.findById('edit'))!.amount.subunits, 1200);
        expect((await repo.findById('edit'))!.description, 'Original entry');
        expect(await _balance(db, 'a'), 8800);
        expect((await _totals(db, 'a', 6)).totalExpense, 1200);
      },
    );

    test(
      'deleting income, expense and transfer reverses all ledger effects once',
      () async {
        for (final type in TransactionType.values) {
          await repo.create(
            _entry(
              type.name,
              type,
              1200,
              credit: type == TransactionType.transfer ? 'b' : 'a',
            ),
          );
        }
        for (final type in TransactionType.values) {
          await repo.delete(type.name);
          await repo.delete(type.name);
        }
        expect(await _balance(db, 'a'), 10000);
        expect(await _balance(db, 'b'), 5000);
        expect(await db.select(db.transactions).get(), isEmpty);
        for (final row in await db.select(db.monthlyAggregates).get()) {
          expect(row.totalIncome, 0);
          expect(row.totalExpense, 0);
        }
      },
    );
  });

  test(
    'v5 upgrade reconciles corrupt totals and indexes existing history',
    () async {
      final directory = await Directory.systemTemp.createTemp('finpal-ledger-');
      final file = File('${directory.path}/legacy.sqlite');
      var legacy = AppDatabase.forTesting(NativeDatabase(file));
      try {
        await _addAccounts(legacy);
        await legacy.customStatement('DROP TRIGGER transactions_ai');
        await legacy
            .into(legacy.transactions)
            .insert(_entry('legacy', TransactionType.expense, 1200));
        await legacy
            .into(legacy.monthlyAggregates)
            .insert(
              MonthlyAggregatesCompanion.insert(
                accountId: 'a',
                year: 2026,
                month: 6,
                totalExpense: const Value(9999),
              ),
            );
        await legacy.customStatement('PRAGMA user_version = 5');
        await legacy.close();
        legacy = AppDatabase.forTesting(NativeDatabase(file));

        expect(await _balance(legacy, 'a'), 8800);
        expect(await _balance(legacy, 'b'), 5000);
        expect((await _totals(legacy, 'a', 6)).totalExpense, 1200);
        final matches = await legacy
            .customSelect(
              "SELECT rowid FROM transactions_fts WHERE transactions_fts MATCH 'Original'",
            )
            .get();
        expect(matches, hasLength(1));
      } finally {
        await legacy.close();
        await directory.delete(recursive: true);
      }
    },
  );
}

Future<void> _addAccounts(AppDatabase db) async {
  for (final (id, balance) in [('a', 10000), ('b', 5000)]) {
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: id,
            name: id,
            type: AccountType.bank,
            openingBalance: Value(balance),
            currentBalance: Value(balance),
            createdAt: '2026-06-10T12:00:00',
          ),
        );
  }
}

TransactionsCompanion _entry(
  String id,
  TransactionType type,
  int amount, {
  String credit = 'a',
}) => TransactionsCompanion.insert(
  id: id,
  type: type,
  amount: amount,
  debitAccountId: 'a',
  creditAccountId: credit,
  description: const Value('Original entry'),
  transactionDate: '2026-06-10',
  createdAt: '2026-06-10T12:00:00',
);

Future<int> _balance(AppDatabase db, String id) async => (await (db.select(
  db.accounts,
)..where((a) => a.id.equals(id))).getSingle()).currentBalance;

Future<MonthlyAggregateData> _totals(
  AppDatabase db,
  String accountId,
  int month,
) =>
    (db.select(db.monthlyAggregates)..where(
          (m) =>
              m.accountId.equals(accountId) &
              m.year.equals(2026) &
              m.month.equals(month),
        ))
        .getSingle();
