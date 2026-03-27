import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  String get readableSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class FileService {
  final _bucket = Supabase.instance.client.storage.from('uploads');

  Future<Map<String, String>> uploadImage(XFile imageFile) async {
    final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'images/$fileName';
    final bytes = await imageFile.readAsBytes();

    await _bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: 'image/jpeg'),
    );

    return {'url': _bucket.getPublicUrl(path), 'storagePath': path};
  }

  Future<Map<String, String>> uploadPDF(PlatformFile file) async {
    final fileName = 'pdf_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final path = 'pdfs/$fileName';

    await _bucket.uploadBinary(
      path,
      file.bytes!,
      fileOptions: FileOptions(contentType: 'application/pdf'),
    );

    return {'url': _bucket.getPublicUrl(path), 'storagePath': path};
  }

  Future<Map<String, String>> uploadVideo(PlatformFile file) async {
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

    return {'url': _bucket.getPublicUrl(path), 'storagePath': path};
  }

  Future<List<FileModel>> getAllFiles() async {
    final results = await Future.wait([
      _bucket.list(path: 'images'),
      _bucket.list(path: 'pdfs'),
      _bucket.list(path: 'videos'),
    ]);

    final imageFiles = results[0];
    final pdfFiles = results[1];
    final videoFiles = results[2];

    FileModel toModel(FileObject f, String folder, String type) {
      final path = '$folder/${f.name}';

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
      ...imageFiles.map((f) => toModel(f, 'images', 'image')),
      ...pdfFiles.map((f) => toModel(f, 'pdfs', 'pdf')),
      ...videoFiles.map((f) => toModel(f, 'videos', 'video')),
    ];

    allFiles.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

    return allFiles;
  }

  Future<void> deleteFile(String storagePath) async {
    await _bucket.remove([storagePath]);
  }
}

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
  bool _uploading = false;
  // ignore: unused_field
  double _uploadProgress = 0.0;
  String _selectedFilter = 'all';

  final List<Map<String, String>> _filters = [
    {'key': 'all', 'label': 'All'},
    {'key': 'image', 'label': 'Image'},
    {'key': 'pdf', 'label': 'PDFs'},
    {'key': 'video', 'label': 'Videos'},
  ];

  List<FileModel> get _filteredFiles {
    if (_selectedFilter == 'all') return _files;

    return _files.where((f) => f.type == _selectedFilter).toList();
  }

  @override
  void initState() {
    super.initState();

    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _loading = true;
    });

    try {
      final files = await _service.getAllFiles();

      setState(() {
        _files = files;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error loading files: $e')));
        }
      });
    }
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.vertical(top: Radius.circular(20)),
      ),

      builder: (_) => Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),

            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple.shade50,
                child: Icon(Icons.photo_library, color: Colors.purple),
              ),
              title: Text('Image'),
              subtitle: Text('jpg, png - from gallery or camera'),
              onTap: () {
                Navigator.pop(context);
                _showImageSourceOptions();
              },
            ),

            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade50,
                child: Icon(Icons.picture_as_pdf, color: Colors.orange),
              ),
              title: Text('PDF'),
              subtitle: Text('Pick a PDF from device'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPDF();
              },
            ),

            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade50,
                child: Icon(Icons.picture_as_pdf, color: Colors.green),
              ),
              title: Text('Video'),
              subtitle: Text('mp4, mov - from device storage'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadVideo();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsetsGeometry.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Source',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // gallery
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.pinkAccent),
              title: Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            // camera
            ListTile(
              leading: Icon(Icons.photo_camera, color: Colors.limeAccent),
              title: Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (picked == null) return;

    setState(() {
      _uploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final result = await _service.uploadImage(picked);

      final fileObj = File(picked.path);
      final size = await fileObj.length();

      final newFile = FileModel(
        name: picked.name,
        url: result['url']!,
        type: "image",
        storagePath: result['storagePath']!,
        size: size,
        uploadedAt: DateTime.now(),
      );

      setState(() {
        _files.insert(0, newFile);
        _uploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Iamage Uploaded Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _uploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Iamage Uploaded Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;

    if (file.bytes == null) return;

    setState(() {
      _uploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final Uploadresult = await _service.uploadPDF(file);

      final newFile = FileModel(
        name: file.name,
        url: Uploadresult['url']!,
        type: "pdf",
        storagePath: Uploadresult['storagePath']!,
        size: file.size,
        uploadedAt: DateTime.now(),
      );

      setState(() {
        _files.insert(0, newFile);
        _uploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pdf Uploaded Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _uploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pdf Uploaded Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;

    if (file.path == null) return;

    setState(() {
      _uploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final Uploadresult = await _service.uploadVideo(file);

      final newFile = FileModel(
        name: file.name,
        url: Uploadresult['url']!,
        type: "video",
        storagePath: Uploadresult['storagePath']!,
        size: file.size,
        uploadedAt: DateTime.now(),
      );

      setState(() {
        _files.insert(0, newFile);
        _uploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video Uploaded Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _uploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video Uploaded Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openFile(FileModel file) {
    if (file.type == 'image') {
      _showFullImage(file);
    } else {
      _launchUrl(file.url);
    }
  }

  void _showFullImage(FileModel file) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black12,
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: file.url,
              fit: BoxFit.contain,

              placeholder: (_, __) =>
                  Center(child: CircularProgressIndicator()),

              errorWidget: (_, __, ___) => Icon(Icons.error, color: Colors.red),
            ),

            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${file.name} * ${file.readableSize}',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('could not open the file')));
      }
    }
  }

  void _confirmDelete(FileModel file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete File'),
        content: Text('Delete "${file.name}"?'),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),

          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _service.deleteFile(file.storagePath);

              setState(() {
                _files.remove(file);
              });

              Navigator.pop(context);

              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('File Deleted')));
              }
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Management'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadFiles,
            icon: Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadOptions,
        icon: Icon(Icons.upload),
        label: Text("Upload"),
        backgroundColor: Colors.blueAccent,
      ),

      body: Column(
        children: [
          Container(
            color: Colors.deepPurple.shade100,
            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 8),

            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,

              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter['key'];

                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${filter['label']}'),
                      selected: isSelected,

                      selectedColor: Colors.tealAccent,

                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),

                      onSelected: (_) => setState(() {
                        _selectedFilter = filter['key']!;
                      }),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          if (_uploading)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.purpleAccent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.deepPurple,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Uploading....',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    backgroundColor: Colors.deepPurple.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                  ),
                ],
              ),
            ),

          if (!_loading)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Text(
                    '${_filteredFiles.length}'
                    'file${_filteredFiles.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : _filteredFiles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colors.blueGrey,
                        ),
                        SizedBox(height: 12),

                        Text(
                          _selectedFilter == 'all'
                              ? 'No files yet'
                              : 'No ${_selectedFilter}s yet',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blueGrey,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(
                          'Tap Upload the files',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, 100),

                    itemCount: _filteredFiles.length,

                    separatorBuilder: (_, __) => SizedBox(height: 8),

                    itemBuilder: (_, i) => _FileCard(
                      file: _filteredFiles[i],
                      onTap: () => _openFile(_filteredFiles[i]),
                      onDelete: () => _confirmDelete(_filteredFiles[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  final FileModel file;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  _FileCard({required this.file, required this.onTap, required this.onDelete});

  Color get _typeColor {
    switch (file.type) {
      case 'image':
        return Colors.amber;
      case 'pdf':
        return Colors.deepOrangeAccent;
      case 'video':
        return Colors.green;
      default:
        return Colors.brown;
    }
  }

  IconData get _typeIcon {
    switch (file.type) {
      case 'image':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'video':
        return Icons.videocam;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              if (file.type == 'image')
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: file.url,
                    width: 56,
                    height: 56,

                    fit: BoxFit.cover,

                    placeholder: (_, __) => Container(
                      width: 56,
                      height: 56,
                      color: Colors.blueGrey,
                      child: Icon(Icons.image, color: Colors.blueGrey),
                    ),

                    errorWidget: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: Colors.blueGrey,
                      child: Icon(Icons.image_search, color: Colors.blueGrey),
                    ),
                  ),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _typeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_typeIcon, color: _typeColor, size: 28),
                ),
              SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,

                      maxLines: 1,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            file.type.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              color: _typeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        SizedBox(width: 8),

                        Text(
                          file.readableSize,
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  file.type == 'image' ? Icons.fullscreen : Icons.open_in_new,

                  color: Colors.indigo,
                ),
                tooltip: file.type == 'image' ? 'View' : 'Open',
                onPressed: onTap,
              ),

              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'delete',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
