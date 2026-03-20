import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network/cached_network.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final _storage = FirebaseStorage.instance;

  // uploading the image
  Future<String> uploadImage(XFile imageFile) async {
    final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child("uploads/image/$fileName");
    final uploadTask = await ref.putFile(File(imageFile.path));
    return await uploadTask.ref.getDownloadURL();
  }

  // uploading the pdf
  Future<String> uploadPdf(PlatformFile file) async {
    final fileName = 'pdf_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final ref = _storage.ref().child("uploads/pdf/$fileName");
    final uploadTask = await ref.putData((file.bytes!));
    return await uploadTask.ref.getDownloadURL();
  }

  // uploading the video
  Future<String> uploadvideo(PlatformFile file) async {
    final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final ref = _storage.ref().child("uploads/video/$fileName");
    final uploadTask = await ref.putData((file.bytes!));
    return await uploadTask.ref.getDownloadURL();
  }
}
