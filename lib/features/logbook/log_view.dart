import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'log_controller.dart';
import 'models/log_model.dart';
import 'package:logbook_app_001/services/access_control_service.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';
import 'package:logbook_app_001/features/logbook/log_editor_page.dart'; // BARU: Import Editor Page
import '../auth/login_view.dart';

class LogView extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  const LogView({super.key, required this.currentUser});
  @override
  State<LogView> createState() => _LogViewState();
}

const List<String> kCategories = ['Umum', 'Pekerjaan', 'Pribadi', 'Urgent'];
Color _categoryColor(String category) {
  switch (category) {
    case 'Pekerjaan':
      return Colors.blue.shade900;
    case 'Pribadi':
      return Colors.green.shade900;
    case 'Urgent':
      return Colors.red.shade900;
    default:
      return Colors.grey.shade800;
  }
}

// ── HOMEWORK 3: Timestamp relatif ──────────────────────────────────────────
String _formatRelativeTime(DateTime timestamp) {
  final diff = DateTime.now().difference(timestamp);
  if (diff.inSeconds < 60) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
  if (diff.inDays == 1) {
    return 'Kemarin, ${DateFormat('HH:mm').format(timestamp)}';
  }
  if (diff.inDays < 7) return '${diff.inDays} hari yang lalu';
  return DateFormat('d MMM yyyy', 'id_ID').format(timestamp);
}

class _LogViewState extends State<LogView> {
  late final LogController _controller;
  late final String _username;
  late final String _userId;
  late final String _userRole;
  late final String _teamId;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const String _src = 'log_view.dart';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);

    // Extract user info dari currentUser
    _username = widget.currentUser['username'] as String;
    _userId = widget.currentUser['uid'] as String;
    _userRole = widget.currentUser['role'] as String;
    _teamId = widget.currentUser['teamId'] as String;

    _controller = LogController(
      username: _username,
      userId: _userId,
      userRole: _userRole,
      teamId: _teamId,
    );

    LogHelper.info(
      'LogView dibuka untuk user: $_username (Role: $_userRole, Team: $_teamId)',
      source: _src,
    );
    
    // LANGKAH 4: Panggil loadLogs setelah frame pertama selesai untuk hindari Navigator error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadLogs();
    });
  }

  void _refreshLogs() {
    LogHelper.info('UI: Refresh data dipicu', source: _src);
    _controller.loadLogs(); // LANGKAH 4: Gunakan loadLogs() yang Offline-First
  }

  // ── LANGKAH 3.3: Navigasi ke Halaman Editor (Gantikan Dialog Lama) ────
  void _goToEditor({LogModel? log, int? index}) {
    LogHelper.info(
      'UI: Navigasi ke Editor (${log == null ? "Tambah Baru" : "Edit"})',
      source: _src,
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          currentUser: {
            'username': _username,
            'uid': _userId,
            'role': _userRole,
            'teamId': _teamId,
          },
        ),
      ),
    ).then((_) {
      // Refresh data setelah kembali dari editor
      _refreshLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Logbook: $_username ($_userRole)',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // LANGKAH 4.3: Indikator Visual Sync Status
          ValueListenableBuilder<bool>(
            valueListenable: _controller.syncStatusNotifier,
            builder: (context, isSynced, _) {
              return Tooltip(
                message: isSynced 
                    ? 'Data tersinkron dengan Cloud' 
                    : 'Data tertahan lokal (offline)',
                child: Icon(
                  isSynced ? Icons.cloud_done : Icons.cloud_off,
                  color: isSynced ? Colors.greenAccent : Colors.orangeAccent,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshLogs,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Apakah Anda yakin ingin logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginView()),
                          (route) => false,
                        );
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan judul...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white54),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white54),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.purple),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // LANGKAH 4: ValueListenableBuilder untuk Offline-First
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.logsNotifier,
              builder: (context, logs, child) {
                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.menu_book_rounded,
                            size: 80, color: Colors.white.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'Data Kosong',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tekan tombol + untuk mulai mencatat',
                          style: TextStyle(
                              fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  );
                }

                final filteredLogs = _searchQuery.isEmpty
                    ? logs
                    : logs
                        .where((l) => 
                            l.title.toLowerCase().contains(_searchQuery) ||
                            l.description.toLowerCase().contains(_searchQuery)
                        )
                        .toList();

                if (filteredLogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: Colors.white.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ditemukan catatan untuk "$_searchQuery"',
                          style: const TextStyle(fontSize: 15, color: Colors.white),
                        ),
                      ],
                    ),
                  );
                }

                // ── HOMEWORK 2: Pull-to-Refresh ──────────────────────────
                return RefreshIndicator(
                  color: Colors.purple,
                  onRefresh: () async => _refreshLogs(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      final originalIndex = logs.indexOf(log);

                      return Card(
                        color: _categoryColor(log.category),
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          title: Text(log.title,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(log.description,
                                  style: const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 6),

                              // ── HOMEWORK 3: Timestamp relatif + tooltip ──
                              Tooltip(
                                message: DateFormat(
                                        'EEEE, d MMMM yyyy — HH:mm', 'id_ID')
                                    .format(log.timestampDate),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time,
                                        size: 14, color: Colors.white54),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatRelativeTime(log.timestampDate),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.white54),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _categoryColor(log.category)
                                      .withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  log.category,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ── LANGKAH 2.3 & 3.3: Conditional Rendering untuk Edit ──────────
                              if (AccessControlService.canPerform(
                                _userRole,
                                AccessControlService.actionUpdate,
                                isOwner: log.authorId == _userId,
                              ))
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.white70),
                                  onPressed: () => _goToEditor(log: log, index: originalIndex),
                                ),

                              // ── LANGKAH 2.3: Conditional Rendering untuk Delete ──────────
                              if (AccessControlService.canPerform(
                                _userRole,
                                AccessControlService.actionDelete,
                                isOwner: log.authorId == _userId,
                              ))
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.white70),
                                  onPressed: () async {
                                    LogHelper.info(
                                      "UI: User menekan hapus ('${log.title}')",
                                      source: _src,
                                    );
                                    try {
                                      await _controller.removeLog(originalIndex);
                                      LogHelper.info('UI: Data berhasil dihapus', source: _src);
                                    } catch (e) {
                                      LogHelper.severe('UI: Data gagal dihapus',
                                          source: _src, error: e);
                                      // Tampilkan error ke user
                                      if (mounted && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString()),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                    _refreshLogs();
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        onPressed: () => _goToEditor(), // LANGKAH 3.3: Navigasi ke Editor Page
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Tambah Catatan Baru',
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}