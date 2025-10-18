// Platform-specific file attachment service imports
// ignore_for_file: uri_does_not_exist

// Conditional imports for different platforms
import 'file_attachment_service_web.dart'
    if (dart.library.io) 'file_attachment_service.dart'
    if (dart.library.html) 'file_attachment_service_web.dart';

// Export the FileAttachmentService class
export 'file_attachment_service_web.dart'
    if (dart.library.io) 'file_attachment_service.dart'
    if (dart.library.html) 'file_attachment_service_web.dart';
