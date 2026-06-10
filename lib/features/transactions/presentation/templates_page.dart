import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../application/providers.dart';
import '../domain/transaction.dart';
import '../../../core/database/app_database.dart';

/// Displays bookmarked transactions as quick-entry templates (PBI-007).
/// Tapping a template pre-fills the AddTransactionPage.
class TemplatesPage extends ConsumerWidget {
  const TemplatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarked = ref.watch(bookmarkedTransactionsProvider);

    return bookmarked.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (templates) {
        if (templates.isEmpty) return const _EmptyTemplatesState();
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: templates.length,
          itemBuilder: (ctx, i) => _TemplateTile(tx: templates[i]),
        );
      },
    );
  }
}

class _EmptyTemplatesState extends StatelessWidget {
  const _EmptyTemplatesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          const Text('No templates yet'),
          const SizedBox(height: 8),
          Text(
            'Long-press any transaction to bookmark it as a template.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TemplateTile extends ConsumerWidget {
  final FinTransaction tx;

  const _TemplateTile({required this.tx});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final isIncome = tx.type == TransactionType.income;
    final isTransfer = tx.type == TransactionType.transfer;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        subtitle: Text(
          '${tx.type.name.toUpperCase()} · ${fmt.format(tx.amount.asMajorUnits)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Remove bookmark
            IconButton(
              icon: const Icon(Icons.bookmark, size: 20),
              tooltip: 'Remove template',
              onPressed: () {
                ref
                    .read(transactionRepositoryProvider)
                    .toggleBookmark(tx.id, false);
              },
            ),
            // Use as template
            FilledButton.tonal(
              onPressed: () => context.push(
                '/transactions/new',
                extra: _TemplateData(
                  type: tx.type,
                  amountSubunits: tx.amount.subunits,
                  debitAccountId: tx.debitAccountId,
                  creditAccountId: tx.creditAccountId,
                  categoryId: tx.categoryId,
                  description: tx.description,
                  notes: tx.notes,
                ),
              ),
              child: const Text('Use'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carries template data to AddTransactionPage via GoRouter's `extra`.
final class TemplateData {
  final TransactionType type;
  final int amountSubunits;
  final String debitAccountId;
  final String creditAccountId;
  final String? categoryId;
  final String description;
  final String? notes;

  const TemplateData({
    required this.type,
    required this.amountSubunits,
    required this.debitAccountId,
    required this.creditAccountId,
    this.categoryId,
    this.description = '',
    this.notes,
  });
}

// Private alias so the widget file doesn't export the data class directly.
typedef _TemplateData = TemplateData;
