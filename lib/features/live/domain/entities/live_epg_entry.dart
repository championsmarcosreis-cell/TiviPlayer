class LiveEpgEntry {
  const LiveEpgEntry({
    required this.title,
    required this.startAt,
    required this.endAt,
    this.description,
  });

  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final String? description;

  bool isOnAirAt(DateTime instant) {
    return !instant.isBefore(startAt) && instant.isBefore(endAt);
  }
}
