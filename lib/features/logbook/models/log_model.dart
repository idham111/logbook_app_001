import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel {
  @HiveField(7)
  final String? id;

  @HiveField(0)
  final String username;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String timestamp; // ← ganti jadi String agar Hive lebih mudah

  @HiveField(4)
  final String category;

  @HiveField(5)
  final String authorId; // BARU — untuk RBAC

  @HiveField(6)
  final String teamId;   // BARU — untuk Team Isolation

  LogModel({
    this.id,
    required this.username,
    required this.title,
    required this.description,
    required String timestamp,
    this.category = 'Umum',
    this.authorId = '',
    this.teamId = '',
  }) : timestamp = timestamp;

  // Helper getter agar kode lain tidak perlu diubah
  DateTime get timestampDate => DateTime.tryParse(timestamp) ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      '_id': id != null ? ObjectId.fromHexString(id!) : ObjectId(),
      'username': username,
      'title': title,
      'description': description,
      'timestamp': timestamp,
      'category': category,
      'authorId': authorId,
      'teamId': teamId,
    };
  }

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: (map['_id'] as ObjectId?)?.oid,
      username: map['username'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: map['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      category: map['category'] ?? 'Umum',
      authorId: map['authorId'] ?? '',
      teamId: map['teamId'] ?? '',
    );
  }
}