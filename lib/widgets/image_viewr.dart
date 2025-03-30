import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:typed_data';

// This file contains all the viewers needed for different media types

// 1. Image Viewer
class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String? title;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? 'Image Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // Implement download functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading image...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing image...')),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        constraints: BoxConstraints.expand(
          height: MediaQuery.of(context).size.height,
        ),
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
          loadingBuilder: (context, event) => Center(
            child: CircularProgressIndicator(
              value: event == null
                  ? 0
                  : event.cumulativeBytesLoaded /
                      (event.expectedTotalBytes ?? 1),
            ),
          ),
          errorBuilder: (context, error, stackTrace) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Error loading image',
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  error.toString(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
        ),
      ),
    );
  }
}

// 2. PDF Viewer
class PDFViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String? title;

  const PDFViewerScreen({
    super.key,
    required this.pdfUrl,
    this.title,
  });

  @override
  _PDFViewerScreenState createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  String? localFilePath;
  bool isLoading = true;
  String? errorMessage;
  int? totalPages;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      print('respionsepdf ${response.bodyBytes}');
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getApplicationDocumentsDirectory();
        final file =
            File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.pdf');

        await file.writeAsBytes(bytes);

        setState(() {
          localFilePath = file.path;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Failed to load PDF: Server returned ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading PDF: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'PDF Viewer'),
        actions: [
          if (totalPages != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Page $currentPage of $totalPages',
                style: const TextStyle(fontSize: 16),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  // In your PDFViewerScreen class, replace the _buildBody method

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Error',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPdf,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (localFilePath == null) {
      return const Center(
        child: Text('No PDF file to display'),
      );
    }
    return PDFView(
      filePath: localFilePath!,
      enableSwipe: true,
      swipeHorizontal: true,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      defaultPage: currentPage - 1,
    );
    // Use SfPdfViewer for more robust PDF viewing
    // return SfPdfViewer.file(
    //   File(localFilePath!),
    //   onPageChanged: (PdfPageChangedDetails details) {
    //     setState(() {
    //       currentPage = details.newPageNumber;
    //       totalPages = details.newPageNumber;
    //     });
    //   },
    // );
  }
}

// 3. Video Player
// Complete fixed implementation of VideoPlayerScreen class

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String? title;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    this.title,
  });

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  // Removed 'late' keyword to prevent initialization error
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isInitialized = false;
      _errorMessage = null;
    });

    String videoUrl = widget.videoUrl;
    if (!videoUrl.startsWith('http://') && !videoUrl.startsWith('https://')) {
      videoUrl = 'https://$videoUrl';
    }

    print('Initializing video player with URL: $videoUrl');

    try {
      // Dispose old controllers if they exist
      if (_videoPlayerController != null) {
        await _videoPlayerController!.dispose();
      }
      if (_chewieController != null) {
        _chewieController!.dispose();
      }

      // Create new controller
      _videoPlayerController = VideoPlayerController.network(videoUrl);

      // Initialize the controller
      await _videoPlayerController!.initialize();

      if (_videoPlayerController!.value.isInitialized) {
        print(
            'Video initialized successfully. Duration: ${_videoPlayerController!.value.duration}');

        // Create Chewie controller
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: false,
          // Only set aspect ratio if we can determine it
          aspectRatio: _videoPlayerController!.value.aspectRatio != 0
              ? _videoPlayerController!.value.aspectRatio
              : 16 / 9,
          allowFullScreen: true,
          allowMuting: true,
          showControls: true,
          placeholder: Container(
            color: Colors.black,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorBuilder: (context, errorMessage) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.white,
                title: Text(widget.title ?? 'Video Player'),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.white, size: 42),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );

        setState(() {
          _isInitialized = true;
        });
      } else {
        setState(() {
          _errorMessage = 'Could not initialize video player';
        });
        print('Video could not be initialized');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing video: $e';
      });
      print("Video player error: $e");
    }
  }

  @override
  void dispose() {
    if (_videoPlayerController != null) {
      _videoPlayerController!.dispose();
    }
    if (_chewieController != null) {
      _chewieController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title ?? 'Video Player'),
        backgroundColor: Colors.black,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializePlayer,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized || _chewieController == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Center(
      child: Chewie(controller: _chewieController!),
    );
  }
}

// 4. Audio Player

class AudioPlayerScreen extends StatefulWidget {
  final String audioUrl;
  final String? title;
  final String? fileName;

  const AudioPlayerScreen({
    super.key,
    required this.audioUrl,
    this.title,
    this.fileName,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _errorMessage;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    String audioUrl = widget.audioUrl;
    if (!audioUrl.startsWith('http://') && !audioUrl.startsWith('https://')) {
      audioUrl = 'https://$audioUrl';
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Listen for changes in the player state
      _audioPlayer.playerStateStream.listen((playerState) {
        final isPlaying = playerState.playing;
        final processingState = playerState.processingState;

        setState(() {
          _isPlaying = isPlaying;
          if (processingState == ProcessingState.completed) {
            _isPlaying = false;
            _position = _duration;
          }
        });
      });

      // Listen for changes in the playback position
      _audioPlayer.positionStream.listen((position) {
        setState(() {
          _position = position;
        });
      });

      // Listen for changes in the buffered position
      _audioPlayer.durationStream.listen((duration) {
        if (duration != null) {
          setState(() {
            _duration = duration;
          });
        }
      });

      // Set the audio source
      await _audioPlayer.setUrl(audioUrl);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading audio: $e';
      });
      print("Audio player error: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Audio Player'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Artwork or placeholder
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(
                  Icons.audiotrack,
                  size: 120,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              widget.fileName ?? 'Audio File',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Error message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _initAudioPlayer,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),

            // Progress bar
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_errorMessage == null)
              Column(
                children: [
                  // Progress slider
                  Slider(
                    value: _position.inSeconds.toDouble().clamp(
                        0,
                        _duration.inSeconds.toDouble() > 0
                            ? _duration.inSeconds.toDouble()
                            : 1),
                    min: 0,
                    max: _duration.inSeconds.toDouble() > 0
                        ? _duration.inSeconds.toDouble()
                        : 1,
                    onChanged: (value) {
                      final position = Duration(seconds: value.toInt());
                      _audioPlayer.seek(position);
                      setState(() {
                        _position = position;
                      });
                    },
                  ),

                  // Progress duration text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(_position)),
                        Text(_formatDuration(_duration)),
                      ],
                    ),
                  ),

                  // Controls
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Rewind button
                      IconButton(
                        icon: const Icon(Icons.replay_10),
                        iconSize: 36,
                        onPressed: () {
                          final newPosition = Duration(
                            seconds: (_position.inSeconds - 10)
                                .clamp(0, _duration.inSeconds),
                          );
                          _audioPlayer.seek(newPosition);
                        },
                      ),

                      // Play/Pause button
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon:
                              Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                          iconSize: 42,
                          color: Colors.white,
                          onPressed: () {
                            if (_isPlaying) {
                              _audioPlayer.pause();
                            } else {
                              _audioPlayer.play();
                            }
                          },
                        ),
                      ),

                      // Forward button
                      IconButton(
                        icon: const Icon(Icons.forward_10),
                        iconSize: 36,
                        onPressed: () {
                          final newPosition = Duration(
                            seconds: (_position.inSeconds + 10)
                                .clamp(0, _duration.inSeconds),
                          );
                          _audioPlayer.seek(newPosition);
                        },
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// 5. Document Viewer for various document types
class DocumentViewerScreen extends StatefulWidget {
  final String documentUrl;
  final String? title;
  final String? fileName;

  const DocumentViewerScreen({
    super.key,
    required this.documentUrl,
    this.title,
    this.fileName,
  });

  @override
  _DocumentViewerScreenState createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _localFilePath;
  late String _fileExtension;

  @override
  void initState() {
    super.initState();
    _fileExtension = _getFileExtension();
    _loadDocument();
  }

  String _getFileExtension() {
    if (widget.fileName != null) {
      return widget.fileName!.split('.').last.toLowerCase();
    }

    // Try to get extension from URL
    final uri = Uri.parse(widget.documentUrl);
    final path = uri.path;
    if (path.contains('.')) {
      return path.split('.').last.toLowerCase();
    }

    return '';
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String documentUrl = widget.documentUrl;
    if (!documentUrl.startsWith('http://') &&
        !documentUrl.startsWith('https://')) {
      documentUrl = 'https://$documentUrl';
    }

    try {
      final response = await http.get(Uri.parse(documentUrl));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getApplicationDocumentsDirectory();

        // Use a filename that includes the original extension
        final filename = widget.fileName ?? 'document.$_fileExtension';
        final file = File(
            '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_$filename');

        await file.writeAsBytes(bytes);

        setState(() {
          _localFilePath = file.path;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load document: Server returned ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading document: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? (widget.fileName ?? 'Document Viewer')),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading document...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Error',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDocument,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_localFilePath == null) {
      return const Center(
        child: Text('No document file to display'),
      );
    }

    // For PDF documents, use the PDF viewer
    if (_fileExtension == 'pdf') {
      return PDFView(
        filePath: _localFilePath!,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: true,
        pageFling: true,
        pageSnap: true,
        onError: (error) {
          setState(() {
            _errorMessage = error.toString();
          });
        },
      );
    }

    // For other document types, show info and options
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getDocumentIcon(),
              size: 72,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            Text(
              widget.fileName ?? 'Document',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'File type: ${_fileExtension.toUpperCase()}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Download'),
              onPressed: () {
                // Implement download functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Document downloaded')),
                );
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open in Browser'),
              onPressed: () {
                // Open in browser functionality could be added here
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDocumentIcon() {
    switch (_fileExtension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }
}

// 6. Helper class to open files in the appropriate viewer
class FileViewerHelper {
  static void openFile(
    BuildContext context,
    String fileUrl,
    String messageType,
    String? fileName,
  ) {
    print('Opening file in app: $fileUrl');
    print('Message type: $messageType');
    print('File name: $fileName');

    if (fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid file URL')),
      );
      return;
    }

    // Make sure URL has proper scheme
    String url = fileUrl;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    switch (messageType) {
      case 'image':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImageViewer(
              imageUrl: url,
              title: fileName,
            ),
          ),
        );
        break;

      case 'video':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(
              videoUrl: url,
              title: fileName,
            ),
          ),
        );
        break;

      case 'audio':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioPlayerScreen(
              audioUrl: url,
              title: 'Voice Message',
              fileName: fileName,
            ),
          ),
        );
        break;

      case 'document':
        // For PDF files, use PDF viewer
        if (fileName != null && fileName.toLowerCase().endsWith('.pdf')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFViewerScreen(
                pdfUrl: url,
                title: fileName,
              ),
            ),
          );
        } else {
          // For other document types
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentViewerScreen(
                documentUrl: url,
                title: 'Document Viewer',
                fileName: fileName,
              ),
            ),
          );
        }
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unsupported file type: $messageType')),
        );
    }
  }
}
