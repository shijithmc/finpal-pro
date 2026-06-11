import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/accounts/presentation/account_form_page.dart';
import '../../features/auth/application/providers.dart';
import '../../features/auth/presentation/mobile_login_page.dart';
import '../../features/backup/presentation/backup_page.dart';
import '../../features/budgets/presentation/budget_page.dart';
import '../../features/analytics/presentation/analytics_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/transactions/presentation/add_transaction_page.dart';
import '../../features/transactions/presentation/templates_page.dart'
    show TemplateData;

final routerProvider = Provider<GoRouter>((ref) {
  // Watch auth state changes so the router refreshes on login/logout.
  ref.watch(authStateChangedProvider);
  final isLoggedInAsync = ref.watch(isLoggedInProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // While the auth state is loading, stay put to avoid flash.
      if (isLoggedInAsync.isLoading) return null;

      final loggedIn = isLoggedInAsync.valueOrNull ?? false;

      // Not logged in → send to /login (unless already there).
      if (!loggedIn && state.matchedLocation != '/login') return '/login';

      // Logged in → send to home if somehow on /login.
      if (loggedIn && state.matchedLocation == '/login') return '/';

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomePage()),
      GoRoute(path: '/login', builder: (_, _) => const MobileLoginPage()),
      GoRoute(
        path: '/transactions/new',
        builder: (_, state) {
          final template = state.extra as TemplateData?;
          return AddTransactionPage(template: template);
        },
      ),
      GoRoute(
        path: '/accounts/new',
        builder: (_, _) => const AccountFormPage(),
      ),
      GoRoute(
        path: '/accounts/:id',
        builder: (_, state) =>
            AccountFormPage(accountId: state.pathParameters['id']),
      ),
      GoRoute(path: '/search', builder: (_, _) => const _SearchPage()),
      GoRoute(
        path: '/settings',
        builder: (_, _) => const _SettingsPage(),
        routes: [
          GoRoute(path: 'backup', builder: (_, _) => const BackupPage()),
          GoRoute(path: 'budgets', builder: (_, _) => const BudgetPage()),
        ],
      ),
      GoRoute(path: '/analytics', builder: (_, _) => const AnalyticsPage()),
    ],
  );
});

class _SearchPage extends StatelessWidget {
  const _SearchPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Search')),
    body: const Center(child: Text('Search — Sprint 3 (PBI-013)')),
  );
}

class _SettingsPage extends ConsumerWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Budgets'),
            subtitle: const Text('Set monthly spend limits by category'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/budgets'),
          ),
          const Divider(indent: 72),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Data Management'),
            subtitle: const Text('Backup, restore, and export'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/backup'),
          ),
          const Divider(indent: 72),
          ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('Analytics'),
            subtitle: const Text('Spend breakdown and trends'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/analytics'),
          ),
          const Divider(indent: 72),
          // ── Sign out ────────────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.logout_outlined),
            title: const Text('Sign Out'),
            subtitle: const Text('Remove stored login from this device'),
            onTap: () async {
              await ref.read(authServiceProvider).signOut();
              ref.invalidate(isLoggedInProvider);
              ref.read(authStateChangedProvider.notifier).state++;
            },
          ),
          const Divider(indent: 72),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'FinPal Pro v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
