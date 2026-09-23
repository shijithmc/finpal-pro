import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finpal_pro/core/database/app_database.dart';
import 'package:finpal_pro/features/accounts/domain/i_account_repository.dart';
import 'package:finpal_pro/features/accounts/infrastructure/drift_account_repository.dart';
import 'package:finpal_pro/features/transactions/infrastructure/drift_transaction_repository.dart';

void main() {
  late AppDatabase db;
  late DriftAccountRepository repo;
  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftAccountRepository(db);
    await repo.create(
      AccountsCompanion.insert(
        id: 'cash',
        name: 'Cash',
        type: AccountType.cash,
        openingBalance: const Value(10000),
        currentBalance: const Value(10000),
        createdAt: '2026-06-10T12:00:00',
      ),
    );
  });
  tearDown(() => db.close());

  test(
    'edit retains ledger activity and adjusts balance by opening difference',
    () async {
      await DriftTransactionRepository(db).create(
        TransactionsCompanion.insert(
          id: 'expense',
          type: TransactionType.expense,
          amount: 1200,
          debitAccountId: 'cash',
          creditAccountId: 'cash',
          transactionDate: '2026-06-10',
          createdAt: '2026-06-10T12:00:00',
        ),
      );
      await repo.update(
        'cash',
        const AccountsCompanion(
          name: Value('Savings'),
          type: Value(AccountType.savings),
          openingBalance: Value(20000),
        ),
      );
      final account = (await repo.findById('cash'))!;
      expect(await repo.countActive(), 1);
      expect(account.name, 'Savings');
      expect(account.type, AccountType.savings);
      expect(account.currentBalance.subunits, 18800);
      expect(account.openingBalance.subunits, 20000);
      await repo.update(
        'cash',
        const AccountsCompanion(openingBalance: Value(20000)),
      );
      expect((await repo.findById('cash'))!.currentBalance.subunits, 18800);
    },
  );

  test(
    'duplicate rename cannot partially change the opening balance',
    () async {
      await repo.create(
        AccountsCompanion.insert(
          id: 'bank',
          name: 'Bank',
          type: AccountType.bank,
          createdAt: '2026-06-10T12:00:00',
        ),
      );
      await expectLater(
        repo.update(
          'cash',
          const AccountsCompanion(
            name: Value('Bank'),
            openingBalance: Value(20000),
          ),
        ),
        throwsA(isA<DuplicateAccountNameException>()),
      );
      final account = (await repo.findById('cash'))!;
      expect(account.name, 'Cash');
      expect(account.openingBalance.subunits, 10000);
      expect(account.currentBalance.subunits, 10000);
    },
  );
}
