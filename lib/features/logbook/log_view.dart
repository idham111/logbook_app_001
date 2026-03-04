import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'log_controller.dart';
import 'models/log_model.dart';
import 'package:logbook_app_001/services/mongo_service.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';
import '../auth/login_view.dart';

class LogView extends StatefulWidget {
  final String username;
  const LogView({super.key, required this.username});
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
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Umum';

  // ── HOMEWORK 1: Connection Guard ───────────────────────────────────────
  bool _isOffline = false;

  static const String _src = 'log_view.dart';
  late Future<List<LogModel>> _logsFuture;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _controller = LogController(username: widget.username);
    LogHelper.info('LogView dibuka untuk user: ${widget.username}', source: _src);
    _logsFuture = _fetchWithGuard();
  }

  // ── HOMEWORK 1: Wrapper fetch yang mendeteksi offline ──────────────────
  Future<List<LogModel>> _fetchWithGuard() async {
    try {
      final data = await MongoService().getLogs(username: widget.username);
      if (mounted) setState(() => _isOffline = false);
      return data;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('socket') ||
          msg.contains('connection') ||
          msg.contains('timeout') ||
          msg.contains('host lookup')) {
        if (mounted) setState(() => _isOffline = true);
      }
      rethrow;
    }
  }

  void _refreshLogs() {
    LogHelper.info('UI: Refresh data dipicu', source: _src);
    setState(() {
      _logsFuture = _fetchWithGuard();
    });
  }

  void _showAddDialog() {
    _titleController.clear();
    _descController.clear();
    _selectedCategory = 'Umum';

    LogHelper.info('UI: User membuka dialog tambah catatan', source: _src);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Catatan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Judul'),
                  ),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: kCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => _selectedCategory = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () async {
                    if (_titleController.text.isNotEmpty) {
                      Navigator.pop(context);
                      LogHelper.info(
                        "UI: User menekan tombol Simpan ('${_titleController.text}')",
                        source: _src,
                      );
                      try {
                        await _controller.addLog(
                          _titleController.text,
                          _descController.text,
                          category: _selectedCategory,
                        );
                        LogHelper.info('UI: Data berhasil disimpan', source: _src);
                      } catch (e) {
                        LogHelper.severe('UI: Data gagal disimpan', source: _src, error: e);
                      }
                      _refreshLogs();
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditDialog(int index, List<LogModel> logs) {
    final current = logs[index];
    _titleController.text = current.title;
    _descController.text = current.description;
    _selectedCategory = current.category;

    LogHelper.info("UI: User membuka dialog edit ('${current.title}')", source: _src);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Catatan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Judul'),
                  ),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: kCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => _selectedCategory = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () async {
                    if (_titleController.text.isNotEmpty) {
                      Navigator.pop(context);
                      LogHelper.info(
                        "UI: User menekan simpan edit ('${_titleController.text}')",
                        source: _src,
                      );
                      try {
                        await _controller.updateLog(
                          index,
                          _titleController.text,
                          _descController.text,
                          category: _selectedCategory,
                        );
                        LogHelper.info('UI: Data berhasil diupdate', source: _src);
                      } catch (e) {
                        LogHelper.severe('UI: Data gagal diupdate', source: _src, error: e);
                      }
                      _refreshLogs();
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── HOMEWORK 1: Banner offline ─────────────────────────────────────────
  Widget _buildOfflineBanner() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _isOffline
          ? Container(
              key: const ValueKey('offline'),
              width: double.infinity,
              color: Colors.red.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Offline — Tidak dapat terhubung ke server. Tarik untuk mencoba lagi.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                    onPressed: _refreshLogs,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(key: ValueKey('online')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Logbook: ${widget.username}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
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
          // ── HOMEWORK 1: Offline banner ─────────────────────────────────
          _buildOfflineBanner(),

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

          Expanded(
            child: FutureBuilder<List<LogModel>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.purple),
                        SizedBox(height: 16),
                        Text(
                          'Mengambil data dari Cloud...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, size: 64, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak dapat terhubung ke server.\nPastikan internet aktif lalu coba lagi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.redAccent, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _refreshLogs,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                final logs = snapshot.data ?? [];
                _controller.logsNotifier.value = logs;

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
                        .where((l) => l.title.toLowerCase().contains(_searchQuery))
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
                                    .format(log.timestamp),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time,
                                        size: 14, color: Colors.white54),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatRelativeTime(log.timestamp),
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
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white70),
                                onPressed: () => _showEditDialog(originalIndex, logs),
                              ),
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
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}