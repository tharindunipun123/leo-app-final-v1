// Add this to your VideoCallScreen class (zim_video_call.dart)

import 'package:flutter/material.dart';
import '../services/zego_service.dart';
import '../services/socket_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String userId;
  final String targetUserId;
  final String roomId;
  final bool isIncoming;
  final bool isVideoCall;

  const VideoCallScreen({
    super.key,
    required this.userId,
    required this.targetUserId,
    required this.roomId,
    required this.isIncoming,
    required this.isVideoCall,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final ZegoService _zegoService = ZegoService();
  final SocketService _socketService = SocketService();
  bool _isMicEnabled = true;
  bool _isCameraEnabled = true;
  bool _isSpeakerEnabled = true;
  late bool _isVideoCall;

  @override
  void initState() {
    super.initState();
    _isVideoCall = widget.isVideoCall;
    _setupCall();
  }

  Future<void> _setupCall() async {
    // Request permissions and initialize Zego
    final hasPermissions = await _zegoService.requestPermissions();
    if (!hasPermissions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Camera and Microphone permissions required')),
      );
      Navigator.pop(context);
      return;
    }

    await _zegoService.initZegoEngine();

    // Join the room
    await _zegoService.joinRoom(widget.roomId, widget.userId, widget.userId);

    // Important! Configure stream based on call type
    await _zegoService.createStream(
      enableVideo: _isVideoCall, // Only enable video if it's a video call
      enableAudio: true, // Always enable audio initially
    );
    await _zegoService.enableSpeaker(true);
    // If incoming call, handle accepting
    if (widget.isIncoming) {
      _socketService.acceptCall(
          widget.targetUserId, widget.userId, widget.roomId);
    }

    // Start local preview if it's a video call
    if (_isVideoCall) {
      // We'll implement this after widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startLocalPreview();
        }
      });
    }

    // Start publishing stream (audio or audio+video)
    await _zegoService.startPublishingStream();

    // Setup socket listeners
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Handle call ended event
    _socketService.onCallEnded = (data) {
      if (data['roomId'] == widget.roomId) {
        _endCall();
      }
    };

    // Add more listeners as needed
  }

  void _startLocalPreview() async {
    if (!_isVideoCall) return;

    // Get the view ID for local preview and start it
    // This depends on how you've set up your UI
    // Example:
    // final int localViewID = await _localViewKey.current?.viewId ?? 0;
    // await _zegoService.startPreview(localViewID);
  }

  void _toggleMicrophone() async {
    setState(() {
      _isMicEnabled = !_isMicEnabled;
    });
    await _zegoService.enableMicrophone(_isMicEnabled);
  }

  void _toggleCamera() async {
    if (!_isVideoCall) return;

    setState(() {
      _isCameraEnabled = !_isCameraEnabled;
    });
    await _zegoService.enableCamera(_isCameraEnabled);
  }

  void _toggleSpeaker() async {
    setState(() {
      _isSpeakerEnabled = !_isSpeakerEnabled;
    });
    await _zegoService.enableSpeaker(_isSpeakerEnabled);
  }

  void _endCall() async {
    // Stop publishing and playing streams
    await _zegoService.stopPublishingStream();

    if (_zegoService.remoteStreamID != null) {
      await _zegoService.stopPlayingStream(_zegoService.remoteStreamID!);
    }

    // Leave the room
    await _zegoService.leaveRoom(widget.roomId);

    // Notify the other user
    _socketService.endCall(widget.userId, widget.targetUserId, widget.roomId);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    // Clean up resources
    _zegoService.stopPreview();
    _zegoService.stopPublishingStream();

    if (_zegoService.remoteStreamID != null) {
      _zegoService.stopPlayingStream(_zegoService.remoteStreamID!);
    }

    _zegoService.leaveRoom(widget.roomId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isVideoCall ? 'Video Call' : 'Audio Call'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isVideoCall ? _buildVideoCallView() : _buildAudioCallView(),
          ),
          _buildCallControls(),
        ],
      ),
    );
  }

  Widget _buildVideoCallView() {
    // Implement your video call UI here
    return const Center(
      child: Text('Video Call View'),
      // Add your video views here
    );
  }

  Widget _buildAudioCallView() {
    // A simple UI for audio calls
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person,
            size: 100,
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
          Text(
            'Audio call with ${widget.targetUserId}',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            _isMicEnabled ? 'Microphone: ON' : 'Microphone: OFF',
            style: TextStyle(
              color: _isMicEnabled ? Colors.green : Colors.red,
            ),
          ),
          Text(
            _isSpeakerEnabled ? 'Speaker: ON' : 'Speaker: OFF',
            style: TextStyle(
              color: _isSpeakerEnabled ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      color: Colors.black12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              _isMicEnabled ? Icons.mic : Icons.mic_off,
              color: _isMicEnabled ? Colors.black : Colors.red,
            ),
            onPressed: _toggleMicrophone,
          ),
          IconButton(
            icon: const Icon(
              Icons.call_end,
              color: Colors.red,
              size: 36,
            ),
            onPressed: _endCall,
          ),
          IconButton(
            icon: Icon(
              _isSpeakerEnabled ? Icons.volume_up : Icons.volume_off,
              color: _isSpeakerEnabled ? Colors.black : Colors.red,
            ),
            onPressed: _toggleSpeaker,
          ),
          if (_isVideoCall)
            IconButton(
              icon: Icon(
                _isCameraEnabled ? Icons.videocam : Icons.videocam_off,
                color: _isCameraEnabled ? Colors.black : Colors.red,
              ),
              onPressed: _toggleCamera,
            ),
        ],
      ),
    );
  }
}
