import 'package:flutter/material.dart';
import 'package:zego_zimkit/zego_zimkit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../HomeScreen.dart';
import 'HomePagePopMenu.dart';
import 'Status.dart';
import 'newcontact.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class ChatScreen1 extends StatefulWidget {
  const ChatScreen1({Key? key}) : super(key: key);

  @override
  ChatScreen1State createState() => ChatScreen1State();
}

class ChatScreen1State extends State<ChatScreen1> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final int tabCount = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: tabCount,
      vsync: this,
      initialIndex: 0,
    );
    _tabController.addListener(_handleTabChange);
    _initializeZegoCloud();
    _fetchAndSetUserAvatar();
  }

  void _handleTabChange() {
    setState(() {});
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

      final callService = ZegoUIKitPrebuiltCallInvitationService();
      callService.setNavigatorKey(navigatorKey);

      await callService.init(
        appID: 1244136023,
        appSign: '087a2a4ce49e2e91e175a2b0153b5638df2a65ce3d6b0a515cd743fbe62a6ea2',
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

          config.audioVideoViewConfig.useVideoViewAspectFill = true;
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
        // Hide bottom nav before navigation
        print("Hiding bottom nav"); // For debugging
        HomeScreen.setBottomBarVisibility(false);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ZIMKitMessageListPage(
              conversationID: conversation.id,
              conversationType: conversation.type,
              appBarActions: conversation.type == ZIMConversationType.peer ? [] : null,
            ),
          ),
        ).then((_) {
          // Show bottom nav after returning
          print("Showing bottom nav"); // For debugging
          HomeScreen.setBottomBarVisibility(true);
        });
      },
    );
  }

  Widget _buildStatusPage() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: StatusPage(),
    );
  }

  Widget _buildContactPage() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      //child: NewContactAndCallHistoryScreen(),
    );
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
            actions: const [HomePagePopupMenuButton()],
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
                Tab(icon: Icon(Icons.chat_bubble)),
                Tab(icon: Icon(Icons.access_time)),
                Tab(icon: Icon(Icons.people)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildChatTab(),
              _buildStatusPage(),
              _buildContactPage(),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => const HomePagePopupMenuButton(),
            backgroundColor: Colors.blue[700],
            child: Icon(
              _tabController.index == 0
                  ? Icons.chat
                  : _tabController.index == 1
                  ? Icons.camera_alt
                  : Icons.person_add,
            ),
          ),
        ),
      ),
    );
  }
}