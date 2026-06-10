import 'package:equatable/equatable.dart';

import '../../../core/database/app_database.dart';
import '../../accounts/domain/money.dart';

/// Transaction domain entity. Immutable; maps 1-to-1 with TransactionData row.
final class FinTransaction extends Equatable {
  final String id;
  final TransactionType type;
  final Money amount;
  final String debitAccountId;
  final String creditAccountId;
  final String? categoryId;
  final String description;
  final String? notes;
  final DateTime transactionDate;
  final DateTime createdAt;
  final bool isBookmarked;
  final String? receiptImagePath;

  const FinTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.debitAccountId,
    required this.creditAccountId,
    this.categoryId,
    required this.description,
    this.notes,
    required this.transactionDate,
    required this.createdAt,
    required this.isBookmarked,
    this.receiptImagePath,
  });

  factory FinTransaction.fromData(TransactionData data) {
    return FinTransaction(
      id: data.id,
      type: data.type,
      amount: Money(subunits: data.amount),
      debitAccountId: data.debitAccountId,
      creditAccountId: data.creditAccountId,
      categoryId: data.categoryId,
      description: data.description,
      notes: data.notes,
      transactionDate: DateTime.parse(data.transactionDate),
      createdAt: DateTime.parse(data.createdAt),
      isBookmarked: data.isBookmarked,
      receiptImagePath: data.receiptImagePath,
    );
  }

  /// Returns validation error message or null if valid.
  static String? validate({
    required int amountSubunits,
    required String debitAccountId,
    required String creditAccountId,
    required TransactionType type,
  }) {
    if (amountSubunits <= 0) return 'Amount must be greater than zero';
    if (type == TransactionType.transfer && debitAccountId == creditAccountId) {
      return 'Transfer source and destination accounts must differ';
    }
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    type,
    amount,
    debitAccountId,
    creditAccountId,
    categoryId,
    description,
    transactionDate,
    isBookmarked,
  ];
}
