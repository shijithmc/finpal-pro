import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/app_database.dart';
import '../../accounts/application/providers.dart' show appDatabaseProvider;
import '../domain/i_backup_service.dart';

/// Current backup schema version. Increment when the JSON structure changes.
const _kBackupVersion = 1;

/// Production implementation of [IBackupService].
/// Writes files to the app's temporary directory, then shares via OS sheet.
final class BackupService implements IBackupService {
  final AppDatabase _db;

  const BackupService(this._db);

  @override
  Future<String> exportTransactionsTsv() async {
    final transactions = await _db.select(_db.transactions).get();
    final accounts = {
      for (final a in await _db.select(_db.accounts).get()) a.id: a.name,
    };
    final categories = {
      for (final c in await _db.select(_db.categories).get()) c.id: c.name,
    };

    final buffer = StringBuffer();
    buffer.writeln(
      'Date\tType\tAmount (₹)\tDescription\tDebit Account\tCredit Account\tCategory\tNotes\tBookmarked',
    );

    for (final tx
        in transactions
          ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate))) {
      final amount = (tx.amount / 100).toStringAsFixed(2);
      buffer.writeln(
        [
          tx.transactionDate,
          tx.type.name,
          amount,
          _escapeTsv(tx.description),
          _escapeTsv(accounts[tx.debitAccountId] ?? tx.debitAccountId),
          _escapeTsv(accounts[tx.creditAccountId] ?? tx.creditAccountId),
          _escapeTsv(
            tx.categoryId != null
                ? (categories[tx.categoryId] ?? tx.categoryId!)
                : '',
          ),
          _escapeTsv(tx.notes ?? ''),
          tx.isBookmarked ? 'Yes' : 'No',
        ].join('\t'),
      );
    }

    final file = await _writeTemp(
      'finpal_transactions_${_timestamp()}.tsv',
      buffer.toString(),
    );
    await Share.shareXFiles([
      XFile(file.path),
    ], subject: 'FinPal Pro Transactions');
    return file.path;
  }

  @override
  Future<String> createJsonBackup() async {
    final accounts = await _db.select(_db.accounts).get();
    final categories = await _db.select(_db.categories).get();
    final transactions = await _db.select(_db.transactions).get();
    final budgets = await _db.select(_db.budgets).get();

    final payload = {
      'version': _kBackupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'accounts': accounts
          .map(
            (a) => {
              'id': a.id,
              'name': a.name,
              'type': a.type.name,
              'currency': a.currency,
              'openingBalance': a.openingBalance,
              'currentBalance': a.currentBalance,
              'isArchived': a.isArchived,
              'sortOrder': a.sortOrder,
              'createdAt': a.createdAt,
            },
          )
          .toList(),
      'categories': categories
          .map(
            (c) => {
              'id': c.id,
              'name': c.name,
              'parentId': c.parentId,
              'type': c.type.name,
              'iconCode': c.iconCode,
              'icon': c.icon,
              'colorHex': c.colorHex,
              'isSystem': c.isSystem,
              'sortOrder': c.sortOrder,
            },
          )
          .toList(),
      'transactions': transactions
          .map(
            (t) => {
              'id': t.id,
              'type': t.type.name,
              'amount': t.amount,
              'debitAccountId': t.debitAccountId,
              'creditAccountId': t.creditAccountId,
              'categoryId': t.categoryId,
              'description': t.description,
              'notes': t.notes,
              'transactionDate': t.transactionDate,
              'createdAt': t.createdAt,
              'isBookmarked': t.isBookmarked,
              'receiptImagePath': t.receiptImagePath,
            },
          )
          .toList(),
      'budgets': budgets
          .map(
            (b) => {
              'id': b.id,
              'categoryId': b.categoryId,
              'year': b.year,
              'month': b.month,
              'limitPaise': b.limitPaise,
            },
          )
          .toList(),
    };

    final json = const JsonEncoder.withIndent('  ').convert(payload);
    final file = await _writeTemp('finpal_backup_${_timestamp()}.json', json);
    await Share.shareXFiles([XFile(file.path)], subject: 'FinPal Pro Backup');
    return file.path;
  }

  @override
  Future<void> restoreFromJson(String filePath) async {
    final raw = await File(filePath).readAsString();
    late Map<String, dynamic> payload;
    try {
      payload = json.decode(raw) as Map<String, dynamic>;
    } catch (e) {
      throw const BackupRestoreException('File is not valid JSON.');
    }

    final version = payload['version'] as int?;
    if (version == null || version > _kBackupVersion) {
      throw BackupRestoreException(
        'Unsupported backup version: $version. '
        'Update the app to restore this backup.',
      );
    }

    await _db.transaction(() async {
      // Clear in reverse FK order.
      await _db.delete(_db.budgets).go();
      await _db.delete(_db.transactions).go();
      await _db.delete(_db.monthlyAggregates).go();
      await _db.delete(_db.categories).go();
      await _db.delete(_db.accounts).go();

      // Restore accounts.
      for (final raw
          in (payload['accounts'] as List).cast<Map<String, dynamic>>()) {
        await _db
            .into(_db.accounts)
            .insert(
              AccountsCompanion(
                id: Value(raw['id'] as String),
                name: Value(raw['name'] as String),
                type: Value(AccountType.values.byName(raw['type'] as String)),
                currency: Value(raw['currency'] as String),
                openingBalance: Value(raw['openingBalance'] as int),
                currentBalance: Value(raw['currentBalance'] as int),
                isArchived: Value(raw['isArchived'] as bool),
                sortOrder: Value(raw['sortOrder'] as int),
                createdAt: Value(raw['createdAt'] as String),
              ),
            );
      }

      // Restore categories (root first, then children).
      final cats = (payload['categories'] as List).cast<Map<String, dynamic>>();
      final roots = cats.where((c) => c['parentId'] == null).toList();
      final children = cats.where((c) => c['parentId'] != null).toList();
      for (final batch in [roots, children]) {
        for (final raw in batch) {
          await _db
              .into(_db.categories)
              .insert(
                CategoriesCompanion(
                  id: Value(raw['id'] as String),
                  name: Value(raw['name'] as String),
                  parentId: Value(raw['parentId'] as String?),
                  type: Value(
                    CategoryType.values.byName(raw['type'] as String),
                  ),
                  iconCode: Value(raw['iconCode'] as int?),
                  icon: Value(raw['icon'] as String?),
                  colorHex: Value(raw['colorHex'] as String?),
                  isSystem: Value(raw['isSystem'] as bool),
                  sortOrder: Value(raw['sortOrder'] as int),
                ),
              );
        }
      }

      // Restore transactions.
      for (final raw
          in (payload['transactions'] as List).cast<Map<String, dynamic>>()) {
        await _db
            .into(_db.transactions)
            .insert(
              TransactionsCompanion(
                id: Value(raw['id'] as String),
                type: Value(
                  TransactionType.values.byName(raw['type'] as String),
                ),
                amount: Value(raw['amount'] as int),
                debitAccountId: Value(raw['debitAccountId'] as String),
                creditAccountId: Value(raw['creditAccountId'] as String),
                categoryId: Value(raw['categoryId'] as String?),
                description: Value(raw['description'] as String),
                notes: Value(raw['notes'] as String?),
                transactionDate: Value(raw['transactionDate'] as String),
                createdAt: Value(raw['createdAt'] as String),
                isBookmarked: Value(raw['isBookmarked'] as bool),
                receiptImagePath: Value(raw['receiptImagePath'] as String?),
              ),
            );
      }

      // Restore budgets (v1+).
      if (payload.containsKey('budgets')) {
        for (final raw
            in (payload['budgets'] as List).cast<Map<String, dynamic>>()) {
          await _db
              .into(_db.budgets)
              .insert(
                BudgetsCompanion(
                  id: Value(raw['id'] as String),
                  categoryId: Value(raw['categoryId'] as String),
                  year: Value(raw['year'] as int),
                  month: Value(raw['month'] as int),
                  limitPaise: Value(raw['limitPaise'] as int),
                ),
              );
        }
      }
    });

    // Rebuild monthly aggregates from restored transactions.
    await _rebuildMonthlyAggregates();
  }

  @override
  Future<DateTime?> lastBackupTime() async {
    final dir = await getTemporaryDirectory();
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.contains('finpal_backup_'))
            .toList()
          ..sort(
            (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
          );
    if (files.isEmpty) return null;
    return files.first.statSync().modified;
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Future<File> _writeTemp(String filename, String content) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content, flush: true);
    return file;
  }

  String _timestamp() => DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

  String _escapeTsv(String value) =>
      value.replaceAll('\t', ' ').replaceAll('\n', ' ');

  /// Reconstructs monthly_aggregates from transaction history after a restore.
  Future<void> _rebuildMonthlyAggregates() => _db.rebuildAllMonthlyAggregates();
}

/// Riverpod provider for [BackupService].
final backupServiceProvider = Provider<BackupService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return BackupService(db);
});
