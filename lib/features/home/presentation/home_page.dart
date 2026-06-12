import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../accounts/application/providers.dart';
import '../../profile/application/providers.dart';
import '../../transactions/application/providers.dart';
import '../../transactions/presentation/transaction_list_page.dart';
import '../../transactions/presentation/templates_page.dart';
import '../../accounts/presentation/accounts_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _DashboardTab(onSeeAllTransactions: () => setState(() => _navIndex = 1)),
      const TransactionListPage(),
      const TemplatesPage(),
      const AccountsPage(),
    ];

    return Scaffold(
      body: pages[_navIndex],
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
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Templates',
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
  final VoidCallback onSeeAllTransactions;

  const _DashboardTab({required this.onSeeAllTransactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final txAsync = ref.watch(transactionsByMonthProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FinPal Pro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_outlined),
            tooltip: 'Scan a bill',
            onPressed: () => context.push('/scan'),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Time-of-day greeting with display name (Welcome Experience)
          const _GreetingHeader(),
          const SizedBox(height: 16),
          // Net worth hero card
          accountsAsync.when(
            loading: () => const Card(
              child: SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => Text('$e'),
            data: (accounts) {
              final netWorth = accounts.fold<int>(
                0,
                (sum, a) => sum + a.currentBalance.subunits,
              );
              return _NetWorthHeroCard(
                netWorthPaise: netWorth,
                accountCount: accounts.length,
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
                      color: AppTheme.incomeGreen,
                      icon: Icons.arrow_downward_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: 'Expense',
                      amount: expense / 100,
                      color: AppTheme.expenseRed,
                      icon: Icons.arrow_upward_rounded,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Recent transactions header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent', style: theme.textTheme.titleMedium),
                TextButton(
                  onPressed: onSeeAllTransactions,
                  child: const Text('See all'),
                ),
              ],
            ),
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

/// Gradient hero card for the headline net worth figure (FA-002).
/// On-gradient text is always white-on-brand; the figure never competes
/// with surrounding surface cards.
class _NetWorthHeroCard extends StatelessWidget {
  final int netWorthPaise;
  final int accountCount;

  const _NetWorthHeroCard({
    required this.netWorthPaise,
    required this.accountCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final accountsLabel = accountCount == 1
        ? '1 account'
        : '$accountCount accounts';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient(scheme),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: scheme.onPrimary.withValues(alpha: .85),
              ),
              const SizedBox(width: 8),
              Text(
                'Total Balance',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onPrimary.withValues(alpha: .85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fmt.format(netWorthPaise / 100),
            style: theme.textTheme.headlineLarge?.copyWith(
              color: scheme.onPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.onPrimary.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              accountsLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Income/expense summary tile with a tinted icon chip (FA-003).
/// Colors come from theme tokens — no raw Colors.* or hardcoded sizes.
class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fmt.format(amount),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Time-of-day-aware greeting with the user's display name and today's
/// date (FA-005). "Good morning, Shijith" — falls back to a nameless
/// greeting if the name was skipped during onboarding.
class _GreetingHeader extends ConsumerWidget {
  const _GreetingHeader();

  static String _greetingFor(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final nameAsync = ref.watch(displayNameProvider);
    final now = DateTime.now();
    final greeting = _greetingFor(now);
    final name = nameAsync.valueOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name == null || name.isEmpty ? '$greeting!' : '$greeting, $name',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('EEEE, d MMMM').format(now),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
