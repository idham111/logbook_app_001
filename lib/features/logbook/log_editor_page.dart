import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/features/logbook/log_controller.dart';
import 'package:logbook_app_001/helpers/log_helper.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final int? index;
  final LogController controller;
  final Map<String, dynamic> currentUser;

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
    required this.currentUser,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  String _selectedCategory = 'Umum';
  
  static const String _src = 'log_editor_page.dart';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(
      text: widget.log?.description ?? '',
    );
    _selectedCategory = widget.log?.category ?? 'Umum';

    // TAMBAHKAN INI: Listener agar Pratinjau terupdate otomatis
    _descController.addListener(() {
      setState(() {});
    });

    LogHelper.info(
      'LogEditorPage dibuka (${widget.log == null ? "Tambah Baru" : "Edit"})',
      source: _src,
    );
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (widget.log == null) {
        // Tambah Baru
        LogHelper.info('Editor: User menekan simpan (Tambah Baru)', source: _src);
        await widget.controller.addLog(
          _titleController.text,
          _descController.text,
          category: _selectedCategory,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Catatan berhasil disimpan'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Update
        LogHelper.info('Editor: User menekan simpan (Update)', source: _src);
        await widget.controller.updateLog(
          widget.index!,
          _titleController.text,
          _descController.text,
          category: _selectedCategory,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Catatan berhasil diupdate'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      LogHelper.severe('Editor: Gagal menyimpan', source: _src, error: e);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // JANGAN LUPA: Bersihkan controller agar tidak memory leak
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(
            widget.log == null ? "Catatan Baru" : "Edit Catatan",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.purple,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.edit), text: "Editor"),
              Tab(icon: Icon(Icons.visibility), text: "Pratinjau"),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _save,
              tooltip: 'Simpan',
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Editor
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      labelText: "Judul",
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.purple),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Dropdown kategori
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: Colors.grey.shade900,
                    decoration: const InputDecoration(
                      labelText: "Kategori",
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.purple),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Umum', child: Text('Umum')),
                      DropdownMenuItem(value: 'Pekerjaan', child: Text('Pekerjaan')),
                      DropdownMenuItem(value: 'Pribadi', child: Text('Pribadi')),
                      DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCategory = val);
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Help text untuk markdown
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Tips: Gunakan Markdown (# judul, **bold**, *italic*, - list)',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  Expanded(
                    child: TextField(
                      controller: _descController,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: "Tulis laporan dengan format Markdown...\n\nContoh:\n# Judul Besar\n## Subjudul\n- Poin 1\n- Poin 2\n\n**Tebal** dan *miring*",
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white54),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white54),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.purple, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab 2: Markdown Preview
            Container(
              color: Colors.grey.shade900,
              padding: const EdgeInsets.all(16),
              child: _descController.text.trim().isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility_off,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pratinjau akan muncul di sini',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Markdown(
                      data: _descController.text,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: Colors.white, fontSize: 16),
                        h1: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        h2: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        h3: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        listBullet: const TextStyle(color: Colors.white),
                        code: TextStyle(
                          backgroundColor: Colors.grey.shade800,
                          color: Colors.greenAccent,
                        ),
                        strong: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        em: const TextStyle(
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
