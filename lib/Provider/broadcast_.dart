import 'package:flutter/material.dart';
import '../models/admin_model.dart';
import '../models/message.dart';
import '../services/socket_service.dart';
import '../constants/app_constants.dart';

class BroadcastProvider extends ChangeNotifier {
  final SocketService _socketService = SocketService();
  List<AdminUser> _adminUsers = [];
  List<Message> _broadcastHistory = [];
  bool _isLoading = false;
  String? _currentUserId;
  Map<String, int> _unreadCounts = {};
  final Map<String, List<Message>> _adminBroadcastMessages =
      {}; // Store messages by admin ID

  List<AdminUser> get adminUsers => _adminUsers;
  List<Message> get broadcastHistory => _broadcastHistory;
  bool get isLoading => _isLoading;
  bool get isAdmin =>
      _currentUserId != null && AppConstants.isAdmin(_currentUserId!);
  Map<String, int> get unreadCounts => _unreadCounts;
  Map<String, List<Message>> get adminBroadcastMessages =>
      _adminBroadcastMessages;

  BroadcastProvider() {
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _socketService.onAdminUsersList = (admins) {
      _adminUsers = admins.map((admin) {
        // Get unread count for this admin
        int unreadCount = _unreadCounts[admin['userId']] ?? 0;

        return AdminUser(
          userId: admin['userId'],
          name: admin['name'],
          avatar: admin['avatar'],
          unreadCount: unreadCount,
        );
      }).toList();

      _isLoading = false;
      notifyListeners();

      // After receiving admin list, load broadcast messages for each admin
      for (var admin in _adminUsers) {
        loadBroadcastHistory(admin.userId);
      }
    };

    _socketService.onBroadcastHistory = (messages) {
      if (messages.isNotEmpty) {
        // Get the adminId from the first message in the list
        String adminId = messages.first.senderId;

        // Store broadcast messages by admin ID
        _adminBroadcastMessages[adminId] = messages;

        // If this is for the current user, also update broadcastHistory
        if (_currentUserId != null && adminId == _currentUserId) {
          _broadcastHistory = messages;
        }
      }

      _isLoading = false;
      notifyListeners();
    };

    _socketService.onNewMessage = (message) {
      // Handle incoming broadcast messages
      if (message.isBroadcast) {
        String adminId = message.senderId;

        // Add to the appropriate admin's message list
        if (_adminBroadcastMessages.containsKey(adminId)) {
          _adminBroadcastMessages[adminId]!.add(message);
          _adminBroadcastMessages[adminId]!
              .sort((a, b) => a.timestamp.compareTo(b.timestamp));
        } else {
          _adminBroadcastMessages[adminId] = [message];
        }

        // If this is from the current user, also update broadcastHistory
        if (_currentUserId != null && adminId == _currentUserId) {
          _broadcastHistory.add(message);
          _broadcastHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        }

        // Update unread counts
        if (_currentUserId != null && adminId != _currentUserId) {
          _unreadCounts[adminId] = (_unreadCounts[adminId] ?? 0) + 1;

          // Update admin user with new unread count
          for (int i = 0; i < _adminUsers.length; i++) {
            if (_adminUsers[i].userId == adminId) {
              _adminUsers[i] = AdminUser(
                userId: _adminUsers[i].userId,
                name: _adminUsers[i].name,
                avatar: _adminUsers[i].avatar,
                isOnline: _adminUsers[i].isOnline,
                lastSeen: _adminUsers[i].lastSeen,
                unreadCount: _unreadCounts[adminId] ?? 0,
              );
              break;
            }
          }
        }

        notifyListeners();
      }
    };

    _socketService.onBroadcastSent = (data) {
      // Add message to history if needed
      notifyListeners();
    };

    _socketService.onUnreadCounts = (counts) {
      _unreadCounts = counts;

      // Update admin users with new unread counts
      for (var i = 0; i < _adminUsers.length; i++) {
        final admin = _adminUsers[i];
        _adminUsers[i] = AdminUser(
          userId: admin.userId,
          name: admin.name,
          avatar: admin.avatar,
          isOnline: admin.isOnline,
          lastSeen: admin.lastSeen,
          unreadCount: _unreadCounts[admin.userId] ?? 0,
        );
      }

      notifyListeners();
    };

    _socketService.onUnreadCountUpdate = (data) {
      final String fromUserId = data['fromUserId'];
      final int count = data['count'];

      _unreadCounts[fromUserId] = count;

      // Update specific admin's unread count
      for (var i = 0; i < _adminUsers.length; i++) {
        if (_adminUsers[i].userId == fromUserId) {
          _adminUsers[i] = AdminUser(
            userId: _adminUsers[i].userId,
            name: _adminUsers[i].name,
            avatar: _adminUsers[i].avatar,
            isOnline: _adminUsers[i].isOnline,
            lastSeen: _adminUsers[i].lastSeen,
            unreadCount: count,
          );
          break;
        }
      }

      notifyListeners();
    };
  }

  void initialize(String userId) {
    _currentUserId = userId;
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    // Get admin users
    _socketService.getAdminUsers();

    // If current user is admin, get their broadcast history
    if (isAdmin) {
      _socketService.getBroadcastHistoryForAdmin(_currentUserId!);
    }

    // Get unread counts for all chats (including admin broadcasts)
    if (_currentUserId != null) {
      _socketService.getUnreadCounts(_currentUserId!);
    }
  }

  Future<void> sendBroadcast(String message,
      {String? fileUrl, String? fileName, String messageType = 'text'}) async {
    if (!isAdmin || _currentUserId == null) {
      throw Exception('Only admin users can send broadcasts');
    }

    final newMessage = Message(
      messageId:
          'broadcast_${DateTime.now().millisecondsSinceEpoch}_$_currentUserId',
      senderId: _currentUserId!,
      receiverId: 'broadcast', // special receiver ID for broadcasts
      message: message,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      messageType: messageType,
      fileUrl: fileUrl,
      fileName: fileName,
      isBroadcast: true,
    );

    _socketService.broadcastMessage(newMessage);

    // Optimistically add message to local state
    _broadcastHistory.add(newMessage);
    if (!_adminBroadcastMessages.containsKey(_currentUserId)) {
      _adminBroadcastMessages[_currentUserId!] = [];
    }
    _adminBroadcastMessages[_currentUserId!]?.add(newMessage);

    notifyListeners();
  }

  Future<void> loadBroadcastHistory(String adminId) async {
    _socketService.getBroadcastHistoryForAdmin(adminId);
  }

  List<Message> getBroadcastMessagesForAdmin(String adminId) {
    return _adminBroadcastMessages[adminId] ?? [];
  }

  void markAdminMessagesAsRead(String adminId) {
    if (_currentUserId != null) {
      _socketService.markMessagesAsRead(_currentUserId!, adminId);

      // Update local unread count
      _unreadCounts[adminId] = 0;

      // Update admin user unread count
      for (var i = 0; i < _adminUsers.length; i++) {
        if (_adminUsers[i].userId == adminId) {
          _adminUsers[i] = AdminUser(
            userId: _adminUsers[i].userId,
            name: _adminUsers[i].name,
            avatar: _adminUsers[i].avatar,
            isOnline: _adminUsers[i].isOnline,
            lastSeen: _adminUsers[i].lastSeen,
            unreadCount: 0,
          );
          break;
        }
      }

      notifyListeners();
    }
  }
}
