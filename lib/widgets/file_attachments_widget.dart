// lib/widgets/file_attachments_widget.dart

// ignore_for_file: deprecated_member_use, unused_element

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/task.dart';
import '../services/file_attachment_service.dart';

class FileAttachmentsWidget extends StatefulWidget {
  final String taskId;
  final List<TaskAttachment> attachments;
  final Function(TaskAttachment) onAttachmentAdded;
  final Function(String) onAttachmentDeleted;

  const FileAttachmentsWidget({
    super.key,
    required this.taskId,
    required this.attachments,
    required this.onAttachmentAdded,
    required this.onAttachmentDeleted,
  });

  @override
  State<FileAttachmentsWidget> createState() => _FileAttachmentsWidgetState();
}

class _FileAttachmentsWidgetState extends State<FileAttachmentsWidget> {
  final FileAttachmentService _fileService = FileAttachmentService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.attach_file, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Attachments',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.attachments.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Add attachment buttons
          _buildAttachmentButtons(),

          // Upload progress indicator
          if (_isUploading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              'Uploading file...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],

          if (widget.attachments.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            
            // Attachments List
            ...widget.attachments.map((attachment) => _buildAttachmentItem(attachment)),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentButtons() {
    return Row(
      children: [
        // Add file button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isUploading ? null : _pickFile,
            icon: const Icon(Icons.folder_open, size: 18),
            label: const Text('Add File', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Add photo button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isUploading ? null : _pickImage,
            icon: const Icon(Icons.photo_camera, size: 18),
            label: const Text('Add Photo', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentItem(TaskAttachment attachment) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getAttachmentIconColor(attachment.fileType).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getAttachmentIcon(attachment.fileType),
            size: 16,
            color: _getAttachmentIconColor(attachment.fileType),
          ),
        ),
        title: Text(
          attachment.fileName,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _formatFileSize(attachment.fileSize.round()),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    attachment.fileType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              _formatUploadDate(attachment.attachedAt),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view',
              child: const Row(
                children: [
                  Icon(Icons.visibility, size: 16),
                  SizedBox(width: 8),
                  Text('View'),
                ],
              ),
              onTap: () => _viewAttachment(attachment),
            ),
            PopupMenuItem(
              value: 'share',
              child: const Row(
                children: [
                  Icon(Icons.share, size: 16),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
              onTap: () => _shareAttachment(attachment),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red[600]),
                  const SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red[600])),
                ],
              ),
              onTap: () => _confirmDeleteAttachment(attachment),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      setState(() => _isUploading = true);
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        allowedExtensions: null,
      );

      if (result != null && result.files.single.path != null) {
        final attachment = await _fileService.pickFile(widget.taskId);
        
        if (attachment != null) {
          widget.onAttachmentAdded(attachment);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File attached successfully')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to attach file: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      setState(() => _isUploading = true);

      // Show image source selection
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );

      if (source != null) {
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );

        if (pickedFile != null) {
          final attachment = await _fileService.pickImage(widget.taskId);
          
          if (attachment != null) {
            widget.onAttachmentAdded(attachment);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Image attached successfully')),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to attach image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _viewAttachment(TaskAttachment attachment) async {
    try {
      final success = await _fileService.openAttachment(attachment);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open file')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')),
        );
      }
    }
  }

  Future<void> _shareAttachment(TaskAttachment attachment) async {
    try {
      final success = await _fileService.openAttachment(attachment);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to share file')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing file: $e')),
        );
      }
    }
  }

  void _confirmDeleteAttachment(TaskAttachment attachment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Attachment'),
        content: Text('Are you sure you want to delete "${attachment.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAttachment(attachment);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAttachment(TaskAttachment attachment) async {
    try {
      final success = await _fileService.deleteAttachment(attachment);
      if (success) {
        widget.onAttachmentDeleted(attachment.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attachment deleted')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete attachment')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting attachment: $e')),
        );
      }
    }
  }

  IconData _getAttachmentIcon(String fileType) {
    final type = fileType.toLowerCase();
    
    if (type.contains('image') || ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(type)) {
      return Icons.image;
    } else if (type.contains('pdf') || type == 'pdf') {
      return Icons.picture_as_pdf;
    } else if (type.contains('video') || ['mp4', 'mov', 'avi', 'mkv'].contains(type)) {
      return Icons.video_file;
    } else if (type.contains('audio') || ['mp3', 'wav', 'aac', 'm4a'].contains(type)) {
      return Icons.audio_file;
    } else if (['doc', 'docx'].contains(type)) {
      return Icons.description;
    } else if (['xls', 'xlsx'].contains(type)) {
      return Icons.table_chart;
    } else if (['ppt', 'pptx'].contains(type)) {
      return Icons.slideshow;
    } else if (['zip', 'rar', '7z', 'tar'].contains(type)) {
      return Icons.archive;
    } else if (['txt', 'md'].contains(type)) {
      return Icons.text_snippet;
    } else {
      return Icons.insert_drive_file;
    }
  }

  Color _getAttachmentIconColor(String fileType) {
    final type = fileType.toLowerCase();
    
    if (type.contains('image') || ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(type)) {
      return Colors.green;
    } else if (type.contains('pdf') || type == 'pdf') {
      return Colors.red;
    } else if (type.contains('video') || ['mp4', 'mov', 'avi', 'mkv'].contains(type)) {
      return Colors.purple;
    } else if (type.contains('audio') || ['mp3', 'wav', 'aac', 'm4a'].contains(type)) {
      return Colors.orange;
    } else if (['doc', 'docx'].contains(type)) {
      return Colors.blue;
    } else if (['xls', 'xlsx'].contains(type)) {
      return Colors.teal;
    } else if (['ppt', 'pptx'].contains(type)) {
      return Colors.deepOrange;
    } else if (['zip', 'rar', '7z', 'tar'].contains(type)) {
      return Colors.brown;
    } else if (['txt', 'md'].contains(type)) {
      return Colors.indigo;
    } else {
      return Colors.grey;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatUploadDate(DateTime uploadDate) {
    final now = DateTime.now();
    final difference = now.difference(uploadDate);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}