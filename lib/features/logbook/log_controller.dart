import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

class LogController extends ChangeNotifier {
  final String username;
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);

  static const String _src = 'log_controller.dart';

  LogController({required this.username});


  Future<void> fetchLogs() async {
    try {
      final data = await MongoService().getLogs(username: username);
      logsNotifier.value = data;

      LogHelper.info(
        '${data.length} log berhasil di-fetch dari Cloud',
        source: _src,
      );
    } catch (e, stackTrace) {
      LogHelper.severe(
        'Gagal fetch logs',
        source: _src,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }


  Future<void> addLog(String title, String description,
      {String category = 'Umum'}) async {
    try {
      final newLog = LogModel(
        username: username,
        title: title,
        description: description,
        timestamp: DateTime.now(),
        category: category,
      );

      LogHelper.info("User menekan simpan: '$title'", source: _src);

      await MongoService().insertLog(newLog);
      await fetchLogs();

      LogHelper.info("Log '$title' berhasil ditambahkan", source: _src);
    } catch (e, stackTrace) {
      LogHelper.severe(
        'Gagal menambahkan log',
        source: _src,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }


  Future<void> updateLog(int index, String title, String description,
      {String category = 'Umum'}) async {
    try {
      final currentLog = logsNotifier.value[index];

      final updatedLog = LogModel(
        id: currentLog.id,
        username: username,
        title: title,
        description: description,
        timestamp: currentLog.timestamp,
        category: category,
      );

      await MongoService().updateLog(updatedLog);
      await fetchLogs();

      LogHelper.info("Log '$title' berhasil diupdate", source: _src);
    } catch (e, stackTrace) {
      LogHelper.severe(
        'Gagal update log',
        source: _src,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }


  Future<void> removeLog(int index) async {
    try {
      final log = logsNotifier.value[index];

      if (log.id == null) {
        throw Exception('ID log tidak ditemukan, tidak bisa dihapus');
      }

      await MongoService().deleteLog(log.id!);
      await fetchLogs();

      LogHelper.info("Log '${log.title}' berhasil dihapus", source: _src);
    } catch (e, stackTrace) {
      LogHelper.severe(
        'Gagal hapus log',
        source: _src,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}