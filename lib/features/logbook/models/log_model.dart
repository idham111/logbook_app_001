import 'package:mongo_dart/mongo_dart.dart';

class LogModel {
  ObjectId? id;

  final String username;
  final String title;
  final String description;
  final DateTime timestamp;
  final String category;

  LogModel({
    this.id,
    required this.username,
    required this.title,
    required this.description,
    required this.timestamp,
    this.category = 'Umum',
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'username': username,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'category': category,
    };
  }

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] as ObjectId?,
      username: map['username'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'].toString())
          : DateTime.now(),
      category: map['category'] ?? 'Umum',
    );
  }
}