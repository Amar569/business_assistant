import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<FileSystemEntity> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final docsDir = Directory('${directory.path}/documents');

      if (!await docsDir.exists()) {
        await docsDir.create(recursive: true);
      }

      final files = docsDir
          .listSync()
          .where((f) => f.path.endsWith('.pdf'))
          .toList()
        ..sort(
            (a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      setState(() {
        _documents = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load documents: $e')),
        );
      }
    }
  }

  String _fileName(FileSystemEntity file) {
    return file.path.split(Platform.pathSeparator).last;
  }

  String _fileSize(FileSystemEntity file) {
    final bytes = File(file.path).lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formattedDate(FileSystemEntity file) {
    final modified = file.statSync().modified;
    return '${modified.day}/${modified.month}/${modified.year} '
        '${modified.hour.toString().padLeft(2, '0')}:${modified.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openDocument(FileSystemEntity file) async {
    await Printing.layoutPdf(
      onLayout: (_) => File(file.path).readAsBytes(),
      name: _fileName(file),
    );
  }

  Future<void> _shareDocument(FileSystemEntity file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: _fileName(file),
    );
  }

  Future<void> _deleteDocument(FileSystemEntity file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Delete "${_fileName(file)}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await File(file.path).delete();
      _loadDocuments();
    }
  }

  IconData _fileIcon(String fileName) {
    if (fileName.toLowerCase().contains('invoice')) return Icons.receipt_long;
    if (fileName.toLowerCase().contains('quotation')) return Icons.description;
    return Icons.picture_as_pdf;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDocuments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No documents yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Generated invoice and quotation PDFs\nwill appear here',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDocuments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _documents.length,
                    itemBuilder: (context, index) {
                      final file = _documents[index];
                      final name = _fileName(file);
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            child: Icon(
                              _fileIcon(name),
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          title: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${_formattedDate(file)} • ${_fileSize(file)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'open') _openDocument(file);
                              if (value == 'share') _shareDocument(file);
                              if (value == 'delete') _deleteDocument(file);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'open',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility, size: 20),
                                    SizedBox(width: 8),
                                    Text('Open'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'share',
                                child: Row(
                                  children: [
                                    Icon(Icons.share, size: 20),
                                    SizedBox(width: 8),
                                    Text('Share'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete,
                                        size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _openDocument(file),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
