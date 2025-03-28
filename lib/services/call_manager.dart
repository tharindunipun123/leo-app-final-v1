import 'package:flutter/material.dart';
import 'dart:math';
import '../services/socket_service.dart';
import '../widgets/zim_video_call.dart';

class CallHandler {
  final SocketService _socketService = SocketService();
  final BuildContext context;
  final String currentUserId;

  // Call state tracking
  String? activeCallRoomId;
  String? activeCallTargetId;
  bool isInCall = false;

  // Dialog context reference to handle multiple dialogs properly
  BuildContext? _dialogContext;

  CallHandler({required this.context, required this.currentUserId}) {
    // Initialize socket listeners for calls
    _setupCallListeners();
  }

  void _setupCallListeners() {
    // Listen for incoming calls
    _socketService.onIncomingCall = (data) {
      if (isInCall) {
        // Already in a call, auto-reject
        _socketService.rejectCall(data['caller'], currentUserId);
        return;
      }

      _showIncomingCallUI(
        callerId: data['caller'],
        roomId: data['roomId'],
        isVideoCall: data['isVideoCall'] ?? true,
      );
    };

    // Call ended remotely
    _socketService.onCallEnded = (data) {
      if (data['roomId'] == activeCallRoomId) {
        // Close any open dialogs first
        if (_dialogContext != null && Navigator.of(_dialogContext!).canPop()) {
          Navigator.of(_dialogContext!).pop();
          _dialogContext = null;
        }

        // Reset call state
        isInCall = false;
        activeCallRoomId = null;
        activeCallTargetId = null;

        // Show notification if needed
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Call ended")));
      }
    };

    // Feedback when your call request was received
    _socketService.onCallRequested = (data) {
      // Show UI feedback that call is ringing
      if (_dialogContext != null && data['roomId'] == activeCallRoomId) {
        // You could update the dialog content here if needed
        // For example, change text from "Calling..." to "Ringing..."
      }
    };

    // Handle call accepted
    _socketService.onCallAccepted = (data) {
      if (data['roomId'] == activeCallRoomId) {
        // Close any dialogs first
        if (_dialogContext != null && Navigator.of(_dialogContext!).canPop()) {
          Navigator.of(_dialogContext!).pop();
          _dialogContext = null;
        }

        // Navigate to call screen if not already there
        _navigateToCallScreen(
          data['roomId'],
          data['caller'],
          data['target'],
          false, // outgoing call
          data['isVideoCall'] ?? true,
        );
      }
    };

    // Handle call rejected
    _socketService.onCallRejected = (data) {
      if (data['caller'] == currentUserId) {
        // Close any dialogs first
        if (_dialogContext != null && Navigator.of(_dialogContext!).canPop()) {
          Navigator.of(_dialogContext!).pop();
          _dialogContext = null;
        }

        // Reset call state
        isInCall = false;
        activeCallRoomId = null;
        activeCallTargetId = null;

        // Show rejection notification
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Call was declined")));
      }
    };
  }

  // Show incoming call UI
  void _showIncomingCallUI({
    required String callerId,
    required String roomId,
    required bool isVideoCall,
  }) {
    // Store call info temporarily
    activeCallRoomId = roomId;
    activeCallTargetId = callerId;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        _dialogContext = context; // Store dialog context
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button from dismissing
          child: AlertDialog(
            title: Text("Incoming ${isVideoCall ? 'Video' : 'Audio'} Call"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(
                    isVideoCall ? Icons.videocam : Icons.call,
                    size: 30,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                Text("Call from $callerId"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  _dialogContext = null;
                  _rejectCall(callerId, roomId);
                },
                child:
                    const Text("Decline", style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  _dialogContext = null;
                  _acceptCall(callerId, roomId, isVideoCall);
                },
                child: const Text("Accept"),
              ),
            ],
          ),
        );
      },
    );
  }

  // Accept an incoming call
  void _acceptCall(String callerId, String roomId, bool isVideoCall) {
    isInCall = true;

    // Notify socket server
    _socketService.acceptCall(callerId, currentUserId, roomId);

    // Navigate to call screen
    _navigateToCallScreen(
      roomId,
      callerId,
      currentUserId,
      true, // incoming call
      isVideoCall,
    );
  }

  // Reject an incoming call
  void _rejectCall(String callerId, String roomId) {
    // Reset call state
    isInCall = false;
    activeCallRoomId = null;
    activeCallTargetId = null;

    // Notify socket server
    _socketService.rejectCall(callerId, currentUserId);
  }

  // Make an outgoing call
  void makeCall(String targetId, bool isVideoCall) {
    if (isInCall) {
      // Already in a call
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Already in a call")));
      return;
    }

    // Generate a unique room ID
    final roomId = _generateRoomId();

    // Store call info
    isInCall = true;
    activeCallRoomId = roomId;
    activeCallTargetId = targetId;

    // Request call via socket
    _socketService.requestCall(
      currentUserId,
      targetId,
      roomId,
      isVideoCall,
    );

    // Show calling UI (dialog while waiting)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        _dialogContext = context; // Store dialog context
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button from dismissing
          child: AlertDialog(
            title: const Text("Calling..."),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text("Calling $targetId..."),
                const SizedBox(height: 8),
                const Text("Waiting for answer"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _dialogContext = null;
                  _socketService.endCall(currentUserId, targetId, roomId);
                  isInCall = false;
                  activeCallRoomId = null;
                  activeCallTargetId = null;
                },
                child:
                    const Text("Cancel", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }

  // Navigate to call screen
  void _navigateToCallScreen(
    String roomId,
    String callerId,
    String targetId,
    bool isIncoming,
    bool isVideoCall,
  ) {
    // Navigate to call screen
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          roomId: roomId,
          targetUserId: targetId,
          userId: currentUserId,
          isIncoming: isIncoming,
          isVideoCall: isVideoCall,
        ),
      ),
    )
        .then((_) {
      // When returning from call screen
      isInCall = false;
      activeCallRoomId = null;
      activeCallTargetId = null;
    });
  }

  // Generate a unique room ID for Agora channel
  String _generateRoomId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return 'room_${DateTime.now().millisecondsSinceEpoch}_${String.fromCharCodes(
      Iterable.generate(
        10,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    )}';
  }

  // Clean up when done
  void dispose() {
    _socketService.onIncomingCall = null;
    _socketService.onCallAccepted = null;
    _socketService.onCallRejected = null;
    _socketService.onCallEnded = null;
    _socketService.onCallRequested = null;
  }
}
