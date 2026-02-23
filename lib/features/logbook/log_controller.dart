import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models/log_model.dart';
class LogController extends ChangeNotifier {
  final String username;
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  
  LogController({required this.username});
  
  Future<void> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('logs_$username');
    if (data != null) {
      List<dynamic> jsonList = jsonDecode(data);
      logsNotifier.value = jsonList.map((e) => LogModel.fromMap(e)).toList();
    }
  }
  Future<void> _saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(
      logsNotifier.value.map((e) => e.toMap()).toList(),
    );
    await prefs.setString('logs_$username', data);
  }
  void addLog(String title, String description) {
    logsNotifier.value = [
      ...logsNotifier.value,
      LogModel(
        title: title,
        description: description,
        timestamp: DateTime.now(),
      ),
    ];
    _saveToDisk();
  }
  void updateLog(int index, String title, String description) {
    final List<LogModel> updated = List.from(logsNotifier.value);
    updated[index] = LogModel(
      title: title,
      description: description,
      timestamp: updated[index].timestamp,
    );
    logsNotifier.value = updated;
    _saveToDisk();
  }
  void removeLog(int index) {
    final List<LogModel> updated = List.from(logsNotifier.value);
    updated.removeAt(index);
    logsNotifier.value = updated;
    _saveToDisk();
  }
}