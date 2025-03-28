import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:leo_app_01/widgets/image_viewr.dart';
import '../constants/app_constants.dart';

class FilePreviewWidget extends StatelessWidget {
  final String fileUrl;
  final String messageType;
  final String? fileName;

  const FilePreviewWidget({
    super.key,
    required this.fileUrl,
    required this.messageType,
    this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    // Debug output
    print('FilePreviewWidget build:');
    print('- fileUrl: $fileUrl');
    print('- messageType: $messageType');
    print('- fileName: $fileName');

    // Check for empty URL
    if (fileUrl.isEmpty) {
      return _buildErrorWidget("Empty file URL", context);
    }

    switch (messageType) {
      case AppConstants.messageTypeImage:
        return _buildImagePreview(context);
      case AppConstants.messageTypeVideo:
        return _buildVideoPreview(context);
      case AppConstants.messageTypeAudio:
        return _buildAudioPreview(context);
      case AppConstants.messageTypeDocument:
        return _buildDocumentPreview(context);
      default:
        return _buildErrorWidget("Unknown message type: $messageType", context);
    }
  }

  Widget _buildErrorWidget(String errorMessage, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Error displaying file',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.red[800]),
          ),
          Text(
            errorMessage,
            style: TextStyle(fontSize: 12, color: Colors.red[800]),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GestureDetector(
        onTap: () => _openFileInApp(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 200,
          ),
          child: CachedNetworkImage(
            imageUrl: fileUrl,
            placeholder: (context, url) => Container(
              height: 150,
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 150,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.error, color: Colors.red),
              ),
            ),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPreview(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFileInApp(context),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.play_circle_fill,
              size: 50,
              color: Colors.white,
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  fileName ?? 'Video',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPreview(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFileInApp(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.audio_file, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Voice Message',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    fileName ?? 'Audio file',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.play_arrow, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentPreview(BuildContext context) {
    final icon = _getDocumentIcon();
    final displayName = fileName ?? 'Document';

    return GestureDetector(
      onTap: () => _openFileInApp(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.open_in_new,
                        size: 14,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to open',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDocumentIcon() {
    if (fileName == null) return Icons.insert_drive_file;

    final extension = fileName!.split('.').last.toLowerCase();

    switch (extension) {
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

  void _openFileInApp(BuildContext context) {
    // Prepare URL - ensure it has http/https prefix
    String url = fileUrl;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }

    print('Opening file in app: $url');

    // Navigate to the appropriate screen based on file type
    switch (messageType) {
      case AppConstants.messageTypeImage:
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

      case AppConstants.messageTypeVideo:
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

      case AppConstants.messageTypeAudio:
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

      case AppConstants.messageTypeDocument:
        // For PDF files, use PDF viewer
        if (fileName != null && fileName!.toLowerCase().endsWith('.pdf')) {
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
