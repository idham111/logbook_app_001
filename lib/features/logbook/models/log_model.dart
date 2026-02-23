class LogModel {
  final String title;
  final String description;
  final DateTime timestamp;
  LogModel({
    required this.title,
    required this.description,
    required this.timestamp,
  });
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}