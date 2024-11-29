import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../widgets/body_container.dart';
import '../widgets/profile_info.dart';
import '../../constants.dart';
import '../widgets/back_button.dart';
import '../widgets/badge_grid_item.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  String? userId;
  String? name;
  String? profileImgUrl;
  List<Map<String, dynamic>> badges = [];
  final baseUrl = 'http://145.223.21.62:8090';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
      name = prefs.getString('firstName');
    });
    if (userId != null) {
      await Future.wait([
        fetchUserAvatar(),
        fetchUserBadges(),
      ]);
    }
  }

  Future<void> fetchUserAvatar() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/collections/users/records/$userId'),
      );
      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          profileImgUrl = userData['avatar'] != null
              ? '$baseUrl/api/files/${userData['collectionId']}/${userData['id']}/${userData['avatar']}'
              : null;
        });
      }
    } catch (e) {
      debugPrint('Error fetching avatar: $e');
    }
  }

  Future<void> fetchUserBadges() async {
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
              'badgeName': badgeData['badgeName'],
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
    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(),
        centerTitle: true,
        title: Text(
          'Badges',
          style: TextStyle(
            fontSize: 16.sp,
            color: darkModeEnabled ? kDarkTextColor : kTextColor,
          ),
        ),
      ),
      body: BodyContainer(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userId != null && name != null)
              ProfileInfo(
                name: name!,
                userId: userId!,
                profileImgUrl: profileImgUrl ?? 'assets/images/avatar.png',
              ),
            SizedBox(height: 30.w),
            Text(
              'Earned Badges',
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
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: badges.length,
                itemBuilder: (context, index) {
                  final badge = badges[index];
                  return BadgeGridItem(
                    icon: '$baseUrl/api/files/${badge['collectionId']}/${badge['id']}/${badge['badgePhoto']}',
                    text: badge['badgeName'],
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