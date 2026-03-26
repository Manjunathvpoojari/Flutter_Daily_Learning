import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ================= MODEL =================
class FileModel {
  final String name;
  final String url;
  final String type;
  final String storagePath;
  final int size;
  final DateTime uploadedAt;

  FileModel({
    required this.name,
    required this.url,
    required this.type,
    required this.storagePath,
    required this.size,
    required this.uploadedAt,
  });

  String get readableSize {
    if (size < 1024) return "$size B";
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// ================= SERVICE =================
class FileService {
  final _bucket = Supabase.instance.client.storage.from('uploads');

  Future<String> uploadImage(XFile imageFile) async {
    final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'images/$fileName';
    final bytes = await imageFile.readAsBytes();

    await _bucket.uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg'),
    );

    return _bucket.getPublicUrl(path);
  }

  Future<String> uploadPdf(PlatformFile file) async {
    final fileName = 'pdf_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final path = 'pdfs/$fileName';

    await _bucket.uploadBinary(
      path,
      file.bytes!,
      fileOptions: const FileOptions(contentType: 'application/pdf'),
    );

    return _bucket.getPublicUrl(path);
  }

  Future<String> uploadVideo(PlatformFile file) async {
    final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final path = 'videos/$fileName';

    if (file.path != null) {
      await _bucket.upload(
        path,
        File(file.path!),
        fileOptions: const FileOptions(contentType: 'video/mp4'),
      );
    } else {
      await _bucket.uploadBinary(
        path,
        file.bytes!,
        fileOptions: const FileOptions(contentType: 'video/mp4'),
      );
    }

    return _bucket.getPublicUrl(path);
  }

  Future<List<FileModel>> getAllFiles() async {
    final results = await Future.wait([
      _bucket.list(path: 'images'),
      _bucket.list(path: 'pdfs'),
      _bucket.list(path: 'videos'),
    ]);

    FileModel toModel(FileObject f, String folder, String type) {
      final path = "$folder/${f.name}";
      return FileModel(
        name: f.name,
        url: _bucket.getPublicUrl(path),
        type: type,
        storagePath: path,
        size: f.metadata?['size'] ?? 0,
        uploadedAt: DateTime.tryParse(f.createdAt ?? '') ?? DateTime.now(),
      );
    }

    final allFiles = [
      ...results[0].map((f) => toModel(f, 'images', 'image')),
      ...results[1].map((f) => toModel(f, 'pdfs', 'pdf')),
      ...results[2].map((f) => toModel(f, 'videos', 'video')),
    ];

    allFiles.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return allFiles;
  }

  Future<void> deleteFile(String path) async {
    await _bucket.remove([path]);
  }
}

/// ================= UI PAGE =================
class FileManagerPage extends StatefulWidget {
  const FileManagerPage({super.key});

  @override
  State<FileManagerPage> createState() => _FileManagerPageState();
}

class _FileManagerPageState extends State<FileManagerPage> {
  final _service = FileService();
  final _picker = ImagePicker();

  List<FileModel> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _loading = true);

    try {
      final files = await _service.getAllFiles();
      setState(() => _files = files);
    } catch (e) {
      print("Error: $e");
    }

    setState(() => _loading = false);
  }

  /// ===== OPEN FILE =====
  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      print("Could not open file");
    }
  }

  /// ===== DELETE FILE =====
  Future<void> _deleteFile(String path) async {
    await _service.deleteFile(path);
    _loadFiles();
  }

  /// ===== PICK IMAGE =====
  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _service.uploadImage(image);
      _loadFiles();
    }
  }

  /// ===== PICK PDF =====
  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      await _service.uploadPdf(result.files.first);
      _loadFiles();
    }
  }

  /// ===== PICK VIDEO =====
  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);

    if (result != null) {
      await _service.uploadVideo(result.files.first);
      _loadFiles();
    }
  }

  /// ===== UI =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("File Manager"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(onPressed: _loadFiles, icon: const Icon(Icons.refresh)),
        ],
      ),

      /// ===== BODY =====
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
          ? const Center(child: Text("No files uploaded"))
          : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];

                return Card(
                  child: ListTile(
                    title: Text(file.name),
                    subtitle: Text(file.readableSize),
                    leading: Icon(
                      file.type == 'image'
                          ? Icons.image
                          : file.type == 'pdf'
                          ? Icons.picture_as_pdf
                          : Icons.video_file,
                    ),
                    onTap: () => _openFile(file.url),

                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteFile(file.storagePath),
                    ),
                  ),
                );
              },
            ),

      /// ===== FLOATING BUTTON =====
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _pickImage,
            heroTag: "img",
            child: const Icon(Icons.image),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _pickPdf,
            heroTag: "pdf",
            child: const Icon(Icons.picture_as_pdf),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _pickVideo,
            heroTag: "video",
            child: const Icon(Icons.video_call),
          ),
        ],
      ),
    );
  }
}

// this is not fully complete
