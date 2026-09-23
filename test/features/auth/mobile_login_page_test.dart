import 'package:finpal_pro/features/auth/application/providers.dart';
import 'package:finpal_pro/features/auth/domain/i_auth_service.dart';
import 'package:finpal_pro/features/auth/presentation/mobile_login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _Auth extends Mock implements IAuthService {}

const _challenge = OtpChallenge(
  phoneNumber: '9876543210',
  username: '+919876543210',
  kind: OtpChallengeKind.signIn,
  session: 'session',
);

void main() {
  testWidgets(
    'phone entry sends SMS; wrong code stays; verified code reaches home',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(700, 1100));
      final auth = _Auth();
      when(() => auth.getLastUsedPhone()).thenAnswer((_) async => null);
      when(
        () => auth.requestSignIn('9876543210'),
      ).thenAnswer((_) async => _challenge);
      when(() => auth.verifySignIn(_challenge, '123456')).thenThrow(
        const AuthException('That code is incorrect. Please try again.'),
      );
      when(
        () => auth.verifySignIn(_challenge, '87654321'),
      ).thenAnswer((_) async => null);
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/login', builder: (_, _) => const MobileLoginPage()),
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('Home ledger')),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authServiceProvider.overrideWithValue(auth)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '9876543210');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Verify your number'), findsOneWidget);
      expect(find.text('Home ledger'), findsNothing);
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      await tester.tap(find.text('Verify and sign in'));
      await tester.pumpAndSettle();
      expect(
        find.text('That code is incorrect. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Home ledger'), findsNothing);
      await tester.enterText(find.byType(TextField), '87654321');
      await tester.pump();
      await tester.tap(find.text('Verify and sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Home ledger'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      await tester.binding.setSurfaceSize(null);
    },
  );
}
