import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:finpal_pro/core/database/app_database.dart';
import 'package:finpal_pro/features/search/domain/search_statistics.dart';
import 'package:finpal_pro/features/transactions/domain/transaction.dart';
import 'package:finpal_pro/features/transactions/domain/transaction_search_filter.dart';
import 'package:finpal_pro/features/transactions/infrastructure/drift_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftTransactionRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftTransactionRepository(db);
    for (final id in ['bank', 'cash', 'other']) {
      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: id,
              name: id,
              type: AccountType.bank,
              createdAt: '2026-09-01',
            ),
          );
    }
    Future<void> add(
      String id,
      String description,
      String notes,
      String date,
      int amount,
      TransactionType type,
      String debit,
      String credit,
      String? category,
    ) {
      return repo.create(
        TransactionsCompanion.insert(
          id: id,
          type: type,
          amount: amount,
          debitAccountId: debit,
          creditAccountId: credit,
          categoryId: Value(category),
          description: Value(description),
          notes: Value(notes),
          transactionDate: date,
          createdAt: '${date}T12:00:00',
        ),
      );
    }

    await add(
      'old',
      'Coffee at café',
      'travel receipt',
      '2023-01-01',
      12000,
      TransactionType.expense,
      'bank',
      'cash',
      'cat-food',
    );
    await add(
      'income',
      'Coffee refund',
      'returned order',
      '2026-09-15',
      50000,
      TransactionType.income,
      'other',
      'bank',
      'cat-salary',
    );
    await add(
      'notes',
      'Train ticket',
      'coffee receipt',
      '2026-09-16',
      18000,
      TransactionType.expense,
      'cash',
      'other',
      'cat-transport',
    );
    await add(
      'transfer',
      'Move money',
      'coffee budget',
      '2026-09-17',
      30000,
      TransactionType.transfer,
      'bank',
      'cash',
      null,
    );
    await add(
      'unrelated',
      'Rent',
      '',
      '2026-09-16',
      90000,
      TransactionType.expense,
      'other',
      'cash',
      'cat-bills',
    );
  });

  tearDown(() => db.close());

  Future<List<String>> ids(TransactionSearchFilter filter) async =>
      (await repo.watchSearch(filter).first).map((tx) => tx.id).toList();

  test(
    'searches all history and matches words across description and notes',
    () async {
      expect(await ids(const TransactionSearchFilter()), [
        'transfer',
        'notes',
        'unrelated',
        'income',
        'old',
      ]);
      expect(await ids(const TransactionSearchFilter(query: 'receipt coff')), [
        'notes',
        'old',
      ]);
      expect(await ids(const TransactionSearchFilter(query: 'café')), ['old']);
    },
  );

  test(
    'FTS operators, quotes and punctuation are literal safe input',
    () async {
      expect(await ids(const TransactionSearchFilter(query: '"coffee"')), [
        'transfer',
        'notes',
        'income',
        'old',
      ]);
      expect(
        await ids(const TransactionSearchFilter(query: 'coffee OR rent')),
        isEmpty,
      );
      expect(
        await ids(const TransactionSearchFilter(query: '" ) * - :')),
        isEmpty,
      );
      expect(
        await ids(
          const TransactionSearchFilter(
            query: "coffee'; DROP TABLE transactions; --",
          ),
        ),
        isEmpty,
      );
      expect(await ids(const TransactionSearchFilter()), hasLength(5));
    },
  );

  test(
    'combines all filters with inclusive dates and exact paise bounds',
    () async {
      expect(
        await ids(
          TransactionSearchFilter(
            query: 'coffee',
            from: DateTime(2026, 9, 16),
            to: DateTime(2026, 9, 16),
            accountIds: {'cash'},
            categoryIds: {'cat-transport'},
            type: TransactionType.expense,
            minAmount: 18000,
            maxAmount: 18000,
          ),
        ),
        ['notes'],
      );
      expect(
        await ids(
          const TransactionSearchFilter(minAmount: 12000, maxAmount: 18000),
        ),
        ['notes', 'old'],
      );
      expect(
        await ids(const TransactionSearchFilter(categoryIds: {'cat-food'})),
        ['old'],
      );
      expect(
        await ids(const TransactionSearchFilter(type: TransactionType.income)),
        ['income'],
      );
    },
  );

  test(
    'account filter includes both transfer endpoints and archived history',
    () async {
      await (db.update(db.accounts)
            ..where((account) => account.id.equals('bank')))
          .write(const AccountsCompanion(isArchived: Value(true)));
      expect(await ids(const TransactionSearchFilter(accountIds: {'bank'})), [
        'transfer',
        'income',
        'old',
      ]);
      expect(
        await ids(
          const TransactionSearchFilter(
            accountIds: {'cash'},
            type: TransactionType.transfer,
          ),
        ),
        ['transfer'],
      );
    },
  );

  test(
    'multi-select ORs each selection and combines the filter groups',
    () async {
      expect(
        await ids(
          const TransactionSearchFilter(
            accountIds: {'bank', 'other'},
            categoryIds: {'cat-food', 'cat-transport'},
            type: TransactionType.expense,
          ),
        ),
        ['notes', 'old'],
      );
      expect(
        await ids(
          const TransactionSearchFilter(
            accountIds: {'bank'},
            categoryIds: {'cat-food', 'cat-transport'},
          ),
        ),
        ['old'],
      );
    },
  );

  test('search stream and FTS stay in sync after edits and deletion', () async {
    final stream = StreamIterator<List<FinTransaction>>(
      repo.watchSearch(const TransactionSearchFilter(query: 'travel')),
    );
    try {
      expect(await stream.moveNext(), isTrue);
      expect(stream.current.map((tx) => tx.id), ['old']);
      await (db.update(db.transactions)..where((tx) => tx.id.equals('old')))
          .write(const TransactionsCompanion(notes: Value('hotel')));
      expect(await stream.moveNext(), isTrue);
      expect(stream.current, isEmpty);
      expect(await ids(const TransactionSearchFilter(query: 'hotel')), ['old']);
      await repo.delete('old');
      expect(await ids(const TransactionSearchFilter(query: 'hotel')), isEmpty);
    } finally {
      await stream.cancel();
    }
  });

  test(
    'statistics use only matching rows and exclude transfers from net',
    () async {
      final all = SearchStatistics.fromTransactions(
        await repo
            .watchSearch(const TransactionSearchFilter(query: 'coffee'))
            .first,
      );
      expect(all.income, 50000);
      expect(all.expense, 30000);
      expect(all.transfers, 30000);
      expect(all.net, 20000);
      expect(all.expensesByCategory, {
        'cat-food': 12000,
        'cat-transport': 18000,
      });

      final filtered = SearchStatistics.fromTransactions(
        await repo
            .watchSearch(
              const TransactionSearchFilter(query: 'coffee', maxAmount: 18000),
            )
            .first,
      );
      expect(filtered.income, 0);
      expect(filtered.expense, 30000);
      expect(filtered.net, -30000);
      expect(filtered.transfers, 0);
      final empty = SearchStatistics.fromTransactions([]);
      expect(empty.net, 0);
      expect(empty.expensesByCategory, isEmpty);
    },
  );

  test(
    'searches a 10000-row history without truncating matching results',
    () async {
      await db.batch((batch) {
        batch.insertAll(
          db.transactions,
          List.generate(10000, (index) {
            return TransactionsCompanion.insert(
              id: 'bulk-$index',
              type: TransactionType.expense,
              amount: 5000,
              debitAccountId: 'bank',
              creditAccountId: 'cash',
              description: Value(
                index % 200 == 0 ? 'bulkneedle meal' : 'bulk meal',
              ),
              notes: const Value('receipt'),
              transactionDate: '2020-01-01',
              createdAt: '2020-01-01T12:00:00',
            );
          }),
        );
      });
      final timer = Stopwatch()..start();
      final matches = await ids(
        const TransactionSearchFilter(query: 'bulkneedle receipt'),
      );
      timer.stop();
      expect(matches, hasLength(50));
      // Timings are diagnostic: CI CPU scheduling must not make correctness flaky.
      // The interactive search target is under 500ms on a 10000-row history.
      // ignore: avoid_print
      print('10000-row FTS search: ${timer.elapsedMilliseconds}ms');
      timer.reset();
      timer.start();
      expect(await ids(const TransactionSearchFilter()), hasLength(10005));
      timer.stop();
      // ignore: avoid_print
      print('10000-row unfiltered search: ${timer.elapsedMilliseconds}ms');
    },
  );
}
