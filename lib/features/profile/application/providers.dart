import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounts/application/providers.dart';
import '../../auth/application/providers.dart';
import '../domain/i_user_profile_repository.dart';
import '../domain/user_profile.dart';
import '../infrastructure/drift_user_profile_repository.dart';

// ─── Repository provider ─────────────────────────────────────────────────────

final userProfileRepositoryProvider = Provider<IUserProfileRepository>((ref) {
  return DriftUserProfileRepository(ref.read(appDatabaseProvider));
});

// ─── Current user profile ────────────────────────────────────────────────────

/// Profile row for the currently logged-in Cognito user.
/// Null when not logged in or no profile row exists yet.
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  // Re-evaluate whenever auth state changes (login/logout).
  ref.watch(authStateChangedProvider);

  final userId = await ref.watch(authServiceProvider).getCurrentUserId();
  if (userId == null || userId.isEmpty) return null;

  return ref.watch(userProfileRepositoryProvider).find(userId);
});

/// True when the current user finished (or skipped through) onboarding.
/// False for brand-new users and users mid-onboarding.
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return profile?.onboardingComplete ?? false;
});

/// Display name of the current user, or null if unset.
final displayNameProvider = FutureProvider<String?>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return profile?.displayName;
});
