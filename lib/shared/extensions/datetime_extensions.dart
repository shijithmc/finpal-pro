import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  /// e.g. "June 2025"
  String get monthYearLabel => DateFormat.yMMMM().format(this);

  /// e.g. "Jun 2025" (compact)
  String get shortMonthYear => DateFormat.yMMM().format(this);

  /// e.g. "10 Jun" — short date label used in transaction lists.
  String get shortDateLabel => DateFormat('d MMM').format(this);

  /// True if this DateTime is in the same calendar month as [other].
  bool isSameMonth(DateTime other) =>
      year == other.year && month == other.month;

  /// First moment of this month.
  DateTime get monthStart => DateTime(year, month);

  /// Last moment of this month (start of next month minus 1 microsecond).
  DateTime get monthEnd =>
      DateTime(year, month + 1).subtract(const Duration(microseconds: 1));
}
