import 'dart:io';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

class MongoService {
  static final MongoService _instance = MongoService._internal();

  Db? _db;
  DbCollection? _collection;

  static const String _src = 'mongo_service.dart';

  factory MongoService() => _instance;
  MongoService._internal();

  Future<DbCollection> _getSafeCollection() async {
    if (_db == null || !_db!.isConnected || _collection == null) {
      LogHelper.warning(
        'Koleksi belum siap, mencoba rekoneksi...',
        source: _src,
      );
      await connect();
    }
    return _collection!;
  }

  Future<void> connect() async {
    try {
      final dbUri = dotenv.env['MONGODB_URI'];
      if (dbUri == null || dbUri.isEmpty) {
        throw Exception('MONGODB_URI tidak ditemukan di .env');
      }

      LogHelper.info('DATABASE: Membuka koneksi...', source: _src);

      if (dbUri.startsWith('mongodb+srv://')) {
        LogHelper.warning(
          'Menggunakan format SRV — pastikan perangkat bisa akses dns.google.com. '
          'Jika gagal, ganti ke format standar mongodb:// di .env',
          source: _src,
        );
      }

      _db = await Db.create(dbUri);

      await _db!.open().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception(
            'Koneksi Timeout. Cek IP Whitelist (0.0.0.0/0) atau jaringan.',
          );
        },
      );

      _collection = _db!.collection('logs');

      LogHelper.info('DATABASE: Terhubung & Koleksi Siap', source: _src);
    } on SocketException catch (e, stackTrace) {
      LogHelper.severe(
        'DATABASE: Gagal DNS/Socket — pastikan INTERNET permission ada '
        'dan gunakan format mongodb:// (bukan mongodb+srv://)',
        source: _src,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      LogHelper.severe(
        'DATABASE: Gagal Koneksi',
        source: _src,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }


  /// LANGKAH 4.1: READ dengan Collaborative Filter berdasarkan teamId
  Future<List<LogModel>> getLogs({required String teamId}) async {
    try {
      final collection = await _getSafeCollection();

      LogHelper.info('DATABASE: Fetching data for Team: $teamId', source: _src);

      final data = await collection.find(
        where.eq('teamId', teamId), // Filter berdasarkan tim, bukan username
      ).toList();

      if (data.isEmpty) {
        LogHelper.warning('DATABASE: Data kosong untuk team $teamId', source: _src);
      } else {
        LogHelper.info(
          'DATABASE: ${data.length} dokumen berhasil di-fetch untuk team $teamId',
          source: _src,
        );
      }

      return data.map((json) => LogModel.fromMap(json)).toList();
    } catch (e, stackTrace) {
      LogHelper.severe(
        'DATABASE: Fetch Failed',
        source: _src,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  Future<void> insertLog(LogModel log) async {
    try {
      final collection = await _getSafeCollection();

      final map = log.toMap();

      if (log.id == null) {
        map.remove('_id');
      }

      await collection.insertOne(map);

      LogHelper.info(
        "DATABASE: Insert '${log.title}' berhasil",
        source: _src,
      );
    } catch (e, stackTrace) {
      LogHelper.severe(
        'DATABASE: Insert Failed',
        source: _src,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }


  Future<void> updateLog(LogModel log) async {
    try {
      final collection = await _getSafeCollection();

      if (log.id == null) {
        throw Exception('ID Log tidak ditemukan untuk update');
      }

      await collection.replaceOne(
        where.id(ObjectId.fromHexString(log.id!)),
        log.toMap(),
      );

      LogHelper.info(
        "DATABASE: Update '${log.title}' berhasil",
        source: _src,
      );
    } catch (e, stackTrace) {
      LogHelper.severe(
        'DATABASE: Update Gagal',
        source: _src,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }


  Future<void> deleteLog(String id) async {
    try {
      final collection = await _getSafeCollection();

      await collection.remove(where.id(ObjectId.fromHexString(id)));

      LogHelper.info('DATABASE: Hapus ID $id berhasil', source: _src);
    } catch (e, stackTrace) {
      LogHelper.severe(
        'DATABASE: Hapus Gagal',
        source: _src,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }


  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      LogHelper.info('DATABASE: Koneksi ditutup', source: _src);
    }
  }
}