class DailySnapshot {
  final DateTime date;
  final double limit;
  final double spent;

  DailySnapshot({required this.date, required this.limit, required this.spent});

  double get surplus => limit - spent;
  bool get isOverspent => spent > limit && limit > 0;

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}
