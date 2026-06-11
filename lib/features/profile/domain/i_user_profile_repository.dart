import 'user_profile.dart';

/// Contract for user profile persistence. Infrastructure layer implements this.
abstract interface class IUserProfileRepository {
  /// Returns the profile for [cognitoUserId], or null if none exists yet.
  Future<UserProfile?> find(String cognitoUserId);

  /// Creates the profile row if absent; returns the (possibly new) profile.
  Future<UserProfile> findOrCreate(String cognitoUserId);

  /// Updates the display name. Pass null to clear it.
  Future<void> setDisplayName(String cognitoUserId, String? displayName);

  /// Advances onboarding progress. Never moves backwards.
  Future<void> setOnboardingStep(String cognitoUserId, OnboardingStep step);
}
