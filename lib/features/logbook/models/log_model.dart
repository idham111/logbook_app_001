class LogModel {
  final String title;
  final String description;
  final DateTime timestamp;
  final String category; // TAMBAHAN HOMEWORK — field kategori

  LogModel({
    required this.title,
    required this.description,
    required this.timestamp,
    this.category = 'Umum', // TAMBAHAN HOMEWORK — default agar backward-compatible
  });
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'category': category, // TAMBAHAN HOMEWORK
    };
  }
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      category: map['category'] ?? 'Umum', // TAMBAHAN HOMEWORK — default untuk data lama
    );
  }
}