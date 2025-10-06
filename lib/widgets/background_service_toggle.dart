import 'package:flutter/material.dart';
import '../services/background_voice_service.dart';
import '../services/voice_service.dart';

class BackgroundServiceToggle extends StatefulWidget {
  final VoiceService voiceService;

  const BackgroundServiceToggle({
    super.key,
    required this.voiceService,
  });

  @override
  State<BackgroundServiceToggle> createState() => _BackgroundServiceToggleState();
}

class _BackgroundServiceToggleState extends State<BackgroundServiceToggle> {
  bool _isServiceRunning = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
  }

  Future<void> _checkServiceStatus() async {
    try {
      final isRunning = await widget.voiceService.isBackgroundServiceRunning();
      if (mounted) {
        setState(() {
          _isServiceRunning = isRunning;
        });
      }
    } catch (e) {
      debugPrint('Error checking background service status: $e');
    }
  }

  Future<void> _toggleService() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isServiceRunning) {
        await widget.voiceService.stopBackgroundService();
        setState(() {
          _isServiceRunning = false;
        });
        _showSnackBar('Background voice detection stopped');
      } else {
        // Check permissions first
        final hasPermissions = await BackgroundVoiceService.checkPermissions();
        if (!hasPermissions) {
          _showSnackBar('Microphone permission required for background detection');
          return;
        }

        await widget.voiceService.startBackgroundService();
        setState(() {
          _isServiceRunning = true;
        });
        _showSnackBar('Background voice detection started');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isServiceRunning ? Icons.mic : Icons.mic_off,
                  color: _isServiceRunning ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Background Wake Word Detection',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isServiceRunning
                  ? 'WhispTask is listening for "Hey Whisp" even when the app is closed.'
                  : 'Enable background listening to detect wake words when the app is closed.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isServiceRunning ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: _isServiceRunning ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Switch(
                        value: _isServiceRunning,
                        onChanged: (_) => _toggleService(),
                        activeThumbColor: Colors.green,
                      ),
              ],
            ),
            if (_isServiceRunning) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Say "Hey Whisp" followed by your command to create tasks in the background.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
