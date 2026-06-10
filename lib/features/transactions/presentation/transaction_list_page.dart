import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/extensions/datetime_extensions.dart';
import '../application/providers.dart';
import '../domain/transaction.dart';

class TransactionListPage extends ConsumerWidget {
  const TransactionListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsByMonthProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    return Column(
      children: [
        _MonthSelector(current: selectedMonth),
        Expanded(
          child: txAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (txList) {
              if (txList.isEmpty) return const _EmptyTransactionsState();
              return TransactionListView(transactions: txList);
            },
          ),
        ),
      ],
    );
  }
}

class _MonthSelector extends ConsumerWidget {
  final DateTime current;

  const _MonthSelector({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              ref.read(selectedMonthProvider.notifier).state = DateTime(
                current.year,
                current.month - 1,
              );
            },
          ),
          Text(
            current.monthYearLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: current.isSameMonth(DateTime.now())
                ? null
                : () {
                    ref.read(selectedMonthProvider.notifier).state = DateTime(
                      current.year,
                      current.month + 1,
                    );
                  },
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactionsState extends StatelessWidget {
  const _EmptyTransactionsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          const Text('No transactions this month'),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => context.push('/transactions/new'),
            icon: const Icon(Icons.add),
            label: const Text('Add Transaction'),
          ),
        ],
      ),
    );
  }
}

/// Public widget — also used by home dashboard for recent transactions.
class TransactionListView extends ConsumerWidget {
  final List<FinTransaction> transactions;

  const TransactionListView({super.key, required this.transactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (ctx, i) => _TransactionTile(tx: transactions[i]),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  final FinTransaction tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final isIncome = tx.type == TransactionType.income;
    final isTransfer = tx.type == TransactionType.transfer;

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Transaction'),
            content: const Text(
              'This cannot be undone. Account balances will be reversed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(transactionRepositoryProvider).delete(tx.id);
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isTransfer
              ? theme.colorScheme.tertiaryContainer
              : isIncome
              ? Colors.green.withValues(alpha: 0.2)
              : theme.colorScheme.errorContainer,
          child: Icon(
            isTransfer
                ? Icons.swap_horiz
                : isIncome
                ? Icons.arrow_downward
                : Icons.arrow_upward,
            color: isTransfer
                ? theme.colorScheme.tertiary
                : isIncome
                ? Colors.green
                : theme.colorScheme.error,
            size: 20,
          ),
        ),
        title: Text(
          tx.description.isEmpty ? '(no description)' : tx.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(tx.transactionDate.shortDateLabel),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tx.isBookmarked)
              Icon(Icons.bookmark, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              '${isIncome
                  ? '+'
                  : isTransfer
                  ? '↔'
                  : '-'}${fmt.format(tx.amount.asMajorUnits)}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: isIncome
                    ? Colors.green
                    : isTransfer
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        onLongPress: () => ref
            .read(transactionRepositoryProvider)
            .toggleBookmark(tx.id, !tx.isBookmarked),
      ),
    );
  }
}
