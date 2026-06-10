import 'package:equatable/equatable.dart';

import '../../../core/constants/app_constants.dart';

/// Immutable monetary value stored as integer subunits (paise for INR).
/// ₹100.50 = 10050 paise.
final class Money extends Equatable {
  final int subunits;
  final String currencyCode;

  const Money({required this.subunits, this.currencyCode = 'INR'});

  const Money.zero({this.currencyCode = 'INR'}) : subunits = 0;

  factory Money.fromMajorUnits(double amount, {String currencyCode = 'INR'}) {
    final subunits =
        (amount * AppConstants.currencySubunits).round();
    return Money(subunits: subunits, currencyCode: currencyCode);
  }

  double get asMajorUnits =>
      subunits / AppConstants.currencySubunits;

  Money operator +(Money other) {
    assert(currencyCode == other.currencyCode,
        'Cannot add Money with different currencies');
    return Money(subunits: subunits + other.subunits, currencyCode: currencyCode);
  }

  Money operator -(Money other) {
    assert(currencyCode == other.currencyCode,
        'Cannot subtract Money with different currencies');
    return Money(subunits: subunits - other.subunits, currencyCode: currencyCode);
  }

  bool get isNegative => subunits < 0;
  bool get isZero => subunits == 0;
  bool get isPositive => subunits > 0;

  @override
  List<Object?> get props => [subunits, currencyCode];

  @override
  String toString() => '$currencyCode ${asMajorUnits.toStringAsFixed(2)}';
}
