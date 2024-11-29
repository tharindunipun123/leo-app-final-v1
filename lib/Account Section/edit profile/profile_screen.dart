import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'theme.dart';
import 'widgets/body_container.dart';
import 'widgets/primary_button.dart';
import 'widgets/voice_room_item.dart';
import 'widgets/gift_item.dart';
import 'widgets/outline_button.dart';
import 'widgets/profile_info.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'http://145.223.21.62:8090';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? userId;
  Map<String, dynamic>? userProfile;
  List<Map<String, dynamic>>? gifts;
  List<Map<String, dynamic>>? badges;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    if (userId != null) {
      await Future.wait([
        _fetchUserProfile(),
        _fetchReceivedGifts(),
        _fetchUserBadges(),
      ]);
      setState(() {});
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('http://145.223.21.62:8090/api/collections/users/records/$userId'),
      );
      if (response.statusCode == 200) {
        setState(() {
          userProfile = json.decode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> _fetchReceivedGifts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/collections/sending_recieving_gifts/records'),
        headers: {'filter': 'reciever_user_id="$userId"'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['items'];
        Map<String, int> giftCounts = {};

        for (var item in data) {
          String giftName = item['giftname'];
          int count = (item['gift_count'] as num).toInt();
          giftCounts[giftName] = (giftCounts[giftName] ?? 0) + count;
        }

        List<Map<String, dynamic>> giftsList = [];
        for (var entry in giftCounts.entries) {
          final giftResponse = await http.get(
            Uri.parse('$baseUrl/api/collections/gifts/records'),
            headers: {'filter': 'giftname="${entry.key}"'},
          );

          if (giftResponse.statusCode == 200) {
            var giftData = json.decode(giftResponse.body)['items'][0];
            giftsList.add({
              'id': giftData['id'],
              'collectionId': giftData['collectionId'],
              'gifphoto': giftData['gifphoto'],
              'giftCount': entry.value,
            });
          }
        }
        setState(() {
          gifts = giftsList;
        });
      }
    } catch (e) {
      debugPrint('Error fetching gifts: $e');
    }
  }

  Future<void> _fetchUserBadges() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/collections/recieved_badges/records'),
        headers: {'filter': 'userId="$userId"'},
      );

      if (response.statusCode == 200) {
        final receivedBadges = json.decode(response.body)['items'];
        List<Map<String, dynamic>> badgesList = [];

        for (var badge in receivedBadges) {
          final badgeResponse = await http.get(
            Uri.parse('$baseUrl/api/collections/badges/records'),
            headers: {'filter': 'badgeName="${badge['batch_name']}"'},
          );

          if (badgeResponse.statusCode == 200) {
            var badgeData = json.decode(badgeResponse.body)['items'][0];
            badgesList.add({
              'id': badgeData['id'],
              'collectionId': badgeData['collectionId'],
              'badgePhoto': badgeData['badgePhoto'],
            });
          }
        }
        setState(() {
          badges = badgesList;
        });
      }
    } catch (e) {
      debugPrint('Error fetching badges: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userProfile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      bottomNavigationBar: Container(
        width: double.infinity,
        color: darkModeEnabled ? kDarkBoxColor : kLightBlueColor,
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(child: OutlineButton(onTap: () {}, text: 'Share')),
            SizedBox(width: 10.w),
            Expanded(
              child: PrimaryButton(
                onTap: () => Navigator.pushNamed(context, 'edit-profile'),
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
                    name: '${userProfile!['firstname']} ${userProfile!['lastname']}',
                    userId: userProfile!['id'],
                    profileImgUrl: userProfile!['avatar'].isNotEmpty
                        ? '$baseUrl/api/files/${userProfile!['collectionId']}/${userProfile!['id']}/${userProfile!['avatar']}'
                        : 'default_avatar_url',
                  ),
                  SizedBox(height: 20.w),
                  Text(
                    userProfile!['moto'] ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: darkModeEnabled ? kDarkTextColor : kAltTextColor,
                    ),
                  ),
                  _buildGiftsSection(),
                  _buildBadgesSection(),
                  //_buildVoiceRoomsSection(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGiftsSection() {
    return Column(
      children: [
        _sectionHeader('Gifts', 'gifts'),
        SizedBox(height: 10.w),
        SizedBox(
          height: 75.w,
          width: double.infinity,
          child: gifts == null
              ? const Center(child: CircularProgressIndicator())
              : gifts!.isEmpty
              ? const Center(child: Text('No gifts'))
              : ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: gifts!.length,
            separatorBuilder: (_, __) => SizedBox(width: 20.w),
            itemBuilder: (context, index) {
              final gift = gifts![index];
              return GiftItem(
                icon: '$baseUrl/api/files/${gift['collectionId']}/${gift['id']}/${gift['gifphoto']}',
                text: 'x${gift['giftCount']}',
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesSection() {
    return Column(
      children: [
        _sectionHeader('Badges', 'badges'),
        SizedBox(height: 10.w),
        SizedBox(
          height: 75.w,
          width: double.infinity,
          child: badges == null
              ? const Center(child: CircularProgressIndicator())
              : badges!.isEmpty
              ? const Center(child: Text('No badges'))
              : ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: badges!.length,
            separatorBuilder: (_, __) => SizedBox(width: 20.w),
            itemBuilder: (context, index) {
              final badge = badges![index];
              return GiftItem(
                icon: '$baseUrl/api/files/${badge['collectionId']}/${badge['id']}/${badge['badgePhoto']}',
                text: '',
              );
            },
          ),
        ),
      ],
    );
  }

  // Widget _buildVoiceRoomsSection() {
  //   return Column(
  //     children: [
  //       _sectionHeader('Voice Rooms', 'rooms'),
  //       SizedBox(height: 10.w),
  //       SizedBox(
  //         height: 106.w,
  //         width: double.infinity,
  //         child: ListView.separated(
  //           itemCount: 5,
  //           scrollDirection: Axis.horizontal,
  //           separatorBuilder: (_, __) => SizedBox(width: 20.w),
  //           itemBuilder: (_, __) => const VoiceRoomItem(
  //             image: 'assets/images/room.png',
  //             text: 'My Voice Room',
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _sectionHeader(String title, String route) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pushNamed(context, route),
          icon: SvgPicture.asset('assets/icons/ic-arrow-right.svg'),
        )
      ],
    );
  }
}