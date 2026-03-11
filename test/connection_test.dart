import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';

void main() {
  const String src = 'connection_test.dart';

  setUpAll(() async {

    LogHelper.init(level: Level.ALL);
    await dotenv.load(fileName: ".env");
  });
  test('MONGODB_URI harus tersedia di file .env', () {
    LogHelper.info('--- TEST: Cek MONGODB_URI ---', source: src);

    final uri = dotenv.env['MONGODB_URI'];

    expect(
      uri,
      isNotNull,
      reason: 'MONGODB_URI tidak ditemukan di .env! '
          'Pastikan file .env berisi MONGODB_URI=mongodb+srv://...',
    );
    expect(
      uri!.isNotEmpty,
      isTrue,
      reason: 'MONGODB_URI kosong! Isi dengan connection string MongoDB Atlas.',
    );

    // Jangan log URI lengkap — bisa mengandung password
    LogHelper.info('MONGODB_URI ditemukan (${uri.length} karakter)', source: src);
  });

  test(
    'Memastikan koneksi ke MongoDB Atlas berhasil via MongoService',
    () async {
      final mongoService = MongoService();
      LogHelper.info('--- START CONNECTION TEST ---', source: src);

      try {
        await mongoService.connect();

        expect(dotenv.env['MONGODB_URI'], isNotNull);
        LogHelper.info('Koneksi Atlas Terverifikasi', source: src);
      } catch (e) {
        LogHelper.severe('Kegagalan koneksi', source: src, error: e);
        fail('Koneksi gagal: $e');
      } finally {
        await mongoService.close();
        LogHelper.info('--- END CONNECTION TEST ---', source: src);
      }
    },
  );

  // ─── TEST 3: CRUD Smoke Test ────────────────────────
  test('Smoke test: Insert, Read, Delete log ke MongoDB', () async {
    final mongoService = MongoService();
    LogHelper.info('--- START CRUD SMOKE TEST ---', source: src);

    try {
      await mongoService.connect();

      // 1. INSERT
      final testLog = LogModel(
        username: 'test_user',
        title: 'Test Smoke',
        description: 'Data percobaan dari connection_test.dart',
        timestamp: DateTime.now().toIso8601String(),
        category: 'Testing',
        authorId: 'test_user_001',
        teamId: 'MEKTRA_KLP_01',
      );
      await mongoService.insertLog(testLog);

      // 2. READ
      final logs = await mongoService.getLogs(teamId: 'MEKTRA_KLP_01');
      final found = logs.any((l) => l.title == 'Test Smoke');
      expect(found, isTrue, reason: 'Log yang baru di-insert tidak ditemukan');

      // 3. DELETE
      final insertedLog = logs.firstWhere((l) => l.title == 'Test Smoke');
      await mongoService.deleteLog(insertedLog.id!);

      LogHelper.info('CRUD Smoke Test selesai', source: src);
    } catch (e) {
      LogHelper.severe('CRUD Smoke Test gagal', source: src, error: e);
      fail('CRUD Smoke Test gagal: $e');
    } finally {
      await mongoService.close();
      LogHelper.info('--- END CRUD SMOKE TEST ---', source: src);
    }
  });
}
