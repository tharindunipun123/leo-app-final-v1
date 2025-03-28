import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

typedef OnRecordingComplete = Function(String path);

class AudioRecorderWidget extends StatefulWidget {
  final OnRecordingComplete onRecordingComplete;
  final VoidCallback onRecordingCancelled;

  const AudioRecorderWidget({
    Key? key,
    required this.onRecordingComplete,
    required this.onRecordingCancelled,
  }) : super(key: key);

  @override
  _AudioRecorderWidgetState createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  String? _recordingPath;
  int _recordingDuration = 0;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }



  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return;
    }

    await _recorder.openRecorder();
    _isRecorderInitialized = true;
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) {
      await _initRecorder();
    }

    Directory tempDir = await getTemporaryDirectory();
    _recordingPath = '${tempDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.startRecorder(
      toFile: _recordingPath,
      codec: Codec.aacADTS,
    );

    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
      _startTime = DateTime.now();
    });

    // Start timer to update recording duration
    Future.delayed(const Duration(seconds: 1), _updateDuration);
  }

  void _updateDuration() {
    if (_isRecording) {
      setState(() {
        _recordingDuration = DateTime.now().difference(_startTime).inSeconds;
      });
      Future.delayed(const Duration(seconds: 1), _updateDuration);
    }
  }



  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    await _recorder.stopRecorder();

    setState(() {
      _isRecording = false;
    });

    if (_recordingPath != null) {
      widget.onRecordingComplete(_recordingPath!);
    }
  }


  void _cancelRecording() async {
    if (_isRecording) {
      await _recorder.stopRecorder();

      // Delete the recording file
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }

    setState(() {
      _isRecording = false;
    });

    widget.onRecordingCancelled();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_isRecording) ...[
            const Icon(
              Icons.mic,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Recording... ${_formatDuration(_recordingDuration)}',
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.grey),
              onPressed: _cancelRecording,
            ),
            IconButton(
              icon: const Icon(Icons.stop, color: Colors.red),
              onPressed: _stopRecording,
            ),
          ] else ...[
            const Icon(
              Icons.mic_none,
              color: Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Tap and hold to record',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            GestureDetector(
              onLongPress: _startRecording,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}