import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TopRechargerCard extends StatelessWidget {
  final Map<String, dynamic> userDetails;
  final double totalAmount;

  const TopRechargerCard({
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
            Color(0xFF4682B4).withOpacity(0.95),  // Steel blue
            Color(0xFF0000CD).withOpacity(0.90), // Royal blue
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
            // Profile Image Section
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: CachedNetworkImage(
                  imageUrl: 'http://145.223.21.62:8090/api/files/${userDetails['collectionId']}/${userDetails['id']}/${userDetails['avatar']}',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),

            // User Details Section
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
                        'Last Week\'s Champion',
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
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black.withOpacity(0.2),
                        ),
                      ],
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

            // Amount Section
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
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black.withOpacity(0.2),
                        ),
                      ],
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

class RechargeRankings extends StatefulWidget {
  @override
  _RechargeRankingsState createState() => _RechargeRankingsState();
}

class _RechargeRankingsState extends State<RechargeRankings>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;
  List<Map<String, dynamic>> dailyRankings = [];
  List<Map<String, dynamic>> weeklyRankings = [];
  List<Map<String, dynamic>> monthlyRankings = [];
  Map<String, dynamic> userDetails = {};
  Map<String, dynamic>? lastWeekTopRecharger;

  // Modified cache mechanism with separate caches
  static Map<String, List<Map<String, dynamic>>> _rankingsCache = {};
  static Map<String, DateTime> _lastFetchTime = {};
  static const cacheDuration = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadAllData();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        lastWeekTopRecharger = null; // Clear the last week's champion
      });
      _loadAllData();
    }
  }

  bool _isCacheValid(String key) {
    final lastFetch = _lastFetchTime[key];
    if (lastFetch == null) return false;
    return DateTime.now().difference(lastFetch) < cacheDuration;
  }

  Future<void> _loadAllData() async {
    setState(() => isLoading = true);

    try {
      // Always fetch last week's top recharger first
      await _fetchLastWeekTopRecharger();

      // Then fetch the rankings if cache is invalid
      if (!_isCacheValid('rankings')) {
        await _fetchRechargeHistory();
        _lastFetchTime['rankings'] = DateTime.now();
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }
  Future<bool> _verifyBillionaireBadge(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('http://145.223.21.62:8090/api/collections/recieved_badges/records?filter=userId="${userId}"&fields=batch_name'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;

        // Check if user has billionaire badge
        bool hasBillionairBadge = items.any((item) => item['batch_name'] == 'billionair');

        if (!hasBillionairBadge) {
          // Create the badge if not found
          final createResponse = await http.post(
            Uri.parse('http://145.223.21.62:8090/api/collections/recieved_badges/records'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'userId': userId,
              'batch_name': 'billionair',
              'created': DateTime.now().toIso8601String(),
              'updated': DateTime.now().toIso8601String(),
            }),
          );

          if (createResponse.statusCode == 200) {
            print('Created billionaire badge for user: $userId');
            return true;
          } else {
            print('Failed to create billionaire badge: ${createResponse.statusCode}');
            return false;
          }
        }

        return hasBillionairBadge;
      }
    } catch (e) {
      print('Error verifying billionaire badge: $e');
    }
    return false;
  }

  Future<bool> _createBillionaireBadgeIfNeeded(String userId) async {
    try {
      // First check if badge already exists
      final response = await http.get(
        Uri.parse('http://145.223.21.62:8090/api/collections/recieved_badges/records/$userId'),
      );

      if (response.statusCode == 404) {
        // Badge doesn't exist, create it
        final createResponse = await http.post(
          Uri.parse('http://145.223.21.62:8090/api/collections/recieved_badges/records'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'userId': userId,
            'batch_name': 'billionair',
          }),
        );

        return createResponse.statusCode == 200;
      }

      return response.statusCode == 200;
    } catch (e) {
      print('Error creating billionaire badge: $e');
      return false;
    }
  }

  Future<void> _fetchLastWeekTopRecharger() async {
    try {
      final now = DateTime.now();
      final lastWeekStart = now.subtract(Duration(days: 14));
      final lastWeekEnd = now.subtract(Duration(days: 7));

      final encodedFilter = Uri.encodeComponent(
          'created >= "${lastWeekStart.toIso8601String()}" && created < "${lastWeekEnd.toIso8601String()}"'
      );

      final response = await http.get(
        Uri.parse(
            'http://145.223.21.62:8090/api/collections/recharge_history/records'
                '?filter=$encodedFilter'
                '&perPage=500'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;

        if (items.isNotEmpty) {
          Map<String, double> userTotals = {};

          for (var recharge in items) {
            final userId = recharge['userId'];
            final amount = (recharge['diamond_amount'] as num).toDouble();
            userTotals[userId] = (userTotals[userId] ?? 0) + amount;
          }

          var topEntry = userTotals.entries
              .reduce((a, b) => a.value > b.value ? a : b);

          // Always verify/create badge for top recharger
          await _verifyBillionaireBadge(topEntry.key);

          final userResponse = await http.get(
            Uri.parse('http://145.223.21.62:8090/api/collections/users/records/${topEntry.key}'),
          );

          if (userResponse.statusCode == 200) {
            final userData = json.decode(userResponse.body);
            setState(() {
              lastWeekTopRecharger = {
                'userDetails': userData,
                'total': topEntry.value,
              };
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching last week top recharger: $e');
    }
  }

  Future<void> _fetchUserDetailsInBatches(Set<String> userIds) async {
    final batches = <List<String>>[];
    final batchSize = 20;
    final ids = userIds.toList();

    for (var i = 0; i < ids.length; i += batchSize) {
      batches.add(ids.skip(i).take(batchSize).toList());
    }

    await Future.wait(
      batches.map((batch) async {
        await Future.wait(
          batch.map((userId) async {
            if (userDetails.containsKey(userId)) return;

            try {
              final response = await http.get(
                Uri.parse('http://145.223.21.62:8090/api/collections/users/records/$userId'),
              );

              if (response.statusCode == 200) {
                final userData = json.decode(response.body);
                userDetails[userId] = userData;
              }
            } catch (e) {
              print('Error fetching user $userId: $e');
            }
          }),
        );
      }),
    );
  }

  Future<List<dynamic>> _fetchAllPagesOptimized() async {
    final futures = <Future<List<dynamic>>>[];
    final perPage = 500;

    final initialResponse = await http.get(
      Uri.parse('http://145.223.21.62:8090/api/collections/recharge_history/records?page=1&perPage=$perPage'),
    );

    if (initialResponse.statusCode != 200) return [];

    final initialData = json.decode(initialResponse.body);
    final totalPages = initialData['totalPages'] as int;

    for (var page = 1; page <= totalPages; page++) {
      futures.add(
        http.get(Uri.parse(
            'http://145.223.21.62:8090/api/collections/recharge_history/records?page=$page&perPage=$perPage'
        )).then((response) {
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            return data['items'] as List;
          }
          return <dynamic>[];
        }),
      );
    }

    final results = await Future.wait(futures);
    return results.expand((items) => items).toList();
  }

  Future<void> _fetchRechargeHistory() async {
    try {
      final recharges = await _fetchAllPagesOptimized();
      final rankings = await compute(_calculateAllRankings, recharges);

      final allUserIds = <String>{};
      rankings.values.forEach((rankingList) {
        rankingList.forEach((ranking) {
          allUserIds.add(ranking['userId'] as String);
        });
      });

      await _fetchUserDetailsInBatches(allUserIds);

      void addUserDetailsToRankings(List<Map<String, dynamic>> rankings) {
        for (var ranking in rankings) {
          ranking['userDetails'] = userDetails[ranking['userId']];
        }
      }

      addUserDetailsToRankings(rankings['daily']!);
      addUserDetailsToRankings(rankings['weekly']!);
      addUserDetailsToRankings(rankings['monthly']!);

      setState(() {
        dailyRankings = rankings['daily']!;
        weeklyRankings = rankings['weekly']!;
        monthlyRankings = rankings['monthly']!;
      });
    } catch (e) {
      print('Error in _fetchRechargeHistory: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (lastWeekTopRecharger != null)
          TopRechargerCard(
            userDetails: lastWeekTopRecharger!['userDetails'],
            totalAmount: lastWeekTopRecharger!['total'],
          ),
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
        Expanded(
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : TabBarView(
            controller: _tabController,
            children: [
              _buildRankingList(dailyRankings),
              _buildRankingList(weeklyRankings),
              _buildRankingList(monthlyRankings),
            ],
          ),
        ),
      ],
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

              if (userDetail == null) return SizedBox.shrink();

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
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: CachedNetworkImage(
                          imageUrl: 'http://145.223.21.62:8090/api/files/${userDetail['collectionId']}/${userDetail['id']}/${userDetail['avatar']}',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.person,
                            color: Colors.grey[400],
                          ),
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

// Isolate function for calculating rankings
Map<String, List<Map<String, dynamic>>> _calculateAllRankings(List<dynamic> recharges) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(Duration(days: 1));
  final weekAgo = now.subtract(Duration(days: 7));
  final monthStart = DateTime(now.year, now.month, 1);
  final nextMonth = DateTime(now.year, now.month + 1, 1);

  List<Map<String, dynamic>> calculatePeriodRankings(
      bool Function(DateTime) dateFilter,
      ) {
    Map<String, double> userTotals = {};

    for (var recharge in recharges) {
      final rechargeDate = DateTime.parse(recharge['created']);
      if (!dateFilter(rechargeDate)) continue;

      final userId = recharge['userId'];
      final amount = (recharge['diamond_amount'] as num).toDouble();
      userTotals[userId] = (userTotals[userId] ?? 0) + amount;
    }

    return userTotals.entries
        .map((e) => {'userId': e.key, 'total': e.value})
        .toList()
      ..sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));
  }

  return {
    'daily': calculatePeriodRankings(
          (date) => date.isAfter(today) && date.isBefore(tomorrow),
    ),
    'weekly': calculatePeriodRankings(
          (date) => date.isAfter(weekAgo) && date.isBefore(tomorrow),
    ),
    'monthly': calculatePeriodRankings(
          (date) => date.isAfter(monthStart) && date.isBefore(nextMonth),
    ),
  };
}