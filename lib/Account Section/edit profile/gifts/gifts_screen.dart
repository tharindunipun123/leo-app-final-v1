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
        fetchUserProfile(),
        fetchReceivedGifts(),
      ]);
    }
  }

  Future<void> fetchUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/collections/users/records/$userId'),
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

  Future<void> fetchReceivedGifts() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(),
      ),
      body: BodyContainer(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/ic-gift.svg',
                  width: 80.w,
                  height: 80.w,
                ),
                SizedBox(width: 10.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gifts.isEmpty ? '0' : gifts.length.toString(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: darkModeEnabled ? kDarkTextColor : kTextColor,
                      ),
                    ),
                    Text(
                      userProfile?['moto'] ?? 'Loading...',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.normal,
                        color: darkModeEnabled ? kDarkTextColor : kTextColor,
                      ),
                    ),
                    SizedBox(height: 5.w),
                    TopContributor(
                      name: userProfile?['firstname'] ?? 'Loading...',
                      image: userProfile?['avatar'] != null
                          ? '$baseUrl/api/files/${userProfile!['collectionId']}/${userProfile!['id']}/${userProfile!['avatar']}'
                          : 'assets/images/avatar.png',
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 30.w),
            Text(
              'Gifts Display',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 16.sp,
                color: kPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.w),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.74,
                ),
                itemCount: gifts.length,
                itemBuilder: (context, index) {
                  final gift = gifts[index];
                  return GiftGridItem(
                    icon: '$baseUrl/api/files/${gift['collectionId']}/${gift['id']}/${gift['gifphoto']}',
                    text: 'x${gift['giftCount']}',
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