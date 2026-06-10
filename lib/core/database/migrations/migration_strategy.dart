import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../../features/categories/domain/category_icon.dart';

/// Builds the Drift MigrationStrategy for AppDatabase.
/// Forward-only migrations — every schema version bump adds a case.
MigrationStrategy buildMigrationStrategy(AppDatabase db) {
  return MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await db.createFtsSchema();
      await _seedDefaultCategories(db);
      await _insertSecurityConfigRow(db);
    },
    onUpgrade: (m, from, to) async {
      // v1 → v2: add `icon` text column to categories; backfill from iconCode.
      if (from < 2) {
        await m.addColumn(db.categories, db.categories.icon);
        await _backfillCategoryIcons(db);
      }
      // v2 → v3: add budgets table (PBI-002).
      if (from < 3) {
        await m.createTable(db.budgets);
      }
      // v3 → v4: add cognitoUserId to security_configs; clear legacy pinHash.
      if (from < 4) {
        // Use raw ALTER TABLE to avoid Drift generics mismatch on TextColumn.
        await db.customStatement(
          'ALTER TABLE security_configs ADD COLUMN cognito_user_id TEXT',
        );
        // Clear PIN hashes — PIN auth replaced by Cognito mobile-number login.
        await db.customStatement(
          'UPDATE security_configs SET pin_hash = NULL',
        );
      }
    },
    beforeOpen: (details) async {
      await db.customStatement('PRAGMA foreign_keys = ON');
      await db.customStatement('PRAGMA journal_mode = WAL');
    },
  );
}

/// Backfills the new `icon` column from legacy `iconCode` int values.
Future<void> _backfillCategoryIcons(AppDatabase db) async {
  final rows = await db.select(db.categories).get();
  for (final row in rows) {
    final enumValue = row.iconCode != null
        ? legacyIconCodeMap[row.iconCode]
        : null;
    if (enumValue != null) {
      await (db.update(db.categories)..where((c) => c.id.equals(row.id))).write(
        CategoriesCompanion(icon: Value(enumValue.name)),
      );
    }
  }
}

Future<void> _seedDefaultCategories(AppDatabase db) async {
  final expenseRoots = [
    (
      id: 'cat-food',
      name: 'Food & Dining',
      type: CategoryType.expense,
      iconCode: 0xe533,
      icon: CategoryIcon.foodDining,
    ),
    (
      id: 'cat-transport',
      name: 'Transport',
      type: CategoryType.expense,
      iconCode: 0xe531,
      icon: CategoryIcon.transport,
    ),
    (
      id: 'cat-shopping',
      name: 'Shopping',
      type: CategoryType.expense,
      iconCode: 0xe59c,
      icon: CategoryIcon.shopping,
    ),
    (
      id: 'cat-bills',
      name: 'Bills & Utilities',
      type: CategoryType.expense,
      iconCode: 0xe5fb,
      icon: CategoryIcon.bills,
    ),
    (
      id: 'cat-health',
      name: 'Health & Medical',
      type: CategoryType.expense,
      iconCode: 0xe3f3,
      icon: CategoryIcon.health,
    ),
    (
      id: 'cat-entertainment',
      name: 'Entertainment',
      type: CategoryType.expense,
      iconCode: 0xe63b,
      icon: CategoryIcon.entertainment,
    ),
    (
      id: 'cat-education',
      name: 'Education',
      type: CategoryType.expense,
      iconCode: 0xe80c,
      icon: CategoryIcon.education,
    ),
    (
      id: 'cat-personal',
      name: 'Personal Care',
      type: CategoryType.expense,
      iconCode: 0xe7fd,
      icon: CategoryIcon.personalCare,
    ),
    (
      id: 'cat-travel',
      name: 'Travel',
      type: CategoryType.expense,
      iconCode: 0xe1d5,
      icon: CategoryIcon.travel,
    ),
    (
      id: 'cat-other-exp',
      name: 'Other Expense',
      type: CategoryType.expense,
      iconCode: 0xe8b8,
      icon: CategoryIcon.other,
    ),
  ];

  final incomeRoots = [
    (
      id: 'cat-salary',
      name: 'Salary',
      type: CategoryType.income,
      iconCode: 0xe263,
      icon: CategoryIcon.salary,
    ),
    (
      id: 'cat-freelance',
      name: 'Freelance',
      type: CategoryType.income,
      iconCode: 0xe8d5,
      icon: CategoryIcon.freelance,
    ),
    (
      id: 'cat-business',
      name: 'Business Income',
      type: CategoryType.income,
      iconCode: 0xe1d3,
      icon: CategoryIcon.business,
    ),
    (
      id: 'cat-investment-inc',
      name: 'Investment Returns',
      type: CategoryType.income,
      iconCode: 0xe8dc,
      icon: CategoryIcon.investment,
    ),
    (
      id: 'cat-gifts',
      name: 'Gifts Received',
      type: CategoryType.income,
      iconCode: 0xe40c,
      icon: CategoryIcon.gift,
    ),
    (
      id: 'cat-other-inc',
      name: 'Other Income',
      type: CategoryType.income,
      iconCode: 0xe8b8,
      icon: CategoryIcon.other,
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
            iconCode: Value(cat.iconCode),
            icon: Value(cat.icon.name),
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
  await db
      .into(db.securityConfigs)
      .insert(
        const SecurityConfigsCompanion(id: Value(1)),
        mode: InsertMode.insertOrIgnore,
      );
}
