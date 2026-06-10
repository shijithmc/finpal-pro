import 'package:flutter_test/flutter_test.dart';
import 'package:finpal_pro/core/database/app_database.dart';
import 'package:finpal_pro/features/transactions/domain/transaction.dart';

void main() {
  group('FinTransaction.validate', () {
    test('validate_zeroAmount_returnsError', () {
      final error = FinTransaction.validate(
        amountSubunits: 0,
        debitAccountId: 'acc-001',
        creditAccountId: 'acc-002',
        type: TransactionType.expense,
      );
      expect(error, isNotNull);
    });

    test('validate_negativeAmount_returnsError', () {
      final error = FinTransaction.validate(
        amountSubunits: -100,
        debitAccountId: 'acc-001',
        creditAccountId: 'acc-002',
        type: TransactionType.expense,
      );
      expect(error, isNotNull);
    });

    test('validate_validExpense_returnsNull', () {
      final error = FinTransaction.validate(
        amountSubunits: 35000,
        debitAccountId: 'acc-001',
        creditAccountId: 'acc-001',
        type: TransactionType.expense,
      );
      expect(error, isNull);
    });

    test('validate_transferSameAccount_returnsError', () {
      final error = FinTransaction.validate(
        amountSubunits: 1000,
        debitAccountId: 'acc-001',
        creditAccountId: 'acc-001',
        type: TransactionType.transfer,
      );
      expect(error, isNotNull);
    });

    test('validate_transferDifferentAccounts_returnsNull', () {
      final error = FinTransaction.validate(
        amountSubunits: 1000,
        debitAccountId: 'acc-001',
        creditAccountId: 'acc-002',
        type: TransactionType.transfer,
      );
      expect(error, isNull);
    });
  });
}
