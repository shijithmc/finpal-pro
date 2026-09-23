import 'package:finpal_pro/core/database/app_database.dart';
import 'package:finpal_pro/features/accounts/domain/account.dart';
import 'package:finpal_pro/features/accounts/domain/money.dart';
import 'package:finpal_pro/features/categories/application/providers.dart';
import 'package:finpal_pro/features/categories/domain/category.dart';
import 'package:finpal_pro/features/search/application/providers.dart';
import 'package:finpal_pro/features/search/presentation/search_page.dart';
import 'package:finpal_pro/features/transactions/application/providers.dart';
import 'package:finpal_pro/features/transactions/domain/i_transaction_repository.dart';
import 'package:finpal_pro/features/transactions/domain/transaction.dart';
import 'package:finpal_pro/features/transactions/domain/transaction_search_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements ITransactionRepository {}

void main() {
  setUpAll(() => registerFallbackValue(const TransactionSearchFilter()));

  final expense = FinTransaction(
    id: 'expense',
    type: TransactionType.expense,
    amount: const Money(subunits: 12345),
    debitAccountId: 'bank',
    creditAccountId: 'cash',
    categoryId: 'food',
    description: 'Coffee',
    transactionDate: DateTime(2023),
    createdAt: DateTime(2023),
    isBookmarked: false,
  );

  Future<ProviderContainer> showPage(
    WidgetTester tester,
    _Repository repo,
  ) async {
    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(repo),
        searchAccountsProvider.overrideWith(
          (ref) => Stream.value([
            Account(
              id: 'bank',
              name: 'Bank',
              type: AccountType.bank,
              openingBalance: const Money.zero(),
              currentBalance: const Money.zero(),
              isArchived: false,
              sortOrder: 0,
              createdAt: DateTime(2023),
            ),
            Account(
              id: 'cash',
              name: 'Cash',
              type: AccountType.cash,
              openingBalance: const Money.zero(),
              currentBalance: const Money.zero(),
              isArchived: false,
              sortOrder: 1,
              createdAt: DateTime(2023),
            ),
          ]),
        ),
        categoriesProvider.overrideWith(
          (ref) => Stream.value([
            const Category(
              id: 'food',
              name: 'Food',
              type: CategoryType.expense,
              isSystem: false,
              sortOrder: 0,
            ),
            const Category(
              id: 'travel',
              name: 'Travel',
              type: CategoryType.expense,
              isSystem: false,
              sortOrder: 1,
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SearchPage()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('debounces typing for 300ms and cancels pending query on clear', (
    tester,
  ) async {
    final repo = _Repository();
    final queries = <String>[];
    when(() => repo.watchSearch(any())).thenAnswer((call) {
      queries.add(
        (call.positionalArguments.single as TransactionSearchFilter).query,
      );
      return Stream.value([]);
    });
    await showPage(tester, repo);
    await tester.enterText(find.byType(TextField), 'cof');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), 'coffee');
    await tester.pump(const Duration(milliseconds: 299));
    expect(queries, ['']);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(queries, ['', 'coffee']);
    await tester.enterText(find.byType(TextField), 'stale');
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    expect(queries.last, '');
    expect(queries, isNot(contains('stale')));
  });

  testWidgets(
    'shows filtered totals, amount validation and removable filter chips',
    (tester) async {
      final repo = _Repository();
      when(() => repo.watchSearch(any())).thenAnswer((call) {
        final filter =
            call.positionalArguments.single as TransactionSearchFilter;
        return Stream.value(filter.minAmount == null ? [expense] : []);
      });
      final container = await showPage(tester, repo);
      expect(find.text('1 matching transactions'), findsOneWidget);
      await tester.tap(find.text('Stats'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('search-total-Expenses')))
            .data,
        '₹123.45',
      );
      expect(find.text('Food'), findsOneWidget);
      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Minimum amount (₹)'),
        '200.01',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Maximum amount (₹)'),
        '100',
      );
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(find.text('Maximum must be at least the minimum'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Maximum amount (₹)'),
        '',
      );
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(container.read(searchFilterProvider).minAmount, 20001);
      expect(find.text('No matching transactions'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('search-total-Expenses')))
            .data,
        '₹0.00',
      );
      final chip = tester.widget<InputChip>(find.byType(InputChip));
      chip.onDeleted!();
      await tester.pumpAndSettle();
      expect(container.read(searchFilterProvider).minAmount, isNull);
      expect(find.text('1 matching transactions'), findsOneWidget);
    },
  );

  testWidgets('selects multiple accounts and categories with separate chips', (
    tester,
  ) async {
    final repo = _Repository();
    when(() => repo.watchSearch(any())).thenAnswer((_) => Stream.value([]));
    final container = await showPage(tester, repo);
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accounts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bank'));
    await tester.tap(find.text('Cash'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food'));
    await tester.tap(find.text('Travel'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(container.read(searchFilterProvider).accountIds, {'bank', 'cash'});
    expect(container.read(searchFilterProvider).categoryIds, {
      'food',
      'travel',
    });
    expect(find.byType(InputChip), findsNWidgets(4));
    final bankChip = find.widgetWithText(InputChip, 'Bank');
    await tester.tap(
      find.descendant(of: bankChip, matching: find.byTooltip('Delete')),
    );
    await tester.pumpAndSettle();
    expect(container.read(searchFilterProvider).accountIds, {'cash'});
    expect(container.read(searchFilterProvider).categoryIds, {
      'food',
      'travel',
    });
  });

  testWidgets('query timer is cancelled when leaving search', (tester) async {
    final repo = _Repository();
    when(() => repo.watchSearch(any())).thenAnswer((_) => Stream.value([]));
    await showPage(tester, repo);
    await tester.enterText(find.byType(TextField), 'coffee');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
