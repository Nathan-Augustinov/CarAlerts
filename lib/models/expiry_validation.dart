/// Expiries are calendar dates in the same ISO format as built-in documents.
String? validateExpiryDate(DateTime? date, {String? original, DateTime? now}) {
  if (date == null) return 'Choose an expiry date.';
  final today = now ?? DateTime.now();
  final day = DateTime(date.year, date.month, date.day);
  final previous = original == null ? null : DateTime.tryParse(original);
  if (previous != null &&
      day == DateTime(previous.year, previous.month, previous.day)) {
    return null;
  }
  return day.isBefore(DateTime(today.year, today.month, today.day))
      ? 'Choose today or a future date.'
      : null;
}
