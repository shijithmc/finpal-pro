import 'package:equatable/equatable.dart';

import '../../../core/database/app_database.dart';

/// Optional filters are combined; an empty filter searches the entire history.
final class TransactionSearchFilter extends Equatable {
  final String query;
  final DateTime? from;
  final DateTime? to;
  final Set<String> accountIds;
  final Set<String> categoryIds;
  final TransactionType? type;
  final int? minAmount;
  final int? maxAmount;

  const TransactionSearchFilter({
    this.query = '',
    this.from,
    this.to,
    this.accountIds = const {},
    this.categoryIds = const {},
    this.type,
    this.minAmount,
    this.maxAmount,
  });

  TransactionSearchFilter copyWith({
    String? query,
    DateTime? from,
    DateTime? to,
    Set<String>? accountIds,
    Set<String>? categoryIds,
    TransactionType? type,
    int? minAmount,
    int? maxAmount,
    bool clearDates = false,
    bool clearType = false,
    bool clearAmount = false,
  }) => TransactionSearchFilter(
    query: query ?? this.query,
    from: clearDates ? null : from ?? this.from,
    to: clearDates ? null : to ?? this.to,
    accountIds: accountIds ?? this.accountIds,
    categoryIds: categoryIds ?? this.categoryIds,
    type: clearType ? null : type ?? this.type,
    minAmount: clearAmount ? null : minAmount ?? this.minAmount,
    maxAmount: clearAmount ? null : maxAmount ?? this.maxAmount,
  );

  @override
  List<Object?> get props => [
    query,
    from,
    to,
    accountIds,
    categoryIds,
    type,
    minAmount,
    maxAmount,
  ];
}
