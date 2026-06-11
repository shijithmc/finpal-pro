import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/i_user_profile_repository.dart';
import '../domain/user_profile.dart';

/// Drift-backed user profile repository.
final class DriftUserProfileRepository implements IUserProfileRepository {
  final AppDatabase _db;

  DriftUserProfileRepository(this._db);

  @override
  Future<UserProfile?> find(String cognitoUserId) async {
    final row = await (_db.select(
      _db.userProfiles,
    )..where((p) => p.cognitoUserId.equals(cognitoUserId))).getSingleOrNull();
    return row == null ? null : UserProfile.fromData(row);
  }

  @override
  Future<UserProfile> findOrCreate(String cognitoUserId) async {
    final existing = await find(cognitoUserId);
    if (existing != null) return existing;

    final now = DateTime.now().toIso8601String();
    await _db
        .into(_db.userProfiles)
        .insert(
          UserProfilesCompanion.insert(
            cognitoUserId: cognitoUserId,
            createdAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return (await find(cognitoUserId))!;
  }

  @override
  Future<void> setDisplayName(String cognitoUserId, String? displayName) async {
    final trimmed = displayName?.trim();
    await (_db.update(
      _db.userProfiles,
    )..where((p) => p.cognitoUserId.equals(cognitoUserId))).write(
      UserProfilesCompanion(
        displayName: Value(
          (trimmed == null || trimmed.isEmpty) ? null : trimmed,
        ),
      ),
    );
  }

  @override
  Future<void> setOnboardingStep(
    String cognitoUserId,
    OnboardingStep step,
  ) async {
    // Never move backwards — a resumed flow must not regress completed state.
    final current = await find(cognitoUserId);
    if (current != null && current.onboardingStep.value >= step.value) return;

    await (_db.update(_db.userProfiles)
          ..where((p) => p.cognitoUserId.equals(cognitoUserId)))
        .write(UserProfilesCompanion(onboardingStep: Value(step.value)));
  }
}
