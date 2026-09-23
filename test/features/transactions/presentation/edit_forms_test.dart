import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:finpal_pro/core/database/app_database.dart';
import 'package:finpal_pro/features/accounts/application/providers.dart';
import 'package:finpal_pro/features/accounts/presentation/account_form_page.dart';
import 'package:finpal_pro/features/transactions/infrastructure/drift_transaction_repository.dart';
import 'package:finpal_pro/features/transactions/presentation/add_transaction_page.dart';

void main() {
  late AppDatabase db;
  late GoRouter router;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: 'bank',
            name: 'My bank',
            type: AccountType.bank,
            openingBalance: const Value(10000),
            currentBalance: const Value(10000),
            createdAt: '2026-06-10T12:00:00',
          ),
        );
    await DriftTransactionRepository(db).create(
      TransactionsCompanion.insert(
        id: 'entry',
        type: TransactionType.expense,
        amount: 1200,
        debitAccountId: 'bank',
        creditAccountId: 'bank',
        description: const Value('Original purchase'),
        notes: const Value('Original note'),
        transactionDate: '2026-06-10',
        createdAt: '2026-06-10T12:00:00',
      ),
    );
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/account',
          builder: (_, _) => const AccountFormPage(accountId: 'bank'),
        ),
        GoRoute(
          path: '/entry',
          builder: (_, _) => const AddTransactionPage(transactionId: 'entry'),
        ),
      ],
    );
  });
  tearDown(() async {
    router.dispose();
    await db.close();
  });

  Future<void> open(WidgetTester tester, String path) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    router.push(path);
    await tester.pumpAndSettle();
  }

  testWidgets('account editor loads fields and updates existing account', (
    tester,
  ) async {
    await open(tester, '/account');
    final fields = find.byType(TextFormField);
    expect(
      tester.widget<TextFormField>(fields.at(0)).controller!.text,
      'My bank',
    );
    expect(
      tester.widget<TextFormField>(fields.at(1)).controller!.text,
      '100.00',
    );
    await tester.enterText(fields.at(0), 'Renamed bank');
    await tester.enterText(fields.at(1), '200.00');
    await tester.ensureVisible(find.text('Save Account'));
    await tester.tap(find.text('Save Account'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    final accounts = await db.select(db.accounts).get();
    expect(accounts, hasLength(1));
    expect(accounts.single.id, 'bank');
    expect(accounts.single.name, 'Renamed bank');
    expect(accounts.single.currentBalance, 18800);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('invalid opening amount cannot overwrite the account balance', (
    tester,
  ) async {
    await open(tester, '/account');
    await tester.enterText(find.byType(TextFormField).at(1), '1.2.3');
    await tester.ensureVisible(find.text('Save Account'));
    await tester.tap(find.text('Save Account'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid amount'), findsOneWidget);
    final account = (await db.select(db.accounts).get()).single;
    expect(account.openingBalance, 10000);
    expect(account.currentBalance, 8800);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('transaction editor loads fields and saves in place', (
    tester,
  ) async {
    await open(tester, '/entry');
    final fields = find.byType(TextFormField);
    expect(find.text('Edit Transaction'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(fields.at(0)).controller!.text,
      '12.00',
    );
    expect(
      tester.widget<TextFormField>(fields.at(1)).controller!.text,
      'Original purchase',
    );
    expect(
      tester.widget<TextFormField>(fields.at(2)).controller!.text,
      'Original note',
    );
    await tester.enterText(fields.at(0), '25.00');
    await tester.enterText(fields.at(1), 'Corrected purchase');
    await tester.ensureVisible(fields.at(2));
    await tester.enterText(fields.at(2), 'Corrected note');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    final entries = await db.select(db.transactions).get();
    expect(entries, hasLength(1));
    expect(entries.single.id, 'entry');
    expect(entries.single.amount, 2500);
    expect(entries.single.description, 'Corrected purchase');
    expect(entries.single.notes, 'Corrected note');
    expect(entries.single.transactionDate, '2026-06-10');
    expect((await db.select(db.accounts).get()).single.currentBalance, 7500);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
