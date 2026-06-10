extension DateTimeExtensions on DateTime {
  /// Returns "Jun 2026" style month label.
  String get monthYearLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[month - 1]} $year';
  }

  /// Returns "10 Jun 2026" style date label.
  String get shortDateLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '$day ${months[month - 1]} $year';
  }

  /// True if this date is in the same month and year as [other].
  bool isSameMonth(DateTime other) =>
      year == other.year && month == other.month;

  /// First moment of this date's month.
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Last moment of this date's month.
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59);
}
