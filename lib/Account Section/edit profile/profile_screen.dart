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
      // First fetch all gifts
      final allGiftsResponse = await http.get(
        Uri.parse('$baseUrl/api/collections/gifts/records'),
      );

      if (allGiftsResponse.statusCode != 200) {
        throw Exception('Failed to fetch gifts');
      }

      final allGifts = json.decode(allGiftsResponse.body)['items'] as List;
      Map<String, Map<String, dynamic>> giftsMap = {};

      // Debug: Print all gift fields
      print('First gift data: ${allGifts.first}');

      // Create gifts map
      for (var gift in allGifts) {
        giftsMap[gift['giftname']] = {
          ...gift,
          'count': 0,
        };
      }

      // Fetch received gifts
      final receivedResponse = await http.get(
        Uri.parse('$baseUrl/api/collections/sending_recieving_gifts/records?filter=(reciever_user_id="$userId")'),
      );

      if (receivedResponse.statusCode != 200) {
        throw Exception('Failed to fetch received gifts');
      }

      final receivedGifts = json.decode(receivedResponse.body)['items'] as List;

      // Count gifts
      for (var received in receivedGifts) {
        final giftName = received['giftname'] as String;
        final count = received['gift_count'] as int;

        if (giftsMap.containsKey(giftName)) {
          giftsMap[giftName]!['count'] = (giftsMap[giftName]!['count'] as int) + count;
        }
      }

      // Convert to list and filter out gifts with count 0
      List<Map<String, dynamic>> giftsList = giftsMap.values
          .where((gift) => gift['count'] > 0)
          .map((gift) => {
        'id': gift['id'],
        'collectionId': gift['collectionId'],
        // Try all possible field names for gift photo
        'gifphoto': gift['gift_photo'] ?? gift['giftphoto'] ?? gift['gifPhoto'] ?? gift['photo'] ?? '',
        'giftCount': gift['count'],
        'giftName': gift['giftname'],
      })
          .toList();

      // Sort by count
      giftsList.sort((a, b) => (b['giftCount'] as int).compareTo(a['giftCount'] as int));

      if (mounted) {
        setState(() {
          gifts = giftsList;
        });
      }

      // Debug log
      for (var gift in giftsList) {
        print('\nGift details:');
        print('Name: ${gift['giftName']}');
        print('ID: ${gift['id']}');
        print('CollectionId: ${gift['collectionId']}');
        print('Photo field: ${gift['gifphoto']}');
        print('Full URL: $baseUrl/api/files/${gift['collectionId']}/${gift['id']}/${gift['gifphoto']}');
      }

    } catch (e) {
      debugPrint('Error fetching gifts: $e');
    }
  }
  Future<void> _fetchUserBadges() async {
    try {
      // First fetch received badges for the specific user
      final receivedBadgesResponse = await http.get(
        Uri.parse('$baseUrl/api/collections/recieved_badges/records?filter=(userId="$userId")'),
      );

      if (receivedBadgesResponse.statusCode == 200) {
        final receivedBadges = json.decode(receivedBadgesResponse.body)['items'] as List;
        List<Map<String, dynamic>> badgesList = [];

        // Create a Set to track unique badge names
        Set<String> processedBadgeNames = {};

        for (var receivedBadge in receivedBadges) {
          final badgeName = receivedBadge['batch_name'];

          // Skip if we've already processed this badge name
          if (processedBadgeNames.contains(badgeName)) continue;
          processedBadgeNames.add(badgeName);

          // Fetch badge details
          final badgeResponse = await http.get(
            Uri.parse('$baseUrl/api/collections/badges/records?filter=(badgeName="$badgeName")'),
          );

          if (badgeResponse.statusCode == 200) {
            final badgeItems = json.decode(badgeResponse.body)['items'] as List;
            if (badgeItems.isNotEmpty) {
              final badgeData = badgeItems[0];
              // Make sure badgePhoto exists and is not empty
              if (badgeData['badgePhoto'] != null && badgeData['badgePhoto'].toString().isNotEmpty) {
                badgesList.add({
                  'id': badgeData['id'],
                  'collectionId': badgeData['collectionId'],
                  'badgePhoto': badgeData['badgePhoto'],
                  'badgeName': badgeData['badgeName'],
                });
              }
            }
          }
        }

        if (mounted) {
          setState(() {
            badges = badgesList;
          });
        }
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

    // Fetch the cover photo URL
    String coverPhotoUrl = userProfile!['coverphoto'] != null && userProfile!['coverphoto'].isNotEmpty
        ? '$baseUrl/api/files/${userProfile!['collectionId']}/${userProfile!['id']}/${userProfile!['coverphoto']}'
        : 'assets/images/default_cover.png'; // Default cover image if not available

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
            // Display the cover photo
            Image.network(
              coverPhotoUrl,
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/images/default_cover.png', // Fallback image in case of error
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                );
              },
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
              final imageUrl = '$baseUrl/api/files/${gift['collectionId']}/${gift['id']}/${gift['gifphoto']}';
              return Column(
                children: [
                  Image.network(
                    imageUrl,
                    width: 50.w,
                    height: 50.w,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.error, size: 50.w);
                    },
                  ),
                  Text('x${gift['giftCount']}')
                ],
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
          height: 100.w,
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
              final imageUrl = '$baseUrl/api/files/${badge['collectionId']}/${badge['id']}/${badge['badgePhoto']}';
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _buildBadgeImage(imageUrl),
                  ),
                  SizedBox(height: 5.w),
                  Container(
                    width: 60.w,
                    child: Text(
                      badge['badgeName'] ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: darkModeEnabled ? kDarkTextColor : kAltTextColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeImage(String imageUrl) {
    final extension = imageUrl.split('.').last.toLowerCase();

    if (extension == 'svg') {
      return SvgPicture.network(
        imageUrl,
        fit: BoxFit.cover,
        placeholderBuilder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 50.w,
            height: 50.w,
            color: Colors.grey[300],
            child: Icon(Icons.broken_image, size: 25.w),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }
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