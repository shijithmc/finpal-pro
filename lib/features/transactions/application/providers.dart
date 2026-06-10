import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/i_transaction_repository.dart';
import '../domain/transaction.dart';
import '../infrastructure/drift_transaction_repository.dart';
import '../../accounts/application/providers.dart';

final transactionRepositoryProvider = Provider<ITransactionRepository>((ref) {
  return DriftTransactionRepository(ref.read(appDatabaseProvider));
});

/// Selected month for the transaction list view.
final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

final transactionsByMonthProvider = StreamProvider<List<FinTransaction>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  final from = DateTime(month.year, month.month, 1);
  final to = DateTime(month.year, month.month + 1, 0); // last day of month
  return repo.watchByDateRange(from, to);
});

final bookmarkedTransactionsProvider = StreamProvider<List<FinTransaction>>((
  ref,
) {
  return ref.watch(transactionRepositoryProvider).watchBookmarked();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<FinTransaction>>((
  ref,
) {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return Future.value([]);
  return ref.read(transactionRepositoryProvider).searchByText(query);
});

// ─── Create transaction ───────────────────────────────────────────────────────

final createTransactionProvider =
    Provider<Future<void> Function(CreateTransactionParams)>((ref) {
      final repo = ref.read(transactionRepositoryProvider);
      final uuid = const Uuid();

      return (CreateTransactionParams p) async {
        final error = FinTransaction.validate(
          amountSubunits: p.amountSubunits,
          debitAccountId: p.debitAccountId,
          creditAccountId: p.creditAccountId,
          type: p.type,
        );
        if (error != null) throw ArgumentError(error);

        await repo.create(
          TransactionsCompanion.insert(
            id: uuid.v4(),
            type: p.type,
            amount: p.amountSubunits,
            debitAccountId: p.debitAccountId,
            creditAccountId: p.creditAccountId,
            categoryId: Value(p.categoryId),
            description: Value(p.description),
            notes: Value(p.notes),
            transactionDate: p.date.toIso8601String().substring(0, 10),
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      };
    });

final class CreateTransactionParams {
  final TransactionType type;
  final int amountSubunits;
  final String debitAccountId;
  final String creditAccountId;
  final String? categoryId;
  final String description;
  final String? notes;
  final DateTime date;

  const CreateTransactionParams({
    required this.type,
    required this.amountSubunits,
    required this.debitAccountId,
    required this.creditAccountId,
    this.categoryId,
    this.description = '',
    this.notes,
    required this.date,
  });
}
