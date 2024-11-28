import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import '../constants.dart';
import 'theme.dart';
import 'widgets/body_container.dart';
import 'widgets/primary_button.dart';
import 'widgets/voice_room_item.dart';

import 'widgets/gift_item.dart';
import 'widgets/outline_button.dart';
import 'widgets/profile_info.dart';
import 'widgets/stats_box.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

class Gift {
  final int giftId;
  final String createdAt;
  final int senderId;
  final int receiverId;
  final String giftName;
  final String giftUrl;
  final int transactionId;

  Gift({
    required this.giftId,
    required this.createdAt,
    required this.senderId,
    required this.receiverId,
    required this.giftName,
    required this.giftUrl,
    required this.transactionId,
  });

  factory Gift.fromJson(Map<String, dynamic> json) {
    return Gift(
      giftId: json['giftId'],
      createdAt: json['createdAt'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      giftName: json['giftName'],
      giftUrl: json['giftUrl'],
      transactionId: json['transactionId'],
    );
  }
}

class GiftItem extends StatelessWidget {
  final String icon;
  final String text;

  const GiftItem({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
            image: DecorationImage(
              image: NetworkImage(icon),
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(fontSize: 14, color: Colors.black),
        ),
      ],
    );
  }
}

class ProfileScreen extends StatefulWidget {
  final String userId;
  final String name;
  final String profileImgUrl;

  const ProfileScreen(
      {super.key,
      required this.name,
      required this.userId,
      required this.profileImgUrl});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<List<Gift>> futureGifts;

  @override
  void initState() {
    super.initState();
    futureGifts = fetchGifts(widget.userId);
  }

  Future<List<Gift>> fetchGifts(String userId) async {
    final response = await http.get(Uri.parse(
        'http://45.126.125.172:8080/api/v1/gifting/getReceivedGifts/$userId'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((gift) => Gift.fromJson(gift)).toList();
    } else {
      throw Exception('Failed to load gifts');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        width: double.infinity,
        color: darkModeEnabled ? kDarkBoxColor : kLightBlueColor,
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              child: OutlineButton(
                onTap: () {},
                text: 'Share',
              ),
            ),
            SizedBox(
              width: 10.w,
            ),
            Expanded(
              child: PrimaryButton(
                onTap: () {
                  Navigator.pushNamed(context, 'edit-profile');
                },
                text: 'Edit',
              ),
            )
          ],
        ),
      ),
      body: BodyContainer(
        enableScroll: true,
        padding: const EdgeInsets.all(0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/coverpic.png',
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileInfo(
                      name: widget.name,
                      userId: widget.userId,
                      profileImgUrl: widget.profileImgUrl),
                  SizedBox(
                    height: 20.w,
                  ),
                  Text(
                    'Online Entrepreneur | Youtuber | Blockchain Developer | Astrophotographer | Game Developer',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: darkModeEnabled ? kDarkTextColor : kAltTextColor,
                    ),
                  ),
                  SizedBox(
                    height: 20.w,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: darkModeEnabled ? kDarkBoxColor : kLightBlueColor,
                      borderRadius: BorderRadius.circular(12.w),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        StatsBox(
                          text: 'Followers',
                          value: 11,
                        ),
                        StatsBox(
                          text: 'Fans',
                          value: 11,
                        ),
                        StatsBox(
                          text: 'Visitors',
                          value: 11,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20.w,
                  ),
                  Text(
                    'Lorem ipsum dolor sit amet, consectetur adipiscing. Lorem ipsum dolor sit amet, consectetur adipiscing. Lorem ipsum dolor sit amet, consectetur adipiscing.  Lorem ipsum dolor sit amet, consectetur adipiscing.  Lorem ipsum dolor sit amet, consectetur adipiscing.',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: darkModeEnabled ? kDarkTextColor : kAltTextColor,
                    ),
                  ),
                  SizedBox(
                    height: 20.w,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Gifts',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pushNamed(context, 'gifts');
                        },
                        icon: SvgPicture.asset(
                          'assets/icons/ic-arrow-right.svg',
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 10.w,
                  ),
                  SizedBox(
                    height: 75.w,
                    width: double.infinity,
                    child: FutureBuilder<List<Gift>>(
                      future: futureGifts,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Failed to load gifts'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Center(child: Text('No gifts received'));
                        } else {
                          return ListView.separated(
                            itemCount: snapshot.data!.length,
                            scrollDirection: Axis.horizontal,
                            separatorBuilder: (context, index) {
                              return SizedBox(
                                width: 20.w,
                              );
                            },
                            itemBuilder: (context, index) {
                              final gift = snapshot.data![index];
                              return GiftItem(
                                icon: gift.giftUrl,
                                text: gift.giftName,
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    height: 20.w,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Badges',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pushNamed(context, 'badges');
                        },
                        icon: SvgPicture.asset(
                          'assets/icons/ic-arrow-right.svg',
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 10.w,
                  ),
                  SizedBox(
                    height: 75.w,
                    width: double.infinity,
                    child: ListView.separated(
                      itemCount: 5,
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (context, index) {
                        return SizedBox(
                          width: 20.w,
                        );
                      },
                      itemBuilder: (context, index) {
                        return const GiftItem(
                          icon: 'assets/icons/ic-gifticon.svg',
                          text: 'x263',
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    height: 10.w,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Voice Rooms',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pushNamed(context, 'rooms');
                        },
                        icon: SvgPicture.asset(
                          'assets/icons/ic-arrow-right.svg',
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 106.w,
                    width: double.infinity,
                    child: ListView.separated(
                      itemCount: 5,
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (context, index) {
                        return SizedBox(
                          width: 20.w,
                        );
                      },
                      itemBuilder: (context, index) {
                        return const VoiceRoomItem(
                          image: 'assets/images/room.png',
                          text: 'My Voice Room',
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
