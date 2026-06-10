import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../application/providers.dart';
import '../domain/account.dart';

class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add account',
            onPressed: () => context.push('/accounts/new'),
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (accounts) {
          if (accounts.isEmpty) {
            return const _EmptyAccountsState();
          }
          return ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (ctx, i) =>
                _AccountTile(account: accounts[i]),
          );
        },
      ),
    );
  }
}

class _EmptyAccountsState extends StatelessWidget {
  const _EmptyAccountsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          const Text('No accounts yet'),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => context.push('/accounts/new'),
            icon: const Icon(Icons.add),
            label: const Text('Add Account'),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final Account account;

  const _AccountTile({required this.account});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final balance = account.currentBalance;
    final isNegative = balance.isNegative;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _typeColor(account.type, theme),
        child: Icon(_typeIcon(account.type), color: Colors.white, size: 20),
      ),
      title: Text(account.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(_typeLabel(account.type)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            fmt.format(balance.asMajorUnits),
            style: theme.textTheme.titleMedium?.copyWith(
              color: isNegative
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text('Balance', style: theme.textTheme.bodySmall),
        ],
      ),
      onTap: () => context.push('/accounts/${account.id}'),
    );
  }

  Color _typeColor(AccountType type, ThemeData theme) {
    return switch (type) {
      AccountType.cash => Colors.green,
      AccountType.bank => theme.colorScheme.primary,
      AccountType.savings => Colors.teal,
      AccountType.creditCard => Colors.orange,
      AccountType.investment => Colors.purple,
    };
  }

  IconData _typeIcon(AccountType type) {
    return switch (type) {
      AccountType.cash => Icons.payments_outlined,
      AccountType.bank => Icons.account_balance_outlined,
      AccountType.savings => Icons.savings_outlined,
      AccountType.creditCard => Icons.credit_card_outlined,
      AccountType.investment => Icons.trending_up_outlined,
    };
  }

  String _typeLabel(AccountType type) {
    return switch (type) {
      AccountType.cash => 'Cash',
      AccountType.bank => 'Bank Account',
      AccountType.savings => 'Savings',
      AccountType.creditCard => 'Credit Card',
      AccountType.investment => 'Investment',
    };
  }
}
