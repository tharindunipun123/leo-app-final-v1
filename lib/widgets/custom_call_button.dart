import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import 'package:tencent_calls_uikit/tencent_calls_uikit.dart';
import 'package:tencent_calls_uikit/debug/generate_test_user_sig.dart';

class CallButtons extends StatefulWidget {
  final String currentUserId;
  final String targetUserId;
  final String name;

  const CallButtons({
    super.key,
    required this.currentUserId,
    required this.targetUserId,
    required this.name,
  });

  @override
  State<CallButtons> createState() => _CallButtonsState();
}

class _CallButtonsState extends State<CallButtons> {
  // Replace with your SDKAppID and SecretKey from Tencent Cloud console
  final int sdkAppID = 20021237; // TODO: Replace with your SDK App ID
  final String secretKey =
      "d4e7ab430a4755b8f58cf636a065b2aba9567a77a9db916689f811a87d418c23"; // TODO: Replace with your Secret Key

  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeTUICallKit();
  }

  // Initialize TUICallKit with the current user
  Future<void> _initializeTUICallKit() async {
    if (!isInitialized) {
      // Import this if not already imported

      // Generate UserSig
      String userSig = GenerateTestUserSig.genTestSig(
          widget.currentUserId, sdkAppID, secretKey);

      // Login to TUICallKit
      TUIResult result = await TUICallKit.instance
          .login(sdkAppID, widget.currentUserId, userSig);

      if (result.code.isEmpty) {
        setState(() {
          isInitialized = true;
        });
        print('TUICallKit initialized for user: ${widget.currentUserId}');
      } else {
        print(
            'TUICallKit initialization failed: ${result.code} ${result.message}');
      }
    }
  }

  // Generate a unique room ID based on user IDs
  String _generateRoomId() {
    final sortedIds = [widget.currentUserId, widget.targetUserId]..sort();
    return 'room_${sortedIds[0]}_${sortedIds[1]}';
  }

  void _startCall(BuildContext context, bool isVideoCall) {
    final roomId = _generateRoomId();
    final SocketService socketService = SocketService();

    // Check if user is online first
    socketService.debugCallFlow("START_CALL_ATTEMPT", {
      "caller": widget.currentUserId,
      "target": widget.targetUserId,
      "isVideoCall": isVideoCall
    });

    socketService.checkUserOnline(widget.targetUserId);

    // Set up online status callback
    Function originalOnlineStatusCallback =
        socketService.onUserStatus ?? (_) {};

    socketService.onUserStatus = (statusData) {
      originalOnlineStatusCallback(statusData);

      if (statusData['targetId'] == widget.targetUserId) {
        if (statusData['isOnline']) {
          _proceedWithCall(context, socketService, roomId, isVideoCall);
        } else {
          // Show user not available message
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("User is not available for a call right now")));
        }
      }
    };

    // Set up the call requested callback
    socketService.onCallRequested = (callData) {
      print("Call request sent: ${callData.toString()}");
      socketService.debugCallFlow("CALL_REQUESTED_RECEIVED", callData);

      if (callData['status'] == 'sent') {
        // Instead of navigating to VideoCallScreen, use Tencent UIKit to make a call
        _makeTencentCall(isVideoCall);
      } else if (callData['status'] == 'target_not_available') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("User is not available for a call right now")));
      }
    };

    // Signal call request to the other user
    socketService.requestCall(
        widget.currentUserId, widget.targetUserId, roomId, isVideoCall);
  }

  void _proceedWithCall(BuildContext context, SocketService socketService,
      String roomId, bool isVideoCall) {
    socketService.debugCallFlow("PROCEEDING_WITH_CALL", {
      "caller": widget.currentUserId,
      "target": widget.targetUserId,
      "room": roomId,
      "isVideoCall": isVideoCall
    });

    // Signal call request to the other user
    socketService.requestCall(
        widget.currentUserId, widget.targetUserId, roomId, isVideoCall);
  }

  // Make a call using Tencent UIKit
  void _makeTencentCall(bool isVideoCall) async {
    // Ensure TUICallKit is initialized
    if (!isInitialized) {
      await _initializeTUICallKit();
    }

    // Determine media type based on isVideoCall
    TUICallMediaType mediaType =
        isVideoCall ? TUICallMediaType.video : TUICallMediaType.audio;

    // Make the call using Tencent UIKit
    TUICallKit.instance.call(widget.targetUserId, mediaType);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Audio call button
        IconButton(
          icon: const Icon(Icons.phone),
          onPressed: () => _startCall(context, false),
          tooltip: 'Audio Call',
        ),
        // Video call button
        IconButton(
          icon: const Icon(Icons.videocam),
          onPressed: () => _startCall(context, true),
          tooltip: 'Video Call',
        ),
      ],
    );
  }
}
