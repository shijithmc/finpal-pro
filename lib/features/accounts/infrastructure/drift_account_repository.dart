import 'package:drift/drift.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../domain/account.dart';
import '../domain/i_account_repository.dart';

final class DriftAccountRepository implements IAccountRepository {
  final AppDatabase _db;

  const DriftAccountRepository(this._db);

  @override
  Stream<List<Account>> watchAll() {
    return (_db.select(_db.accounts)
          ..where((a) => a.isArchived.equals(false))
          ..orderBy([(a) => OrderingTerm.asc(a.sortOrder)]))
        .watch()
        .map((rows) => rows.map(Account.fromData).toList());
  }

  @override
  Future<Account?> findById(String id) async {
    final row = await (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(id))).getSingleOrNull();
    return row == null ? null : Account.fromData(row);
  }

  @override
  Future<int> countActive() {
    final countExpr = _db.accounts.id.count();
    final query = _db.selectOnly(_db.accounts)
      ..addColumns([countExpr])
      ..where(_db.accounts.isArchived.equals(false));
    return query.map((r) => r.read(countExpr)!).getSingle();
  }

  @override
  Future<void> create(AccountsCompanion companion) async {
    final count = await countActive();
    if (count >= AppConstants.freeAccountLimit) {
      throw AccountLimitExceededException(AppConstants.freeAccountLimit);
    }

    final name = companion.name.value;
    final existing =
        await (_db.select(_db.accounts)..where(
              (a) =>
                  a.name.lower().equals(name.toLowerCase()) &
                  a.isArchived.equals(false),
            ))
            .getSingleOrNull();
    if (existing != null) {
      throw DuplicateAccountNameException(name);
    }

    await _db.into(_db.accounts).insert(companion);
  }

  @override
  Future<void> update(String id, AccountsCompanion companion) async {
    if (companion.name.present) {
      final name = companion.name.value;
      final existing =
          await (_db.select(_db.accounts)..where(
                (a) =>
                    a.name.lower().equals(name.toLowerCase()) &
                    a.isArchived.equals(false) &
                    a.id.isNotValue(id),
              ))
              .getSingleOrNull();
      if (existing != null) {
        throw DuplicateAccountNameException(name);
      }
    }

    await (_db.update(
      _db.accounts,
    )..where((a) => a.id.equals(id))).write(companion);
  }

  @override
  Future<void> archive(String id) async {
    await (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      const AccountsCompanion(isArchived: Value(true)),
    );
  }
}
