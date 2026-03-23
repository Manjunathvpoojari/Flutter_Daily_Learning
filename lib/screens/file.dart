import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network/cached_network.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // 1 byte = 1024 bits
  // 2 byte = 2048 bits

  // 500 = 500 B
  // 1024 = 1.0 KB
  // 10,48,576 = 1.0 MB

  String get readableSize {
    if (size < 1024) return "$size B";

    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';

    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class FileService {
  final _bucket = Supabase.instance.client.storage.from('uploads');

  // uploading the image
  Future<String> uploadImage(XFile imageFile) async {
    final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'images/$fileName';
    final bytes = await imageFile.readAsBytes();

    await _bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: 'image/jpeg'),
    );
    return _bucket.getPublicUrl(path);
  }

  // uploading the pdf
  Future<String> uploadPdf(PlatformFile file) async {
    final fileName = 'pdf_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final path = 'pdfs/$fileName';
    await _bucket.uploadBinary(
      path,
      file.bytes!,
      fileOptions: FileOptions(contentType: 'application/pdf'),
    );
    return _bucket.getPublicUrl(path);
  }

  // uploading the video
  Future<String> uploadvideo(PlatformFile file) async {
    final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final path = 'videos/$fileName';
    if (file.path != null) {
      await _bucket.upload(
        path,
        File(file.path!),
        fileOptions: FileOptions(contentType: 'video/mp4'),
      );
    } else {
      await _bucket.uploadBinary(
        path,
        file.bytes!,
        fileOptions: FileOptions(contentType: 'video/mp4'),
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

    final imagesFiles = results[0];
    final pdfFiles = results[1];
    final videoFiles = results[2];

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
  }
}
