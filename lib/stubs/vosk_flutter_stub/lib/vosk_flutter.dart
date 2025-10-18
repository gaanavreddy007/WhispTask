// Stub implementation of vosk_flutter for iOS builds
// This provides the same API but with no-op implementations

class VoskFlutterPlugin {
  // Stub implementation - returns false to indicate Vosk is not available
  static Future<bool> get isVoskAvailable async => false;
  
  // Stub implementation - throws unsupported error
  static Future<void> initSpeechService(String modelPath) async {
    throw UnsupportedError('Vosk Flutter is not available on iOS builds');
  }
  
  // Stub implementation - returns empty stream
  static Stream<String> get speechResultStream => const Stream.empty();
  
  // Stub implementation - no-op
  static Future<void> startSpeechService() async {
    // No-op for iOS builds
  }
  
  // Stub implementation - no-op  
  static Future<void> stopSpeechService() async {
    // No-op for iOS builds
  }
  
  // Stub implementation - no-op
  static Future<void> dispose() async {
    // No-op for iOS builds
  }
}
