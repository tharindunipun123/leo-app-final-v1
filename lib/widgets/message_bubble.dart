import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/message.dart';
import 'file_preview_widget.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onLongPress;
  final String currentUserId;
  final bool isSelected;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onLongPress,
    required this.currentUserId,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // Check if message is deleted
    final bool isDeletedForMe = message.isDeletedFor(currentUserId);
    final bool isDeletedForEveryone = message.deletedForEveryone == true;
    final bool isDeleted = isDeletedForMe || isDeletedForEveryone;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {},
            onLongPress: isDeleted ? null : onLongPress,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: message.messageType == AppConstants.messageTypeText ||
                      message.messageType == 'status_reply'
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                  : const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getBubbleColor(isDeleted),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
                border: isSelected
                    ? Border.all(color: Colors.blue, width: 2)
                    : null,
              ),
              child: isDeleted
                  ? _buildDeletedMessageContent(isDeletedForEveryone)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // For status reply messages
                        if (message.messageType == 'status_reply')
                          _buildStatusReplyContent(context),

                        // File preview for non-text and non-status-reply messages
                        if (message.messageType !=
                                AppConstants.messageTypeText &&
                            message.messageType != 'status_reply' &&
                            message.fileUrl != null &&
                            message.fileUrl!.isNotEmpty)
                          _buildFilePreview(context),

                        // Text message or caption (not for status replies as they're handled separately)
                        if (message.message.isNotEmpty &&
                            message.messageType != 'status_reply')
                          Padding(
                            padding: message.messageType !=
                                    AppConstants.messageTypeText
                                ? const EdgeInsets.only(top: 8)
                                : EdgeInsets.zero,
                            child: Text(message.message),
                          ),

                        // Add some spacing before timestamp
                        const SizedBox(height: 4),

                        // Timestamp and status in a row at the end
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _formatTimestamp(message.timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              Icon(
                                message.read
                                    ? Icons.done_all
                                    : (message.delivered
                                        ? Icons.done_all
                                        : Icons.done),
                                size: 16,
                                color: message.read
                                    ? Colors.blue
                                    : Colors.grey[400],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Build file preview with error handling
  Widget _buildFilePreview(BuildContext context) {
    // Check if file URL is valid
    if (message.fileUrl == null || message.fileUrl!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Invalid file',
                style: TextStyle(color: Colors.red[700], fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Wrap FilePreviewWidget in error boundary
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.6,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FilePreviewWidget(
          fileUrl: message.fileUrl!,
          messageType: message.messageType,
          fileName: message.fileName,
        ),
      ),
    );
  }

  // Get the appropriate bubble color based on deletion status
  Color _getBubbleColor(bool isDeleted) {
    if (isDeleted) {
      return isMe ? const Color(0xFFE6E6E6) : const Color(0xFFF0F0F0);
    }
    return isMe ? const Color(0xFFDCF8C6) : Colors.white;
  }

  // Build the content for deleted messages
  Widget _buildDeletedMessageContent(bool isDeletedForEveryone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.block,
            size: 16,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isDeletedForEveryone
                  ? 'This message was deleted'
                  : 'You deleted this message',
              style: const TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Status reply specific content builder
  Widget _buildStatusReplyContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status content preview container
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status reply header
              Row(
                children: [
                  const Icon(Icons.reply, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Replied to status',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Status content preview based on type
              _buildStatusContentPreview(),
            ],
          ),
        ),

        // The actual reply message
        Text(message.message),
      ],
    );
  }

  // Helper to build status content preview based on type
  Widget _buildStatusContentPreview() {
    // For text status
    if (message.statusType == AppConstants.messageTypeText) {
      return Text(
        message.statusContent ?? '',
        style: const TextStyle(fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    // For image status
    else if (message.statusType == AppConstants.messageTypeImage) {
      return Row(
        children: [
          const Icon(Icons.image, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              message.statusContent?.isNotEmpty == true
                  ? message.statusContent!
                  : 'Photo',
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    // For video status
    else if (message.statusType == AppConstants.messageTypeVideo) {
      return Row(
        children: [
          const Icon(Icons.videocam, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              message.statusContent?.isNotEmpty == true
                  ? message.statusContent!
                  : 'Video',
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    // Default fallback
    else {
      return Text(
        message.statusContent ?? 'Status',
        style: const TextStyle(fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}
