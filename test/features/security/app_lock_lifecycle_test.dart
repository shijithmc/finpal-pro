import 'dart:async';

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
    Widget? child,
  }) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    when(() => service.readConfig()).thenAnswer(
      (_) async => const SecurityConfigSnapshot(
        biometricEnabled: true,
        lockOnBackground: true,
        lockDelaySeconds: 0,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [securityServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          home: AppLockGate(
            child: Scaffold(body: child ?? const Text('Private ledger')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'authentication finishing in background cannot expose or unlock ledger',
    (tester) async {
      final security = _Security();
      final authenticated = Completer<bool>();
      when(
        () => security.authenticateWithBiometric(),
      ).thenAnswer((_) => authenticated.future);
      await showGate(tester, security);
      await tester.tap(find.text('Unlock'));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      authenticated.complete(true);
      await tester.pump();
      expect(find.text('Private ledger'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Private ledger'), findsNothing);
      expect(find.text('Unlock'), findsOneWidget);
    },
  );

  testWidgets(
    'native authentication inactive transition stays hidden until resumed',
    (tester) async {
      final security = _Security();
      final authenticated = Completer<bool>();
      when(
        () => security.authenticateWithBiometric(),
      ).thenAnswer((_) => authenticated.future);
      await showGate(tester, security);
      await tester.tap(find.text('Unlock'));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      authenticated.complete(true);
      await tester.pump();
      expect(find.text('Private ledger'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Private ledger'), findsOneWidget);
    },
  );

  testWidgets('locking removes keyboard focus from the hidden financial form', (
    tester,
  ) async {
    final security = _Security();
    final focus = FocusNode();
    when(
      () => security.authenticateWithBiometric(),
    ).thenAnswer((_) async => true);
    await showGate(tester, security, child: TextField(focusNode: focus));
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(focus.hasFocus, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox.shrink());
    focus.dispose();
  });
}
