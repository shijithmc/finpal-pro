import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../domain/account.dart';
import '../domain/i_account_repository.dart';
import '../domain/money.dart';
import '../infrastructure/drift_account_repository.dart';

// ─── Database provider ────────────────────────────────────────────────────────

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ─── Repository provider ─────────────────────────────────────────────────────

final accountRepositoryProvider = Provider<IAccountRepository>((ref) {
  return DriftAccountRepository(ref.read(appDatabaseProvider));
});

// ─── Accounts list stream ─────────────────────────────────────────────────────

final accountsProvider = StreamProvider<List<Account>>((ref) {
  return ref.watch(accountRepositoryProvider).watchAll();
});

// ─── Account count (for cap check) ───────────────────────────────────────────

final accountCountProvider = FutureProvider<int>((ref) {
  return ref.watch(accountRepositoryProvider).countActive();
});

// ─── Create account use case as function ─────────────────────────────────────

final createAccountProvider =
    Provider<Future<void> Function(CreateAccountParams)>((ref) {
  final repo = ref.read(accountRepositoryProvider);
  final uuid = const Uuid();

  return (CreateAccountParams params) async {
    final validationError = Account.validate(
      name: params.name,
      sortOrder: 0,
    );
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final companion = AccountsCompanion.insert(
      id: uuid.v4(),
      name: params.name.trim(),
      type: params.type,
      currency: Value(AppConstants.defaultCurrency),
      openingBalance:
          Value(Money.fromMajorUnits(params.openingBalanceMajor).subunits),
      currentBalance:
          Value(Money.fromMajorUnits(params.openingBalanceMajor).subunits),
      createdAt: DateTime.now().toIso8601String(),
    );

    await repo.create(companion);
  };
});

final class CreateAccountParams {
  final String name;
  final AccountType type;
  final double openingBalanceMajor;

  const CreateAccountParams({
    required this.name,
    required this.type,
    this.openingBalanceMajor = 0.0,
  });
}
