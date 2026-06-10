import 'package:flutter_test/flutter_test.dart';
import 'package:finpal_pro/core/database/app_database.dart';
import 'package:finpal_pro/features/accounts/domain/account.dart';
import 'package:finpal_pro/features/accounts/domain/money.dart';

void main() {
  group('Account.validate', () {
    test('validate_emptyName_returnsError', () {
      final error = Account.validate(name: '', sortOrder: 0);
      expect(error, isNotNull);
    });

    test('validate_whitespaceOnlyName_returnsError', () {
      final error = Account.validate(name: '   ', sortOrder: 0);
      expect(error, isNotNull);
    });

    test('validate_validName_returnsNull', () {
      final error = Account.validate(name: 'HDFC Savings', sortOrder: 0);
      expect(error, isNull);
    });

    test('validate_nameTooLong_returnsError', () {
      final longName = 'A' * 51;
      final error = Account.validate(name: longName, sortOrder: 0);
      expect(error, isNotNull);
    });

    test('validate_nameAtMaxLength_returnsNull', () {
      final maxName = 'A' * 50;
      final error = Account.validate(name: maxName, sortOrder: 0);
      expect(error, isNull);
    });
  });

  group('Account.fromData', () {
    test('fromData_mapsAllFields', () {
      final data = AccountData(
        id: 'acc-001',
        name: 'Cash Wallet',
        type: AccountType.cash,
        currency: 'INR',
        openingBalance: 500000,
        currentBalance: 450000,
        isArchived: false,
        sortOrder: 0,
        createdAt: '2026-06-10T00:00:00.000',
      );
      final account = Account.fromData(data);
      expect(account.id, 'acc-001');
      expect(account.name, 'Cash Wallet');
      expect(account.type, AccountType.cash);
      expect(account.currentBalance.subunits, 450000);
      expect(account.currentBalance.asMajorUnits, 4500.0);
    });
  });

  group('Money', () {
    test('fromMajorUnits_convertsCorrectly', () {
      final m = Money.fromMajorUnits(100.50);
      expect(m.subunits, 10050);
    });

    test('addition_sameCurrency_addsSubunits', () {
      final a = Money(subunits: 10000);
      final b = Money(subunits: 5000);
      expect((a + b).subunits, 15000);
    });

    test('subtraction_sameCurrency_subtractsSubunits', () {
      final a = Money(subunits: 10000);
      final b = Money(subunits: 3000);
      expect((a - b).subunits, 7000);
    });

    test('isNegative_negativeSubunits_returnsTrue', () {
      expect(Money(subunits: -1).isNegative, isTrue);
    });

    test('isZero_zeroSubunits_returnsTrue', () {
      expect(const Money.zero().isZero, isTrue);
    });
  });
}
