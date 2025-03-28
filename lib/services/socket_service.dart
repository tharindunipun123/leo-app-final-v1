import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/app_constants.dart';
import '../models/message.dart';
import '../models/status_model.dart';

typedef MessageDeletedCallback = void Function(
    String messageId, bool forEveryone);
typedef MessageDeletedByOtherCallback = void Function(
    String messageId, String senderId);
typedef BroadcastUnreadCountsCallback = void Function(Map<String, int> counts);
typedef BroadcastMarkedAsReadCallback = void Function(String adminId);

typedef MessageCallback = void Function(Message message);
typedef MessagesCallback = void Function(List<Message> messages);
typedef DeliveredCallback = void Function(String messageId);
typedef ReadCallback = void Function(String messageId);
typedef TypingCallback = void Function(String userId);
typedef UserStatusCallback = void Function(Map<String, dynamic> statusMap);

// Call callback typedefs
typedef CallRequestCallback = void Function(Map<String, dynamic> callData);
typedef CallResponseCallback = void Function(Map<String, dynamic> callData);
typedef CallEndedCallback = void Function(Map<String, dynamic> callData);

// Status callbacks
typedef StatusPostedCallback = void Function(Map<String, dynamic> statusData);
typedef ActiveStatusesCallback = void Function(List<StatusUser> users);
typedef UserStatusesCallback = void Function(
    String userId, List<Status> statuses);

typedef BroadcastSentCallback = void Function(
    Map<String, dynamic> broadcastData);

typedef VoidCallback = void Function();
typedef ErrorCallback = void Function(dynamic error);
typedef ErrorDataCallback = void Function(Map<String, dynamic> errorData);
typedef ChattedUsersCallback = void Function(
    List<String> users); // New callback type
typedef AdminUsersCallback = void Function(List<Map<String, dynamic>> admins);

class SocketService {
  static SocketService? _instance;
  late IO.Socket _socket;
  String? _currentUserId;
  VoidCallback? onConnect;
  ErrorCallback? onConnectError;
  ErrorDataCallback? onError;
  // Existing callbacks
  MessageCallback? onNewMessage;
  MessagesCallback? onChatHistory;
  DeliveredCallback? onMessageDelivered;
  ReadCallback? onMessageRead;
  TypingCallback? onUserTyping;
  TypingCallback? onUserStoppedTyping;
  UserStatusCallback? onUserStatus;
  ChattedUsersCallback? onChattedUsers;
  // Add these properties
  StatusPostedCallback? onStatusPosted;
  ActiveStatusesCallback? onActiveStatuses;
  UserStatusesCallback? onUserStatuses;

  BroadcastSentCallback? onBroadcastSent;
  MessagesCallback? onBroadcastHistory;

  // Call callbacks
  CallRequestCallback? onIncomingCall; // renamed for clarity
  CallResponseCallback? onCallAccepted;
  CallResponseCallback? onCallRejected;
  CallEndedCallback? onCallEnded;
  CallResponseCallback? onCallRequested; // feedback to caller

  MessageDeletedCallback? onMessageDeleted;
  MessageDeletedByOtherCallback? onMessageDeletedByOther;

  BroadcastUnreadCountsCallback? onBroadcastUnreadCounts;
  BroadcastMarkedAsReadCallback? onBroadcastMarkedAsRead;

  Function(String blockedUserId)? onUserBlocked;
  Function(String unblockedUserId)? onUserUnblocked;
  Function(List<String> blockedUsers)? onBlockedUsersList;
  Function(bool isUserBlocked, bool isOtherUserBlocked)? onBlockedStatus;
  Function(String blockedByUserId)? onBlockedByUser;
  Function(String receiverId, String reason)? onMessageBlocked;

  // Keep track of processed message IDs to prevent duplicates
  final Set<String> _processedMessageIds = {};
  Function(Map<String, dynamic>)? onUnreadCountUpdate;
  Function(Map<String, int>)? onUnreadCounts;
  AdminUsersCallback? onAdminUsersList;
  bool isAdmin(String userId) {
    return AppConstants.adminUsers.contains(userId);
  }

  // Singleton pattern
  factory SocketService() {
    _instance ??= SocketService._internal();
    return _instance!;
  }

  SocketService._internal() {
    _initSocket();
    _setupBlockListeners();
    _setupBroadcastListeners();
  }

  void _setupBroadcastListeners() {
    _socket.on('broadcastSent', (data) {
      print('✅ Broadcast sent confirmation: $data');
      if (onBroadcastSent != null) {
        onBroadcastSent!(Map<String, dynamic>.from(data));
      }
    });
    _socket.on('broadcastUnreadCounts', (data) {
      print('📢 Received broadcast unread counts: ${data['counts']}');
      if (onBroadcastUnreadCounts != null && data['counts'] != null) {
        onBroadcastUnreadCounts!(Map<String, int>.from(data['counts']));
      }
    });

    _socket.on('broadcastMarkedAsRead', (data) {
      print('✓ Broadcasts from ${data['adminId']} marked as read');
      if (onBroadcastMarkedAsRead != null && data['adminId'] != null) {
        onBroadcastMarkedAsRead!(data['adminId']);
      }
    });

    // For broadcast history
    _socket.on('broadcastHistory', (data) {
      print('📜 Received broadcast history');
      if (onBroadcastHistory != null && data['messages'] != null) {
        final List<dynamic> messagesJson = data['messages'];
        final List<Message> messages = [];
        for (var msg in messagesJson) {
          final message = Message.fromJson(msg);
          messages.add(message);
        }
        // Sort by timestamp
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        onBroadcastHistory!(messages);
      }
    });

    // Admin users list
    _socket.on('adminUsersList', (data) {
      print('👤 Received admin users list');
      if (onAdminUsersList != null && data['admins'] != null) {
        final List<dynamic> adminsJson = data['admins'];
        final List<Map<String, dynamic>> admins = adminsJson
            .map((admin) => Map<String, dynamic>.from(admin))
            .toList();
        onAdminUsersList!(admins);
      }
    });
  }

  void _setupBlockListeners() {
    _socket.on('userBlocked', (data) {
      if (onUserBlocked != null) {
        onUserBlocked!(data['blockedUserId']);
      }
    });

    _socket.on('userUnblocked', (data) {
      if (onUserUnblocked != null) {
        onUserUnblocked!(data['unblockedUserId']);
      }
    });

    _socket.on('blockedUsersList', (data) {
      if (onBlockedUsersList != null) {
        List<String> blockedUsers = List<String>.from(data['blockedUsers']);
        onBlockedUsersList!(blockedUsers);
      }
    });

    _socket.on('blockedStatus', (data) {
      if (onBlockedStatus != null) {
        onBlockedStatus!(
          data['isUserBlocked'],
          data['isOtherUserBlocked'],
        );
      }
    });

    _socket.on('blockedByUser', (data) {
      if (onBlockedByUser != null) {
        onBlockedByUser!(data['blockedByUserId']);
      }
    });

    _socket.on('messageBlocked', (data) {
      if (onMessageBlocked != null) {
        onMessageBlocked!(data['receiverId'], data['reason']);
      }
    });
  }

  void _initSocket() {
    _socket = IO.io(AppConstants.serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.onConnect((_) {
      print('🟢 Connected to server with ID: ${_socket.id}');
      if (_currentUserId != null) {
        _socket.emit('register', _currentUserId);
        print('🔄 Registered user ID: $_currentUserId');
      }
      if (onConnect != null) {
        onConnect!();
      }
    });

    _socket.onConnectError((error) {
      print('⚠️ Connect error: $error');
      if (onConnectError != null) {
        onConnectError!(error);
      }
    });
    _socket.onDisconnect((_) => print('🔴 Disconnected from server'));
    _socket.onError((err) {
      print('❌ Socket error: $err');
      if (onError != null) {
        onError!({"message": err.toString()});
      }
    });

    // Add this to monitor all events
    _socket.onAny((event, data) {
      print('📌 EVENT: $event - DATA: $data');
    });

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _socket.on('messageDeleted', (data) {
      print(
          '✅ Message deleted: ${data['messageId']}, for everyone: ${data['forEveryone']}');
      if (onMessageDeleted != null) {
        onMessageDeleted!(
          data['messageId'],
          data['forEveryone'] ?? false,
        );
      }
    });

    _socket.on('messageDeletedByOther', (data) {
      print(
          '🗑️ Message ${data['messageId']} was deleted by ${data['senderId']}');
      if (onMessageDeletedByOther != null) {
        onMessageDeletedByOther!(
          data['messageId'],
          data['senderId'],
        );
      }
    });

    _socket.on('unreadCountUpdate', (data) {
      print('📬 Received unread count update: $data');
      if (onUnreadCountUpdate != null) {
        onUnreadCountUpdate!(Map<String, dynamic>.from(data));
      }
    });

    _socket.on('unreadCounts', (data) {
      print('📊 Received all unread counts: ${data['counts']}');
      if (onUnreadCounts != null && data['counts'] != null) {
        onUnreadCounts!(Map<String, int>.from(data['counts']));
      }
    });

    // Implement message listener with deduplication
    _socket.on('newMessage', (data) {
      print(
          "Received message: ${data['messageType']} from ${data['senderId']}");

      if (data['isBroadcast'] == true) {
        print("🔴 This is a broadcast message!");
      }

      final message = Message.fromJson(data);

      if (!_processedMessageIds.contains(message.messageId)) {
        _processedMessageIds.add(message.messageId);

        if (onNewMessage != null) {
          onNewMessage!(message);
        }
      } else {
        print("🔄 Skipping duplicate message: ${message.messageId}");
      }
    });

    // Fixed chatHistory handler
    _socket.on('chatHistory', (data) {
      print(
          "📦 CHAT HISTORY RECEIVED: userId=${data['userId']}, otherUserId=${data['otherUserId']}");

      if (data['messages'] == null) {
        print("⚠️ No messages found in chat history data");
        if (onChatHistory != null) {
          onChatHistory!([]); // Send empty list
        }
        return;
      }

      final List<dynamic> messagesJson = data['messages'];
      print("📊 Received ${messagesJson.length} messages in chat history");

      try {
        // Create a separate set for this chat history to avoid conflicts
        final Set<String> chatHistoryMessageIds = {};

        // Convert to Message objects
        final List<Message> messages = [];
        for (var msg in messagesJson) {
          try {
            final message = Message.fromJson(msg);

            // Only add if not already in this batch (avoid duplicates within same history)
            if (!chatHistoryMessageIds.contains(message.messageId)) {
              chatHistoryMessageIds.add(message.messageId);
              messages.add(message);
              print(
                  "✓ Added message: ${message.messageId} - ${message.message.substring(0, message.message.length > 20 ? 20 : message.message.length)}...");
            } else {
              print(
                  "⚠️ Skipping duplicate message in history: ${message.messageId}");
            }
          } catch (e) {
            print("⚠️ Error parsing message: $e");
          }
        }

        // Sort by timestamp (ascending for chat display)
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        if (onChatHistory != null) {
          print("🔄 Calling onChatHistory with ${messages.length} messages");
          onChatHistory!(messages);
        } else {
          print("⚠️ onChatHistory callback is null - no listener set up!");
        }
      } catch (e) {
        print("❌ Error processing chat history: $e");
        // Still send an empty list if error occurs
        if (onChatHistory != null) {
          onChatHistory!([]);
        }
      }
    });

    // Add this to your _setupSocketListeners() method in SocketService class
    _socket.on('chatContacts', (data) {
      print(
          '📋 Received chat contacts: ${data['contacts']?.length ?? 0} contacts');

      if (onChattedUsers != null && data['contacts'] != null) {
        final List<dynamic> contactsJson = data['contacts'];

        // Extract just the user IDs from the contacts
        final List<String> userIds = contactsJson
            .map((contact) => contact['userId'].toString())
            .toList();

        onChattedUsers!(userIds);
      }
    });

    _socket.on('broadcastSent', (data) {
      print('✅ Broadcast sent confirmation: $data');
      if (onBroadcastSent != null) {
        onBroadcastSent!(Map<String, dynamic>.from(data));
      }
    });

    // For broadcast history
    _socket.on('broadcastHistory', (data) {
      print('📜 Received broadcast history');
      if (onBroadcastHistory != null && data['messages'] != null) {
        final List<dynamic> messagesJson = data['messages'];
        _processedMessageIds.clear();
        final List<Message> messages = [];
        for (var msg in messagesJson) {
          final message = Message.fromJson(msg);
          _processedMessageIds.add(message.messageId);
          messages.add(message);
        }
        // Sort by timestamp
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        onBroadcastHistory!(messages);
      }
    });

    // Make sure your 'error' listener handles admin message errors
    _socket.on('error', (data) {
      print('Socket error: $data');
      if (data['errorType'] == 'ADMIN_MESSAGE_BLOCKED') {
        // Handle admin message blocking (show special UI message)
        print('Cannot send messages to admin broadcast accounts');
      }
    });

    _socket.on('messageDelivered', (data) {
      if (onMessageDelivered != null && data['messageId'] != null) {
        onMessageDelivered!(data['messageId']);
      }
    });

    _socket.on('messageRead', (data) {
      if (onMessageRead != null && data['messageId'] != null) {
        onMessageRead!(data['messageId']);
      }
    });

    _socket.on('userTyping', (data) {
      if (onUserTyping != null && data['userId'] != null) {
        onUserTyping!(data['userId']);
      }
    });

    _socket.on('userStoppedTyping', (data) {
      if (onUserStoppedTyping != null && data['userId'] != null) {
        onUserStoppedTyping!(data['userId']);
      }
    });

    _socket.on('userStatus', (data) {
      print('👤 Received user status update: $data');

      if (data is Map<String, dynamic>) {
        try {
          // Convert the status data to a properly typed map
          Map<String, dynamic> statusMap = {};

          // Process each user status entry
          data.forEach((userId, statusInfo) {
            if (statusInfo is Map) {
              // Extract and normalize the online status
              bool isOnline = false;
              if (statusInfo.containsKey('online')) {
                isOnline = statusInfo['online'] == true;
              }

              // Store in our map with standard format
              statusMap[userId] = {
                'online': isOnline,
                'lastSeen': statusInfo['lastSeen'] ??
                    DateTime.now().millisecondsSinceEpoch,
              };

              print(
                  '📊 User $userId is ${isOnline ? 'online' : 'offline'}, last seen: ${statusMap[userId]['lastSeen']}');
            }
          });

          if (onUserStatus != null) {
            onUserStatus!(statusMap);
          }
        } catch (e) {
          print('❌ Error processing user status: $e');
        }
      } else {
        print('⚠️ Received malformed user status data: $data');
      }
    });

    // Call listeners - listen to the correct event names
    _socket.on('incoming_call', (data) {
      print("INCOMING CALL RECEIVED: ${data.toString()}");
      if (onIncomingCall != null) {
        onIncomingCall!(Map<String, dynamic>.from(data));
      }
    });

    _socket.on('call_requested', (data) {
      if (onCallRequested != null) {
        onCallRequested!(Map<String, dynamic>.from(data));
      }
    });

    _socket.on('call_accepted', (data) {
      if (onCallAccepted != null) {
        onCallAccepted!(Map<String, dynamic>.from(data));
      }
    });

    _socket.on('call_rejected', (data) {
      if (onCallRejected != null) {
        onCallRejected!(Map<String, dynamic>.from(data));
      }
    });

    _socket.on('call_ended', (data) {
      if (onCallEnded != null) {
        onCallEnded!(Map<String, dynamic>.from(data));
      }
    });
    // Add this listener
    _socket.on('user_online_status', (data) {
      print("TARGET USER ONLINE STATUS: ${data['isOnline']}");
    });

    _socket.on('debug_call_flow_echo', (data) {
      print("CALL FLOW DEBUG ECHO: ${data['step']} - ${data['details']}");
    });

    // Status listeners
    _socket.on('statusPosted', (data) {
      if (onStatusPosted != null) {
        onStatusPosted!(Map<String, dynamic>.from(data));
      }
    });

    _socket.on('activeStatuses', (data) {
      print("Received active statuses: $data");
      if (onActiveStatuses != null) {
        final List<dynamic> usersJson = data['users'];
        print("Users with status: ${usersJson.length}");
        final users =
            usersJson.map((user) => StatusUser.fromJson(user)).toList();
        onActiveStatuses!(users);
      }
    });

    _socket.on('userStatuses', (data) {
      if (onUserStatuses != null) {
        final String userId = data['userId'];
        final List<dynamic> statusesJson = data['statuses'];
        final statuses =
            statusesJson.map((status) => Status.fromJson(status)).toList();
        onUserStatuses!(userId, statuses);
      }
    });
  }

  void blockUser(String userId, String blockedUserId) {
    _socket.emit('blockUser', {
      'userId': userId,
      'blockedUserId': blockedUserId,
    });
  }

  void unblockUser(String userId, String unblockedUserId) {
    _socket.emit('unblockUser', {
      'userId': userId,
      'unblockedUserId': unblockedUserId,
    });
  }

  void getBlockedUsers(String userId) {
    _socket.emit('getBlockedUsers', {
      'userId': userId,
    });
  }

  void checkBlockedStatus(String userId, String otherUserId) {
    _socket.emit('checkBlocked', {
      'userId': userId,
      'otherUserId': otherUserId,
    });
  }

  void getChattedUsers(String userId) {
    print('🔍 Requesting chatted users for: $userId');

    // Check connection status
    if (!_socket.connected) {
      print("⚠️ Socket not connected. Attempting to reconnect...");
      connect(_currentUserId ?? userId);

      // Retry after a delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (_socket.connected) {
          print("✅ Reconnected, now requesting chatted users");
          _socket.emit('getChatContacts', {'userId': userId});
        } else {
          print("❌ Failed to reconnect for chatted users request");
        }
      });
      return;
    }

    _socket.emit('getChatContacts', {'userId': userId});
  }

  void postStatus({
    required String userId,
    required String statusType,
    required String content,
    String? fileUrl,
    String? fileName,
    int? duration,
  }) {
    // Ensure duration has a default value of 24 hours (in milliseconds)
    final actualDuration = duration ?? 86400000; // 24 hours in milliseconds

    print('Posting status with duration: $actualDuration ms');

    _socket.emit('postStatus', {
      'userId': userId,
      'statusType': statusType,
      'content': content,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'duration': actualDuration,
    });
  }

  void getActiveStatuses() {
    _socket.emit('getActiveStatuses');
  }

  void getUserStatuses(String userId) {
    _socket.emit('getUserStatuses', {
      'userId': userId,
    });
  }

  void replyToStatus({
    required String statusId,
    required String message,
    required String senderId,
    required String receiverId,
  }) {
    print(
        'Replying to status $statusId: From $senderId to $receiverId - "$message"');

    _socket.emit('replyToStatus', {
      'statusId': statusId,
      'message': message,
      'senderId': senderId,
      'receiverId': receiverId,
    });
  }

  // Existing methods
  void connect(String userId) {
    _currentUserId = userId;

    if (!_socket.connected) {
      _socket.connect();
    } else {
      _socket.emit('register', userId);
    }
  }

  void disconnect() {
    _socket.disconnect();
  }

  // Update this method to properly handle message sending and avoid echoes
  void sendMessage(Message message) {
    // Add to processed IDs to prevent echoing the same message back
    _processedMessageIds.add(message.messageId);

    print(
        "📤 Sending message: ${message.messageId} from ${message.senderId} to ${message.receiverId}");
    _socket.emit('sendMessage', message.toJson());
  }

  void getChatHistory(String userId, String otherUserId,
      {int limit = 100, int offset = 0}) {
    if (userId.isEmpty || otherUserId.isEmpty) {
      print(
          "⚠️ Invalid user IDs for chat history: userId=$userId, otherUserId=$otherUserId");
      return;
    }

    print(
        '🔍 Requesting chat history between $userId and $otherUserId (limit: $limit, offset: $offset)');

    // Check connection status
    if (!_socket.connected) {
      print("⚠️ Socket not connected. Attempting to reconnect...");
      connect(_currentUserId ?? userId);

      // Retry after a delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (_socket.connected) {
          print("✅ Reconnected, now requesting chat history");
          _emitChatHistoryRequest(userId, otherUserId, limit, offset);
        } else {
          print("❌ Failed to reconnect for chat history request");
        }
      });
      return;
    }

    _emitChatHistoryRequest(userId, otherUserId, limit, offset);
  }

  // Helper method to emit the chat history request with consistent parameters
  void _emitChatHistoryRequest(
      String userId, String otherUserId, int limit, int offset) {
    _socket.emit('getChatHistory', {
      'userId': userId,
      'otherUserId': otherUserId,
      'limit': limit,
      'offset': offset,
    });

    // For debugging, send a ping test
    _socket.emit('ping_test', {
      'action': 'Request chat history',
      'userId': userId,
      'otherUserId': otherUserId,
      'timestamp': DateTime.now().millisecondsSinceEpoch
    });
  }

  void markAsDelivered(String messageId, String senderId, String receiverId) {
    _socket.emit('messageDelivered', {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
    });
  }

  void markAsRead(String messageId, String senderId, String receiverId) {
    _socket.emit('messageRead', {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
    });
  }

  void sendTypingStatus(String senderId, String receiverId, bool isTyping) {
    final event = isTyping ? 'typing' : 'stopTyping';
    _socket.emit(event, {
      'senderId': senderId,
      'receiverId': receiverId,
    });
  }

  void getUserStatus({List<String>? userIds}) {
    if (userIds != null && userIds.isNotEmpty) {
      print('🔍 Requesting status for specific users: $userIds');
      _socket.emit('getUserStatus', {'userIds': userIds});
    } else {
      print('🔍 Requesting all user statuses');
      _socket.emit('getUserStatus');
    }
  }

  void keepAlive() {
    if (_currentUserId != null && _socket.connected) {
      print('💓 Sending keep-alive for user: $_currentUserId');
      _socket.emit('user_online', {'userId': _currentUserId});
    }
  }

  bool get isConnected => _socket.connected;

  // Call methods
  void userOnline() {
    if (_currentUserId != null && isConnected) {
      _socket.emit('user_online', _currentUserId);
    }
  }

  void requestCall(
      String callerId, String targetId, String roomId, bool isVideoCall) {
    print("📱 OUTGOING CALL: from $callerId to $targetId in room $roomId");

    if (!_socket.connected) {
      print("⚠️ Socket not connected when trying to place call!");
      connect(_currentUserId ?? callerId);

      // Try again after reconnection
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (_socket.connected) {
          _emitCallRequest(callerId, targetId, roomId, isVideoCall);
        } else {
          print("❌ Failed to reconnect socket for call request");
        }
      });
      return;
    }

    _emitCallRequest(callerId, targetId, roomId, isVideoCall);
  }

  // Request a call to another user - use the correct event name
  void _emitCallRequest(
      String callerId, String targetId, String roomId, bool isVideoCall) {
    _socket.emit('request_call', {
      'caller': callerId,
      'target': targetId,
      'roomId': roomId,
      'isVideoCall': isVideoCall,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void deleteMessageForMe(String userId, String messageId) {
    print('🗑️ Deleting message $messageId for user $userId');
    _socket.emit('deleteMessageForMe', {
      'userId': userId,
      'messageId': messageId,
    });
  }

  void deleteMessageForEveryone(String senderId, String messageId) {
    print('🗑️🌐 Deleting message $messageId for everyone by $senderId');
    _socket.emit('deleteMessageForEveryone', {
      'senderId': senderId,
      'messageId': messageId,
    });
  }

  void getUnreadCounts(String userId) {
    print('🔍 Requesting unread counts for: $userId');
    _socket.emit('getUnreadCounts', {
      'userId': userId,
    });
  }

  void markMessagesAsRead(String userId, String otherUserId) {
    print('✓ Marking messages from $otherUserId as read by $userId');
    _socket.emit('markMessagesAsRead', {
      'userId': userId,
      'otherUserId': otherUserId,
    });
  }

  void clearUnreadMessages(String userId, String senderId) {
    print('🧹 Clearing unread messages from $senderId for $userId');
    _socket.emit('clearUnreadMessages', {
      'userId': userId,
      'senderId': senderId,
    });
  }

  // Add this method to check server connectivity
  void checkServerConnection() {
    try {
      _socket.emit('ping_test', {
        'userId': _currentUserId,
        'timestamp': DateTime.now().millisecondsSinceEpoch
      });
      print('🏓 Ping test sent to server');
    } catch (e) {
      print('❌ Error sending ping test: $e');
    }
  }

  // In your SocketService.dart file
  // Fix acceptance/rejection event names
  void acceptCall(String callerId, String targetId, String roomId) {
    _socket.emit('accept_call', {
      // Changed from 'call-accepted' to 'accept_call'
      'caller': callerId,
      'target': targetId,
      'roomId': roomId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void rejectCall(String callerId, String targetId) {
    _socket.emit('reject_call', {
      // Changed from 'call-rejected' to 'reject_call'
      'caller': callerId,
      'target': targetId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void endCall(String callerId, String targetId, String roomId) {
    _socket.emit('end_call', {
      // Changed from 'call-ended' to 'end_call'
      'caller': callerId,
      'target': targetId,
      'roomId': roomId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Add to your SocketService class
  void checkUserOnline(String targetId) {
    _socket.emit('check_user_online', {'targetId': targetId});
  }

  void debugCallFlow(String step, Map<String, dynamic> details) {
    _socket.emit('debug_call_flow', {'step': step, 'details': details});
  }

  void getBroadcastUnreadCounts(String userId) {
    print('🔍 Requesting broadcast unread counts for: $userId');
    _socket.emit('getBroadcastUnreadCounts', {
      'userId': userId,
    });
  }

  void markBroadcastAsRead(String userId, String adminId) {
    print('✓ Marking broadcasts from $adminId as read by $userId');
    _socket.emit('markBroadcastAsRead', {
      'userId': userId,
      'adminId': adminId,
    });
  }

  // Handle call quality updates
  void updateCallStats(String roomId, Map<String, dynamic> stats) {
    _socket.emit('call_stats', {
      'roomId': roomId,
      'userId': _currentUserId,
      'stats': stats,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void broadcastMessage(Message message) {
    // Check if current user is an admin
    if (!isAdmin(message.senderId)) {
      print('❌ Error: Only admin users can broadcast messages');
      if (onError != null) {
        onError!({"message": "Only admin users can broadcast messages"});
      }
      return;
    }

    if (!_socket.connected) {
      print(
          '⚠️ Socket not connected when trying to broadcast! Attempting to reconnect...');
      connect(message.senderId);

      // Try again after reconnection
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (_socket.connected) {
          print('🔄 Socket reconnected, sending broadcast after delay');
          _emitBroadcast(message);
        } else {
          print('❌ Failed to reconnect socket for broadcast');
        }
      });
      return;
    }

    _emitBroadcast(message);
  }

// Helper method to emit broadcast with proper logging
  void _emitBroadcast(Message message) {
    try {
      // Create a properly formatted broadcast message
      final broadcastMessage = {
        ...message.toJson(),
        'isBroadcast': true, // Ensure this flag is set
        'messageId': message.messageId ??
            "broadcast_${DateTime.now().millisecondsSinceEpoch}",
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      print('📣 Emitting broadcastMessage event:');
      print('   - Sender: ${message.senderId}');
      print('   - Message: ${message.message}');
      print('   - Message Type: ${message.messageType}');
      print('   - Connected: ${_socket.connected}');
      print('   - Socket ID: ${_socket.id}');

      // Send the broadcast
      _socket.emit('broadcastMessage', broadcastMessage);
    } catch (e) {
      print('❌ Exception when broadcasting: $e');
    }
  }

  void getBroadcastHistoryForAdmin(String adminId) {
    if (!_socket.connected) {
      print(
          '⚠️ Socket not connected, attempting to reconnect for broadcast history...');
      connect(_currentUserId!);

      // Try again after reconnection
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (_socket.connected) {
          print(
              '✅ Socket reconnected, now fetching broadcast history for admin: $adminId');
          _socket.emit('getBroadcastHistory', {'adminId': adminId});
        } else {
          print('❌ Failed to reconnect socket for getting broadcast history');
        }
      });
      return;
    }

    print('🔍 Requesting broadcast history for admin: $adminId');
    _socket.emit('getBroadcastHistory', {'adminId': adminId});
  }

  void getAdminUsers() {
    if (!_socket.connected) {
      print(
          '⚠️ Socket not connected, attempting to reconnect for admin users list...');
      connect(_currentUserId!);

      // Try again after reconnection
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (_socket.connected) {
          print('✅ Socket reconnected, now fetching admin users');
          _socket.emit('getAdminUsers');
        } else {
          print('❌ Failed to reconnect socket for getting admin users');
        }
      });
      return;
    }

    print('🔍 Requesting admin users list');
    _socket.emit('getAdminUsers');
  }
}
