// Web-compatible file attachment service
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';

class FileAttachmentService {
  static final FileAttachmentService _instance = FileAttachmentService._internal();
  factory FileAttachmentService() => _instance;
  FileAttachmentService._internal();

  Future<List<Map<String, dynamic>>> pickFiles() async {
    // Web implementation - return empty list for now
    print('File picker not available on web');
    return [];
  }

  Future<String?> uploadFile(String filePath, String fileName) async {
    // Web implementation - return null for now
    print('File upload not available on web');
    return null;
  }

  Future<Uint8List?> downloadFile(String url) async {
    // Web implementation - return null for now
    print('File download not available on web');
    return null;
  }

  Future<bool> deleteFile(String url) async {
    // Web implementation - return false for now
    print('File delete not available on web');
    return false;
  }

  // Additional methods for compatibility
  Future<Map<String, dynamic>?> pickFile() async {
    print('File picker not available on web');
    return null;
  }

  Future<Map<String, dynamic>?> pickImage() async {
    print('Image picker not available on web');
    return null;
  }

  Future<void> openAttachment(String url) async {
    print('Open attachment not available on web');
  }

  Future<bool> deleteAttachment(String url) async {
    print('Delete attachment not available on web');
    return false;
  }
}
