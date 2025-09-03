// lib/services/voice_notes_service.dart

// ignore_for_file: unused_import, unnecessary_brace_in_string_interps, unnecessary_string_interpolations, avoid_print, unused_element

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';

class VoiceNotesService {
  static final VoiceNotesService _instance = VoiceNotesService._internal();
  factory VoiceNotesService() => _instance;
  VoiceNotesService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final _uuid = const Uuid();
  
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentPlayingNoteId;
  bool _isDisposed = false;
  
  // Getters
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentPlayingNoteId => _currentPlayingNoteId;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  // Check if recording permission is granted
  Future<bool> hasRecordPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      debugPrint('Error checking record permission: $e');
      return false;
    }
  }

  // Request recording permission
  Future<bool> requestRecordPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      debugPrint('Error requesting record permission: $e');
      return false;
    }
  }

  // Start recording voice note
  Future<String?> startRecording(String taskId) async {
    if (_isDisposed) return null;
    
    try {
      if (_isRecording) {
        throw Exception('Already recording');
      }

      // Check permission
      if (!await hasRecordPermission()) {
        final granted = await requestRecordPermission();
        if (!granted) {
          throw Exception('Recording permission not granted');
        }
      }

      // Generate unique file name
      final noteId = _uuid.v4();
      final fileName = 'voice_note_${taskId}_${noteId}.m4a';
      
      // Get app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final voiceNotesDir = Directory('${appDir.path}/voice_notes');
      
      // Create directory if it doesn't exist
      if (!await voiceNotesDir.exists()) {
        await voiceNotesDir.create(recursive: true);
      }
      
      final filePath = '${voiceNotesDir.path}/$fileName';
      
      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );
      
      _isRecording = true;
      debugPrint('Started recording: $filePath');
      return filePath;
      
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return null;
    }
  }

  // Stop recording voice note
  Future<VoiceNote?> stopRecording(String taskId, String? recordingPath) async {
    if (_isDisposed) return null;
    
    try {
      if (!_isRecording) {
        throw Exception('Not currently recording');
      }

      // Stop recording
      final recordedPath = await _recorder.stop();
      _isRecording = false;
      
      if (recordedPath == null) {
        throw Exception('Recording failed - no file path returned');
      }
      
      final file = File(recordedPath);
      if (!await file.exists()) {
        throw Exception('Recording failed - file not found');
      }
      
      final fileStats = await file.stat();
      final fileSizeBytes = fileStats.size;
      final fileSizeMB = fileSizeBytes / (1024 * 1024);
      
      // Create voice note object
      final noteId = _uuid.v4();
      final voiceNote = VoiceNote(
        id: noteId,
        taskId: taskId,
        filePath: recordedPath,
        recordedAt: DateTime.now(),
        duration: await _getAudioDuration(recordedPath),
        fileSize: fileSizeMB,
      );
      
      debugPrint('Recording completed: ${voiceNote.formattedDuration}, ${voiceNote.fileSize?.toStringAsFixed(2)} MB');
      return voiceNote;
      
    } catch (e) {
      _isRecording = false;
      debugPrint('Error stopping recording: $e');
      return null;
    }
  }

  // Cancel current recording
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;
        debugPrint('Recording cancelled');
      }
    } catch (e) {
      debugPrint('Error cancelling recording: $e');
    }
  }

  // Play voice note
  Future<bool> playVoiceNote(String noteId, String filePath) async {
    if (_isDisposed) return false;
    
    try {
      // Stop any current playback
      await stopPlayback();
      
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Voice note file not found');
      }
      
      // Play audio
      await _player.setFilePath(filePath);
      await _player.play();
      
      _isPlaying = true;
      _currentPlayingNoteId = noteId;
      
      // Listen for completion
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
          _currentPlayingNoteId = null;
        }
      });
      
      debugPrint('Playing voice note: $noteId');
      return true;
      
    } catch (e) {
      debugPrint('Error playing voice note: $e');
      return false;
    }
  }

  // Stop playback
  Future<void> stopPlayback() async {
    if (_isDisposed) return;
    
    try {
      if (_isPlaying) {
        await _player.stop();
        _isPlaying = false;
        _currentPlayingNoteId = null;
      }
    } catch (e) {
      debugPrint('Error stopping playback: $e');
    }
  }

  // Pause/resume playback
  Future<void> pausePlayback() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      }
    } catch (e) {
      debugPrint('Error pausing playback: $e');
    }
  }

  Future<void> resumePlayback() async {
    try {
      if (!_isPlaying && _currentPlayingNoteId != null) {
        await _player.play();
      }
    } catch (e) {
      debugPrint('Error resuming playback: $e');
    }
  }

  // Upload voice note to Firebase Storage
  Future<String?> uploadVoiceNote(VoiceNote voiceNote) async {
    try {
      final file = File(voiceNote.filePath);
      if (!await file.exists()) {
        throw Exception('Voice note file not found');
      }

      // Create storage reference
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('voice_notes')
          .child('${voiceNote.taskId}')
          .child('${voiceNote.id}.m4a');

      // Upload file
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('Voice note uploaded: $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      debugPrint('Error uploading voice note: $e');
      return null;
    }
  }

  // Download voice note from Firebase Storage
  Future<bool> _downloadVoiceNote(VoiceNote voiceNote) async {
    try {
      if (voiceNote.cloudUrl == null) return false;
      
      final file = File(voiceNote.filePath);
      
      // Create directories if they don't exist
      await file.parent.create(recursive: true);
      
      // Download from Firebase Storage
      final storageRef = FirebaseStorage.instance.refFromURL(voiceNote.cloudUrl!);
      await storageRef.writeToFile(file);
      
      debugPrint('Voice note downloaded: ${voiceNote.filePath}');
      return true;
      
    } catch (e) {
      debugPrint('Error downloading voice note: $e');
      return false;
    }
  }

  // Delete voice note (local and cloud)
  Future<bool> deleteVoiceNote(VoiceNote voiceNote) async {
    try {
      // Delete local file
      final file = File(voiceNote.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      
      // Delete from cloud storage if URL exists
      if (voiceNote.cloudUrl != null) {
        try {
          final storageRef = FirebaseStorage.instance.refFromURL(voiceNote.cloudUrl!);
          await storageRef.delete();
        } catch (e) {
          debugPrint('Warning: Could not delete cloud file: $e');
          // Continue even if cloud deletion fails
        }
      }
      
      debugPrint('Voice note deleted: ${voiceNote.id}');
      return true;
      
    } catch (e) {
      debugPrint('Error deleting voice note: $e');
      return false;
    }
  }

  // Get audio duration
  Future<Duration> _getAudioDuration(String filePath) async {
    try {
      await _player.setFilePath(filePath);
      return _player.duration ?? Duration.zero;
    } catch (e) {
      debugPrint('Error getting audio duration: $e');
      return Duration.zero;
    }
  }

  // Transcribe voice note (placeholder for future Speech-to-Text integration)
  Future<String?> transcribeVoiceNote(VoiceNote voiceNote) async {
    try {
      // For now, return placeholder
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      // Mock transcription for testing
      final mockTranscriptions = [
        "Remember to buy groceries on the way home",
        "Call dentist to reschedule appointment",
        "Finish the project report by Friday",
        "Pick up dry cleaning tomorrow morning",
        "Meeting with team at 2 PM about budget review",
      ];
      
      final transcription = mockTranscriptions[
          DateTime.now().millisecondsSinceEpoch % mockTranscriptions.length
      ];
      
      debugPrint('Voice note transcribed: $transcription');
      return transcription;
      
    } catch (e) {
      debugPrint('Error transcribing voice note: $e');
      return null;
    }
  }

  // Get voice notes directory size
  Future<double> getVoiceNotesDirectorySize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final voiceNotesDir = Directory('${appDir.path}/voice_notes');
      
      if (!await voiceNotesDir.exists()) return 0.0;
      
      double totalSize = 0.0;
      
      await for (final entity in voiceNotesDir.list(recursive: true)) {
        if (entity is File) {
          final fileStats = await entity.stat();
          totalSize += fileStats.size;
        }
      }
      
      return totalSize / (1024 * 1024); // Convert to MB
      
    } catch (e) {
      debugPrint('Error getting voice notes directory size: $e');
      return 0.0;
    }
  }

  // Clean up old voice notes (for storage management)
  Future<void> cleanupOldVoiceNotes({int daysOld = 30}) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final voiceNotesDir = Directory('${appDir.path}/voice_notes');
      
      if (!await voiceNotesDir.exists()) return;
      
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      int deletedCount = 0;
      
      await for (final entity in voiceNotesDir.list()) {
        if (entity is File) {
          final fileStats = await entity.stat();
          if (fileStats.modified.isBefore(cutoffDate)) {
            await entity.delete();
            deletedCount++;
          }
        }
      }
      
      debugPrint('Cleaned up $deletedCount old voice notes');
      
    } catch (e) {
      debugPrint('Error cleaning up voice notes: $e');
    }
  }

  // Dispose resources
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    
    try {
      if (_isRecording) {
        _recorder.stop();
        _isRecording = false;
      }
    } catch (e) {
      print('Error stopping recorder: $e');
    }
    
    try {
      if (_isPlaying) {
        _player.stop();
        _isPlaying = false;
      }
    } catch (e) {
      print('Error stopping player: $e');
    }
    
    try {
      _recorder.dispose();
    } catch (e) {
      print('Error disposing recorder: $e');
    }
    try {
      _player.dispose();
    } catch (e) {
      print('Error disposing player: $e');
    }
  }
}