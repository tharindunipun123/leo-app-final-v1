import 'package:flutter/material.dart';
import 'package:zego_zimkit/zego_zimkit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'HomePagePopMenu.dart';
import 'Status.dart'; // Import the status screen

// Global navigator key for handling call invitations
final navigatorKey = GlobalKey<NavigatorState>();

class ChatScreen1 extends StatefulWidget {
  const ChatScreen1({Key? key}) : super(key: key);

  @override
  ChatScreen1State createState() => ChatScreen1State();
}

class ChatScreen1State extends State<ChatScreen1> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _initializeZegoCloud();
    _fetchAndSetUserAvatar();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeZegoCloud() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      final userName = prefs.getString('firstName') ?? '';

      if (userId.isEmpty) return;

      ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);

      await ZegoUIKitPrebuiltCallInvitationService().init(
        appID: 1382376685,
        appSign: '0a9bce0b90584625b087d27e8e3c9a2a15ea28eb16119022da829f87c3763142',
        userID: userId,
        userName: userName,
        plugins: [ZegoUIKitSignalingPlugin()],
        config: ZegoCallInvitationConfig(
          canInvitingInCalling: true,
        ),
        notificationConfig: ZegoCallInvitationNotificationConfig(
          androidNotificationConfig: ZegoCallAndroidNotificationConfig(
            channelID: 'ZegoUIKit',
            channelName: 'Call Notifications',
            sound: 'call',
            icon: 'call',
          ),
        ),
        requireConfig: (ZegoCallInvitationData data) {
          final config = data.type == ZegoCallInvitationType.videoCall
              ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
              : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

          config.audioVideoViewConfig
            ..useVideoViewAspectFill = true;

          return config;
        },
      );
    } catch (e) {
      print('Error initializing Zego Cloud: $e');
    }
  }

  Future<void> _fetchAndSetUserAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      final userName = prefs.getString('firstName') ?? '';

      if (userId.isEmpty) return;

      final response = await http.get(
        Uri.parse('http://145.223.21.62:8090/api/collections/users/records/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final avatarUrl = data['avatar'] != null
            ? 'http://145.223.21.62:8090/api/files/${data['collectionId']}/${data['id']}/${data['avatar']}'
            : null;

        if (avatarUrl != null) {
          await ZIMKit().updateUserInfo(
            avatarUrl: avatarUrl,
            name: userName,
          );
        }
      }
    } catch (e) {
      print('Error fetching user avatar: $e');
    }
  }

  Widget _buildChatTab() {
    return ZIMKitConversationListView(
      onPressed: (context, conversation, defaultAction) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ZIMKitMessageListPage(
              conversationID: conversation.id,
              conversationType: conversation.type,
              appBarActions: conversation.type == ZIMConversationType.peer
                  ? [
                ZegoSendCallInvitationButton(
                  isVideoCall: true,
                  resourceID: 'zego_data',
                  invitees: [
                    ZegoUIKitUser(
                      id: conversation.id,
                      name: conversation.name,
                    ),
                  ],
                ),
                ZegoSendCallInvitationButton(
                  isVideoCall: false,
                  resourceID: 'zego_data',
                  invitees: [
                    ZegoUIKitUser(
                      id: conversation.id,
                      name: conversation.name,
                    ),
                  ],
                ),
              ]
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusPage() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: StatusPage(), // Your StatusPage widget
    );
  }

  void _handleFABPressed() {
    const HomePagePopupMenuButton();
    // if (_tabController.index == 0) {
    //   // Handle chat FAB press
    // } else {
    //   // Handle status FAB press
    // }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primaryColor: Colors.blue[700],
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.blue[700],
        ),
      ),
      home: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            title: Text(
              'Messages',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            actions: [
              // IconButton(
              //   icon: Icon(Icons.search, color: Colors.blue[700]),
              //   onPressed: () {},
              // ),
              const HomePagePopupMenuButton(),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.blue[700],
              labelColor: Colors.blue[700],
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              tabs: const [
                Tab(text: 'CHATS'),
                Tab(text: 'STATUS'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildChatTab(),
              _buildStatusPage(),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _handleFABPressed,
            backgroundColor: Colors.blue[700],
            child: Icon(
              _tabController.index == 0 ? Icons.chat : Icons.camera_alt,
            ),
          ),
        ),
      ),
    );
  }
}
