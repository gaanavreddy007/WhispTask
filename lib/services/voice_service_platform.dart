// Platform-specific voice service imports
// ignore_for_file: uri_does_not_exist

// Conditional imports for different platforms
import 'voice_service_stub.dart'
    if (dart.library.io) 'voice_service.dart'
    if (dart.library.html) 'voice_service_web.dart';

// Export the VoiceService class
export 'voice_service_stub.dart'
    if (dart.library.io) 'voice_service.dart'
    if (dart.library.html) 'voice_service_web.dart';
