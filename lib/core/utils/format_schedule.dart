String formatSchedule(String? value) {
  if (value == null || value.isEmpty) {
    return 'Not scheduled';
  }

  final dateTime = DateTime.tryParse(value);

  if (dateTime == null) {
    return value;
  }

  final localTime = dateTime.toLocal();

  final date =
      '${localTime.day.toString().padLeft(2, '0')}/'
      '${localTime.month.toString().padLeft(2, '0')}/'
      '${localTime.year}';

  final hour = localTime.hour % 12 == 0 ? 12 : localTime.hour % 12;
  final minute = localTime.minute.toString().padLeft(2, '0');
  final period = localTime.hour >= 12 ? 'PM' : 'AM';

  return '$date • $hour:$minute $period';
}
