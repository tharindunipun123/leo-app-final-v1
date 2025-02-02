// Flutter imports:
import 'dart:async';

import 'package:flutter/material.dart';

import './gift/gift.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_image_carousel_slider/image_carousel_slider.dart';
import 'package:flutter_image_carousel_slider/image_carousel_slider_left_right_show.dart';
// Package imports:
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_live_audio_room/zego_uikit_prebuilt_live_audio_room.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'memberlist.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'Ranking/roomRanking.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/services.dart';
import '../Account Section/edit profile/FriendsProfileView.dart';

// Project imports:
import 'constants.dart';
import 'media.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class OnlineUser {
  final String id;
  final String name;
  final String avatarUrl;
  final String motto;
  final String firstName;
  final String lastName;

  OnlineUser({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.motto,
    this.firstName = '',
    this.lastName = '',
  });
}


class LivePage extends StatefulWidget {
  final String roomID;
  final bool isHost;
  final LayoutMode layoutMode;
  final String username1;
  final String userId;

  const LivePage({
    Key? key,
    required this.roomID,
    this.layoutMode = LayoutMode.defaultLayout,
    this.isHost = false,
    required this.username1, required this.userId
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => LivePageState();
}

class LivePageState extends State<LivePage> with SingleTickerProviderStateMixin {

  final pb = PocketBase('http://145.223.21.62:8090');
  late UnsubscribeFunc? _unsubscribe;
  int userCount = 0; // Add this to track user count


  late IO.Socket socket;
  bool isConnecting = true;
  bool isReconnecting = false;
  Timer? reconnectionTimer;
  int reconnectAttempts = 0;
  static const maxReconnectAttempts = 5;

  bool isAdmin = false;
  List<OnlineUser> onlineUsers = [];
  bool isLoadingUsers = false;
  bool _isMinimized = false;
  bool _showCopySuccess = false;
  DateTime? _lastTapTime;
  DateTime? _lastBottomSheetTime;
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  String? _onlineUserRecordId;
  String? _groupPhotoUrl;
  String? _userAvatarUrl;
  String? _voiceRoomName;
  String? _backgroundImageUrl;
  String? _language;
  int?  _voiceroomid;
  static const String POCKETBASE_URL = 'http://145.223.21.62:8090'; // Replace with your actual PocketBase URL

  @override
  void initState() {
    super.initState();
    _initializeSocket();
    _fetchInitialUsers();
    //_createOnlineUserRecord().then((_) => _fetchInitialUsers());
    _checkAdminStatus();
    _fetchOnlineUsers();
    // ZegoGiftManager().cache.cacheAllFiles(giftItemList);
    // ZegoGiftManager().service.recvNotifier.addListener(onGiftReceived);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ZegoGiftManager().service.init(
        appID: 2069292420,
        liveID: widget.roomID,
        localUserID: localUserID,
        localUserName: widget.username1,
      );

      print("------------------------------------------");
      print(localUserID);
      // Fetch avatar URL when component mounts
      updateStartTime(widget.userId, widget.roomID);
      _fetchAndSetUserAvatar();
      _fetchVoiceRoomDetails();
      _fetchLanguageDetails(widget.roomID);
      _createOnlineUserRecord();
    });

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
      lowerBound: 0.5,
      upperBound: 1.2,
    )..repeat(reverse: true);
    //
     _glowAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(_controller);
    //
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   // Get crown gift data
    //   final crownGift = giftItemList.firstWhere(
    //           (gift) => gift.name == 'crown',  // Adjust name to match your gift
    //       orElse: () => giftItemList.first
    //   );
    //
    //   // Auto play the gift
    //   ZegoGiftManager().playList.add(PlayData(
    //       giftItem: crownGift,
    //       count: 1
    //   ));
    // });
  }

  Future<void> _checkAdminStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$POCKETBASE_URL/api/collections/voiceRooms/records/${widget.roomID}'),
      );

      if (response.statusCode == 200) {
        final roomData = json.decode(response.body);
        setState(() {
          isAdmin = roomData['ownerId'] == widget.userId;
        });
      }
    } catch (e) {
      print('Error checking admin status: $e');
    }
  }

  Future<void> _disbandGroup() async {
    try {
      // First, remove all joined users
      final joinedUsersResponse = await http.get(
        Uri.parse('$POCKETBASE_URL/api/collections/joined_users/records?filter=(voice_room_id="${widget.roomID}")'),
      );

      if (joinedUsersResponse.statusCode == 200) {
        final joinedUsers = json.decode(joinedUsersResponse.body)['items'] as List;

        // Delete all joined user records
        for (var user in joinedUsers) {
          await http.delete(
            Uri.parse('$POCKETBASE_URL/api/collections/joined_users/records/${user['id']}'),
          );
        }
      }

      // First, clean up all duplicate records
      await _deleteDuplicateOnlineUserRecords(widget.userId, widget.roomID);

      // Uninitialize ZEGO services
      ZegoGiftManager().service.uninit();
      await ZegoUIKit().leaveRoom();

      // Emit leave room event to socket
      socket.emit('leaveRoom', {
        'roomId': widget.roomID,
        'userId': widget.userId,
      });

      // Update end time for the session
      await updateEndTime(widget.userId, widget.roomID);

      // Disconnect socket
      socket.disconnect();

      // Then, delete the voice room
      final deleteResponse = await http.delete(
        Uri.parse('$POCKETBASE_URL/api/collections/voiceRooms/records/${widget.roomID}'),
      );

      _handleLogout();

        //
        // // Finally, navigate back
        //
        //   Navigator.of(context).pop(); // Close current screen
        //   Navigator.of(context).pop(); // Pop back to groups screen
        //
        //   // Show success message
        //   if (context.mounted) {
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       SnackBar(
        //         content: Text('Group disbanded successfully'),
        //         backgroundColor: Colors.green,
        //       ),
        //     );
        //   }


    } catch (e) {
      print('Error disbanding group: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to disband group')),
        );
      }
    }
  }

  void _initializeSocket() {
    socket = IO.io('http://145.223.21.62:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 5000,
      'reconnectionAttempts': maxReconnectAttempts,
    });

    socket.onConnect((_) async {
      print('Connected to Socket.IO server');
      reconnectAttempts = 0;
      isReconnecting = false;

      if (mounted) {
        setState(() {
          isConnecting = false;
        });
      }

      // Send full user details when joining
      await _fetchAndSetUserAvatar(); // Make sure we have avatar URL

      socket.emit('joinRoom', {
        'roomId': widget.roomID,
        'userId': widget.userId,
        'userName': widget.username1,
        'userAvatar': _userAvatarUrl,
        'userMotto': '' // Add any other user details you want to track
      });
    });

    socket.on('roomUpdate', (data) {
      if (!mounted) return;

      try {
        final List<dynamic> usersList = data['users'] as List;
        final users = usersList.map((userData) => OnlineUser(
          id: userData['id'] as String,
          name: userData['name'] as String,
          avatarUrl: userData['avatarUrl'] as String,
          motto: userData['motto'] as String? ?? '',
        )).toList();

        setState(() {
          onlineUsers = users;
          userCount = data['count'] as int;
          isLoadingUsers = false;
        });
      } catch (e) {
        print('Error processing room update: $e');
      }
    });

    // Handle individual user join/leave events
    socket.on('userJoined', (userData) {
      if (!mounted) return;

      try {
        final newUser = OnlineUser(
          id: userData['id'],
          name: userData['name'],
          avatarUrl: userData['avatarUrl'],
          motto: userData['motto'] ?? '',
        );

        setState(() {
          // Add user if not already in list
          if (!onlineUsers.any((user) => user.id == newUser.id)) {
            onlineUsers.add(newUser);
            userCount = onlineUsers.length;
          }
        });
      } catch (e) {
        print('Error processing user join: $e');
      }
    });

    socket.on('userLeft', (userData) {
      if (!mounted) return;

      setState(() {
        onlineUsers.removeWhere((user) => user.id == userData['id']);
        userCount = onlineUsers.length;
      });
    });

    socket.connect();
  }

  void _handleReconnection() {
    reconnectionTimer?.cancel();

    if (reconnectAttempts >= maxReconnectAttempts) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to reconnect. Please check your connection.'),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                reconnectAttempts = 0;
                socket.connect();
              },
            ),
          ),
        );
      }
      return;
    }

    reconnectionTimer = Timer(Duration(seconds: 2), () {
      reconnectAttempts++;
      if (!socket.connected) {
        socket.connect();
      }
    });
  }

  void _updateUserList(Map<String, dynamic> data) {
    if (data['users'] != null) {
      final List<dynamic> usersList = data['users'] as List;
      final users = usersList.map((userData) => OnlineUser(
        id: userData['id'] as String,
        name: userData['name'] as String,
        avatarUrl: userData['avatarUrl'] as String,
        motto: userData['motto'] as String? ?? '',
      )).toList();

      setState(() {
        onlineUsers = users;
        userCount = data['count'] as int;
      });
    }
  }


  Future<bool> checkAndRecordProfileView(String viewerUserId, String viewedUserId) async {
    const String baseUrl = 'http://145.223.21.62:8090';

    try {
      // 1. Early return if viewer and viewed are the same user
      if (viewerUserId == viewedUserId) {
        return false;
      }

      // 2. Check for existing view with proper URL encoding
      final queryFilter = '(viewer_user_id="${Uri.encodeComponent(viewerUserId)}" && viewed_users_id="${Uri.encodeComponent(viewedUserId)}")';
      final checkResponse = await http.get(
        Uri.parse('$baseUrl/api/collections/profileView/records').replace(
            queryParameters: {'filter': queryFilter}
        ),
      );

      if (checkResponse.statusCode != 200) {
        print('Error checking existing view: ${checkResponse.statusCode}');
        print('Response body: ${checkResponse.body}');
        return false;
      }

      final existingViews = json.decode(checkResponse.body)['items'] as List;
      if (existingViews.isNotEmpty) {
        return true; // View already exists
      }

      // 3. Create new profile view record with proper headers
      final createResponse = await http.post(
        Uri.parse('$baseUrl/api/collections/profileView/records'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'viewer_user_id': viewerUserId,
          'viewed_users_id': viewedUserId,
        }),
      );

      // 4. Detailed error logging
      print('Create profile view response status: ${createResponse.statusCode}');
      print('Create profile view response body: ${createResponse.body}');

      if (createResponse.statusCode != 200) {
        final errorBody = json.decode(createResponse.body);
        print('Error creating profile view: $errorBody');
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      print('Error in checkAndRecordProfileView: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }


  Future<void> _fetchInitialUsers() async {
    if (!mounted) return;

    setState(() {
      isLoadingUsers = true;
    });

    try {
      // First try to get users from socket server
      socket.emitWithAck('fetchUsers', {'roomId': widget.roomID}, ack: (data) {
        if (data != null && mounted) {
          _updateUserList(data);
        }
      });

      // Fallback to HTTP if socket isn't connected
      if (!socket.connected) {
        final response = await http.get(
          Uri.parse('http://145.223.21.62:3000/api/rooms/${widget.roomID}/users'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _updateUserList(data);
        }
      }
    } catch (e) {
      print('Error fetching initial users: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingUsers = false;
        });
      }
    }
  }



  Future<void> _handleNewOnlineUser(Map<String, dynamic> record) async {
    if (record['userId'] == widget.userId) return; // Skip current user

    try {
      final userResponse = await http.get(
        Uri.parse('$POCKETBASE_URL/api/collections/users/records/${record['userId']}'),
      );

      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        final newUser = OnlineUser(
          id: userData['id'],
          name: '${userData['firstname']} ${userData['lastname']}'.trim(),
          avatarUrl: '$POCKETBASE_URL/api/files/${userData['collectionId']}/${userData['id']}/${userData['avatar']}',
          motto: userData['moto'] ?? '',
          firstName: userData['firstname'] ?? '',
          lastName: userData['lastname'] ?? '',
        );

        if (mounted) {
          setState(() {
            onlineUsers = [...onlineUsers, newUser];
          });
        }
      }
    } catch (e) {
      print('Error handling new online user: $e');
    }
  }

  void _handleUserLeft(Map<String, dynamic> record) {
    if (mounted) {
      setState(() {
        onlineUsers.removeWhere((user) => user.id == record['userId']);
      });
    }
  }




  Future<void> _fetchOnlineUsers() async {
    if (mounted) {
      setState(() => isLoadingUsers = true);
    }

    try {
      final onlineUsersResponse = await http.get(
        Uri.parse('$POCKETBASE_URL/api/collections/online_users/records')
            .replace(queryParameters: {
          'filter': 'voiceRoomId="${widget.roomID}"',
        }),
      );

      if (onlineUsersResponse.statusCode != 200) throw Exception('Failed to fetch online users');

      final onlineUsersData = json.decode(onlineUsersResponse.body);
      List<OnlineUser> users = [];

      for (var onlineUser in onlineUsersData['items']) {
        if (onlineUser['userId'] == widget.userId) continue;

        try {
          final userDetailsResponse = await http.get(
            Uri.parse('$POCKETBASE_URL/api/collections/users/records/${onlineUser['userId']}'),
          );

          if (userDetailsResponse.statusCode == 200) {
            final userData = json.decode(userDetailsResponse.body);
            users.add(OnlineUser(
              id: userData['id'],
              name: '${userData['firstname']} ${userData['lastname']}'.trim(),
              avatarUrl: '$POCKETBASE_URL/api/files/${userData['collectionId']}/${userData['id']}/${userData['avatar']}',
              motto: userData['moto'] ?? '',
              firstName: userData['firstname'] ?? '',
              lastName: userData['lastname'] ?? '',
            ));
          }
        } catch (e) {
          print('Error fetching user details: $e');
        }
      }

      if (mounted) {
        setState(() {
          onlineUsers = users;
          userCount = users.length; // Update the count
          isLoadingUsers = false;
        });
      }
    } catch (e) {
      print('Error fetching online users: $e');
      if (mounted) {
        setState(() => isLoadingUsers = false);
      }
    }
  }



  Future<bool> _isUserJoined(String roomId, String userId) async {
    try {
      // Check both conditions in parallel using Future.wait
      final responses = await Future.wait([
        // Check joined_users
        http.get(Uri.parse('$POCKETBASE_URL/api/collections/joined_users/records')),
        // Check if user is owner
        http.get(Uri.parse('$POCKETBASE_URL/api/collections/voiceRooms/records/$roomId')),
      ]);

      final joinedResponse = responses[0];
      final roomResponse = responses[1];

      // Check if user is joined
      if (joinedResponse.statusCode == 200) {
        final joinedData = json.decode(joinedResponse.body);
        if (joinedData['items'] != null) {
          final records = joinedData['items'] as List;
          if (records.any((record) =>
          record['userid'] == userId &&
              record['voice_room_id'] == roomId
          )) {
            return true;
          }
        }
      }

      // Check if user is owner
      if (roomResponse.statusCode == 200) {
        final roomData = json.decode(roomResponse.body);
        if (roomData['ownerId'] == userId) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking join status: $e');
      return false;
    }
  }

  Future<void> updateStartTime(String userId, String voiceRoomId) async {
    final String baseUrl = 'http://145.223.21.62:8090/api/collections/level_Timer/records';

    try {
      // Step 1: Fetch existing records for the user and voice room
      final filter = Uri.encodeComponent('UserID="$userId" && voiceRoom_id="$voiceRoomId"');
      final response = await http.get(Uri.parse('$baseUrl?filter=$filter'));

      print('GET Response status: ${response.statusCode}');
      print('GET Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> records = data['items'] ?? [];

        // Step 2: Check existing record conditions
        if (records.isNotEmpty) {
          final record = records.first;

          if (record['Start_Time'] != null && record['End_Time'] == null) {
            // Delete the existing record
            final deleteResponse = await http.delete(Uri.parse('$baseUrl/${record['id']}'));
            print('DELETE Response status: ${deleteResponse.statusCode}');
            print('DELETE Response body: ${deleteResponse.body}');

            if (deleteResponse.statusCode != 204) {
              throw Exception('Failed to delete record');
            }
          }
        }

        // Step 3: Insert a new record with the current start time
        final newRecord = {
          'UserID': userId,
          'voiceRoom_id': voiceRoomId,
          'Start_Time': DateTime.now().toIso8601String(),
          'End_Time': null,
        };

        final postResponse = await http.post(
          Uri.parse(baseUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(newRecord),
        );

        print('POST Response status: ${postResponse.statusCode}');
        print('POST Response body: ${postResponse.body}');

        if (postResponse.statusCode != 200 && postResponse.statusCode != 201) {
          throw Exception('Failed to create new record');
        }
      } else {
        print('Failed to fetch records: ${response.statusCode}');
        throw Exception('Failed to fetch records');
      }
    } catch (e) {
      print('Error occurred: $e');
      rethrow;
    }
  }



  Future<void> _createOnlineUserRecord() async {
    try {
      final response = await http.post(
        Uri.parse('$POCKETBASE_URL/api/collections/online_users/records'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': widget.userId,
          'voiceRoomId': widget.roomID,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _onlineUserRecordId = data['id']; // Store the record ID for later deletion
        print('Created online user record: $_onlineUserRecordId');
      } else {
        print('Failed to create online user record: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating online user record: $e');
    }
  }



  Future<void> _fetchAndSetUserAvatar() async {
    try {
      final uri = Uri.parse('$POCKETBASE_URL/api/collections/users/records')
          .replace(queryParameters: {
        'filter': 'id="${widget.userId}"',
        'fields': 'id,avatar,collectionId',
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('------------------------');
        print(data);
        if (data['items'] != null && data['items'].isNotEmpty) {
          final userData = data['items'][0];
          if (userData['avatar'] != null) {
            setState(() {
              _userAvatarUrl = '$POCKETBASE_URL/api/files/${userData['collectionId']}/${userData['id']}/${userData['avatar']}';
              print('------------------------');
              print(_userAvatarUrl);
            });
          }
        }
      } else {
        print('Failed to fetch user avatar: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user avatar: $e');
    }
  }

  Future<void> _joinRoom(String roomId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('http://145.223.21.62:8090/api/collections/joined_users/records'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'voice_room_id': roomId,
          'userid': userId,
          'admin_or_not': false,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully joined the room')),
        );
      }
    } catch (e) {
      print('Error joining room: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join room')),
      );
    }
  }

  Future<void> _deleteDuplicateOnlineUserRecords(String userId, String roomId) async {
    const String baseUrl = 'http://145.223.21.62:8090/api/collections/online_users/records';

    try {
      // Step 1: Fetch all records for this user and room
      final filter = Uri.encodeComponent('userId="$userId" && voiceRoomId="$roomId"');
      final response = await http.get(
        Uri.parse('$baseUrl?filter=$filter'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final records = data['items'] as List;

        if (records.isEmpty) {
          print('No records found for user $userId in room $roomId');
          return;
        }

        print('Found ${records.length} records to delete');

        // Step 2: Delete all records found
        for (var record in records) {
          final recordId = record['id'];
          final deleteResponse = await http.delete(
            Uri.parse('$baseUrl/$recordId'),
            headers: {'Content-Type': 'application/json'},
          );

          if (deleteResponse.statusCode == 204 || deleteResponse.statusCode == 200) {
            print('Successfully deleted record: $recordId');
          } else {
            print('Failed to delete record $recordId: ${deleteResponse.statusCode}');
          }
        }
      } else {
        print('Failed to fetch records: ${response.statusCode}');
        throw Exception('Failed to fetch online user records');
      }
    } catch (e) {
      print('Error in _deleteDuplicateOnlineUserRecords: $e');
      rethrow;
    }
  }

// Modified _handleLogout function
  Future<void> _handleLogout() async {
    try {
      // First, clean up all duplicate records
      await _deleteDuplicateOnlineUserRecords(widget.userId, widget.roomID);

      // Uninitialize ZEGO services
      ZegoGiftManager().service.uninit();
      await ZegoUIKit().leaveRoom();

      // Emit leave room event to socket
      socket.emit('leaveRoom', {
        'roomId': widget.roomID,
        'userId': widget.userId,
      });

      // Update end time for the session
      await updateEndTime(widget.userId, widget.roomID);

      // Disconnect socket
      socket.disconnect();

      // Finally, navigate back
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during logout: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }



  Future<void> _fetchVoiceRoomDetails() async {
    try {
      final uri = Uri.parse('$POCKETBASE_URL/api/collections/voiceRooms/records/${widget.roomID}')
          .replace(queryParameters: {
        'fields': 'voice_room_name,background_images,group_photo,voiceRoom_id'
      });

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _voiceRoomName = data['voice_room_name'];
          _voiceroomid = data['voiceRoom_id'];
          if (data['background_images'] != null) {
            _backgroundImageUrl = '$POCKETBASE_URL/api/files/voiceRooms/${widget.roomID}/${data['background_images']}';
            _groupPhotoUrl = '$POCKETBASE_URL/api/files/voiceRooms/${widget.roomID}/${data['group_photo']}';

          }

          if (data['group_photo'] != null) {

          }
          print("-----------------------------------------------------------------");
          print(_groupPhotoUrl);
        });
      }
    } catch (e) {
      print('Error fetching voice room details: $e');
    }
  }
  Future<void> _shareToWhatsApp() async {
    final String shareText = 'Join our voice room!\nRoom Name: ${_voiceRoomName ?? "Voice Room"}\nRoom ID: ${_voiceroomid}\nCome join us for an amazing conversation!';
    final Uri whatsappUrl = Uri.parse("whatsapp://send?text=${Uri.encodeComponent(shareText)}");

    try {
      await launchUrl(whatsappUrl);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('WhatsApp is not installed')),
      );
    }
  }

  Future<void> _shareToFacebook() async {
    final String shareText = 'Join our voice room!\nRoom Name: ${_voiceRoomName ?? "Voice Room"}\nRoom ID: ${_voiceroomid}\nCome join us for an amazing conversation!';
    final Uri fbUrl = Uri.parse("https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(shareText)}");

    try {
      await launchUrl(fbUrl, mode: LaunchMode.externalApplication);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Facebook')),
      );
    }
  }

  void _copyRoomLink() {
    final String shareText = 'Join our voice room!\nRoom Name: ${_voiceRoomName ?? "Voice Room"}\nRoom ID: ${_voiceroomid}\nCome join us for an amazing conversation!';
    Clipboard.setData(ClipboardData(text: shareText)).then((_) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room link copied to clipboard')),
      );
    });
  }

  Future<void> _fetchLanguageDetails(String roomId) async {
    try {
      final uri = Uri.parse('$POCKETBASE_URL/api/collections/voiceRooms/records/$roomId')
          .replace(queryParameters: {
        'fields': 'language', // Specify the fields you want to fetch
      });

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // Assuming 'language' is the field you want to display
          _language = data['language'];
        });
      } else {
        print('Failed to fetch language details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching language details: $e');
    }
  }



  Future<void> updateEndTime(String userId, String voiceRoomId) async {
    final String baseUrl = 'http://145.223.21.62:8090/api/collections/level_Timer/records';

    try {
      // Step 1: Fetch existing records for the given userId and voiceRoomId
      final filter = Uri.encodeComponent('UserID="$userId" && voiceRoom_id="$voiceRoomId"');
      final response = await http.get(Uri.parse('$baseUrl?filter=$filter'));

      print('GET Response status: ${response.statusCode}');
      print('GET Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> records = data['items'] ?? [];

        // Step 2: Find the record with an empty End_Time
        final record = records.firstWhere(
              (r) => r['End_Time'] == null || r['End_Time'] == "",
          orElse: () => null,
        );

        if (record != null) {
          // Update the End_Time for the correct record
          final updatedRecord = {
            'End_Time': DateTime.now().toIso8601String(),
          };

          final patchResponse = await http.patch(
            Uri.parse('$baseUrl/${record['id']}'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(updatedRecord),
          );

          print('PATCH Response status: ${patchResponse.statusCode}');
          print('PATCH Response body: ${patchResponse.body}');

          if (patchResponse.statusCode != 200) {
            throw Exception('Failed to update the record');
          }
        } else {
          print('No active session found for the given userId and voiceRoomId');
          throw Exception('No active session found');
        }
      } else {
        throw Exception('Failed to fetch records: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
      rethrow;
    }
  }


  @override
  void dispose() {

    reconnectionTimer?.cancel();
    socket.emit('leaveRoom', {
      'roomId': widget.roomID,
      'userId': widget.userId,
    });
    socket.dispose();
    // Only cleanup if not minimized
    if (!_isMinimized) {
      ZegoGiftManager().service.recvNotifier.removeListener(onGiftReceived);
      ZegoGiftManager().service.uninit();
      _controller.dispose();

      if (_onlineUserRecordId != null) {
        http.delete(
          Uri.parse('$POCKETBASE_URL/api/collections/online_users/records/$_onlineUserRecordId'),
          headers: {'Content-Type': 'application/json'},
        ).catchError((e) => print('Error cleaning up online user record: $e'));

        socket.emit('leaveRoom', {
          'roomId': widget.roomID,
          'userId': widget.userId,
        });
      }

      updateEndTime(widget.userId, widget.roomID);

    }


    socket.disconnect();
    super.dispose();
  }

  bool isAttributeHost(Map<String, String>? userInRoomAttributes) {
    return (userInRoomAttributes?['role'] ?? "") == ZegoLiveAudioRoomRole.host.index.toString();
  }

  Widget backgroundBuilder(BuildContext context, Size size, ZegoUIKitUser? user, Map extraInfo) {
    if (!isAttributeHost(user?.inRoomAttributes.value)) {
      return Container();
    }

    return Positioned(
      top: -6,
      left: 0,
      child: Container(

        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images1/bac.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget foregroundBuilder(BuildContext context, Size size, ZegoUIKitUser? user, Map extraInfo) {
    var userName = user?.name.isEmpty ?? true
        ? Container()
        : Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Text(
        " ${user?.name}  " ?? "",
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          backgroundColor: Colors.blueAccent,

          fontSize: 9,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
        ),
      ),
    );

    if (!isAttributeHost(user?.inRoomAttributes.value)) {
      return userName;
    }

    // var hostIconSize = Size(size.width / 3, size.height / 3);
    // var hostIcon = Positioned(
    //   bottom: 3,
    //   right: 0,
    //   child: Container(
    //     width: hostIconSize.width,
    //     height: hostIconSize.height,
    //     decoration: const BoxDecoration(
    //       image: DecorationImage(
    //         image: AssetImage('assets/images1/king.png'),
    //         fit: BoxFit.cover,
    //       ),
    //     ),
    //   ),
    // );

    return Stack(children: [userName]);
  }

  // First, add a method to fetch joined users count
  Future<int> _fetchJoinedUsersCount(String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('http://145.223.21.62:8090/api/collections/joined_users/records?filter=(voice_room_id="$roomId")'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List items = data['items'];
        // Add 1 to include the owner
        return items.length + 1;
      }
      return 1; // Return 1 if only owner exists
    } catch (e) {
      print('Error fetching joined users: $e');
      return 1;
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.black.withOpacity(0.95),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Room Settings',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              Divider(color: Colors.white24, height: 32),

              // Room Photo Setting
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.photo_camera, color: Colors.blue[300]),
                ),
                title: Text(
                  'Change Room Photo',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                subtitle: Text(
                  'Update room profile picture',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () => Navigator.pop(context),
              ),

              Divider(color: Colors.white12, indent: 56),

              // Room Name Setting
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.edit, color: Colors.green[300]),
                ),
                title: Text(
                  'Edit Room Name',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                subtitle: Text(
                  'Change room display name',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () => Navigator.pop(context),
              ),

              Divider(color: Colors.white12, indent: 56),

              // Background Setting
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.wallpaper, color: Colors.purple[300]),
                ),
                title: Text(
                  'Change Background',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                subtitle: Text(
                  'Customize room background',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () => Navigator.pop(context),
              ),

              SizedBox(height: 20),

              // Danger Zone
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Danger Zone',
                      style: TextStyle(
                        color: Colors.red[300],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _showDisbandConfirmation();
                      },
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, color: Colors.red[400]),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Disband Group',
                                  style: TextStyle(
                                    color: Colors.red[400],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Permanently delete this room',
                                  style: TextStyle(
                                    color: Colors.red[200],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

// Add this method to show disband confirmation
  void _showDisbandConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        backgroundColor: Colors.black.withOpacity(0.9),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Disband Group',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Are you sure you want to disband this group? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context); // Close dialog
                      await _disbandGroup(); // This will handle the navigation and refresh
                    },
                    child: Text(
                      'Disband',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiButton(String emoji) {
    return Container(
      margin: EdgeInsets.all(4), // Reduced from 8
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12), // Reduced from 16
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            print('Selected emoji: $emoji');
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(8), // Reduced from 12
            child: Center(
              child: Text(
                emoji,
                style: TextStyle(
                  fontSize: 24, // Reduced from 30
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (ZegoUIKitPrebuiltLiveAudioRoomController().minimize.isMinimizing) {
          setState(() {
            _isMinimized = true;
          });
          ZegoUIKitPrebuiltLiveAudioRoomController()
              .minimize
              .minimize(navigatorKey.currentState!.context);
          return true;
        }

        bool? shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            backgroundColor: Colors.black.withOpacity(0.9),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Padding(
                    padding: EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(
                      'Leave Room',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Message
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      'Would you like to leave the room?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.3,
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Divider
                  Divider(
                    height: 1,
                    color: Colors.white.withOpacity(0.2),
                  ),

                  // Action Buttons
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        // Cancel Button
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(15),
                                ),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                        ),

                        // Vertical Divider
                        VerticalDivider(
                          width: 1,
                          color: Colors.white.withOpacity(0.2),
                        ),

                        // Minimize Button
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              // setState(() {
                              //   _isMinimized = true;
                              // });
                              // ZegoUIKitPrebuiltLiveAudioRoomController()
                              //     .minimize
                              //     .minimize(navigatorKey.currentState!.context);
                              // Navigator.pop(context, false);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Minimize',
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        // Vertical Divider
                        VerticalDivider(
                          width: 1,
                          color: Colors.white.withOpacity(0.2),
                        ),

                        // Leave Button
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              await _handleLogout();
                              Navigator.pop(context, true);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  bottomRight: Radius.circular(15),
                                ),
                              ),
                            ),
                            child: Text(
                              'Leave',
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        return shouldPop ?? false;
      },
      child: SafeArea(
        child: Stack(
          children: [
            // Main Zego UIKit widget
            ZegoUIKitPrebuiltLiveAudioRoom(
              appID: 2069292420,
              appSign: '3b8893143a13c24f6d82dd7260b70a9d29814b99130e7bcebfe3e09dac8c0731',
              userID: localUserID,
              userName: widget.username1,
              roomID: widget.roomID,
              events: events,
              config: config,
            ),

            // Power/Logout button
            Positioned(
              top: MediaQuery.of(context).padding.top + 2,
              right: 10,
              child: GestureDetector(
                onTap: () => _showLogoutDialog(context),
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.power_settings_new,
                      color: Colors.white.withOpacity(0.9),
                      size: 19,
                    ),
                  ),
                ),
              ),
            ),

            // if (isConnecting)
            //   Positioned(
            //     top: MediaQuery.of(context).padding.top + 10,
            //     right: 10,
            //     child: Container(
            //       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            //       decoration: BoxDecoration(
            //         color: Colors.black54,
            //         borderRadius: BorderRadius.circular(20),
            //       ),
            //       child: Row(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           SizedBox(
            //             width: 12,
            //             height: 12,
            //             child: CircularProgressIndicator(
            //               strokeWidth: 2,
            //               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            //             ),
            //           ),
            //           SizedBox(width: 8),
            //           Text(
            //             'Connecting...',
            //             style: TextStyle(
            //               color: Colors.white,
            //               fontSize: 12,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),

            // Add a user count display
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              right: 10,
              child: GestureDetector(
                onTap: () {
                  _showOnlineUsersBottomSheet(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Reduced padding
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(15), // Reduced border radius
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Make row as small as possible
                    children: [
                      if (isLoadingUsers)
                        SizedBox(
                          width: 14, // Smaller loading indicator
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5, // Thinner stroke
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else ...[
                        ...onlineUsers.take(2).map((user) => Padding(
                          padding: const EdgeInsets.only(right: 3), // Reduced padding
                          child: CircleAvatar(
                            radius: 10, // Smaller avatar radius
                            backgroundImage: NetworkImage(user.avatarUrl),
                            onBackgroundImageError: (e, s) => AssetImage('assets/default_avatar.png'),
                          ),
                        )),
                        if (onlineUsers.length > 2)
                          Container(
                            width: 14, // Smaller counter container
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '+${onlineUsers.length - 2}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8, // Smaller font size
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Emoji bottom sheet
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.02, // 2% from bottom
              left: MediaQuery.of(context).size.width * 0.35, // 35% from left
              child: Container(
                width: 35, // Reduced from 30
                height: 35, // Reduced from 30
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero, // Remove default padding
                  constraints: BoxConstraints(), // Remove default constraints
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (BuildContext context) {
                        return Container(
                          height: MediaQuery.of(context).size.height * 0.4, // Reduced from 0.5
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.9),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Handle bar
                              Container(
                                width: 40, // Reduced from 40
                                height: 4, // Reduced from 4
                                margin: EdgeInsets.only(top: 8), // Reduced from 12
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(1.5),
                                ),
                              ),

                              // Close button
                              Align(
                                alignment: Alignment.topRight,
                                child: IconButton(
                                  icon: Icon(Icons.close, color: Colors.white70, size: 20),
                                  padding: EdgeInsets.all(12),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),

                              // Emoji grid
                              Expanded(
                                child: GridView.count(
                                  crossAxisCount: 5,
                                  mainAxisSpacing: 8, // Added spacing
                                  crossAxisSpacing: 8, // Added spacing
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  childAspectRatio: 1.1, // Adjust aspect ratio for better fit
                                  children: [
                                    // Happy faces
                                    _buildEmojiButton('😊'),
                                    _buildEmojiButton('😄'),
                                    _buildEmojiButton('😃'),
                                    _buildEmojiButton('😁'),
                                    _buildEmojiButton('😅'),

                                    // Love faces
                                    _buildEmojiButton('😍'),
                                    _buildEmojiButton('🥰'),
                                    _buildEmojiButton('😘'),
                                    _buildEmojiButton('😗'),
                                    _buildEmojiButton('🤗'),

                                    // Fun faces
                                    _buildEmojiButton('😜'),
                                    _buildEmojiButton('😝'),
                                    _buildEmojiButton('😋'),
                                    _buildEmojiButton('😂'),
                                    _buildEmojiButton('🤣'),

                                    // Cool faces
                                    _buildEmojiButton('😎'),
                                    _buildEmojiButton('🤩'),
                                    _buildEmojiButton('🥳'),
                                    _buildEmojiButton('😏'),
                                    _buildEmojiButton('😌'),

                                    // Reaction faces
                                    _buildEmojiButton('😮'),
                                    _buildEmojiButton('🤔'),
                                    _buildEmojiButton('😳'),
                                    _buildEmojiButton('🥺'),
                                    _buildEmojiButton('😇'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  icon: Icon(
                    Icons.emoji_emotions,
                    color: Colors.white,
                    size: 20, // Reduced from 24
                  ),
                ),
              ),
            ),

            if (isAdmin)
              Positioned(
                top: MediaQuery.of(context).padding.top + 2,
                right: MediaQuery.of(context).size.width * 0.132, // Responsive positioning
                child: GestureDetector(
                  onTap: _showSettingsDialog,
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.settings,
                        color: Colors.white.withOpacity(0.9),
                        size: 19,
                      ),
                    ),
                  ),
                ),
              ),

            // Share button
            Positioned(
              top: MediaQuery.of(context).padding.top + 2,
              right: isAdmin ? 100 : 55, // Adjust based on admin status
              child: GestureDetector(
                onTap: () => _showShareOptions(context),
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.share,
                      color: Colors.white.withOpacity(0.9),
                      size: 19,
                    ),
                  ),
                ),
              ),
            ),

            // Settings button (for admin)


            // Room Info Overlay
            Positioned(
              top: MediaQuery.of(context).padding.top - 15, // Moved higher up
              left: 10,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.5,
                      minHeight: 60,
                      maxHeight: 60,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.withOpacity(0.2),
                          Colors.grey.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Room Image
                        GestureDetector(
                          onTap: () {
                            final now = DateTime.now();
                            if (_lastTapTime != null &&
                                now.difference(_lastTapTime!) < const Duration(milliseconds: 500)) {
                              return;
                            }
                            _lastTapTime = now;
                            _showBottomSheet(context, widget.roomID);
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _groupPhotoUrl != null
                                  ? Image.network(
                                _groupPhotoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 24,
                                    color: Colors.white70,
                                  ),
                                ),
                              )
                                  : Center(
                                child: Icon(
                                  Icons.image,
                                  size: 24,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Room Info Column
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Room Name
                              Text(
                                _voiceRoomName ?? "Voice Room",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 4),

                              // Room ID
                              Row(
                                children: [
                                  Text(
                                    "ID: ",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      "${_voiceroomid}",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),


            // Ranking Overlay
            Positioned(
              top: MediaQuery.of(context).padding.top + 65,
              left: 0,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => RankingBottomSheet(roomId: widget.roomID),
                  );
                },
                child: Container(
                  height: 26,
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.22,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.8),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(13),
                      bottomRight: Radius.circular(13),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(1, 1),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          "Rank",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Icon(
                          Icons.emoji_events,
                          color: Colors.amber[100],
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOnlineUsersBottomSheet(BuildContext context) {
    // Remove duplicates by user ID, excluding current user
    final uniqueUsers = <String, OnlineUser>{};
    for (var user in onlineUsers) {
      if (user.id != widget.userId && !uniqueUsers.containsKey(user.id)) {
        uniqueUsers[user.id] = user;
      }
    }
    final deduplicatedUsers = uniqueUsers.values.toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header with user count
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Online Users (${deduplicatedUsers.length + 1})',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isConnecting) ...[
                        SizedBox(width: 8),
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // User list
            Expanded(
              child: isLoadingUsers
                  ? _buildLoadingIndicator()
                  : RefreshIndicator(
                onRefresh: _fetchOnlineUsers,
                color: Colors.white,
                backgroundColor: Colors.blue,
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  physics: AlwaysScrollableScrollPhysics(),
                  children: [
                    // Current user (always first)
                    if (_userAvatarUrl != null) ...[
                      _buildUserListItem(
                        OnlineUser(
                          id: widget.userId,
                          name: widget.username1,
                          avatarUrl: _userAvatarUrl!,
                          motto: '',
                        ),
                        isCurrentUser: true,
                        index: 1,
                      ),
                      Divider(
                        color: Colors.white.withOpacity(0.1),
                        height: 1,
                      ),
                    ],

                    // Other users
                    ...deduplicatedUsers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final user = entry.value;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildUserListItem(
                            user,
                            isCurrentUser: false,
                            index: index + 2,
                          ),
                          if (index < deduplicatedUsers.length - 1)
                            Divider(
                              color: Colors.white.withOpacity(0.1),
                              height: 1,
                            ),
                        ],
                      );
                    }).toList(),

                    // Empty state
                    if (deduplicatedUsers.isEmpty)
                      _buildEmptyState(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            'Loading users...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              color: Colors.grey,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'No other users online',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserListItem(OnlineUser user, {required bool isCurrentUser, required int index}) {
    return GestureDetector(
      onTap: () => _handleUserTap(user, isCurrentUser),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Index/Star column
            Container(
              width: 30,
              child: isCurrentUser
                  ? Icon(Icons.star, color: Colors.amber, size: 20)
                  : Text(
                '$index',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            // Avatar
            GestureDetector(
              onTap: () => _handleUserTap(user, isCurrentUser),
              child: CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(user.avatarUrl),
                onBackgroundImageError: (e, s) => AssetImage('assets/default_avatar.png'),
              ),
            ),
            SizedBox(width: 12),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'You',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (user.motto.isNotEmpty)
                    Text(
                      user.motto,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            // Chevron icon for non-current users
            if (!isCurrentUser)
              GestureDetector(
                onTap: () => _handleUserTap(user, isCurrentUser),
                child: Icon(Icons.chevron_right, color: Colors.white54, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUserTap(OnlineUser user, bool isCurrentUser) async {
    if (!isCurrentUser) {
      try {
        final canView = await checkAndRecordProfileView(widget.userId, user.id);

        if (canView && mounted) {
          Navigator.pop(context); // Close bottom sheet

          showDialog(
            context: context,
            barrierDismissible: true,
            barrierColor: Colors.black.withOpacity(0.85),
            builder: (BuildContext context) {
              return ProfileScreenView(
                viewedUserId: user.id,
                viewerUserId: widget.userId,
              );
            },
          );
        }
      } catch (e) {
        print('Error showing profile: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unable to load profile')),
          );
        }
      }
    }
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Share via',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareButton(
                    imageUrl: 'https://logodownload.org/wp-content/uploads/2015/04/whatsapp-logo-1.png',
                    label: 'WhatsApp',
                    onTap: () => _shareToWhatsApp(),
                    color: Color(0xFF25D366),
                  ),
                  _buildShareButton(
                    imageUrl: 'https://brandpalettes.com/wp-content/uploads/2018/05/Facebook-Logo-JPG.jpg',
                    label: 'Facebook',
                    onTap: () => _shareToFacebook(),
                    color: Color(0xFF1877F2),
                  ),
                  _buildShareButton(
                    icon: Icons.copy,
                    label: 'Copy Link',
                    onTap: () => _copyRoomLink(),
                    color: Colors.grey[700]!,
                    isIconButton: true,
                  ),
                ],
              ),
              SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareButton({
    String? imageUrl,
    IconData? icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    bool isIconButton = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: isIconButton
                  ? Icon(icon, color: Colors.white, size: 30)
                  : ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.network(
                  imageUrl!,
                  width: 45,
                  height: 45,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 30,
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  // screen eka kalu wela logout wena kalla
  void _showFullBlackLogoutContainer() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8), // Semi-transparent black
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            Navigator.of(context).pop();
            return false;
          },
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logout Button
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _handleLogout();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.lightBlue,
                              Colors.lightBlue
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            )
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.power_settings_new,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Leave',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 30), // Space between buttons

                // Keep Button
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.lightBlue,
                              Colors.lightBlue,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            )
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'keep',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// Modify the _showLogoutDialog method to use the new full black container
  void _showLogoutDialog(BuildContext context) {
    _showFullBlackLogoutContainer(); // Replace the existing alert dialog
  }

  // void _showLogoutDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Leave Room'),
  //       content: const Text('Are you sure you want to leave this room?'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('Cancel'),
  //         ),
  //         TextButton(
  //           onPressed: () async {
  //             Navigator.pop(context); // Close dialog
  //             await _handleLogout();
  //           },
  //           child: const Text(
  //             'Leave',
  //             style: TextStyle(color: Colors.red),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }



  Future<void> _showBottomSheet(BuildContext context, String roomId) async {
    // Prevent multiple bottom sheets
    final now = DateTime.now();
    if (_lastBottomSheetTime != null &&
        now.difference(_lastBottomSheetTime!) < const Duration(milliseconds: 50)) {
      return;
    }
    _lastBottomSheetTime = now;

    if (!mounted) return;

    try {
      // Fetch the current userId from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('userId') ?? ''; // Default to an empty string if not found

      bool isUserJoined = await _isUserJoined(roomId, currentUserId);
      print("----------------------joining____________________");
      print(isUserJoined);

      if (currentUserId.isEmpty) {
        print('Error: User ID not found in SharedPreferences');
        return;
      }

      // Fetch room data
      final roomResponse = await http.get(
        Uri.parse('http://145.223.21.62:8090/api/collections/voiceRooms/records/$roomId'),
      );

      if (roomResponse.statusCode != 200) return;

      final roomData = json.decode(roomResponse.body);
      final joinedUsersCount = await _fetchJoinedUsersCount(roomId);

      // Determine if the current user is joined or the room owner
      //bool isUserJoined = false;
      bool isRoomOwner = false;

      // Check if the user has joined the room
      final joinedCheckResponse = await http.get(
        Uri.parse(
            'http://145.223.21.62:8090/api/collections/joined_users/records?filter=(voice_room_id="$roomId" && userid="$currentUserId")'),
      );
      if (joinedCheckResponse.statusCode == 200) {
        final joinedData = json.decode(joinedCheckResponse.body);
        isUserJoined = (joinedData['items'] as List).isNotEmpty;
      }

      // Check if the user is the room owner
      isRoomOwner = roomData['ownerId'] == currentUserId;

      if (!mounted) return;

      // Show the bottom sheet
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        enableDrag: true,
        builder: (context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  // Header with close and settings buttons
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Center(
                          child: Text(
                            "Room Information",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Spacer(),
                        if (isRoomOwner)
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                      ],
                    ),
                  ),

                  // Tab Bar
                  TabBar(
                    tabs: [Tab(text: 'Profile'), Tab(text: 'Member')],
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue,
                  ),

                  // Tab View Content
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Profile Tab
                        // Inside your _showBottomSheet method, modify the Profile Tab content:
                        SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 24),
                              // Room Profile Image
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey[200]!, width: 2),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: CachedNetworkImage(
                                    imageUrl:
                                    'http://145.223.21.62:8090/api/files/voiceRooms/${roomData['id']}/${roomData['group_photo']}',
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => CircularProgressIndicator(),
                                    errorWidget: (context, url, error) => Icon(Icons.error),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Room Name
                              Text(
                                roomData['voice_room_name'] ?? 'Welcome Everyone',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              // Room ID with copy icon
                              StatefulBuilder(
                                builder: (BuildContext context, StateSetter setModalState) {
                                  return Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Room ID: ',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 16,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              Clipboard.setData(ClipboardData(text: roomData['voiceRoom_id'].toString()));
                                              setModalState(() {
                                                _showCopySuccess = true;
                                              });
                                              Future.delayed(Duration(seconds: 2), () {
                                                if (mounted) {
                                                  setModalState(() {
                                                    _showCopySuccess = false;
                                                  });
                                                }
                                              });
                                            },
                                            child: Row(
                                              children: [
                                                Text(
                                                  '${roomData['voiceRoom_id']}',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.copy,
                                                  size: 16,
                                                  color: Colors.blue,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_showCopySuccess)
                                        Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Copied to clipboard',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              // Room Details Container
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    _buildDetailRow('Country:', roomData['voiceRoom_country'] ?? ''),
                                    _buildLevelRow(),
                                    _buildDetailRow('Members:', '$joinedUsersCount/500'),
                                    _buildRoomModeTags(roomData),
                                    _buildLanguageRow(),
                                    // Add Join Button here
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isUserJoined ? Colors.grey[400] : Colors.lightBlue,
                                          minimumSize: Size(double.infinity, 50),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          elevation: isUserJoined ? 0 : 2,
                                        ),
                                        onPressed: isUserJoined ? null : () => _joinRoom(roomId, currentUserId),
                                        child: Text(
                                          isUserJoined ? 'Already Joined' : 'Join Room',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Member Tab
                        Stack(
                          children: [
                            MemberListScreen(
                              voiceRoomId: roomId,
                              currentUserId: currentUserId,
                              isJoined: isUserJoined,
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
        },
      );
    } catch (e) {
      print('Error in _showBottomSheet: $e');
    }
  }



  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLanguageRow() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'Language:',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Spacer(),
          Text(
            _language ?? 'Not specified', // Display the language or a default message
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelRow() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'Level:',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Spacer(),
          Row(
            children: [
              Text(
                'LV.4',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 100,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[400]!, Colors.blue[300]!],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LV.5',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomModeTags(Map<String, dynamic> roomData) {
    final tags = (roomData['tags'] ?? '')
        .toString()
        .split(',')
        .where((tag) => tag.trim().isNotEmpty)
        .join(', '); // Join all tags with comma and space

    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'Room mode:',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Spacer(),
          Text(
            tags.isEmpty ? 'Not specified' : tags,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }




// Helper method to build member list item
  Widget _buildMemberListItem(Map<String, dynamic> user) {
    return Container(
      height: 70,
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: CachedNetworkImage(
            imageUrl: "http://145.223.21.62:8090/api/files/${user['collectionId']}/${user['id']}/${user['avatar']}",
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue[300],
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.grey[400]),
            ),
          ),
        ),
        title: Text(
          user['firstname'] ?? "Unknown",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          user['bio'] ?? "No bio available",
          style: TextStyle(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }



// Header Section
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Text(
            "Room Information",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }


// Updated helper method for room tags
  Widget _buildRoomTags(String tags) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: tags.split(',').map((tag) {
        final trimmedTag = tag.trim();
        if (trimmedTag.isEmpty) return const SizedBox();
        return Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(
              trimmedTag,
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }


// Helper Widgets


  Widget _buildLevelProgress() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'LV.4',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 100,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
          child: Stack(
            children: [
              Container(
                width: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[400]!, Colors.blue[300]!],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'LV.5',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }




  Future<List<Map<String, dynamic>>> _fetchRoomUserDetails(String roomId) async {
    final String url =
        "http://145.223.21.62:8090/api/collections/users/records"; // Replace with the actual API endpoint
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
      });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['items']);
      } else {
        print("Failed to fetch data: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error fetching user details: $e");
      return [];
    }
  }

  ZegoUIKitPrebuiltLiveAudioRoomConfig get config {
    return (widget.isHost
        ? ZegoUIKitPrebuiltLiveAudioRoomConfig.host()
        : ZegoUIKitPrebuiltLiveAudioRoomConfig.audience())
      ..seat = (getSeatConfig()
        ..takeIndexWhenJoining = widget.isHost ? getHostSeatIndex() : -1
        ..hostIndexes = getLockSeatIndex()
        ..layout = getLayoutConfig())
      ..background = background()
      ..mediaPlayer.supportTransparent = true
      ..foreground = giftForeground()
      ..emptyAreaBuilder = mediaPlayer
      // ..topMenuBar.buttons = [
      //   ZegoLiveAudioRoomMenuBarButtonName.minimizingButton, // Keep only this button
      // ]
      ..userAvatarUrl = _userAvatarUrl;
  }

  ZegoUIKitPrebuiltLiveAudioRoomEvents get events {
    return ZegoUIKitPrebuiltLiveAudioRoomEvents(
      user: ZegoLiveAudioRoomUserEvents(
        onCountOrPropertyChanged: (List<ZegoUIKitUser> users) {
          debugPrint(
            'onUserCountOrPropertyChanged:${users.map((e) => e.toString())}',
          );
        },
      ),
      seat: ZegoLiveAudioRoomSeatEvents(
        onClosed: () {
          debugPrint('on seat closed');
        },
        onOpened: () {
          debugPrint('on seat opened');
        },
        onChanged: (
            Map<int, ZegoUIKitUser> takenSeats,
            List<int> untakenSeats,
            ) {
          debugPrint(
            'on seats changed, taken seats:$takenSeats, untaken seats:$untakenSeats',
          );
        },

        /// WARNING: will override prebuilt logic
        // onClicked:(int index, ZegoUIKitUser? user) {
        //   debugPrint(
        //       'on seat clicked, index:$index, user:${user.toString()}');
        // },
        host: ZegoLiveAudioRoomSeatHostEvents(
          onTakingRequested: (ZegoUIKitUser audience) {
            debugPrint('on seat taking requested, audience:$audience');
          },
          onTakingRequestCanceled: (ZegoUIKitUser audience) {
            debugPrint('on seat taking request canceled, audience:$audience');
          },
          onTakingInvitationFailed: () {
            debugPrint('on invite audience to take seat failed');
          },
          onTakingInvitationRejected: (ZegoUIKitUser audience) {
            debugPrint('on seat taking invite rejected');
          },
        ),
        audience: ZegoLiveAudioRoomSeatAudienceEvents(
          onTakingRequestFailed: () {
            debugPrint('on seat taking request failed');
          },
          onTakingRequestRejected: () {
            debugPrint('on seat taking request rejected');
          },
          onTakingInvitationReceived: () {
            debugPrint('on host seat taking invite sent');
          },
        ),
      ),

      /// WARNING: will override prebuilt logic
      memberList: ZegoLiveAudioRoomMemberListEvents(
        onMoreButtonPressed: onMemberListMoreButtonPressed,
      ),
    );
  }

  Widget mediaPlayer(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container();

        return simpleMediaPlayer(
          canControl: widget.isHost,
        );

        return advanceMediaPlayer(
          constraints: constraints,
          canControl: widget.isHost,
        );
      },
    );
  }

  Widget background() {
    List<String> imageList = [
      "https://th.bing.com/th/id/OIP.XBvFTQ9AFT56EbqP60aKVwHaFj?rs=1&pid=ImgDetMain",
      "https://ids13.com/wp-content/uploads/2021/04/gem-saviour-conquest.jpg",
      "https://play-lh.googleusercontent.com/uMCSwJnIKCemiAIc7xNTGBkOxlSu_e6xzZb29cqqV6bKU8Qz0m4ZQ5pmGhBNxE-vBrA",
    ];
    /// how to replace background view
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.fill,
              image:_backgroundImageUrl != null
                  ? NetworkImage(_backgroundImageUrl!)
                  : AssetImage('assets/images1/back.jpg') as ImageProvider,
            ),
          ),
        ),
        // Positioned(
        //   top: 35,
        //   left: 30,
        //   right: 30,
        //   // Add right and left to create space
        //   bottom: 30,
        //   // Add bottom if you want to create a border for the center
        //   child: Align(
        //     alignment: Alignment.topCenter, // This will center the text
        //     child: Text(
        //       '$_voiceRoomName',
        //       overflow: TextOverflow.ellipsis,
        //       style: TextStyle(
        //         color: Colors.blueAccent,
        //         fontSize: 20,
        //         fontWeight: FontWeight.bold,
        //       ),
        //     ),
        //   ),
        // ),
        Positioned(
          bottom: 165, // Adjusted position
          right: 16, // Adjusted position
          child: Container(
            width: 70, // Vertical rectangle width
            height: 190, // Vertical rectangle height
            child: ImageCarouselSlider(
              items: imageList,
              imageHeight: 180, // Matches the container height
              dotColor: Colors.black, // Dot color for indicators
            ),
          ),
        ),
        Positioned(
          bottom: 70,
          right: 16,
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return InkWell(
                onTap: () {
                  showGiftListSheet(context , widget.roomID);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, // Makes the glow round around the image
                    boxShadow: [
                      BoxShadow(
                        color: Colors.yellowAccent.withOpacity(0.7), // Glow color (you can change it)
                        spreadRadius: 6 * _glowAnimation.value, // Animated spread size of the glow
                        blurRadius: 15 * _glowAnimation.value, // Animated blur size of the glow
                        offset: const Offset(0, 0), // Position of the glow (centered around the image)
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/gift.png',
                    width: 48,
                    height: 48,
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  // ZegoLiveAudioRoomSeatConfig getSeatConfig() {
  //   if (widget.layoutMode == LayoutMode.hostTopCenter) {
  //     return ZegoLiveAudioRoomSeatConfig(
  //       backgroundBuilder: (
  //         BuildContext context,
  //         Size size,
  //         ZegoUIKitUser? user,
  //         Map<String, dynamic> extraInfo,
  //       ) {
  //         return Container(color: Colors.grey);
  //       },
  //     );
  //   }
  //
  //   return ZegoLiveAudioRoomSeatConfig(
  //       avatarBuilder: avatarBuilder,
  //       );
  // }

  ZegoLiveAudioRoomSeatConfig getSeatConfig() {
    return ZegoLiveAudioRoomSeatConfig(
      backgroundBuilder: backgroundBuilder,
      foregroundBuilder: foregroundBuilder,
      avatarBuilder: avatarBuilder,
    );
  }

  Widget avatarBuilder(
      BuildContext context,
      Size size,
      ZegoUIKitUser? user,
      Map<String, dynamic> extraInfo,
      ) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size.width / 2),
        child: _userAvatarUrl != null
            ? CachedNetworkImage(
          imageUrl: _userAvatarUrl!,
          width: size.width,
          height: size.width,
          fit: BoxFit.cover,
          placeholder: (context, url) => CircularProgressIndicator(),
          errorWidget: (context, url, error) => Icon(Icons.error),
        )
            : Container(
          width: size.width,
          height: size.width,
          color: Colors.grey[300],
          child: Icon(Icons.group, color: Colors.grey[400]),
        ),
      ),
    );
  }



  int getHostSeatIndex() {
    if (widget.layoutMode == LayoutMode.hostCenter) {
      return 4;
    }

    return 0;
  }

  List<int> getLockSeatIndex() {
    if (widget.layoutMode == LayoutMode.hostCenter) {
      return [4];
    }

    return [0];
  }

  ZegoLiveAudioRoomLayoutConfig getLayoutConfig() {
    final config = ZegoLiveAudioRoomLayoutConfig();
    LayoutMode lm = widget.layoutMode;
    lm= LayoutMode.hostTopCenter;
    switch (lm) {
      case LayoutMode.defaultLayout:
        break;
      case LayoutMode.full:
        config.rowSpacing = 5;
        config.rowConfigs = List.generate(
          4,
              (index) => ZegoLiveAudioRoomLayoutRowConfig(
            count: 4,
            alignment: ZegoLiveAudioRoomLayoutAlignment.spaceBetween,
          ),
        );
        break;
      case LayoutMode.horizontal:
        config.rowSpacing = 5;
        config.rowConfigs = [
          ZegoLiveAudioRoomLayoutRowConfig(
            count: 8,
            alignment: ZegoLiveAudioRoomLayoutAlignment.spaceBetween,
          ),
        ];
        break;
      case LayoutMode.vertical:
        config.rowSpacing = 5;
        config.rowConfigs = List.generate(
          8,
              (index) => ZegoLiveAudioRoomLayoutRowConfig(
            count: 1,
            alignment: ZegoLiveAudioRoomLayoutAlignment.spaceBetween,
          ),
        );
        break;
      case LayoutMode.hostTopCenter:
        config.rowConfigs = [
          ZegoLiveAudioRoomLayoutRowConfig(
            count: 1,
            alignment: ZegoLiveAudioRoomLayoutAlignment.center,
          ),
          ZegoLiveAudioRoomLayoutRowConfig(
            count: 4,
            alignment: ZegoLiveAudioRoomLayoutAlignment.spaceBetween,
          ),
          ZegoLiveAudioRoomLayoutRowConfig(
            count: 4,
            alignment: ZegoLiveAudioRoomLayoutAlignment.spaceBetween,
          ),

        ];
        break;
      case LayoutMode.hostCenter:
        config.rowSpacing = 5;
        config.rowConfigs = [
          ZegoLiveAudioRoomLayoutRowConfig(
            count: 4,
            alignment: ZegoLiveAudioRoomLayoutAlignment.spaceBetween,
          ),
          ZegoLiveAudioRoomLayoutRowConfig(
            count: 4,
            alignment: ZegoLiveAudioRoomLayoutAlignment.spaceBetween,
          ),

        ];
        break;
      case LayoutMode.fourPeoples:
        config.rowConfigs = [
          ZegoLiveAudioRoomLayoutRowConfig(
            count: 4,
            alignment: ZegoLiveAudioRoomLayoutAlignment.spaceBetween,
          ),
        ];
        break;
    }
    return config;
  }

  void onMemberListMoreButtonPressed(ZegoUIKitUser user) {
    showModalBottomSheet(
      backgroundColor: const Color(0xff111014),
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.0),
          topRight: Radius.circular(32.0),
        ),
      ),
      isDismissible: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        const textStyle = TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        );
        final listMenu = ZegoUIKitPrebuiltLiveAudioRoomController().seat.localHasHostPermissions
            ? [
          GestureDetector(
            onTap: () async {
              Navigator.of(context).pop();

              ZegoUIKit().removeUserFromRoom(
                [user.id],
              ).then((result) {
                debugPrint('kick out result:$result');
              });
            },
            child: Text(
              'Kick Out ${user.name}',
              style: textStyle,
            ),
          ),
          GestureDetector(
            onTap: () async {
              Navigator.of(context).pop();

              ZegoUIKitPrebuiltLiveAudioRoomController().seat.host.inviteToTake(user.id).then((result) {
                debugPrint('invite audience to take seat result:$result');
              });
            },
            child: Text(
              'Invite ${user.name} to take seat',
              style: textStyle,
            ),
          ),
          GestureDetector(
            onTap: () async {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Cancel',
              style: textStyle,
            ),
          ),
        ]
            : [];
        return AnimatedPadding(
          padding: MediaQuery.of(context).viewInsets,
          duration: const Duration(milliseconds: 50),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 10,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: listMenu.length,
              itemBuilder: (BuildContext context, int index) {
                return SizedBox(
                  height: 60,
                  child: Center(child: listMenu[index]),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget giftForeground() {
    return ValueListenableBuilder<PlayData?>(
      valueListenable: ZegoGiftManager().playList.playingDataNotifier,
      builder: (context, playData, _) {
        if (null == playData) {
          return const SizedBox.shrink();
        }

        if (playData.giftItem.type == ZegoGiftType.svga) {
          return svgaWidget(playData);
        } else {
          return mp4Widget(playData);
        }
      },
    );
  }

  Widget svgaWidget(PlayData playData) {
    if (playData.giftItem.type != ZegoGiftType.svga) {
      return const SizedBox.shrink();
    }

    /// you can define the area and size for displaying your own
    /// animations here
    int level = 1;
    if (playData.giftItem.weight < 10) {
      level = 1;
    } else if (playData.giftItem.weight < 100) {
      level = 2;
    } else {
      level = 3;
    }
    switch (level) {
      case 2:
        return Positioned(
          top: 100,
          bottom: 100,
          left: 10,
          right: 10,
          child: ZegoSvgaPlayerWidget(
            key: UniqueKey(),
            playData: playData,
            onPlayEnd: () {
              ZegoGiftManager().playList.next();
            },
          ),
        );
      case 3:
        return ZegoSvgaPlayerWidget(
          key: UniqueKey(),
          playData: playData,
          onPlayEnd: () {
            ZegoGiftManager().playList.next();
          },
        );
    }
    // level 1
    return Positioned(
      bottom: 200,
      left: 10,
      child: ZegoSvgaPlayerWidget(
        key: UniqueKey(),
        size: const Size(100, 100),
        playData: playData,
        onPlayEnd: () {
          /// if there is another gift animation, then play
          ZegoGiftManager().playList.next();
        },
      ),
    );
  }

  Widget mp4Widget(PlayData playData) {
    if (playData.giftItem.type != ZegoGiftType.mp4) {
      return const SizedBox.shrink();
    }

    /// you can define the area and size for displaying your own
    /// animations here
    int level = 1;
    if (playData.giftItem.weight < 10) {
      level = 1;
    } else if (playData.giftItem.weight < 100) {
      level = 2;
    } else {
      level = 3;
    }
    switch (level) {
      case 2:
        return Positioned(
          top: 100,
          bottom: 100,
          left: 10,
          right: 10,
          child: ZegoMp4PlayerWidget(
            key: UniqueKey(),
            playData: playData,
            onPlayEnd: () {
              ZegoGiftManager().playList.next();
            },
          ),
        );
      case 3:
        return ZegoMp4PlayerWidget(
          key: UniqueKey(),
          playData: playData,
          onPlayEnd: () {
            ZegoGiftManager().playList.next();
          },
        );
    }
    // level 1
    return Positioned(
      bottom: 200,
      left: 10,
      child: ZegoMp4PlayerWidget(
        key: UniqueKey(),
        size: const Size(100, 100),
        playData: playData,
        onPlayEnd: () {
          /// if there is another gift animation, then play
          ZegoGiftManager().playList.next();
        },
      ),
    );
  }


  void onGiftReceived() {
    final receivedGift = ZegoGiftManager().service.recvNotifier.value ?? ZegoGiftProtocolItem.empty();
    final giftData = queryGiftInItemList(receivedGift.name);
    if (null == giftData) {
      debugPrint('not ${receivedGift.name} exist');
      return;
    }

    ZegoGiftManager().playList.add(PlayData(
      giftItem: giftData,
      count: receivedGift.count,
    ));
  }
}

