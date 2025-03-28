import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/socket_service.dart';
import '../models/message.dart';
import 'chat_screen_admin.dart';
import 'status_create_screen.dart';
import 'status_screen.dart';
import 'dart:async';

class AdminListScreen extends StatefulWidget {
  final String currentUserId;

  const AdminListScreen({super.key, required this.currentUserId});

  @override
  State<AdminListScreen> createState() => _AdminListScreenState();
}

class _AdminListScreenState extends State<AdminListScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final SocketService _socketService = SocketService();
  Map<String, dynamic> _userStatus = {};
  final List<String> _regularUsers = [];
  List<String> _adminUsers = [];
  final Map<String, Message> _latestBroadcasts =
      {}; // Store latest broadcast per admin
  final Map<String, Message> _latestMessages =
      {}; // Store latest messages per user
  bool _isCurrentUserAdmin = false;
  bool _isLoading = true;
  bool _isBroadCastLoading = true;
  final Map<String, int> _broadcastUnreadCounts =
      {}; // Track broadcast unread messages
  final Map<String, int> _unreadCounts = {}; // Track chat unread messages
  Timer? _refreshTimer;
  bool _isOnAdminListScreen = true;
  bool _dataInitialized = false; // Track if we have initial data

  // Add TabController
  late TabController _tabController;
  int _currentTabIndex = 0;

  void _startPeriodicRefresh() {
    // Cancel any existing timer first
    _stopPeriodicRefresh();

    // Start a new timer that refreshes every 3 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isOnAdminListScreen && mounted) {
        print('📊 Periodic refresh: Updating admin list');
        _fetchBroadcastMessages();
        _socketService.getBroadcastUnreadCounts(widget.currentUserId);
        _socketService.getUnreadCounts(widget.currentUserId);
        _socketService.getUserStatus();
      }
    });

    print('⏰ Started periodic refresh timer for admin list');
  }

  void _stopPeriodicRefresh() {
    if (_refreshTimer != null && _refreshTimer!.isActive) {
      _refreshTimer!.cancel();
      print('⏰ Stopped periodic refresh timer');
    }
    _refreshTimer = null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Check if current user is admin
    _isCurrentUserAdmin =
        AppConstants.adminUsers.contains(widget.currentUserId);

    // Initialize the TabController with a specific length and vsync
    _tabController = TabController(length: 2, vsync: this);

    // Add listener for tab changes
    _tabController.addListener(() {
      // Only update state when the tab actually changes
      if (_tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });

    // Properly separate regular users and admin users
    _adminUsers = AppConstants.adminUsers
        .where((user) => user != widget.currentUserId)
        .toList();

    // Connect to socket server
    _socketService.connect(widget.currentUserId);

    // Set up all socket listeners
    _setupSocketListeners();

    // Start data fetching
    _refreshData();
    _startPeriodicRefresh();

    // Set a timeout to clear loading state
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _isBroadCastLoading = false;
        });
      }
    });
  }

  void _setupSocketListeners() {
    // Set up user status listener
    _socketService.onUserStatus = (statusMap) {
      setState(() {
        _userStatus = statusMap;
      });
    };

    // Set up broadcast unread counts listener
    _socketService.onBroadcastUnreadCounts = (Map<String, int> counts) {
      print('📢 Received broadcast unread counts: $counts');
      setState(() {
        _broadcastUnreadCounts.clear();
        _broadcastUnreadCounts.addAll(counts);

        // Mark data as initialized once we get some counts
        _dataInitialized = true;
      });
    };

    // Set up broadcast marked as read listener
    _socketService.onBroadcastMarkedAsRead = (String adminId) {
      setState(() {
        _broadcastUnreadCounts.remove(adminId);
      });
    };

    // Set up regular unread counts listener
    _socketService.onUnreadCounts = (Map<String, int> counts) {
      print('📊 Received unread counts: $counts');
      setState(() {
        _unreadCounts.clear();
        _unreadCounts.addAll(counts);
      });
    };

    // Set up unread count updates listener
    _socketService.onUnreadCountUpdate = (Map<String, dynamic> data) {
      final fromUserId = data['fromUserId'];
      final count = data['count'] as int;

      print('📬 Unread count update from $fromUserId: $count');

      // Check if this is an admin (broadcast) or regular message
      if (_adminUsers.contains(fromUserId)) {
        setState(() {
          _broadcastUnreadCounts[fromUserId] = count;
        });
      } else {
        setState(() {
          _unreadCounts[fromUserId] = count;
        });
      }
    };

    // Set up new message listener
    _socketService.onNewMessage = (message) {
      setState(() {
        // Handle broadcast messages
        if (message.isBroadcast) {
          // Store the latest broadcast from each admin
          if (!_latestBroadcasts.containsKey(message.senderId) ||
              _latestBroadcasts[message.senderId]!.timestamp <
                  message.timestamp) {
            _latestBroadcasts[message.senderId] = message;
          }

          // Increment broadcast unread count if it's not from current user
          if (message.senderId != widget.currentUserId) {
            _broadcastUnreadCounts[message.senderId] =
                (_broadcastUnreadCounts[message.senderId] ?? 0) + 1;
            print(
                'Broadcast unread count for ${message.senderId}: ${_broadcastUnreadCounts[message.senderId]}');
          }

          // Clear loading states once we receive messages
          _isLoading = false;
          _isBroadCastLoading = false;
        }
        // Handle direct messages - only relevant for admin users
        else if (_isCurrentUserAdmin &&
            (message.receiverId == widget.currentUserId ||
                message.senderId == widget.currentUserId)) {
          String otherUserId = message.senderId == widget.currentUserId
              ? message.receiverId
              : message.senderId;

          // Store latest message
          if (!_latestMessages.containsKey(otherUserId) ||
              _latestMessages[otherUserId]!.timestamp < message.timestamp) {
            _latestMessages[otherUserId] = message;
          }

          // Only increment unread count if we are the receiver (not the sender)
          if (message.receiverId == widget.currentUserId &&
              message.senderId != widget.currentUserId) {
            _unreadCounts[message.senderId] =
                (_unreadCounts[message.senderId] ?? 0) + 1;
            print(
                'Unread count for ${message.senderId}: ${_unreadCounts[message.senderId]}');
          }
        }
      });
    };

    // Set up broadcast history listener
    _socketService.onBroadcastHistory = (messages) {
      if (messages.isNotEmpty) {
        final adminId = messages.first.senderId;

        // Find the latest message (should be the one with the highest timestamp)
        Message? latestMessage;
        for (final msg in messages) {
          if (latestMessage == null ||
              msg.timestamp > latestMessage.timestamp) {
            latestMessage = msg;
          }
        }

        if (latestMessage != null) {
          setState(() {
            _latestBroadcasts[adminId] = latestMessage!;
            _isLoading = false;
            _isBroadCastLoading = false;
            _dataInitialized = true;
          });

          print(
              'Updated latest broadcast for $adminId: ${latestMessage.message}');
        }
      }
    };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('App resumed - refreshing admin data');
      _refreshData();
      if (_isOnAdminListScreen) {
        _startPeriodicRefresh();
      }
    } else if (state == AppLifecycleState.paused) {
      // Stop timer when app goes to background
      _stopPeriodicRefresh();
    }
  }

  void _refreshData() {
    // Request user status
    _socketService.getUserStatus();

    // Request broadcast unread counts
    _socketService.getBroadcastUnreadCounts(widget.currentUserId);

    // Request regular unread counts
    _socketService.getUnreadCounts(widget.currentUserId);

    // Fetch broadcast messages
    _fetchBroadcastMessages();

    // Get regular chats only for admin users
    if (_isCurrentUserAdmin) {
      _fetchUserMessages();
    }

    // Make sure loading state is cleared after a reasonable time
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isBroadCastLoading = false;
        });
      }
    });
  }

  void _fetchUserMessages() {
    // Get chat history for each regular user
    for (final userId in _regularUsers) {
      _socketService.getChatHistory(widget.currentUserId, userId, limit: 1);
    }
  }

  void _fetchBroadcastMessages() {
    // For each admin, get their broadcast history
    for (final adminId in _adminUsers) {
      // Request broadcast history for this admin
      _socketService.getBroadcastHistoryForAdmin(adminId);

      // Keep existing broadcasts if we have them
      if (!_latestBroadcasts.containsKey(adminId) ||
          _latestBroadcasts[adminId]?.message == 'No announcements yet') {
        // Set a timeout to stop showing loading state after a while
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted &&
              _latestBroadcasts.containsKey(adminId) &&
              (_latestBroadcasts[adminId]?.message ==
                  'Loading broadcasts...')) {
            setState(() {
              // Create a placeholder message for admins with no broadcasts
              final noMessagePlaceholder = Message(
                messageId: 'no_message_$adminId',
                senderId: adminId,
                receiverId: 'broadcast',
                message: 'No announcements yet',
                timestamp: DateTime.now().millisecondsSinceEpoch,
                messageType: AppConstants.messageTypeText,
                isBroadcast: true,
              );

              _latestBroadcasts[adminId] = noMessagePlaceholder;
              _isBroadCastLoading = false;
            });
          }
        });

        // Create a placeholder message for better UX while loading
        final placeholderMessage = Message(
          messageId: 'placeholder_$adminId',
          senderId: adminId,
          receiverId: 'broadcast',
          message: 'Loading broadcasts...',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          messageType: AppConstants.messageTypeText,
          isBroadcast: true,
        );

        setState(() {
          _latestBroadcasts[adminId] = placeholderMessage;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPeriodicRefresh();
    // Dispose the TabController
    _tabController.removeListener(() {});
    _tabController.dispose();
    // Don't disconnect here as we will reuse the connection
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildChatsTab(),
      floatingActionButton: _currentTabIndex == 0 && _isCurrentUserAdmin
          ? FloatingActionButton(
              onPressed: () {
                _isOnAdminListScreen = false;
                _stopPeriodicRefresh();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AdminChatScreen(
                              adminId: widget.currentUserId,
                              currentUserId: widget.currentUserId,
                            ))).then((_) {
                  // When returning from the chat screen
                  _isOnAdminListScreen = true;

                  // Don't show loading indicator, just refresh in background
                  _refreshData();
                  _startPeriodicRefresh();
                });
              },
              child: const Icon(Icons.chat),
            )
          : null,
    );
  }

  Widget _buildChatsTab() {
    // Only show loading indicator on first load, when we have no data
    if ((_isLoading && _isBroadCastLoading) &&
        !_dataInitialized &&
        _latestBroadcasts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Empty state
    if (_regularUsers.isEmpty && _adminUsers.isEmpty) {
      return const Center(
        child: Text('No conversations available'),
      );
    }

    return ListView(
      children: [
        // Admin section for announcements
        if (_adminUsers.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  _isOnAdminListScreen ? 'ADMIN BROADCAST' : 'ANNOUNCEMENTS',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                // Show total broadcast unread count if any
                if (_broadcastUnreadCounts.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_broadcastUnreadCounts.values.fold(0, (sum, count) => sum + count)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          ..._adminUsers.map((adminId) => _buildAdminChatItem(adminId)),
          const Divider(height: 24),
        ],

        // Regular users section - only for admins
        if (_isCurrentUserAdmin && _regularUsers.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'USERS',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          ..._regularUsers.map((userId) => _buildUserChatItem(userId)),
        ],
      ],
    );
  }

  Widget _buildAdminChatItem(String adminId) {
    final hasLatestBroadcast = _latestBroadcasts.containsKey(adminId);
    final latestBroadcast =
        hasLatestBroadcast ? _latestBroadcasts[adminId]! : null;
    final isLoading = latestBroadcast?.message == 'Loading broadcasts...';

    // Use the dedicated broadcast unread count
    final unreadCount = _broadcastUnreadCounts[adminId] ?? 0;

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.campaign,
                color: unreadCount > 0
                    ? Colors.white
                    : Colors.white.withOpacity(0.7),
                size: 20),
          ),
          if (unreadCount > 0)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        'Admin ${adminId.substring(0, 5)}',
        style: TextStyle(
          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
          color: unreadCount > 0 ? Colors.black : Colors.black87,
        ),
      ),
      subtitle: isLoading
          ? Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Loading...'),
              ],
            )
          : Text(
              latestBroadcast?.message ?? 'No recent messages',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontStyle:
                    unreadCount > 0 ? FontStyle.normal : FontStyle.italic,
                fontWeight:
                    unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                color: unreadCount > 0 ? Colors.black : Colors.grey.shade700,
              ),
            ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show timestamp
          if (hasLatestBroadcast && !isLoading)
            Text(
              _formatTimestamp(latestBroadcast!.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: unreadCount > 0 ? Colors.green : Colors.grey.shade600,
                fontWeight:
                    unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          // Show unread count in a WhatsApp-style circle
          if (unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        // Clear unread count when entering the chat
        _socketService.markBroadcastAsRead(widget.currentUserId, adminId);
        setState(() {
          _broadcastUnreadCounts.remove(adminId);
        });

        // Navigate to admin chat screen with both adminId and currentUserId
        _isOnAdminListScreen = false;
        _stopPeriodicRefresh();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminChatScreen(
              adminId: adminId,
              currentUserId: widget.currentUserId,
            ),
          ),
        ).then((_) {
          // When returning from the chat screen
          _isOnAdminListScreen = true;

          // Don't show loading indicator, just refresh in background
          _refreshData();
          _startPeriodicRefresh();
        });
      },
    );
  }

  Widget _buildUserChatItem(String userId) {
    // Only admins should see this item
    if (!_isCurrentUserAdmin) return const SizedBox.shrink();

    final isOnline = _userStatus[userId]?['online'] ?? false;
    final unreadCount = _unreadCounts[userId] ?? 0;
    final hasLatestMessage = _latestMessages.containsKey(userId);
    final latestMessage = hasLatestMessage ? _latestMessages[userId]! : null;

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade300,
            child: Text(
              userId.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        userId,
        style: TextStyle(
          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: hasLatestMessage
          ? Text(
              latestMessage!.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight:
                    unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                color: unreadCount > 0 ? Colors.black : Colors.grey.shade700,
              ),
            )
          : Text(
              isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                color: isOnline ? Colors.green : Colors.grey,
              ),
            ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show timestamp
          if (hasLatestMessage)
            Text(
              _formatTimestamp(latestMessage!.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: unreadCount > 0 ? Colors.green : Colors.grey.shade600,
                fontWeight:
                    unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          // Show unread count in WhatsApp style
          if (unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        // Clear unread count when entering the chat
        _socketService.markMessagesAsRead(widget.currentUserId, userId);
        setState(() {
          _unreadCounts[userId] = 0;
        });

        // Navigate to admin chat screen with both adminId and currentUserId
        _isOnAdminListScreen = false;
        _stopPeriodicRefresh();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminChatScreen(
              adminId: userId,
              currentUserId: widget.currentUserId,
            ),
          ),
        ).then((_) {
          // When returning from the chat screen
          _isOnAdminListScreen = true;

          // Don't show loading indicator when returning
          _refreshData();
          _startPeriodicRefresh();
        });
      },
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
