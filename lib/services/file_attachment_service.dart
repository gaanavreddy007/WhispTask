// lib/services/file_attachment_service.dart

// ignore_for_file: unused_local_variable

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:mime/mime.dart';
import '../models/task.dart';

class FileAttachmentService {
  static final FileAttachmentService _instance = FileAttachmentService._internal();
  factory FileAttachmentService() => _instance;
  FileAttachmentService._internal();

  final _uuid = const Uuid();

  // Pick file from device
  Future<TaskAttachment?> pickFile(String taskId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
        allowedExtensions: null,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      
      // Validate file size (max 10MB for free users, 50MB for premium)
      const maxFileSizeMB = 10.0;
      final fileSizeMB = (file.size) / (1024 * 1024);
      
      if (fileSizeMB > maxFileSizeMB) {
        throw Exception('File size too large. Maximum size is ${maxFileSizeMB}MB');
      }

      // Copy file to app directory
      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory('${appDir.path}/attachments');
      
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      // Generate unique file name
      final attachmentId = _uuid.v4();
      final extension = file.extension ?? '';
      final fileName = file.name;
      final safeName = fileName.replaceAll(RegExp(r'[^\w\-_\.]'), '_');
      final newFileName = '${attachmentId}_$safeName';
      final newPath = '${attachmentsDir.path}/$newFileName';

      // Copy file
      if (file.path != null) {
        final originalFile = File(file.path!);
        await originalFile.copy(newPath);
      } else if (file.bytes != null) {
        // For web platform
        final newFile = File(newPath);
        await newFile.writeAsBytes(file.bytes!);
      } else {
        throw Exception('Could not access file data');
      }

      // Determine file type
      final mimeType = lookupMimeType(newPath) ?? 'application/octet-stream';
      final fileType = _getFileTypeFromMime(mimeType);

      // Create attachment object
      final attachment = TaskAttachment(
        id: attachmentId,
        taskId: taskId,
        fileName: fileName,
        filePath: newPath,
        fileType: fileType,
        fileSize: fileSizeMB,
        attachedAt: DateTime.now(),
        mimeType: mimeType,
      );

      debugPrint('File attached: $fileName (${attachment.formattedFileSize})');
      return attachment;

    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }

  // Pick image from gallery or camera
  Future<TaskAttachment?> pickImage(String taskId, {bool fromCamera = false}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      
      // Validate image size
      const maxImageSizeMB = 5.0;
      final fileSizeMB = file.size / (1024 * 1024);
      
      if (fileSizeMB > maxImageSizeMB) {
        throw Exception('Image size too large. Maximum size is ${maxImageSizeMB}MB');
      }

      // Process similar to pickFile but specifically for images
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/attachments/images');
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final attachmentId = _uuid.v4();
      final extension = file.extension ?? 'jpg';
      final fileName = file.name;
      final newPath = '${imagesDir.path}/${attachmentId}_image.$extension';

      // Copy file
      if (file.path != null) {
        await File(file.path!).copy(newPath);
      } else if (file.bytes != null) {
        await File(newPath).writeAsBytes(file.bytes!);
      } else {
        throw Exception('Could not access image data');
      }

      final attachment = TaskAttachment(
        id: attachmentId,
        taskId: taskId,
        fileName: fileName,
        filePath: newPath,
        fileType: 'image',
        fileSize: fileSizeMB,
        attachedAt: DateTime.now(),
        mimeType: lookupMimeType(newPath) ?? 'image/jpeg',
      );

      debugPrint('Image attached: $fileName');
      return attachment;

    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // Upload attachment to Firebase Storage
  Future<String?> uploadAttachment(TaskAttachment attachment) async {
    try {
      final file = File(attachment.filePath);
      if (!await file.exists()) {
        throw Exception('Attachment file not found');
      }

      // Create storage reference
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('attachments')
          .child(attachment.taskId)
          .child('${attachment.id}_${attachment.fileName}');

      // Upload file
      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: attachment.mimeType,
          customMetadata: {
            'taskId': attachment.taskId,
            'attachmentId': attachment.id,
            'originalName': attachment.fileName,
          },
        ),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Attachment uploaded: ${attachment.fileName}');
      return downloadUrl;

    } catch (e) {
      debugPrint('Error uploading attachment: $e');
      return null;
    }
  }

  // Download attachment from Firebase Storage
  Future<bool> downloadAttachment(TaskAttachment attachment) async {
    try {
      if (attachment.cloudUrl == null) return false;
      
      final file = File(attachment.filePath);
      
      // Create directories if they don't exist
      await file.parent.create(recursive: true);
      
      // Download from Firebase Storage
      final storageRef = FirebaseStorage.instance.refFromURL(attachment.cloudUrl!);
      await storageRef.writeToFile(file);
      
      debugPrint('Attachment downloaded: ${attachment.fileName}');
      return true;
      
    } catch (e) {
      debugPrint('Error downloading attachment: $e');
      return false;
    }
  }

  // Delete attachment (local and cloud)
  Future<bool> deleteAttachment(TaskAttachment attachment) async {
    try {
      // Delete local file
      final file = File(attachment.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      
      // Delete from cloud storage
      if (attachment.cloudUrl != null) {
        try {
          final storageRef = FirebaseStorage.instance.refFromURL(attachment.cloudUrl!);
          await storageRef.delete();
        } catch (e) {
          debugPrint('Warning: Could not delete cloud file: $e');
        }
      }
      
      debugPrint('Attachment deleted: ${attachment.fileName}');
      return true;
      
    } catch (e) {
      debugPrint('Error deleting attachment: $e');
      return false;
    }
  }

  // Open/view attachment
  Future<bool> openAttachment(TaskAttachment attachment) async {
    try {
      final file = File(attachment.filePath);
      
      // Download if local file doesn't exist
      if (!await file.exists() && attachment.cloudUrl != null) {
        final downloaded = await downloadAttachment(attachment);
        if (!downloaded) {
          throw Exception('Could not download attachment');
        }
      }
      
      // For now, just check if file exists
      // TODO: Integrate with platform-specific file opening
      // You might want to use packages like:
      // - open_file: for opening files with default system apps
      // - url_launcher: for opening files in browser
      
      if (await file.exists()) {
        debugPrint('Opening attachment: ${attachment.fileName}');
        // Placeholder for file opening logic
        return true;
      } else {
        throw Exception('Attachment file not found');
      }
      
    } catch (e) {
      debugPrint('Error opening attachment: $e');
      return false;
    }
  }

  // Get attachments directory size
  Future<double> getAttachmentsDirectorySize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory('${appDir.path}/attachments');
      
      if (!await attachmentsDir.exists()) return 0.0;
      
      double totalSize = 0.0;
      
      await for (final entity in attachmentsDir.list(recursive: true)) {
        if (entity is File) {
          final fileStats = await entity.stat();
          totalSize += fileStats.size;
        }
      }
      
      return totalSize / (1024 * 1024); // Convert to MB
      
    } catch (e) {
      debugPrint('Error getting attachments directory size: $e');
      return 0.0;
    }
  }

  // Clean up orphaned attachments (attachments whose tasks no longer exist)
  Future<void> cleanupOrphanedAttachments(List<String> activeTaskIds) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory('${appDir.path}/attachments');
      
      if (!await attachmentsDir.exists()) return;
      
      int deletedCount = 0;
      
      await for (final entity in attachmentsDir.list(recursive: true)) {
        if (entity is File) {
          final fileName = entity.path.split('/').last;
          
          // Extract task ID from file name pattern: {attachmentId}_{taskId}_originalName
          final parts = fileName.split('_');
          if (parts.length >= 2) {
            final taskId = parts[1];
            if (!activeTaskIds.contains(taskId)) {
              await entity.delete();
              deletedCount++;
            }
          }
        }
      }
      
      debugPrint('Cleaned up $deletedCount orphaned attachments');
      
    } catch (e) {
      debugPrint('Error cleaning up orphaned attachments: $e');
    }
  }

  // Helper method to determine file type from MIME type
  String _getFileTypeFromMime(String mimeType) {
    if (mimeType.startsWith('image/')) return 'image';
    if (mimeType.startsWith('video/')) return 'video';
    if (mimeType.startsWith('audio/')) return 'audio';
    
    // Document types
    if (mimeType.contains('pdf') ||
        mimeType.contains('document') ||
        mimeType.contains('text') ||
        mimeType.contains('spreadsheet') ||
        mimeType.contains('presentation')) {
      return 'document';
    }
    
    return 'other';
  }

  // Get file type icon based on extension
  String getFileTypeIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return 'image';
        
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
      case 'flv':
      case 'webm':
        return 'video';
        
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'flac':
      case 'ogg':
      case 'm4a':
        return 'audio';
        
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'xls':
      case 'xlsx':
      case 'ppt':
      case 'pptx':
      case 'txt':
      case 'rtf':
        return 'document';
        
      default:
        return 'other';
    }
  }

  // Validate file before attachment
  Map<String, dynamic> validateFile(PlatformFile file) {
    final validationResult = <String, dynamic>{
      'isValid': true,
      'errors': <String>[],
      'warnings': <String>[],
    };

    // Check file size
    const maxSizeMB = 10.0;
    final fileSizeMB = file.size / (1024 * 1024);
    
    if (fileSizeMB > maxSizeMB) {
      validationResult['isValid'] = false;
      validationResult['errors'].add('File size (${fileSizeMB.toStringAsFixed(1)}MB) exceeds maximum allowed size (${maxSizeMB}MB)');
    }

    // Check file name length
    if (file.name.length > 100) {
      validationResult['warnings'].add('File name is very long and may be truncated');
    }

    // Check for potentially problematic file types
    final extension = file.extension?.toLowerCase() ?? '';
    final problematicExtensions = ['exe', 'bat', 'cmd', 'scr', 'com', 'pif', 'jar'];
    
    if (problematicExtensions.contains(extension)) {
      validationResult['isValid'] = false;
      validationResult['errors'].add('File type not allowed for security reasons');
    }

    return validationResult;
  }

  // Get storage usage summary
  Future<Map<String, dynamic>> getStorageUsage() async {
    try {
      final voiceNotesSize = await _getDirectorySize('voice_notes');
      final attachmentsSize = await _getDirectorySize('attachments');
      final totalSize = voiceNotesSize + attachmentsSize;
      
      // Count files
      final voiceNotesCount = await _getDirectoryFileCount('voice_notes');
      final attachmentsCount = await _getDirectoryFileCount('attachments');
      
      return {
        'voiceNotesSize': voiceNotesSize,
        'attachmentsSize': attachmentsSize,
        'totalSize': totalSize,
        'voiceNotesCount': voiceNotesCount,
        'attachmentsCount': attachmentsCount,
        'totalFiles': voiceNotesCount + attachmentsCount,
      };
      
    } catch (e) {
      debugPrint('Error getting storage usage: $e');
      return {
        'voiceNotesSize': 0.0,
        'attachmentsSize': 0.0,
        'totalSize': 0.0,
        'voiceNotesCount': 0,
        'attachmentsCount': 0,
        'totalFiles': 0,
      };
    }
  }

  // Helper: Get directory size in MB
  Future<double> _getDirectorySize(String dirName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/$dirName');
      
      if (!await dir.exists()) return 0.0;
      
      double totalSize = 0.0;
      
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final fileStats = await entity.stat();
          totalSize += fileStats.size;
        }
      }
      
      return totalSize / (1024 * 1024);
      
    } catch (e) {
      return 0.0;
    }
  }

  // Helper: Count files in directory
  Future<int> _getDirectoryFileCount(String dirName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/$dirName');
      
      if (!await dir.exists()) return 0;
      
      int count = 0;
      await for (final entity in dir.list()) {
        if (entity is File) count++;
      }
      
      return count;
      
    } catch (e) {
      return 0;
    }
  }

  // Clean up all attachments and voice notes
  Future<bool> clearAllStorage() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      
      // Delete attachments directory
      final attachmentsDir = Directory('${appDir.path}/attachments');
      if (await attachmentsDir.exists()) {
        await attachmentsDir.delete(recursive: true);
      }
      
      // Delete voice notes directory
      final voiceNotesDir = Directory('${appDir.path}/voice_notes');
      if (await voiceNotesDir.exists()) {
        await voiceNotesDir.delete(recursive: true);
      }
      
      debugPrint('All storage cleared successfully');
      return true;
      
    } catch (e) {
      debugPrint('Error clearing storage: $e');
      return false;
    }
  }

  // Get file preview info for UI
  Map<String, dynamic> getFilePreviewInfo(TaskAttachment attachment) {
    final extension = attachment.fileName.split('.').last.toLowerCase();
    
    return {
      'canPreview': _canPreviewFile(extension),
      'previewType': _getPreviewType(extension),
      'iconName': _getFileIcon(extension),
      'colorCode': _getFileColor(extension),
    };
  }

  bool _canPreviewFile(String extension) {
    const previewableExtensions = [
      'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', // images
      'txt', 'md', // text files
      'pdf', // documents (with viewer)
    ];
    return previewableExtensions.contains(extension);
  }

  String _getPreviewType(String extension) {
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
      return 'image';
    } else if (['txt', 'md'].contains(extension)) {
      return 'text';
    } else if (extension == 'pdf') {
      return 'pdf';
    }
    return 'none';
  }

  String _getFileIcon(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return 'image';
      case 'pdf':
        return 'pdf';
      case 'doc':
      case 'docx':
        return 'word';
      case 'xls':
      case 'xlsx':
        return 'excel';
      case 'ppt':
      case 'pptx':
        return 'powerpoint';
      case 'zip':
      case 'rar':
      case '7z':
        return 'archive';
      default:
        return 'file';
    }
  }

  String _getFileColor(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return '#4CAF50'; // Green for images
      case 'pdf':
        return '#F44336'; // Red for PDF
      case 'doc':
      case 'docx':
        return '#2196F3'; // Blue for Word
      case 'xls':
      case 'xlsx':
        return '#4CAF50'; // Green for Excel
      case 'ppt':
      case 'pptx':
        return '#FF9800'; // Orange for PowerPoint
      case 'txt':
      case 'md':
        return '#9E9E9E'; // Grey for text
      default:
        return '#607D8B'; // Blue grey for others
    }
  }
}