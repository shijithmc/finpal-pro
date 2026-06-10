import 'package:drift/drift.dart';

import '../app_database.dart';

/// Builds the Drift MigrationStrategy for AppDatabase.
/// Every schema version bump adds a case here — forward-only migrations only.
MigrationStrategy buildMigrationStrategy(AppDatabase db) {
  return MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await db.createFtsSchema();
      await _seedDefaultCategories(db);
      await _insertSecurityConfigRow(db);
    },
    onUpgrade: (m, from, to) async {
      // Future migrations added here as version increments.
      // Example for v2:
      // if (from < 2) {
      //   await m.addColumn(db.accounts, db.accounts.someNewColumn);
      // }
    },
    beforeOpen: (details) async {
      await db.customStatement('PRAGMA foreign_keys = ON');
      await db.customStatement('PRAGMA journal_mode = WAL');
    },
  );
}

Future<void> _seedDefaultCategories(AppDatabase db) async {
  final expenseRoots = [
    (
      id: 'cat-food',
      name: 'Food & Dining',
      type: CategoryType.expense,
      icon: 0xe533,
    ),
    (
      id: 'cat-transport',
      name: 'Transport',
      type: CategoryType.expense,
      icon: 0xe531,
    ),
    (
      id: 'cat-shopping',
      name: 'Shopping',
      type: CategoryType.expense,
      icon: 0xe59c,
    ),
    (
      id: 'cat-bills',
      name: 'Bills & Utilities',
      type: CategoryType.expense,
      icon: 0xe5fb,
    ),
    (
      id: 'cat-health',
      name: 'Health & Medical',
      type: CategoryType.expense,
      icon: 0xe3f3,
    ),
    (
      id: 'cat-entertainment',
      name: 'Entertainment',
      type: CategoryType.expense,
      icon: 0xe63b,
    ),
    (
      id: 'cat-education',
      name: 'Education',
      type: CategoryType.expense,
      icon: 0xe80c,
    ),
    (
      id: 'cat-personal',
      name: 'Personal Care',
      type: CategoryType.expense,
      icon: 0xe7fd,
    ),
    (
      id: 'cat-travel',
      name: 'Travel',
      type: CategoryType.expense,
      icon: 0xe1d5,
    ),
    (
      id: 'cat-other-exp',
      name: 'Other Expense',
      type: CategoryType.expense,
      icon: 0xe8b8,
    ),
  ];

  final incomeRoots = [
    (id: 'cat-salary', name: 'Salary', type: CategoryType.income, icon: 0xe263),
    (
      id: 'cat-freelance',
      name: 'Freelance',
      type: CategoryType.income,
      icon: 0xe8d5,
    ),
    (
      id: 'cat-business',
      name: 'Business Income',
      type: CategoryType.income,
      icon: 0xe1d3,
    ),
    (
      id: 'cat-investment-inc',
      name: 'Investment Returns',
      type: CategoryType.income,
      icon: 0xe8dc,
    ),
    (
      id: 'cat-gifts',
      name: 'Gifts Received',
      type: CategoryType.income,
      icon: 0xe40c,
    ),
    (
      id: 'cat-other-inc',
      name: 'Other Income',
      type: CategoryType.income,
      icon: 0xe8b8,
    ),
  ];

  int order = 0;
  for (final cat in [...expenseRoots, ...incomeRoots]) {
    await db
        .into(db.categories)
        .insertOnConflictUpdate(
          CategoriesCompanion.insert(
            id: cat.id,
            name: cat.name,
            type: cat.type,
            iconCode: Value(cat.icon),
            isSystem: const Value(true),
            sortOrder: Value(order++),
          ),
        );
  }

  // Sub-categories for Food & Dining (demonstrates parent_id usage)
  final foodSubs = [
    (id: 'cat-restaurants', name: 'Restaurants', parentId: 'cat-food'),
    (id: 'cat-groceries', name: 'Groceries', parentId: 'cat-food'),
    (id: 'cat-cafe', name: 'Café & Beverages', parentId: 'cat-food'),
    (id: 'cat-delivery', name: 'Food Delivery', parentId: 'cat-food'),
  ];
  for (final sub in foodSubs) {
    await db
        .into(db.categories)
        .insertOnConflictUpdate(
          CategoriesCompanion.insert(
            id: sub.id,
            name: sub.name,
            parentId: Value(sub.parentId),
            type: CategoryType.expense,
            isSystem: const Value(true),
            sortOrder: Value(order++),
          ),
        );
  }
}

Future<void> _insertSecurityConfigRow(AppDatabase db) async {
  // Insert singleton row with id=1 only if it doesn't already exist.
  // All columns have defaults; explicit id=1 satisfies the NOT NULL constraint.
  await db
      .into(db.securityConfigs)
      .insert(
        const SecurityConfigsCompanion(id: Value(1)),
        mode: InsertMode.insertOrIgnore,
      );
}
