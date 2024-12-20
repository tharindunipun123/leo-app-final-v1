import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RankingBottomSheet extends StatefulWidget {

  @override
  _RankingBottomSheetState createState() => _RankingBottomSheetState();
}

class _RankingBottomSheetState extends State<RankingBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String roomId = "qb61a1m8i7c4lxm";
  bool isLoading = true;
  List<Map<String, dynamic>> dailyRankings = [];
  List<Map<String, dynamic>> weeklyRankings = [];
  List<Map<String, dynamic>> totalRankings = [];
  Map<String, double> diamondAmounts = {};
  Map<String, dynamic> userDetails = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      await _fetchGiftDiamondAmounts(); // Ensure this is completed first
      await _fetchRankings();
      setState(() => isLoading = false);
    } catch (e) {
      print('Error loading data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchGiftDiamondAmounts() async {
    try {
      print('Fetching gift diamond amounts...');
      final response = await http.get(
        Uri.parse('http://145.223.21.62:8090/api/collections/gifts/records'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;

        diamondAmounts = Map.fromEntries(
            items.map((item) => MapEntry(
              item['giftname'],
              (item['diamond_amount'] as num).toDouble(),
            ))
        );
        print('Fetched diamond amounts: $diamondAmounts');
      }
    } catch (e) {
      print('Error fetching diamond amounts: $e');
    }
  }

  Future<void> _fetchUserDetails(String userId) async {
    if (userDetails.containsKey(userId)) return;

    try {
      print('Fetching user details for ID: $userId');
      final response = await http.get(
        Uri.parse('http://145.223.21.62:8090/api/collections/users/records/$userId'),
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        userDetails[userId] = userData;
        print('Fetched user details: ${userDetails[userId]}');
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  Future<void> _fetchRankings() async {
    try {
      print('Fetching global rankings...');
      final response = await http.get(
        Uri.parse('http://145.223.21.62:8090/api/collections/sending_recieving_gifts/records'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final gifts = data['items'] as List;

        // Current date
        final now = DateTime.now();

        // Process for daily rankings
        final today = DateTime(now.year, now.month, now.day);
        final dailyGifts = gifts.where((gift) {
          final giftDate = DateTime.parse(gift['created']);
          return giftDate.isAfter(today);
        }).toList();

        // Process for weekly rankings
        final weekAgo = now.subtract(Duration(days: 7));
        final weeklyGifts = gifts.where((gift) {
          final giftDate = DateTime.parse(gift['created']);
          return giftDate.isAfter(weekAgo);
        }).toList();

        // Process for monthly rankings
        final monthStart = DateTime(now.year, now.month, 1);
        final monthlyGifts = gifts.where((gift) {
          final giftDate = DateTime.parse(gift['created']);
          return giftDate.isAfter(monthStart);
        }).toList();

        // Calculate rankings
        dailyRankings = await _calculateRankings(dailyGifts);
        weeklyRankings = await _calculateRankings(weeklyGifts);
        totalRankings = await _calculateRankings(monthlyGifts);

        setState(() {});
      } else {
        print('Error fetching rankings: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching rankings: $e');
    }
  }


  Future<List<Map<String, dynamic>>> _calculateRankings(List<dynamic> gifts) async {
    Map<String, double> userTotals = {};

    for (var gift in gifts) {
      final senderId = gift['sender_user_id'];
      final giftName = gift['giftname'];
      final count = gift['gift_count'] as int;

      // Check if giftName exists in diamondAmounts
      if (diamondAmounts.containsKey(giftName)) {
        final diamondAmount = diamondAmounts[giftName]!;
        userTotals[senderId] = (userTotals[senderId] ?? 0) + (count * diamondAmount);

        // Fetch user details if not already fetched
        if (!userDetails.containsKey(senderId)) {
          await _fetchUserDetails(senderId);
        }
      } else {
        print('Gift name "$giftName" not found in diamond amounts.');
      }
    }

    // Sort and prepare rankings
    var sortedUsers = userTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedUsers.map((entry) => {
      'userId': entry.key,
      'total': entry.value,
      'userDetails': userDetails[entry.key],
    }).toList();
  }




  @override
  Widget build(BuildContext context) {
    // Change from Container to Scaffold for full page
    return Column(
        children: [
          // Tab bar
          Container(
            margin: EdgeInsets.only(top: 8),
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Today'),
                Tab(text: 'This Week'),
                Tab(text: 'This Month'),
              ],
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),

          // Content
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
              controller: _tabController,
              children: [
                _buildRankingList(dailyRankings),
                _buildRankingList(weeklyRankings),
                _buildRankingList(totalRankings), // Use the monthly rankings here
              ],
            ),
          ),
        ]
    );

  }

  Widget _buildRankingList(List<Map<String, dynamic>> rankings) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: rankings.length,
      itemBuilder: (context, index) {
        final ranking = rankings[index];
        final userDetail = ranking['userDetails'];

        return Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // Rank number or medal
              Container(
                width: 30,
                margin: EdgeInsets.only(right: 12),
                child: index < 3
                    ? Image.asset('assets/images/medal${index + 1}.png')
                    : Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),

              // Profile image
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[200]!),
                  image: DecorationImage(
                    image: NetworkImage(
                        'http://145.223.21.62:8090/api/files/${userDetail['collectionId']}/${userDetail['id']}/${userDetail['avatar']}'
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              SizedBox(width: 12),

              // Name and motto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userDetail['firstname'] ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      userDetail['moto'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Diamond amount
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/diamond.png',
                    width: 16,
                    height: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${ranking['total'].toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}