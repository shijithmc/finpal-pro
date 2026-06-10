import 'package:equatable/equatable.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import 'money.dart';

/// Account domain entity. Immutable value object; rebuilt on every state change.
final class Account extends Equatable {
  final String id;
  final String name;
  final AccountType type;
  final Money openingBalance;
  final Money currentBalance;
  final bool isArchived;
  final int sortOrder;
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.openingBalance,
    required this.currentBalance,
    required this.isArchived,
    required this.sortOrder,
    required this.createdAt,
  });

  /// Factory from Drift data class. Pure mapping — no validation.
  factory Account.fromData(AccountData data) {
    return Account(
      id: data.id,
      name: data.name,
      type: data.type,
      openingBalance: Money(
        subunits: data.openingBalance,
        currencyCode: data.currency,
      ),
      currentBalance: Money(
        subunits: data.currentBalance,
        currencyCode: data.currency,
      ),
      isArchived: data.isArchived,
      sortOrder: data.sortOrder,
      createdAt: DateTime.parse(data.createdAt),
    );
  }

  /// Validates business rules. Returns error message or null if valid.
  static String? validate({required String name, required int sortOrder}) {
    if (name.trim().isEmpty) return 'Account name cannot be empty';
    if (name.trim().length > AppConstants.maxAccountNameLength) {
      return 'Account name exceeds ${AppConstants.maxAccountNameLength} characters';
    }
    return null;
  }

  Account copyWith({
    String? name,
    AccountType? type,
    Money? openingBalance,
    Money? currentBalance,
    bool? isArchived,
    int? sortOrder,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    openingBalance,
    currentBalance,
    isArchived,
    sortOrder,
  ];
}
