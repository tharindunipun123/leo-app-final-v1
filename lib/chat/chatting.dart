import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path_lib;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:zego_zimkit/zego_zimkit.dart';
import '../HomeScreen.dart';
import '../constants/app_constants.dart';
import '../models/message.dart';
import '../services/socket_service.dart';
import '../widgets/audio_recorder_widget.dart';
import '../widgets/custom_call_button.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_selection_manager.dart';

// Main chatting page
class DemoChattingMessageListPage extends StatefulWidget {
  DemoChattingMessageListPage({
    super.key,
    required this.currentUserId,
    required this.receiverId,
    required this.receiverName,
    required this.receiverProfileUrl,

    // required this.conversationID,
    // required this.conversationType,
  });
  final String receiverName;
  String? receiverProfileUrl;
  final String currentUserId;
  final String receiverId;

  // final String conversationID;
  // final ZIMConversationType conversationType;

  @override
  State<DemoChattingMessageListPage> createState() => _DemoChattingPageState();
}

class _DemoChattingPageState extends State<DemoChattingMessageListPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final SocketService _socketService = SocketService();
  final MessageSelectionManager _selectionManager = MessageSelectionManager();

  bool _isReceiverTyping = false;
  bool _isShowingRecorder = false;
  bool _isAttachmentMenuOpen = false;
  bool _isUserBlocked = false;
  bool _isCheckingBlockStatus = true;
  bool _isInSelectionMode = false;
  FilePreview? _filePreview;
  @override
  void initState() {
    super.initState();
    _setupSocketListeners();
    _loadChatHistory();
    _checkBlockStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _forceScrollToBottom();

      // Try again after a bit longer
      Future.delayed(const Duration(seconds: 1), () {
        _forceScrollToBottom();
      });
    });
  }

  void _checkBlockStatus() {
    final BuildContext currentContext = context;

    // Set up block status listeners
    _socketService.onBlockedStatus = (isUserBlocked, isOtherUserBlocked) {
      setState(() {
        _isUserBlocked =
            isOtherUserBlocked; // This shows if the current user has blocked the other user
        _isCheckingBlockStatus = false;
      });
    };

    _socketService.onUserBlocked = (blockedUserId) {
      if (blockedUserId == widget.receiverId) {
        setState(() {
          _isUserBlocked = true;
        });
        // Show confirmation
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('User ${widget.receiverId} has been blocked')),
        );
      }
    };

    _socketService.onUserUnblocked = (unblockedUserId) {
      if (unblockedUserId == widget.receiverId) {
        setState(() {
          _isUserBlocked = false;
        });
        // Show confirmation
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
              content: Text('User ${widget.receiverId} has been unblocked')),
        );
      }
    };

    _socketService.onBlockedByUser = (blockedByUserId) {
      if (blockedByUserId == widget.receiverId) {
        // Show a notification that you've been blocked
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('You have been blocked by user ${widget.receiverId}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    };

    _socketService.onMessageBlocked = (receiverId, reason) {
      if (receiverId == widget.receiverId) {
        String message = 'Message not sent';
        if (reason == 'BLOCKED_BY_RECEIVER') {
          message =
              'This user has blocked you. You cannot send messages to them.';
        }

        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    };

    // Check initial block status
    _socketService.checkBlockedStatus(
      widget.currentUserId,
      widget.receiverId,
    );
  }

  void _blockUser() {
    _socketService.blockUser(
      widget.currentUserId,
      widget.receiverId,
    );
  }

  void _unblockUser() {
    _socketService.unblockUser(
      widget.currentUserId,
      widget.receiverId,
    );
  }

  void _showBlockMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: 'block',
          child: Text(_isUserBlocked ? 'Unblock user' : 'Block user'),
        ),
      ],
    ).then((value) {
      if (value == 'block') {
        if (_isUserBlocked) {
          _unblockUser();
        } else {
          _showBlockConfirmationDialog();
        }
      }
    });
  }

  void _showBlockConfirmationDialog() {
    final currentContext = context;
    showDialog(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: Text('Block ${widget.receiverId}?'),
        content: const Text('When you block someone:\n'
            '• They won\'t be able to send you messages\n'
            '• They\'ll be notified that they\'ve been blocked\n'
            '• You can unblock them at any time'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _blockUser();
              Navigator.of(context).pop();
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _setupSocketListeners() {
    _socketService.onMessageDeleted = (messageId, forEveryone) {
      setState(() {
        final index = _messages.indexWhere((msg) => msg.messageId == messageId);
        if (index != -1) {
          if (forEveryone) {
            _messages[index].deletedForEveryone = true;
          } else {
            _messages[index].deletedForUsers ??= [];
            if (!_messages[index]
                .deletedForUsers!
                .contains(widget.currentUserId)) {
              _messages[index].deletedForUsers!.add(widget.currentUserId);
            }
          }

          // Exit selection mode if active
          if (_isInSelectionMode) {
            _exitSelectionMode();
          }
        }
      });
    };

    _socketService.onMessageDeletedByOther = (messageId, senderId) {
      setState(() {
        final index = _messages.indexWhere((msg) => msg.messageId == messageId);
        if (index != -1) {
          _messages[index].deletedForEveryone = true;

          // Exit selection mode if active
          if (_isInSelectionMode) {
            _exitSelectionMode();
          }
        }
      });

      // Show a toast/snackbar notification
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A message was deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    };
    // Handle new messages
    _socketService.onNewMessage = (message) {
      if (message.senderId == widget.receiverId) {
        setState(() {
          _messages.add(message);
        });

        // Mark message as delivered
        _socketService.markAsDelivered(
          message.messageId,
          message.senderId,
          widget.currentUserId,
        );

        // Then mark as read
        _socketService.markAsRead(
          message.messageId,
          message.senderId,
          widget.currentUserId,
        );

        _scrollToBottom();
      }
    };

    // Handle chat history
    // Handle chat history
    _socketService.onChatHistory = (messages) {
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });

      // Mark all messages from receiver as read
      for (var msg in _messages) {
        if (msg.senderId == widget.receiverId && !msg.read) {
          _socketService.markAsRead(
            msg.messageId,
            msg.senderId,
            widget.currentUserId,
          );
        }
      }

      // Use a longer delay to force scroll after chat history is loaded
      _forceScrollToBottom();
    };

    // Handle delivered status updates
    _socketService.onMessageDelivered = (messageId) {
      setState(() {
        final index = _messages.indexWhere((msg) => msg.messageId == messageId);
        if (index != -1) {
          _messages[index].delivered = true;
        }
      });
    };

    // Handle read status updates
    _socketService.onMessageRead = (messageId) {
      setState(() {
        final index = _messages.indexWhere((msg) => msg.messageId == messageId);
        if (index != -1) {
          _messages[index].read = true;
        }
      });
    };

    // Handle typing status
    _socketService.onUserTyping = (userId) {
      if (userId == widget.receiverId) {
        setState(() {
          _isReceiverTyping = true;
        });
      }
    };

    _socketService.onUserStoppedTyping = (userId) {
      if (userId == widget.receiverId) {
        setState(() {
          _isReceiverTyping = false;
        });
      }
    };
  }

  void _loadChatHistory() {
    _socketService.getChatHistory(
      widget.currentUserId,
      widget.receiverId,
    );
    // Add these new listeners for message deletion
  }

  // Add this method to your _ChatScreenState class
  void _forceScrollToBottom() {
    // Use a longer delay to ensure the messages are properly rendered
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        // Get the maximum scroll extent after the messages have been rendered
        final maxScroll = _scrollController.position.maxScrollExtent;
        _scrollController.animateTo(
          maxScroll,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  // Message selection methods
  void _onMessageSelected(Message message) {
    if (_isInSelectionMode) {
      setState(() {
        _selectionManager.toggleSelection(message);
        if (!_selectionManager.hasSelection) {
          _exitSelectionMode();
        }
      });
    } else {
      _enterSelectionMode(message);
    }
  }

  void _enterSelectionMode(Message message) {
    setState(() {
      _isInSelectionMode = true;
      _selectionManager.selectMessage(message);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isInSelectionMode = false;
      _selectionManager.clearSelection();
    });
  }

  // Check if messages can be deleted for everyone
  bool _canDeleteForEveryone() {
    if (!_selectionManager.hasSelection) return false;

    // Check if user is sender of all selected messages
    final allFromCurrentUser =
        _selectionManager.allMessagesFromUser(widget.currentUserId);

    // Check if all messages are newer than 1 hour
    const oneHour = 60 * 60 * 1000; // 1 hour in milliseconds
    final allMessagesRecent = _selectionManager.allMessagesNewerThan(oneHour);

    return allFromCurrentUser && allMessagesRecent;
  }

  // Delete selected messages
  void _deleteSelectedMessages(bool forEveryone) {
    final selectedMessages = List.from(_selectionManager.selectedMessages);
    int deletedCount = 0;

    // First, update the local state immediately to provide instant feedback
    setState(() {
      for (final message in selectedMessages) {
        final index =
            _messages.indexWhere((msg) => msg.messageId == message.messageId);
        if (index != -1) {
          if (forEveryone) {
            _messages[index].deletedForEveryone = true;
          } else {
            _messages[index].deletedForUsers ??= [];
            if (!_messages[index]
                .deletedForUsers!
                .contains(widget.currentUserId)) {
              _messages[index].deletedForUsers!.add(widget.currentUserId);
            }
          }
          deletedCount++;
        }
      }
    });

    // Then send the deletion requests to the server
    for (final message in selectedMessages) {
      if (forEveryone) {
        _socketService.deleteMessageForEveryone(
            widget.currentUserId, message.messageId);
      } else {
        _socketService.deleteMessageForMe(
            widget.currentUserId, message.messageId);
      }
    }

    // Exit selection mode after deletion
    _exitSelectionMode();

    // Show confirmation
    if (deletedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(forEveryone
              ? 'Message${deletedCount > 1 ? 's' : ''} deleted for everyone'
              : 'Message${deletedCount > 1 ? 's' : ''} deleted'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Show delete options dialog
  void _showDeleteOptionsDialog() {
    final bool canDeleteForEveryone = _canDeleteForEveryone();
    final int count = _selectionManager.selectionCount;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${count > 1 ? '$count messages' : 'message'}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSelectedMessages(false);
              },
              child: const Text('Delete for me'),
            ),
            if (canDeleteForEveryone)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteSelectedMessages(true);
                },
                child: const Text('Delete for everyone',
                    style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _sendMessage(
      {String? text, String? fileUrl, String? fileName, String? messageType}) {
    if ((text == null || text.trim().isEmpty) && fileUrl == null) {
      return;
    }

    print(widget.receiverId);

    final message = Message(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: widget.currentUserId,
      message: text ?? '',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      delivered: false,
      read: false,
      messageType: messageType ?? AppConstants.messageTypeText,
      fileName: fileName,
      fileUrl: fileUrl,
      receiverId: widget.receiverId,
    );

    _socketService.sendMessage(message);

    setState(() {
      _messages.add(message);
      _messageController.clear();
      _isShowingRecorder = false;
      _isAttachmentMenuOpen = false;
    });

    _scrollToBottom();
  }

  Future<void> _pickImage(ImageSource source) async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: source);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      // Instead of immediately uploading, set the preview
      setState(() {
        _filePreview = FilePreview(
          file: file,
          messageType: AppConstants.messageTypeImage,
        );
        _isAttachmentMenuOpen = false;
      });
    }
  }

  // Modify the _pickDocument method
  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      setState(() {
        _filePreview = FilePreview(
          file: file,
          messageType: AppConstants.messageTypeDocument,
          fileName: result.files.single.name,
        );
        _isAttachmentMenuOpen = false;
      });
    }
  }

  Future<File?> _generateVideoThumbnail(String videoPath) async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        quality: 75,
      );

      if (thumbnailPath != null) {
        return File(thumbnailPath);
      }
      return null;
    } catch (e) {
      print('Error generating video thumbnail: $e');
      return null;
    }
  }

// Update the _pickVideo method to generate a preview like images and documents
  Future<void> _pickVideo() async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);

      // Generate thumbnail for the video
      final thumbnailFile = await _generateVideoThumbnail(file.path);

      // Set preview instead of immediately uploading
      setState(() {
        _filePreview = FilePreview(
          file: file,
          messageType: AppConstants.messageTypeVideo,
          thumbnailFile: thumbnailFile,
        );
        _isAttachmentMenuOpen = false;
      });
    }
  }

  void _cancelFilePreview() {
    setState(() {
      _filePreview = null;
    });
  }

  // Replace the existing _sendPreviewedFile and _uploadFile methods with these updated versions:

  void _sendPreviewedFile() async {
    if (_filePreview != null) {
      final fileToUpload = _filePreview!.file;
      final messageType = _filePreview!.messageType;
      final fileName = _filePreview!.fileName;

      // Clear the preview first to show chat UI
      setState(() {
        _filePreview = null;
      });

      // Then upload the file (with loading indicator properly contained)
      await _uploadFile(
        fileToUpload,
        messageType,
        fileName: fileName,
      );
    }
  }

  Widget _buildFilePreview() {
    if (_filePreview == null) return const SizedBox.shrink();

    Widget previewWidget;

    switch (_filePreview!.messageType) {
      case AppConstants.messageTypeImage:
        previewWidget = Image.file(
          _filePreview!.file,
          height: 250,
          fit: BoxFit.contain,
        );
        break;

      case AppConstants.messageTypeVideo:
        previewWidget = Stack(
          alignment: Alignment.center,
          children: [
            Image.file(
              File(_filePreview!.file.path),
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 250,
                  color: Colors.black,
                  child: const Center(
                    child: Icon(Icons.videocam, color: Colors.white, size: 50),
                  ),
                );
              },
            ),
            const Icon(Icons.play_circle_outline,
                size: 50, color: Colors.white),
          ],
        );
        break;

      case AppConstants.messageTypeDocument:
        previewWidget = Container(
          height: 150,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_drive_file,
                size: 48,
                color: Colors.blue.shade700,
              ),
              const SizedBox(height: 8),
              Text(
                _filePreview!.fileName ?? 'Document',
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${(_filePreview!.file.lengthSync() / 1024).toStringAsFixed(2)} KB',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ],
          ),
        );
        break;

      default:
        previewWidget = const Text('Unsupported file type');
    }

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Preview',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _cancelFilePreview,
              ),
            ],
          ),
          const SizedBox(height: 8),
          previewWidget,
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _cancelFilePreview,
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _sendPreviewedFile,
                icon: const Icon(Icons.send),
                label: const Text('Send'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF128C7E),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  // This snippet shows the corrected version of the showDialog call in the _uploadFile method
// with the proper BuildContext typing

  Future<void> _uploadFile(File file, String messageType,
      {String? fileName}) async {
    // Create multipart request
    final request =
        http.MultipartRequest('POST', Uri.parse(AppConstants.fileUploadUrl));

    // Determine MIME type
    String? mimeType;
    String? extension = fileName != null
        ? fileName.split('.').last.toLowerCase()
        : file.path.split('.').last.toLowerCase();

    if (messageType == AppConstants.messageTypeImage) {
      mimeType = 'image/$extension';
    } else if (messageType == AppConstants.messageTypeVideo) {
      mimeType = 'video/$extension';
    } else if (messageType == AppConstants.messageTypeAudio) {
      mimeType = 'audio/$extension';
    } else {
      mimeType = 'application/$extension';
    }

    // Add file to request
    request.files.add(
      http.MultipartFile(
        'file',
        file.readAsBytes().asStream(),
        file.lengthSync(),
        filename: fileName ?? path_lib.basename(file.path),
        contentType: MediaType.parse(mimeType),
      ),
    );

    // Create a unique loading dialog key to ensure we can dismiss it properly
    final loadingDialogKey = GlobalKey<State>();

    // Show loading indicator with a better containment strategy
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            key: loadingDialogKey,
            backgroundColor: Colors.white.withOpacity(0.8),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Uploading file...", textAlign: TextAlign.center),
              ],
            ),
          );
        },
      );
    }

    try {
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Hide loading indicator safely
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Only send message with file if the component is still mounted
        if (mounted) {
          _sendMessage(
            fileUrl: data['fileUrl'],
            fileName: data['fileName'],
            messageType: messageType,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload file')),
          );
        }
      }
    } catch (e) {
      // Hide loading indicator
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _onRecordingComplete(String path) {
    final file = File(path);
    _uploadFile(file, AppConstants.messageTypeAudio,
        fileName: 'voice_${DateTime.now().millisecondsSinceEpoch}.aac');

    setState(() {
      _isShowingRecorder = false;
    });
  }

  void _onRecordingCancelled() {
    setState(() {
      _isShowingRecorder = false;
    });
  }

  @override
  void dispose() {
    HomeScreen.setBottomBarVisibility(true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: _isInSelectionMode ? 56 : null,
        leading: _isInSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        title: _isInSelectionMode
            ? Text('${_selectionManager.selectionCount} selected')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.receiverName),
                  if (_isReceiverTyping)
                    const Text(
                      'typing...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  if (_isUserBlocked)
                    const Text(
                      'Blocked',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                ],
              ),
        actions: _isInSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _showDeleteOptionsDialog,
                ),
              ]
            : [
                CallButtons(
                  currentUserId: widget.currentUserId,
                  targetUserId: widget.receiverId,
                  name: widget.receiverName,
                ),
                PopupMenuButton<String>(
                  icon: _isUserBlocked
                      ? const Icon(Icons.block, color: Colors.red)
                      : const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'block') {
                      if (_isUserBlocked) {
                        _unblockUser();
                      } else {
                        _showBlockConfirmationDialog();
                      }
                    }
                  },
                  // Remove the enabled property or set it to always true
                  // enabled: !_isCheckingBlockStatus,
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'block',
                      child:
                          Text(_isUserBlocked ? 'Unblock user' : 'Block user'),
                    ),
                    // // You can add more menu items here if needed
                    // const PopupMenuItem<String>(
                    //   value: 'report',
                    //   child: Text('Report user'),
                    // ),
                  ],
                )
              ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFECE5DD),
                image: DecorationImage(
                  image: AssetImage('assets/chat_background.jpg'),
                  fit: BoxFit.cover,
                  opacity: 0.2,
                ),
              ),
              child: _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No messages yet. Send a message to start chatting!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      key: ValueKey<int>(_messages.length),
                      controller: _scrollController,
                      padding: const EdgeInsets.all(10),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMe = message.senderId == widget.currentUserId;

                        return MessageBubble(
                          message: message,
                          isMe: isMe,
                          currentUserId: widget.currentUserId,
                          isSelected: _selectionManager.isSelected(message),
                          onLongPress: () => _onMessageSelected(message),
                        );
                      },
                    ),
            ),
          ),

          if (_filePreview != null) _buildFilePreview(),
          // Attachment menu
          if (_isAttachmentMenuOpen && _filePreview == null)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentButton(
                    icon: Icons.camera_alt,
                    color: Colors.purple,
                    label: 'Camera',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  _buildAttachmentButton(
                    icon: Icons.photo,
                    color: Colors.purple,
                    label: 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                  _buildAttachmentButton(
                    icon: Icons.videocam,
                    color: Colors.red,
                    label: 'Video',
                    onTap: _pickVideo,
                  ),
                  _buildAttachmentButton(
                    icon: Icons.insert_drive_file,
                    color: Colors.blue,
                    label: 'Document',
                    onTap: _pickDocument,
                  ),
                  _buildAttachmentButton(
                    icon: Icons.mic,
                    color: Colors.orange,
                    label: 'Audio',
                    onTap: () {
                      setState(() {
                        _isShowingRecorder = true;
                        _isAttachmentMenuOpen = false;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Audio recorder
          if (_isShowingRecorder && _filePreview == null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: AudioRecorderWidget(
                onRecordingComplete: _onRecordingComplete,
                onRecordingCancelled: _onRecordingCancelled,
              ),
            ),

          // Input field
          if (!_isShowingRecorder && _filePreview == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -1),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isAttachmentMenuOpen ? Icons.close : Icons.attach_file,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _isAttachmentMenuOpen = !_isAttachmentMenuOpen;
                      });
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (text) {
                        // Send typing status
                        _socketService.sendTypingStatus(
                          widget.currentUserId,
                          widget.receiverId,
                          text.isNotEmpty,
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Color(0xFF128C7E),
                    ),
                    onPressed: () {
                      if (_messageController.text.trim().isNotEmpty) {
                        _sendMessage(
                          text: _messageController.text.trim(),
                          messageType: AppConstants.messageTypeText,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class FilePreview {
  final File file;
  final String messageType;
  final String? fileName;
  final File? thumbnailFile;

  FilePreview({
    required this.file,
    required this.messageType,
    this.fileName,
    this.thumbnailFile,
  });
}
