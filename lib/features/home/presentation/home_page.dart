import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../accounts/application/providers.dart';
import '../../transactions/application/providers.dart';
import '../../transactions/presentation/transaction_list_page.dart';
import '../../accounts/presentation/accounts_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _navIndex = 0;

  static const _pages = <Widget>[
    _DashboardTab(),
    TransactionListPage(),
    AccountsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_navIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Accounts',
          ),
        ],
      ),
      floatingActionButton: _navIndex == 1
          ? FloatingActionButton(
              onPressed: () => context.push('/transactions/new'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final txAsync = ref.watch(transactionsByMonthProvider);
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FinPal Pro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Net worth card
          accountsAsync.when(
            loading: () => const Card(
              child: SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => Text('$e'),
            data: (accounts) {
              final netWorth = accounts.fold<int>(
                0,
                (sum, a) => sum + a.currentBalance.subunits,
              );
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Balance',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmt.format(netWorth / 100),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: netWorth >= 0
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${accounts.length} account(s)',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // This month income/expense summary
          txAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (txList) {
              int income = 0;
              int expense = 0;
              for (final tx in txList) {
                if (tx.type == TransactionType.income) {
                  income += tx.amount.subunits;
                } else if (tx.type == TransactionType.expense) {
                  expense += tx.amount.subunits;
                }
              }
              return Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'Income',
                      amount: income / 100,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Expense',
                      amount: expense / 100,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Recent transactions header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent', style: theme.textTheme.titleMedium),
              TextButton(onPressed: () {}, child: const Text('See all')),
            ],
          ),
          txAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (txList) =>
                TransactionListView(transactions: txList.take(5).toList()),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              fmt.format(amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
