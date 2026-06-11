import 'package:equatable/equatable.dart';

import '../../../core/database/app_database.dart';

/// Onboarding progress states. Stored as int in user_profiles.onboarding_step.
enum OnboardingStep {
  notStarted(0),
  nameDone(1),
  accountDone(2),
  complete(3);

  final int value;
  const OnboardingStep(this.value);

  static OnboardingStep fromValue(int value) => OnboardingStep.values
      .firstWhere((s) => s.value == value, orElse: () => notStarted);
}

/// User profile domain entity. One row per Cognito user on this device.
final class UserProfile extends Equatable {
  final String cognitoUserId;
  final String? displayName;
  final OnboardingStep onboardingStep;
  final DateTime createdAt;

  const UserProfile({
    required this.cognitoUserId,
    required this.displayName,
    required this.onboardingStep,
    required this.createdAt,
  });

  /// Factory from Drift data class. Pure mapping — no validation.
  factory UserProfile.fromData(UserProfileData data) {
    return UserProfile(
      cognitoUserId: data.cognitoUserId,
      displayName: data.displayName,
      onboardingStep: OnboardingStep.fromValue(data.onboardingStep),
      createdAt: DateTime.parse(data.createdAt),
    );
  }

  bool get onboardingComplete => onboardingStep == OnboardingStep.complete;

  /// Validates a display name. Returns error message or null if valid.
  static String? validateName(String name) {
    if (name.trim().length > 50) return 'Name must be 50 characters or fewer';
    return null;
  }

  UserProfile copyWith({String? displayName, OnboardingStep? onboardingStep}) {
    return UserProfile(
      cognitoUserId: cognitoUserId,
      displayName: displayName ?? this.displayName,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [cognitoUserId, displayName, onboardingStep];
}
