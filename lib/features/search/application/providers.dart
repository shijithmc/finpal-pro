import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounts/application/providers.dart';
import '../../accounts/domain/account.dart';
import '../../transactions/application/providers.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_search_filter.dart';

final searchFilterProvider = StateProvider.autoDispose<TransactionSearchFilter>(
  (ref) => const TransactionSearchFilter(),
);

final filteredTransactionsProvider =
    StreamProvider.autoDispose<List<FinTransaction>>(
      (ref) => ref
          .watch(transactionRepositoryProvider)
          .watchSearch(ref.watch(searchFilterProvider)),
    );

/// Archived accounts remain available when searching historical transactions.
final searchAccountsProvider = StreamProvider.autoDispose<List<Account>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db
      .select(db.accounts)
      .watch()
      .map(
        (rows) =>
            rows.map(Account.fromData).toList()
              ..sort((a, b) => a.name.compareTo(b.name)),
      );
});
