import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../widgets/body_container.dart';
import '../../constants.dart';
import '../widgets/back_button.dart';
import '../widgets/gift_grid_item.dart';
import '../widgets/top_contributor.dart';

class GiftsScreen extends StatefulWidget {
  const GiftsScreen({super.key});

  @override
  State<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends State<GiftsScreen> {
  String? userId;
  Map<String, dynamic>? userProfile;
  List<Map<String, dynamic>> gifts = [];
  final baseUrl = 'http://145.223.21.62:8090';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('userId');
      if (userId != null) {
        await Future.wait([
          fetchUserProfile(),
          fetchReceivedGifts(),
        ]);
      }
    } catch (e) {
      debugPrint('Error initializing data: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> fetchUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/collections/users/records/$userId'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            userProfile = data;
          });
        }
        print('User Profile:');
        print('Bio: ${data['bio']}');
        print('Avatar: ${data['avatar']}');
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> fetchReceivedGifts() async {
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

      // Create gifts map
      for (var gift in allGifts) {
        giftsMap[gift['giftname']] = {
          ...gift,
          'count': 0,
        };
      }

      // Fetch received gifts with proper filter for current user
      final receivedResponse = await http.get(
        Uri.parse('$baseUrl/api/collections/sending_recieving_gifts/records?filter=(reciever_user_id="$userId")'),
      );

      if (receivedResponse.statusCode != 200) {
        throw Exception('Failed to fetch received gifts');
      }

      final receivedGifts = json.decode(receivedResponse.body)['items'] as List;

      print('Received Gifts Count: ${receivedGifts.length}');

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
        'giftName': gift['giftname'],
        'giftPhoto': gift['gift_photo'],
        'count': gift['count'],
      })
          .toList();

      // Sort by count
      giftsList.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      if (mounted) {
        setState(() {
          gifts = giftsList;
        });
      }

    } catch (e) {
      debugPrint('Error fetching gifts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(),
        title: Text(
          'My Gifts',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            //color: darkModeEnabled ? kDarkTextColor : kTextColor,
            color: Colors.white
          ),
        ),
      ),
      body: BodyContainer(
        padding: const EdgeInsets.all(20.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  'assets/icons/ic-gift.svg',
                  width: 70.w,  // Slightly reduced size
                  height: 70.w,
                ),
                SizedBox(width: 8.w),
                Expanded(  // Added Expanded to prevent overflow
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gift Items Count
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.w),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.w),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,  // To wrap content
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Gift Items: ',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.black,
                                    ),
                                  ),
                                  TextSpan(
                                    text: gifts.isEmpty ? '0' : gifts.length.toString(),
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: kPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      //SizedBox(height: 4.w),
                      // Bio Text
                      if (userProfile?['bio'] != null)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 4.w),
                          child: Text(
                            userProfile!['bio'].toString(),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.white.withOpacity(0.8),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      //SizedBox(height: 8.w),
                      // Top Contributor
                      Container(
                        width: double.infinity,
                        child: TopContributor(
                          name: (userProfile != null && userProfile!['firstname'] != null)
                              ? userProfile!['firstname'].toString()
                              : '',
                          image: (userProfile != null &&
                              userProfile!['avatar'] != null &&
                              userProfile!['avatar'].toString().isNotEmpty)
                              ? '$baseUrl/api/files/${userProfile!['collectionId']}/${userProfile!['id']}/${userProfile!['avatar']}'
                              : 'assets/images/avatar.png',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 30.w),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gifts Display',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Total Gifts: ${gifts.fold(0, (sum, gift) => sum + (gift['count'] as int))}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: darkModeEnabled ? kDarkTextColor : kTextColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.w),
            Expanded(
              child: gifts.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.card_giftcard,
                      size: 48.w,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 10.w),
                    Text(
                      'No gifts received yet',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
                  : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.74,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: gifts.length,
                itemBuilder: (context, index) {
                  final gift = gifts[index];
                  final photoUrl = '$baseUrl/api/files/${gift['collectionId']}/${gift['id']}/${gift['giftPhoto']}';
                  print('Building grid item:');
                  print('Name: ${gift['giftName']}');
                  print('URL: $photoUrl');
                  print('Count: ${gift['count']}');

                  return GiftGridItem(
                    icon: photoUrl,
                    name: gift['giftName'] ?? 'Unknown Gift',
                    count: gift['count'] ?? 0,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}