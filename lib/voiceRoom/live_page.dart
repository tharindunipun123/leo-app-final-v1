// Flutter imports:
import 'package:flutter/material.dart';
import './gift/gift.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Package imports:
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_live_audio_room/zego_uikit_prebuilt_live_audio_room.dart';

// Project imports:
import 'constants.dart';
import 'media.dart';

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
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  String? _userAvatarUrl;
  String? _voiceRoomName;
  String? _backgroundImageUrl;
  static const String POCKETBASE_URL = 'http://145.223.21.62:8090'; // Replace with your actual PocketBase URL

  @override
  void initState() {
    super.initState();
    ZegoGiftManager().cache.cacheAllFiles(giftItemList);
    ZegoGiftManager().service.recvNotifier.addListener(onGiftReceived);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ZegoGiftManager().service.init(
        appID: 2069292420,
        liveID: widget.roomID,
        localUserID: localUserID,
        localUserName: widget.username1,
      );
      // Fetch avatar URL when component mounts
      _fetchAndSetUserAvatar();
      _fetchVoiceRoomDetails();
    });

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
      lowerBound: 0.5,
      upperBound: 1.2,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(_controller);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Get crown gift data
      final crownGift = giftItemList.firstWhere(
              (gift) => gift.name == 'crown',  // Adjust name to match your gift
          orElse: () => giftItemList.first
      );

      // Auto play the gift
      ZegoGiftManager().playList.add(PlayData(
          giftItem: crownGift,
          count: 1
      ));
    });
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

  Future<void> _fetchVoiceRoomDetails() async {
    try {
      final uri = Uri.parse('$POCKETBASE_URL/api/collections/voiceRooms/records/${widget.roomID}')
          .replace(queryParameters: {
        'fields': 'voice_room_name,background_images',
      });

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _voiceRoomName = data['voice_room_name'];
          if (data['background_images'] != null) {
            _backgroundImageUrl = '$POCKETBASE_URL/api/files/voiceRooms/${widget.roomID}/${data['background_images']}';
          }
        });
      }
    } catch (e) {
      print('Error fetching voice room details: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
    ZegoGiftManager().service.recvNotifier.removeListener(onGiftReceived);
    ZegoGiftManager().service.uninit();
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



  @override
  Widget build(BuildContext context) {
    final hostConfig = ZegoUIKitPrebuiltLiveAudioRoomConfig.host();


    return SafeArea(
      child: ZegoUIKitPrebuiltLiveAudioRoom(
        appID: 2069292420,
        appSign: '3b8893143a13c24f6d82dd7260b70a9d29814b99130e7bcebfe3e09dac8c0731',
        userID: localUserID,
        userName: widget.username1,
        roomID: widget.roomID,
        events: events,
        config: config,
      ),
    );
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
      ..topMenuBar.buttons = [ZegoLiveAudioRoomMenuBarButtonName.minimizingButton]
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
         Positioned(
          top: 35,
          left: 30,
          right: 30,
          // Add right and left to create space
          bottom: 30,
          // Add bottom if you want to create a border for the center
          child: Align(
            alignment: Alignment.topCenter, // This will center the text
            child: Text(
              '$_voiceRoomName',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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
                  showGiftListSheet(context);
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
    return CircleAvatar(
      maxRadius: size.width,
      //backgroundImage: Image.asset("assets/avatars/avatar_${((int.tryParse(user?.id ?? "") ?? 0) % 6)}.png").image,
      backgroundImage: Image.network(_userAvatarUrl!).image,
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
