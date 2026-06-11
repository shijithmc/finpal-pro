import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/i_auth_service.dart';
import '../infrastructure/cognito_auth_service.dart';

/// The auth service singleton.
final authServiceProvider = Provider<IAuthService>((ref) {
  return CognitoAuthService();
});

/// True if the user is currently logged in (has valid tokens in secure storage).
/// Watched by the router to redirect unauthenticated users to /login.
final isLoggedInProvider = FutureProvider<bool>((ref) async {
  return ref.read(authServiceProvider).isLoggedIn();
});

/// The Cognito user ID of the currently signed-in user, or null.
final currentUserIdProvider = FutureProvider<String?>((ref) async {
  return ref.read(authServiceProvider).getCurrentUserId();
});

/// Mutable state that the login page sets to true after successful sign-in,
/// triggering a router refresh without requiring a full provider invalidation.
final authStateChangedProvider = StateProvider<int>((ref) => 0);

/// The phone number of the currently signed-in user (10 digits), or null.
final currentPhoneProvider = FutureProvider<String?>((ref) async {
  ref.watch(authStateChangedProvider);
  return ref.read(authServiceProvider).getCurrentPhone();
});
