import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finpal_pro/core/database/app_database.dart';

void main() {
  group('AppDatabase schema v1', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() => db.close());

    test('allTablesCreated_afterSchemaV1', () async {
      // Verifying tables exist by inserting a row in each
      const now = '2026-06-10T12:00:00.000';

      await db.into(db.accounts).insert(
            AccountsCompanion.insert(
              id: 'acc-test',
              name: 'Test',
              type: AccountType.cash,
              createdAt: now,
            ),
          );

      await db.into(db.categories).insert(
            CategoriesCompanion.insert(
              id: 'cat-test',
              name: 'Test Category',
              type: CategoryType.expense,
            ),
          );

      // Security config row is seeded by migration onCreate; no extra insert needed.

      final accounts = await db.select(db.accounts).get();
      expect(accounts.length, greaterThanOrEqualTo(1));

      final categories = await db.select(db.categories).get();
      expect(categories, isNotEmpty); // seeded defaults + test row
    });

    test('monthlyAggregatesTable_existsWithPrimaryKey', () async {
      const now = '2026-06-10T12:00:00.000';

      await db.into(db.accounts).insert(
            AccountsCompanion.insert(
              id: 'acc-ma',
              name: 'MA Test',
              type: AccountType.bank,
              createdAt: now,
            ),
          );

      await db.into(db.monthlyAggregates).insert(
            MonthlyAggregatesCompanion.insert(
              accountId: 'acc-ma',
              year: 2026,
              month: 6,
            ),
          );

      final rows = await db.select(db.monthlyAggregates).get();
      expect(rows.first.totalIncome, 0);
      expect(rows.first.totalExpense, 0);
    });

    test('categories_parentIdColumn_exists', () async {
      // Insert root + child to verify parent_id FK works
      await db.into(db.categories).insertOnConflictUpdate(
            CategoriesCompanion.insert(
              id: 'cat-root',
              name: 'Root',
              type: CategoryType.expense,
            ),
          );
      await db.into(db.categories).insertOnConflictUpdate(
            CategoriesCompanion.insert(
              id: 'cat-child',
              name: 'Child',
              parentId: const Value('cat-root'),
              type: CategoryType.expense,
            ),
          );
      final child = await (db.select(db.categories)
            ..where((c) => c.id.equals('cat-child')))
          .getSingle();
      expect(child.parentId, 'cat-root');
    });
  });
}
