import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/status_model.dart';
import '../services/socket_service.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';

class StatusViewScreen extends StatefulWidget {
  final String currentUserId;
  final String statusUserId;

  const StatusViewScreen({
    super.key,
    required this.currentUserId,
    required this.statusUserId,
  });

  @override
  _StatusViewScreenState createState() => _StatusViewScreenState();
}

class _StatusViewScreenState extends State<StatusViewScreen>
    with SingleTickerProviderStateMixin {
  final SocketService _socketService = SocketService();
  final TextEditingController _replyController = TextEditingController();
  List<Status> _statuses = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isReplying = false;
  late AnimationController _progressController;
  Timer? _statusTimer;

  // Video player controllers
  VideoPlayerController? _videoPlayerController;
  bool _isVideoInitialized = false;
  String? _videoError;
  bool _useVideoFallback = false;

  // Video file tracking
  String? _localVideoPath;
  bool _isDownloadingVideo = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _goToNextStatus();
        }
      });

    _setupSocketListeners();
    _loadStatuses();
  }

  void _setupSocketListeners() {
    _socketService.onUserStatuses = (userId, statuses) {
      if (userId == widget.statusUserId) {
        setState(() {
          _statuses = statuses;
          _isLoading = false;
        });

        if (_statuses.isNotEmpty) {
          _initializeCurrentStatus();
        }
      }
    };
  }

  void _loadStatuses() {
    _socketService.getUserStatuses(widget.statusUserId);
  }

  void _initializeCurrentStatus() {
    // Dispose any existing video controller
    _disposeVideoController();
    _clearLocalVideoFile();

    setState(() {
      _videoError = null;
      _useVideoFallback = false;
      _isDownloadingVideo = false;
      _downloadProgress = 0.0;
    });

    if (_currentIndex < _statuses.length) {
      final currentStatus = _statuses[_currentIndex];

      // If this is a video status, initialize the video player
      if (currentStatus.statusType == 'video' &&
          currentStatus.fileUrl != null &&
          currentStatus.fileUrl!.isNotEmpty) {
        _handleVideoPlayback(currentStatus.fileUrl!);
      } else {
        // For non-video statuses, just start the timer
        _startStatusTimer();
      }
    }
  }

  // New approach to handle video playback
  Future<void> _handleVideoPlayback(String videoUrl) async {
    try {
      setState(() {
        _isVideoInitialized = false;
        _isDownloadingVideo = true;
        _downloadProgress = 0.0;
      });

      print('Preparing video: $videoUrl');

      // First try direct network playback
      await _tryDirectVideoPlayback(videoUrl);
    } catch (e) {
      print('Direct video playback failed: $e');

      // If direct playback fails, try downloading and using a local file
      try {
        await _downloadAndPlayVideo(videoUrl);
      } catch (e) {
        print('Local video playback failed: $e');
        setState(() {
          _videoError = 'Video playback not supported on this device: $e';
          _useVideoFallback = true;
          _isDownloadingVideo = false;
        });
        _startStatusTimer();
      }
    }
  }

  Future<void> _tryDirectVideoPlayback(String videoUrl) async {
    _videoPlayerController = VideoPlayerController.network(
      videoUrl,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
      ),
    );

    // Set up error listener
    bool hasError = false;
    _videoPlayerController!.addListener(() {
      if (_videoPlayerController!.value.hasError && !hasError) {
        hasError = true;
        print(
            'Network video error: ${_videoPlayerController!.value.errorDescription}');
        // We'll handle this error in the catch block
        throw Exception(_videoPlayerController!.value.errorDescription);
      }
    });

    // Try to initialize with timeout
    await _videoPlayerController!.initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        throw TimeoutException('Video initialization timed out');
      },
    );

    if (_videoPlayerController!.value.isInitialized) {
      print('Direct network playback successful');

      // Set the progress controller duration based on video length
      final videoDuration = _videoPlayerController!.value.duration;
      final progressDuration = videoDuration.inSeconds < 5
          ? const Duration(seconds: 5)
          : (videoDuration.inSeconds > 30
              ? const Duration(seconds: 30)
              : videoDuration);

      _progressController.duration = progressDuration;

      // Start playing and update UI
      await _videoPlayerController!.play();

      setState(() {
        _isVideoInitialized = true;
        _isDownloadingVideo = false;
      });

      _startStatusTimer();
    } else {
      throw Exception('Video failed to initialize properly');
    }
  }

  Future<void> _downloadAndPlayVideo(String videoUrl) async {
    setState(() {
      _isDownloadingVideo = true;
      _downloadProgress = 0.0;
    });

    try {
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final fileName =
          'status_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      _localVideoPath = '${directory.path}/$fileName';

      // Download the file with progress updates
      final response =
          await http.Client().send(http.Request('GET', Uri.parse(videoUrl)));

      final contentLength = response.contentLength ?? 0;
      int bytesReceived = 0;

      final file = File(_localVideoPath!);
      final sink = file.openWrite();

      await response.stream.listen((chunk) {
        sink.add(chunk);
        bytesReceived += chunk.length;

        if (contentLength > 0 && mounted) {
          setState(() {
            _downloadProgress = bytesReceived / contentLength;
          });
        }
      }).asFuture();

      await sink.flush();
      await sink.close();

      print('Video downloaded to: $_localVideoPath');

      // Initialize player with local file
      if (_videoPlayerController != null) {
        await _videoPlayerController!.dispose();
      }

      _videoPlayerController =
          VideoPlayerController.file(File(_localVideoPath!));

      await _videoPlayerController!.initialize();

      if (_videoPlayerController!.value.isInitialized) {
        // Set the progress controller duration based on video length
        final videoDuration = _videoPlayerController!.value.duration;
        final progressDuration = videoDuration.inSeconds < 5
            ? const Duration(seconds: 5)
            : (videoDuration.inSeconds > 30
                ? const Duration(seconds: 30)
                : videoDuration);

        _progressController.duration = progressDuration;

        // Start playing
        await _videoPlayerController!.play();

        setState(() {
          _isVideoInitialized = true;
          _isDownloadingVideo = false;
        });

        _startStatusTimer();
      } else {
        throw Exception('Local video failed to initialize');
      }
    } catch (e) {
      print('Error playing downloaded video: $e');
      setState(() {
        _videoError = 'Error playing video: $e';
        _useVideoFallback = true;
        _isDownloadingVideo = false;
      });
      _startStatusTimer();
    }
  }

  void _clearLocalVideoFile() async {
    if (_localVideoPath != null) {
      try {
        final file = File(_localVideoPath!);
        if (await file.exists()) {
          await file.delete();
          print('Deleted local video file: $_localVideoPath');
        }
      } catch (e) {
        print('Error deleting local video file: $e');
      }
      _localVideoPath = null;
    }
  }

  void _disposeVideoController() {
    if (_videoPlayerController != null) {
      _videoPlayerController!.removeListener(() {});
      _videoPlayerController!.dispose();
      _videoPlayerController = null;
    }

    _isVideoInitialized = false;
  }

  void _startStatusTimer() {
    // Reset and start the progress controller
    _progressController.reset();
    _progressController.forward();
  }

  void _goToNextStatus() {
    if (_currentIndex < _statuses.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _initializeCurrentStatus();
    } else {
      // No more statuses, close the screen
      Navigator.pop(context);
    }
  }

  void _goToPreviousStatus() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _initializeCurrentStatus();
    }
  }

  void _pauseStatus() {
    _progressController.stop();
    if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized &&
        _videoPlayerController!.value.isPlaying) {
      _videoPlayerController!.pause();
    }
  }

  void _resumeStatus() {
    _progressController.forward();
    if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized &&
        !_videoPlayerController!.value.isPlaying) {
      _videoPlayerController!.play();
    }
  }

  void _toggleReplyInput() {
    setState(() {
      _isReplying = !_isReplying;
    });

    if (_isReplying) {
      _pauseStatus();
    } else {
      _resumeStatus();
    }
  }

  void _replyToStatus() {
    if (_replyController.text.trim().isEmpty) return;

    final currentStatus = _statuses[_currentIndex];

    _socketService.replyToStatus(
      statusId: currentStatus.statusId,
      message: _replyController.text.trim(),
      senderId: widget.currentUserId,
      receiverId: widget.statusUserId,
    );

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reply sent')),
    );

    setState(() {
      _isReplying = false;
      _replyController.clear();
    });

    _resumeStatus();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _statusTimer?.cancel();
    _disposeVideoController();
    _clearLocalVideoFile();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _statuses.isEmpty
              ? _buildNoStatus()
              : _buildStatusView(),
    );
  }

  Widget _buildNoStatus() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'No active status found',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusView() {
    final currentStatus = _statuses[_currentIndex];

    return SafeArea(
      child: Stack(
        children: [
          // Progress indicators
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(
              children: List.generate(
                _statuses.length,
                (index) => Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: index == _currentIndex
                        ? FractionallySizedBox(
                            widthFactor: _progressController.value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          )
                        : index < _currentIndex
                            ? Container(color: Colors.white)
                            : null,
                  ),
                ),
              ),
            ),
          ),

          // User info
          Positioned(
            top: 20,
            left: 10,
            right: 10,
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User ${widget.statusUserId}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getTimeAgo(currentStatus.timestamp),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Left/Right tap areas for navigation
          Row(
            children: [
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: _goToPreviousStatus,
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),
              ),
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: _goToNextStatus,
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),

          // Status content
          Center(
            child: _buildStatusContent(currentStatus),
          ),

          // Reply button
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: _isReplying
                ? _buildReplyInput()
                : Center(
                    child: IconButton(
                      icon: const Icon(
                        Icons.reply,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: _toggleReplyInput,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusContent(Status status) {
    switch (status.statusType) {
      case 'image':
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Image.network(
                  status.fileUrl!,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 48,
                      ),
                    );
                  },
                ),
              ),
              if (status.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    status.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        );

      case 'video':
        if (_isDownloadingVideo) {
          // Show download progress
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress : null,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  _downloadProgress > 0
                      ? 'Preparing video... ${(_downloadProgress * 100).toStringAsFixed(0)}%'
                      : 'Preparing video...',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        }

        // Use fallback display for video if there were errors
        if (_useVideoFallback || _videoError != null) {
          return _buildVideoFallback(status);
        }

        if (!_isVideoInitialized) {
          // Show loading indicator while video initializes
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Loading video...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        }

        // Show direct VideoPlayer
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: _videoPlayerController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoPlayerController!.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Video player
                          VideoPlayer(_videoPlayerController!),

                          // Play/pause overlay
                          if (!_videoPlayerController!.value.isPlaying)
                            GestureDetector(
                              onTap: () {
                                _videoPlayerController!.play();
                                setState(() {});
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black26,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(12),
                                child: const Icon(
                                  Icons.play_arrow,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
            ),
            if (status.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  status.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );

      case 'text':
      default:
        return Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.green[800],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        );
    }
  }

  // Build a fallback for video display when playback fails
  Widget _buildVideoFallback(Status status) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Video icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.videocam,
                size: 60,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),

            // Video description
            if (status.content.isNotEmpty)
              Text(
                status.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 12),

            // Error message
            if (_videoError != null) ...[
              Divider(color: Colors.grey[700]),
              const SizedBox(height: 8),
              const Text(
                'Video could not be played',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap to continue',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReplyInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              decoration: const InputDecoration(
                hintText: 'Reply to status...',
                border: InputBorder.none,
              ),
              autofocus: true,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.green),
            onPressed: _replyToStatus,
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(int timestamp) {
    final now = DateTime.now();
    final statusTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(statusTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Yesterday';
    }
  }
}
