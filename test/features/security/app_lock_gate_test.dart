import 'package:finpal_pro/features/security/application/providers.dart';
import 'package:finpal_pro/features/security/domain/i_security_service.dart';
import 'package:finpal_pro/features/security/presentation/app_lock_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Security extends Mock implements ISecurityService {}

void main() {
  Future<void> showGate(
    WidgetTester tester,
    _Security service, {
    bool enabled = true,
    int delay = 0,
  }) async {
    when(() => service.readConfig()).thenAnswer(
      (_) async => SecurityConfigSnapshot(
        biometricEnabled: enabled,
        lockOnBackground: true,
        lockDelaySeconds: delay,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [securityServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(
          home: AppLockGate(child: Scaffold(body: Text('Financial records'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'startup locks ledger; cancellation stays locked; success unlocks',
    (tester) async {
      final service = _Security();
      when(
        () => service.authenticateWithBiometric(),
      ).thenAnswer((_) async => false);
      await showGate(tester, service);
      expect(find.text('Financial records'), findsNothing);
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(find.text('Financial records'), findsNothing);
      when(
        () => service.authenticateWithBiometric(),
      ).thenAnswer((_) async => true);
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(find.text('Financial records'), findsOneWidget);
    },
  );

  testWidgets(
    'background hides ledger and immediate setting re-locks on resume',
    (tester) async {
      final service = _Security();
      when(
        () => service.authenticateWithBiometric(),
      ).thenAnswer((_) async => true);
      await showGate(tester, service);
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.text('Financial records'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('Unlock'), findsOneWidget);
      expect(find.text('Financial records'), findsNothing);
    },
  );

  testWidgets('disabled lock does not ask for authentication', (tester) async {
    final service = _Security();
    await showGate(tester, service, enabled: false);
    expect(find.text('Financial records'), findsOneWidget);
    verifyNever(() => service.authenticateWithBiometric());
  });

  testWidgets('security settings read failure does not expose ledger', (
    tester,
  ) async {
    final service = _Security();
    when(
      () => service.readConfig(),
    ).thenThrow(StateError('database unavailable'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [securityServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(
          home: AppLockGate(child: Text('Financial records')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Financial records'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });
}
