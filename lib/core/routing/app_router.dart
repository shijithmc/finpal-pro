import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../features/accounts/presentation/account_form_page.dart';
import '../../features/auth/application/providers.dart';
import '../../features/auth/presentation/mobile_login_page.dart';
import '../../features/backup/presentation/backup_page.dart';
import '../../features/budgets/presentation/budget_page.dart';
import '../../features/analytics/presentation/analytics_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/profile/application/providers.dart';
import '../../features/profile/domain/user_profile.dart';
import '../../features/transactions/presentation/add_transaction_page.dart';
import '../../features/transactions/presentation/templates_page.dart'
    show TemplateData;

final routerProvider = Provider<GoRouter>((ref) {
  // Watch auth state changes so the router refreshes on login/logout.
  ref.watch(authStateChangedProvider);
  final isLoggedInAsync = ref.watch(isLoggedInProvider);
  final onboardingAsync = ref.watch(onboardingCompleteProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // While auth state is loading, stay put to avoid flash.
      if (isLoggedInAsync.isLoading) return null;

      final loggedIn = isLoggedInAsync.valueOrNull ?? false;
      final location = state.matchedLocation;

      // Not logged in → send to /login (unless already there).
      if (!loggedIn && location != '/login') return '/login';
      if (!loggedIn) return null;

      // Logged in — gate on onboarding completion.
      if (onboardingAsync.isLoading) return null;
      final onboarded = onboardingAsync.valueOrNull ?? false;

      if (!onboarded && location != '/onboarding') return '/onboarding';
      if (onboarded && (location == '/login' || location == '/onboarding')) {
        return '/';
      }
      if (location == '/login') return '/onboarding';

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomePage()),
      GoRoute(path: '/login', builder: (_, _) => const MobileLoginPage()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
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
    final profileAsync = ref.watch(userProfileProvider);
    final phoneAsync = ref.watch(currentPhoneProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Profile ─────────────────────────────────────────────────────
          profileAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (profile) {
              final name = profile?.displayName;
              final memberSince = profile == null
                  ? null
                  : DateFormat.yMMMd().format(profile.createdAt);
              final phone = phoneAsync.valueOrNull;
              final subtitleParts = [
                if (phone != null) '+91 $phone',
                if (memberSince != null) 'Member since $memberSince',
              ];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (name?.isNotEmpty ?? false)
                        ? name!.substring(0, 1).toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(name ?? 'Set your name'),
                subtitle: subtitleParts.isEmpty
                    ? null
                    : Text(subtitleParts.join(' · ')),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => _editName(context, ref, name),
              );
            },
          ),
          const Divider(indent: 72),
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
              ref.invalidate(userProfileProvider);
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

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String? current,
  ) async {
    final controller = TextEditingController(text: current ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Shijith',
            counterText: '',
          ),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName == null) return;
    final validationError = UserProfile.validateName(newName);
    if (validationError != null) return;

    final userId = await ref.read(authServiceProvider).getCurrentUserId();
    if (userId == null) return;

    await ref
        .read(userProfileRepositoryProvider)
        .setDisplayName(userId, newName);
    ref.invalidate(userProfileProvider);
  }
}
