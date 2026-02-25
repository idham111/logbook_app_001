import 'package:flutter/material.dart';
import 'log_controller.dart';
import 'models/log_model.dart';
import '../auth/login_view.dart';
class LogView extends StatefulWidget {
  final String username;
  const LogView({super.key, required this.username});
  @override
  State<LogView> createState() => _LogViewState();
}
// TAMBAHAN HOMEWORK — daftar kategori & warna per kategori
const List<String> kCategories = ['Umum', 'Pekerjaan', 'Pribadi', 'Urgent'];
Color _categoryColor(String category) {
  switch (category) {
    case 'Pekerjaan':
      return Colors.blue.shade100;
    case 'Pribadi':
      return Colors.green.shade100;
    case 'Urgent':
      return Colors.red.shade100;
    default:
      return Colors.grey.shade200;
  }
}

class _LogViewState extends State<LogView> {
  late final LogController _controller;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // TAMBAHAN HOMEWORK — search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // TAMBAHAN HOMEWORK — kategori yang dipilih saat add/edit
  String _selectedCategory = 'Umum';

  @override
  void initState() {
    super.initState();
    _controller = LogController(username: widget.username);
    _controller.loadLogs();
  }
  void _showAddDialog() {
    _titleController.clear();
    _descController.clear();
    _selectedCategory = 'Umum'; // TAMBAHAN HOMEWORK — reset kategori
    showDialog(
      context: context,
      builder: (context) {
        // TAMBAHAN HOMEWORK — StatefulBuilder agar dropdown bisa update di dialog
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
                  // TAMBAHAN HOMEWORK — dropdown kategori
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
                  onPressed: () {
                    if (_titleController.text.isNotEmpty) {
                      _controller.addLog(
                        _titleController.text,
                        _descController.text,
                        category: _selectedCategory, // TAMBAHAN HOMEWORK
                      );
                      Navigator.pop(context);
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
  void _showEditDialog(int index) {
    final current = _controller.logsNotifier.value[index];
    _titleController.text = current.title;
    _descController.text = current.description;
    _selectedCategory = current.category; // TAMBAHAN HOMEWORK — isi kategori dari data
    showDialog(
      context: context,
      builder: (context) {
        // TAMBAHAN HOMEWORK — StatefulBuilder agar dropdown bisa update di dialog
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
                  // TAMBAHAN HOMEWORK — dropdown kategori
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
                  onPressed: () {
                    if (_titleController.text.isNotEmpty) {
                      _controller.updateLog(
                        index,
                        _titleController.text,
                        _descController.text,
                        category: _selectedCategory, // TAMBAHAN HOMEWORK
                      );
                      Navigator.pop(context);
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logbook: ${widget.username}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
          // TAMBAHAN HOMEWORK — Search TextField
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan judul...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
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
          // TAMBAHAN HOMEWORK — list / empty state
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.logsNotifier,
              builder: (context, logs, child) {
                // TAMBAHAN HOMEWORK — filter real-time berdasarkan judul
                final filteredLogs = _searchQuery.isEmpty
                    ? logs
                    : logs
                        .where((l) =>
                            l.title.toLowerCase().contains(_searchQuery))
                        .toList();

                // TAMBAHAN HOMEWORK — Empty State yang menarik
                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.menu_book_rounded,
                            size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada catatan',
                          style: TextStyle(
                              fontSize: 18, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tekan tombol + untuk mulai mencatat',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                // TAMBAHAN HOMEWORK — empty search result
                if (filteredLogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ditemukan catatan untuk "$_searchQuery"',
                          style: TextStyle(
                              fontSize: 15, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    // TAMBAHAN HOMEWORK — cari index asli untuk CRUD
                    final originalIndex = logs.indexOf(log);
                    return Card(
                      // TAMBAHAN HOMEWORK — warna Card berdasarkan kategori
                      color: _categoryColor(log.category),
                      child: ListTile(
                        title: Text(log.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log.description),
                            const SizedBox(height: 4),
                            // TAMBAHAN HOMEWORK — label kategori
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _categoryColor(log.category)
                                    .withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                log.category,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditDialog(originalIndex),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  _controller.removeLog(originalIndex),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}