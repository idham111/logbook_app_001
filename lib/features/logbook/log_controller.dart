import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/services/access_control_service.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

class LogController extends ChangeNotifier {
  final String username;
  final String userId;
  final String userRole;
  final String teamId;
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  
  // LANGKAH 4.3: Sync Status Indicator untuk UI
  final ValueNotifier<bool> syncStatusNotifier = ValueNotifier(true); // true = synced, false = pending

  // LANGKAH 4: Hive Box untuk Offline Storage
  late Box<LogModel> _myBox;
  
  // LANGKAH 4.3: Connectivity listener untuk background sync
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;

  static const String _src = 'log_controller.dart';

  LogController({
    required this.username,
    required this.userId,
    required this.userRole,
    required this.teamId,
  }) {
    _initHive();
    _startConnectivityListener();
  }

  /// Initialize Hive Box
  Future<void> _initHive() async {
    try {
      _myBox = await Hive.openBox<LogModel>('offline_logs');
      LogHelper.info('Hive Box berhasil dibuka', source: _src);
      
      // PERBAIKAN: Jangan auto-load di constructor untuk hindari rebuild sebelum widget ready
      // loadLogs() akan dipanggil manual dari initState dengan addPostFrameCallback
    } catch (e, stackTrace) {
      LogHelper.severe('Gagal membuka Hive Box', source: _src, error: e, stackTrace: stackTrace);
    }
  }

  /// Helper method: Pastikan Hive Box terbuka
  Future<void> _ensureBoxOpen() async {
    if (!Hive.isBoxOpen('offline_logs')) {
      _myBox = await Hive.openBox<LogModel>('offline_logs');
      LogHelper.info('Hive Box dibuka (late open)', source: _src);
    }
  }

  /// LANGKAH 4.3: Background Sync Listener
  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final wasOffline = !_isOnline;
      _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
      
      if (wasOffline && _isOnline) {
        LogHelper.info('SYNC: Internet kembali aktif, memicu sync...', source: _src);
        _syncPendingData();
      }
    });
  }

  /// LANGKAH 4.3: Sync pending data saat kembali online
  Future<void> _syncPendingData() async {
    try {
      LogHelper.info('SYNC: Mencoba sinkronisasi data pending...', source: _src);
      await loadLogs(); // Refresh dari cloud
    } catch (e) {
      LogHelper.warning('SYNC: Gagal sinkronisasi otomatis - $e', source: _src);
    }
  }

  /// LANGKAH 4.2: LOAD DATA (Offline-First Strategy)
  Future<void> loadLogs() async {
    try {
      // PERBAIKAN: Pastikan box sudah terbuka sebelum akses
      await _ensureBoxOpen();
      
      // Langkah 1: Ambil data dari Hive (Sangat Cepat/Instan)
      final localData = _myBox.values.toList();
      logsNotifier.value = localData;
      
      LogHelper.info(
        'OFFLINE-FIRST: ${localData.length} log dimuat dari Hive',
        source: _src,
      );

      // Langkah 2: Sync dari Cloud (Background)
      try {
        final cloudData = await MongoService().getLogs(teamId: teamId);

        // Update Hive dengan data terbaru dari Cloud agar sinkron
        await _myBox.clear();
        await _myBox.addAll(cloudData);

        // Update UI dengan data Cloud
        logsNotifier.value = cloudData;
        syncStatusNotifier.value = true; // ✅ Synced

        LogHelper.info(
          'SYNC: Data berhasil diperbarui dari Atlas (${cloudData.length} dokumen)',
          source: _src,
        );
      } catch (e) {
        syncStatusNotifier.value = false; // ⚠️ Offline/Pending
        LogHelper.warning(
          'OFFLINE: Menggunakan data cache lokal (${{ localData.length }} dokumen)',
          source: _src,
        );
      }
    } catch (e, stackTrace) {
      LogHelper.severe(
        'Gagal load logs',
        source: _src,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// LANGKAH 4.2: ADD DATA (Instant Local + Background Cloud)
  Future<void> addLog(String title, String description,
      {String category = 'Umum'}) async {
    try {
      // Validasi keamanan: cek apakah user bisa create
      if (!AccessControlService.canPerform(userRole, AccessControlService.actionCreate)) {
        LogHelper.warning(
          'SECURITY: Unauthorized create attempt by $username ($userRole)',
          source: _src,
        );
        throw Exception('Anda tidak memiliki izin untuk membuat catatan');
      }

      // Generate ID menggunakan ObjectId (dalam format String untuk Hive)
      final newLog = LogModel(
        id: ObjectId().oid, // Menggunakan .oid (String) untuk Hive
        username: username,
        title: title,
        description: description,
        timestamp: DateTime.now().toIso8601String(),
        category: category,
        authorId: userId,
        teamId: teamId,
      );

      LogHelper.info("User menekan simpan: '$title'", source: _src);

      // PERBAIKAN: Pastikan box terbuka
      await _ensureBoxOpen();

      // ACTION 1: Simpan ke Hive (Instan)
      await _myBox.add(newLog);
      logsNotifier.value = [...logsNotifier.value, newLog];
      
      LogHelper.info('LOCAL: Data tersimpan di Hive', source: _src);

      // ACTION 2: Kirim ke MongoDB Atlas (Background)
      try {
        await MongoService().insertLog(newLog);
        syncStatusNotifier.value = true; // ✅ Synced
        LogHelper.info('SYNC: Data tersinkron ke Cloud', source: _src);
      } catch (e) {
        syncStatusNotifier.value = false; // ⚠️ Pending sync
        LogHelper.warning(
          'WARNING: Data tersimpan lokal, akan sinkron saat online - $e',
          source: _src,
        );
        // Data tetap tersimpan di Hive, akan di-sync otomatis saat online
      }

      LogHelper.info("Log '$title' berhasil ditambahkan", source: _src);
    } catch (e, stackTrace) {
      LogHelper.severe(
        'Gagal menambahkan log',
        source: _src,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// LANGKAH 4.2: UPDATE DATA (Instant Local + Background Cloud)
  Future<void> updateLog(int index, String title, String description,
      {String category = 'Umum'}) async {
    try {
      final currentLog = logsNotifier.value[index];
      final isOwner = currentLog.authorId == userId;

      // Validasi keamanan: cek apakah user bisa update
      if (!AccessControlService.canPerform(
        userRole,
        AccessControlService.actionUpdate,
        isOwner: isOwner,
      )) {
        LogHelper.warning(
          'SECURITY BREACH: Unauthorized update attempt by $username ($userRole) on log "${currentLog.title}"',
          source: _src,
        );
        throw Exception('Anda tidak memiliki izin untuk mengubah catatan ini');
      }

      final updatedLog = LogModel(
        id: currentLog.id,
        username: username,
        title: title,
        description: description,
        timestamp: currentLog.timestamp,
        category: category,
        authorId: currentLog.authorId,
        teamId: currentLog.teamId,
      );

      // PERBAIKAN: Pastikan box terbuka
      await _ensureBoxOpen();

      // ACTION 1: Update di Hive (Instan)
      await _myBox.putAt(index, updatedLog);
      final updatedList = List<LogModel>.from(logsNotifier.value);
      updatedList[index] = updatedLog;
      logsNotifier.value = updatedList;
      
      LogHelper.info('LOCAL: Data diupdate di Hive', source: _src);

      // ACTION 2: Update ke MongoDB Atlas (Background)
      try {
        await MongoService().updateLog(updatedLog);
        syncStatusNotifier.value = true; // ✅ Synced
        LogHelper.info('SYNC: Update tersinkron ke Cloud', source: _src);
      } catch (e) {
        syncStatusNotifier.value = false; // ⚠️ Pending sync
        LogHelper.warning(
          'WARNING: Update tersimpan lokal, akan sinkron saat online - $e',
          source: _src,
        );
      }

      LogHelper.info("Log '$title' berhasil diupdate", source: _src);
    } catch (e, stackTrace) {
      LogHelper.severe(
        'Gagal update log',
        source: _src,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// LANGKAH 4.2: DELETE DATA (Instant Local + Background Cloud)
  Future<void> removeLog(int index) async {
    try {
      final log = logsNotifier.value[index];
      final isOwner = log.authorId == userId;

      // Validasi keamanan: cek apakah user bisa delete
      if (!AccessControlService.canPerform(
        userRole,
        AccessControlService.actionDelete,
        isOwner: isOwner,
      )) {
        LogHelper.warning(
          'SECURITY BREACH: Unauthorized delete attempt by $username ($userRole) on log "${log.title}"',
          source: _src,
        );
        throw Exception('Anda tidak memiliki izin untuk menghapus catatan ini');
      }

      if (log.id == null) {
        throw Exception('ID log tidak ditemukan, tidak bisa dihapus');
      }

      // PERBAIKAN: Pastikan box terbuka
      await _ensureBoxOpen();

      // ACTION 1: Hapus dari Hive (Instan)
      await _myBox.deleteAt(index);
      final updatedList = List<LogModel>.from(logsNotifier.value);
      updatedList.removeAt(index);
      logsNotifier.value = updatedList;
      
      LogHelper.info('LOCAL: Data dihapus dari Hive', source: _src);

      // ACTION 2: Hapus dari MongoDB Atlas (Background)
      try {
        await MongoService().deleteLog(log.id!);
        syncStatusNotifier.value = true; // ✅ Synced
        LogHelper.info('SYNC: Hapus tersinkron ke Cloud', source: _src);
      } catch (e) {
        syncStatusNotifier.value = false; // ⚠️ Pending sync
        LogHelper.warning(
          'WARNING: Hapus dilakukan lokal, akan sinkron saat online - $e',
          source: _src,
        );
      }

      LogHelper.info("Log '${log.title}' berhasil dihapus", source: _src);
    } catch (e, stackTrace) {
      LogHelper.severe(
        'Gagal hapus log',
        source: _src,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    logsNotifier.dispose();
    syncStatusNotifier.dispose();
    super.dispose();
  }
}