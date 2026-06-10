import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/accounts/presentation/account_form_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/security/application/providers.dart';
import '../../features/security/presentation/lock_screen_page.dart';
import '../../features/security/presentation/setup_pin_page.dart';
import '../../features/transactions/presentation/add_transaction_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final isLocked = ref.watch(appLockedProvider);
  final isSetupAsync = ref.watch(isSetupCompleteProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final setupDone = isSetupAsync.valueOrNull ?? false;
      if (!setupDone && state.matchedLocation != '/setup') {
        return '/setup';
      }
      if (setupDone && isLocked && state.matchedLocation != '/lock') {
        return '/lock';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomePage()),
      GoRoute(path: '/lock', builder: (_, _) => const LockScreenPage()),
      GoRoute(
        path: '/setup',
        builder: (ctx, _) => SetupPinPage(
          onSetupComplete: () {
            ref.invalidate(isSetupCompleteProvider);
            GoRouter.of(ctx).go('/');
          },
        ),
      ),
      GoRoute(
        path: '/transactions/new',
        builder: (_, _) => const AddTransactionPage(),
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
      GoRoute(path: '/settings', builder: (_, _) => const _SettingsPage()),
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

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: const Center(child: Text('Settings')),
  );
}
