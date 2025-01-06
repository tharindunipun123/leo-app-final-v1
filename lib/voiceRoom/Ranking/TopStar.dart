import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class TopGifterCard extends StatelessWidget {
  final Map<String, dynamic> userDetails;
  final double totalAmount;

  const TopGifterCard({
    Key? key,
    required this.userDetails,
    required this.totalAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3CB371).withOpacity(0.95),  // Medium sea green
            Color(0xFF006400).withOpacity(0.90),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image.network(
                  'http://145.223.21.62:8090/api/files/${userDetails['collectionId']}/${userDetails['id']}/${userDetails['avatar']}',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Last Week\'s Top Star',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    userDetails['firstname'] ?? 'Unknown',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userDetails['moto'] ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/diamond.png',
                    width: 16,
                    height: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${totalAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class Topstar extends StatefulWidget {

  @override


  _RankingBottomSheetState createState() => _RankingBottomSheetState();
}

class _RankingBottomSheetState extends State<Topstar> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String roomId = "qb61a1m8i7c4lxm";
  bool isLoading = true;
  List<Map<String, dynamic>> dailyRankings = [];
  List<Map<String, dynamic>> weeklyRankings = [];
  List<Map<String, dynamic>> totalRankings = [];
  Map<String, dynamic>? lastWeekTopGifter;
  static Map<String, DateTime> _lastFetchTime = {};
  static const cacheDuration = Duration(minutes: 5);
  Map<String, double> diamondAmounts = {};
  Map<String, dynamic> userDetails = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadAllData();
  }

  void _handleTabChange() {
    setState(() {});
  }

  Future<void> _loadAllData() async {
    setState(() => isLoading = true);
    try {
      await _fetchGiftDiamondAmounts();
      await Future.wait([
        _fetchRankings(),
        _fetchLastWeekTopGifter(),
      ]);
      setState(() => isLoading = false);
    } catch (e) {
      print('Error loading data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<bool> _verifyGifterBadge(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('http://145.223.21.62:8090/api/collections/recieved_badges/records?filter=userId="${userId}"&fields=batch_name'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;

        bool hasGifterBadge = items.any((item) => item['batch_name'] == 'star');
        print(hasGifterBadge);

        if (!hasGifterBadge) {
          final createResponse = await http.post(
            Uri.parse('http://145.223.21.62:8090/api/collections/recieved_badges/records'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'userId': userId,
              'batch_name': 'star',
              'created': DateTime.now().toIso8601String(),
              'updated': DateTime.now().toIso8601String(),
            }),
          );

          return createResponse.statusCode == 200;
        }

        return hasGifterBadge;
      }
    } catch (e) {
      print('Error verifying gifter badge: $e');
    }
    return false;
  }

  Future<void> _fetchLastWeekTopGifter() async {


    try {
      final now = DateTime.now();
      final lastWeekStart = now.subtract(Duration(days: 14));
      final lastWeekEnd = now.subtract(Duration(days: 7));

      final encodedFilter = Uri.encodeComponent(
          'created >= "${lastWeekStart.toIso8601String()}" && created < "${lastWeekEnd.toIso8601String()}"'
      );

      final response = await http.get(
        Uri.parse(
            'http://145.223.21.62:8090/api/collections/sending_recieving_gifts/records'
                '?filter=$encodedFilter'
                '&perPage=500'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final gifts = data['items'] as List;

        Map<String, double> userTotals = {};

        for (var gift in gifts) {
          final senderId = gift['reciever_user_id'];
          final giftName = gift['giftname'];
          final count = gift['gift_count'] as int;

          if (diamondAmounts.containsKey(giftName)) {
            final amount = diamondAmounts[giftName]!;
            userTotals[senderId] = (userTotals[senderId] ?? 0) + (count * amount);
          }
        }

        if (userTotals.isNotEmpty) {
          var topEntry = userTotals.entries
              .reduce((a, b) => a.value > b.value ? a : b);

          await _verifyGifterBadge(topEntry.key);

          final userResponse = await http.get(
            Uri.parse('http://145.223.21.62:8090/api/collections/users/records/${topEntry.key}'),
          );

          if (userResponse.statusCode == 200) {
            final userData = json.decode(userResponse.body);
            setState(() {
              lastWeekTopGifter = {
                'userDetails': userData,
                'total': topEntry.value,
              };
            });
            _lastFetchTime['lastWeekGifter'] = DateTime.now();
          }
        }
      }
    } catch (e) {
      print('Error fetching last week top gifter: $e');
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
      final senderId = gift['reciever_user_id'];
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
          if (lastWeekTopGifter != null)
            TopGifterCard(
              userDetails: lastWeekTopGifter!['userDetails'],
              totalAmount: lastWeekTopGifter!['total'],
            ),
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
    String refreshMessage = '';
    switch (_tabController.index) {
      case 0:
        refreshMessage = 'This ranking will refresh every day at 00:00 (GMT+5:30)';
        break;
      case 1:
        refreshMessage = 'This ranking will refresh every Sunday at 00:00 (GMT+5:30)';
        break;
      case 2:
        refreshMessage = 'This ranking will refresh at the end of every month at 00:00 (GMT+5:30)';
        break;
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.withOpacity(0.1),
                Colors.blue.withOpacity(0.1),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  refreshMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: rankings.length,
            itemBuilder: (context, index) {
              final ranking = rankings[index];
              final userDetail = ranking['userDetails'];

              return Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
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
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}