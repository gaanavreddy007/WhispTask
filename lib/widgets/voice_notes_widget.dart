// lib/widgets/voice_notes_widget.dart

// ignore_for_file: unused_local_variable, deprecated_member_use, use_build_context_synchronously, prefer_const_constructors

import 'dart:async';

import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/voice_notes_service.dart';
import '../services/transcription_service.dart';
import '../l10n/app_localizations.dart';

class EnhancedVoiceNotesWidget extends StatefulWidget {
  final String taskId;
  final List<VoiceNote> voiceNotes;
  final Function(VoiceNote) onVoiceNoteAdded;
  final Function(String) onVoiceNoteDeleted;

  const EnhancedVoiceNotesWidget({
    super.key,
    required this.taskId,
    required this.voiceNotes,
    required this.onVoiceNoteAdded,
    required this.onVoiceNoteDeleted,
  });

  @override
  State<EnhancedVoiceNotesWidget> createState() => _EnhancedVoiceNotesWidgetState();
}

class _EnhancedVoiceNotesWidgetState extends State<EnhancedVoiceNotesWidget> {
  final TranscriptionService _transcriptionService = TranscriptionService();
  final VoiceNotesService _voiceService = VoiceNotesService();
  
  bool _isRecording = false;
  bool _isTranscribing = false;
  String _currentTranscription = '';
  List<VoiceNote> _voiceNotes = [];
  String? _recordingPath;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _voiceNotes = widget.voiceNotes;
    _initializeServices();

    _playerStateSubscription = _voiceService.playerStateStream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _initializeServices() async {
    await _transcriptionService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).voiceNotes, style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 8),
        
        // Recording Controls
        Row(
          children: [
            IconButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              icon: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: _isRecording ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
              ),
              iconSize: 32,
            ),
            if (_isRecording) ...[
              SizedBox(width: 8),
              Text(AppLocalizations.of(context).recording, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            if (_isTranscribing) ...[
              SizedBox(width: 8),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text(AppLocalizations.of(context).transcribing),
            ],
          ],
        ),
        
        // Live Transcription Preview
        if (_currentTranscription.isNotEmpty) ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).liveTranscription, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(_currentTranscription),
              ],
            ),
          ),
        ],
        
        // Existing Voice Notes
        if (_voiceNotes.isNotEmpty) ...[
          SizedBox(height: 16),
          Text(AppLocalizations.of(context).recordedNotes, style: Theme.of(context).textTheme.titleSmall),
          SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _voiceNotes.length,
            itemBuilder: (context, index) {
              return _buildVoiceNoteCard(_voiceNotes[index]);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildVoiceNoteCard(VoiceNote note) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.audiotrack, size: 20),
                SizedBox(width: 8),
                Text(
                  '${AppLocalizations.of(context).duration}: ${note.formattedDuration}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Spacer(),
                IconButton(
                  onPressed: () => _playVoiceNote(note),
                  icon: Icon(_voiceService.isPlaying && _voiceService.currentPlayingNoteId == note.id 
                      ? Icons.pause 
                      : Icons.play_arrow),
                ),
                IconButton(
                  onPressed: () => _deleteVoiceNote(note),
                  icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                ),
              ],
            ),
            if (note.transcription != null && note.transcription!.isNotEmpty) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context).transcription, style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(note.transcription!),
                  ],
                ),
              ),
            ],
            SizedBox(height: 4),
            Text(
              '${AppLocalizations.of(context).created}: ${note.recordedAt.day}/${note.recordedAt.month}/${note.recordedAt.year}',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
      _currentTranscription = '';
    });

    // Start voice recording
    final path = await _voiceService.startRecording(widget.taskId);
    if (path != null) {
      _recordingPath = path;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).failedToStartRecording)),
      );
      setState(() => _isRecording = false);
      return;
    }
    
    // Start live transcription
    await _transcriptionService.startListening(
      onResult: (transcription) {
        setState(() {
          _currentTranscription = transcription;
        });
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).transcriptionError}: $error')),
        );
      },
    );
  }

  Future<void> _stopRecording() async {
    setState(() {
      _isRecording = false;
      _isTranscribing = true;
    });

    // Stop recording and transcription
    if (_recordingPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).recordingPathNotFound)),
      );
      setState(() {
        _isRecording = false;
        _isTranscribing = false;
      });
      return;
    }

    final voiceNote = await _voiceService.stopRecording(widget.taskId, _recordingPath!);
    await _transcriptionService.stopListening();

    if (voiceNote != null) {
      // Add transcription to the new voice note
      final newNoteWithTranscription = VoiceNote(
        id: voiceNote.id,
        taskId: voiceNote.taskId,
        filePath: voiceNote.filePath,
        recordedAt: voiceNote.recordedAt,
        duration: voiceNote.duration,
        fileSize: voiceNote.fileSize,
        transcription: _currentTranscription,
        cloudUrl: voiceNote.cloudUrl,
      );

      setState(() {
        _voiceNotes.add(newNoteWithTranscription);
        _isTranscribing = false;
        _currentTranscription = '';
        _recordingPath = null;
      });

      widget.onVoiceNoteAdded(newNoteWithTranscription);
    } else {
      setState(() {
        _isTranscribing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).failedToSaveVoiceNote)),
      );
    }
  }

  Future<void> _playVoiceNote(VoiceNote note) async {
    if (_voiceService.isPlaying && _voiceService.currentPlayingNoteId == note.id) {
      await _voiceService.stopPlayback();
    } else {
      await _voiceService.playVoiceNote(note.id, note.filePath);
    }
  }

  void _deleteVoiceNote(VoiceNote note) {
    setState(() {
      _voiceNotes.remove(note);
    });
    widget.onVoiceNoteDeleted(note.id);
  }

  @override
  void dispose() {
    _transcriptionService.dispose();
    _playerStateSubscription?.cancel();
    _voiceService.dispose();
    super.dispose();
  }
}

// Compact voice notes list for use in task cards
class CompactVoiceNotesWidget extends StatelessWidget {
  final List<VoiceNote> voiceNotes;
  final VoidCallback? onTap;

  const CompactVoiceNotesWidget({
    super.key,
    required this.voiceNotes,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (voiceNotes.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic, size: 14, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 4),
            Text(
              '${voiceNotes.length}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Voice recording button for quick access
class QuickVoiceRecordButton extends StatefulWidget {
  final String taskId;
  final Function(VoiceNote) onVoiceNoteAdded;

  const QuickVoiceRecordButton({
    super.key,
    required this.taskId,
    required this.onVoiceNoteAdded,
  });

  @override
  State<QuickVoiceRecordButton> createState() => _QuickVoiceRecordButtonState();
}

class _QuickVoiceRecordButtonState extends State<QuickVoiceRecordButton> {
  final VoiceNotesService _voiceService = VoiceNotesService();
  bool _isRecording = false;
  String? _recordingPath;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _isRecording ? null : _startQuickRecording,
      onLongPressEnd: _isRecording ? (_) => _stopQuickRecording() : null,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _isRecording ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.secondary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_isRecording ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.secondary).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          _isRecording ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Future<void> _startQuickRecording() async {
    try {
      setState(() => _isRecording = true);
      
      final path = await _voiceService.startRecording(widget.taskId);
      if (path != null) {
        _recordingPath = path;
      } else {
        throw Exception(AppLocalizations.of(context).failedToStartRecordingException);
      }
    } catch (e) {
      setState(() => _isRecording = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).recordingFailed}: $e')),
      );
    }
  }

  Future<void> _stopQuickRecording() async {
    if (!_isRecording || _recordingPath == null) return;

    try {
      final voiceNote = await _voiceService.stopRecording(widget.taskId, _recordingPath!);
      
      if (voiceNote != null) {
        widget.onVoiceNoteAdded(voiceNote);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).voiceNoteSaved)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).failedToSave}: $e')),
      );
    } finally {
      setState(() {
        _isRecording = false;
        _recordingPath = null;
      });
    }
  }
}