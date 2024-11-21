import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:zego_zimkit/zego_zimkit.dart';
import 'call_button.dart';

// Dialog to start a new chat
void showNewChatDialog(BuildContext context) {
  final userIDController = TextEditingController();

  showDialog<bool>(
    useRootNavigator: false,
    context: context,
    builder: (context) => AlertDialog(
      title:  const Text('New Chat'),
      content: TextField(
        controller: userIDController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'User ID',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('OK'),
        ),
      ],
    ),
  ).then((ok) {
    if (ok == true && userIDController.text.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DemoChattingMessageListPage(
            conversationID: userIDController.text,
            conversationType: ZIMConversationType.peer,
          ),
        ),
      );
    }
  });
}

// Main chatting page
class DemoChattingMessageListPage extends StatefulWidget {
  const DemoChattingMessageListPage({
    Key? key,
    required this.conversationID,
    required this.conversationType,
  }) : super(key: key);

  final String conversationID;
  final ZIMConversationType conversationType;

  @override
  State<DemoChattingMessageListPage> createState() => _DemoChattingPageState();
}

class _DemoChattingPageState extends State<DemoChattingMessageListPage> {
  @override
  Widget build(BuildContext context) {
    return ZIMKitMessageListPage(
      conversationID: widget.conversationID,
      conversationType: widget.conversationType,
      events: ZIMKitMessageListPageEvents(
        audioRecord: ZIMKitAudioRecordEvents(
          onFailed: _handleAudioRecordError,
          onCountdownTick: _handleCountdownTick,
        ),
      ),
      onMessageSent: _handleMessageSent,
      appBarActions: [
        ...buildCallButtons(
            context,
            widget.conversationID,
            widget.conversationType
        ),
      ],
      onMessageItemLongPress: _handleMessageLongPress,
      messageListBackgroundBuilder: (context, defaultWidget) {
        return const ColoredBox(color: Colors.white);
      },
    );
  }

  void _handleAudioRecordError(int errorCode) {
    String errorMessage = 'Recording failed: $errorCode';
    if (errorCode == 32) {
      errorMessage = 'Recording time is too short';
    }
    _showError(errorMessage);
  }

  void _handleCountdownTick(int remainingSecond) {
    if (remainingSecond > 5 || remainingSecond <= 0) return;

    _showToast(
      'Time remaining: $remainingSecond seconds',
      backgroundColor: Colors.black.withOpacity(0.3),
    );
  }

  void _handleMessageSent(ZIMKitMessage message) {
    if (message.info.error != null) {
      _showError(
        'Message send failed: ${message.info.error!.message}\nCode: ${message.info.error!.code}',
      );
    }
  }

  Future<void> _handleMessageLongPress(
      BuildContext context,
      LongPressStartDetails details,
      ZIMKitMessage message,
      Function defaultAction,
      ) async {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Message Options'),
        content: const Text('Delete or recall this message?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              ZIMKit().deleteMessage([message]);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              ZIMKit()
                  .recallMessage(message)
                  .catchError((error) => _showError(error.toString()));
              Navigator.pop(context);
            },
            child: const Text('Recall'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    // Implement additional chat options here
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('View Participants'),
              onTap: () {
                // Implement view participants
                Navigator.pop(context);
              },
            ),
            if (widget.conversationType == ZIMConversationType.group)
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Leave Group'),
                onTap: () {
                  // Implement leave group
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showToast(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(milliseconds: 800),
      ),
    );
  }
}