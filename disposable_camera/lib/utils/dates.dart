const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatDate(DateTime date) =>
    '${_months[date.month - 1]} ${date.day}, ${date.year}';

String formatTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

/// Short countdown like "21h", "45m", or "soon" for develop timers.
String formatCountdown(Duration remaining) {
  if (remaining.inDays >= 1) {
    return '${remaining.inDays}d ${remaining.inHours % 24}h';
  }
  if (remaining.inHours >= 1) return '${remaining.inHours}h';
  if (remaining.inMinutes >= 1) return '${remaining.inMinutes}m';
  return 'soon';
}
