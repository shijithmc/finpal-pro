import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finpal_pro/core/database/app_database.dart';
import 'package:finpal_pro/features/backup/infrastructure/backup_service.dart';

void main() {
  late AppDatabase db;
  late Directory directory;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    directory = await Directory.systemTemp.createTemp('finpal-restore-');
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: 'original',
            name: 'Original account',
            type: AccountType.cash,
            createdAt: '2026-06-10T12:00:00',
          ),
        );
  });

  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  Future<String> backupPath({int amount = 1200}) async {
    final file = File('${directory.path}/backup.json');
    await file.writeAsString(
      jsonEncode({
        'version': 1,
        'accounts': [
          {
            'id': 'bank',
            'name': 'Bank',
            'type': 'bank',
            'currency': 'INR',
            'openingBalance': 10000,
            'currentBalance': 999999,
            'isArchived': false,
            'sortOrder': 0,
            'createdAt': '2026-06-10T12:00:00',
          },
        ],
        'categories': [],
        'transactions': [
          {
            'id': 'expense',
            'type': 'expense',
            'amount': amount,
            'debitAccountId': 'bank',
            'creditAccountId': 'bank',
            'description': 'Restored expense',
            'transactionDate': '2026-06-10',
            'createdAt': '2026-06-10T12:00:00',
            'isBookmarked': false,
          },
        ],
        'budgets': [],
      }),
    );
    return file.path;
  }

  test(
    'restoring recomputes balances and monthly totals from ledger',
    () async {
      await BackupService(db).restoreFromJson(await backupPath());
      final account = (await db.select(db.accounts).get()).single;
      expect(account.id, 'bank');
      expect(account.currentBalance, 8800);
      final total = (await db.select(db.monthlyAggregates).get()).single;
      expect(total.totalExpense, 1200);
    },
  );

  test('failed ledger reconciliation rolls back the entire restore', () async {
    final path = await backupPath(amount: -1200);
    await expectLater(
      BackupService(db).restoreFromJson(path),
      throwsArgumentError,
    );
    expect((await db.select(db.accounts).get()).single.id, 'original');
    expect(await db.select(db.transactions).get(), isEmpty);
  });
}
