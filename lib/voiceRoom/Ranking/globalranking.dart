import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:leo_app_01/voiceRoom/Ranking/rewards.dart';
import 'package:leo_app_01/voiceRoom/Ranking/rules.dart';
import 'TopGifter.dart';
import 'TopRecharger.dart';
import 'TopStar.dart';
import 'package:country_picker/country_picker.dart';

class TopRoomCard extends StatelessWidget {
  final Map<String, dynamic> roomDetails;
  final double totalAmount;

  const TopRoomCard({
    Key? key,
    required this.roomDetails,
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
            Color(0xFFFF8C00).withOpacity(0.95),  // Dark orange
            Color(0xFFDC143C).withOpacity(0.90),
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
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: 'http://145.223.21.62:8090/api/files/voiceRooms/${roomDetails['id']}/${roomDetails['group_photo']}',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.image_not_supported,
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
                      //Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Last Week\'s Top Room',
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
                    roomDetails['voice_room_name'] ?? 'Unknown',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    roomDetails['team_moto'] ?? '',
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


class GlobalRanking extends StatefulWidget {
  const GlobalRanking({Key? key}) : super(key: key);

  @override
  _GlobalRankingState createState() => _GlobalRankingState();
}

class _GlobalRankingState extends State<GlobalRanking> with SingleTickerProviderStateMixin {

  String refreshMessage = '';
  late TabController _timeTabController;
  String currentCategory = 'TopRooms'; // Default category
  Map<String, double> diamondAmounts = {};
  bool isLoading = true; // Holds diamond values for gifts
  Map<String, dynamic>? lastWeekTopRoom;
  //CountryFlag countryFlag = CountryFlag();

  @override
  void initState() {
    super.initState();
    _timeTabController = TabController(length: 3, vsync: this);
    _timeTabController.addListener(_handleTabChange);
    _updateRefreshMessage(); // Initialize the message
    _loadGiftDiamondAmounts();
  }


  void _handleTabChange() {
    if (_timeTabController.indexIsChanging) {
      _updateRefreshMessage();
    }
  }

  Future<void> _fetchGiftDiamondAmounts() async {
    try {
      final response = await http.get(
        Uri.parse('http://145.223.21.62:8090/api/collections/gifts/records'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;

        setState(() {
          diamondAmounts = Map.fromEntries(
            items.map((item) => MapEntry(
              item['giftname'],
              (item['diamond_amount'] as num).toDouble(),
            )),
          );
        });
      } else {
        throw Exception('Failed to fetch gift diamond amounts.');
      }
    } catch (e) {
      print('Error fetching diamond amounts: $e');
    }
  }


  String _getFlagUrl(String? countryName) {
    if (countryName == null || countryName.isEmpty) {
      return 'https://flagcdn.com/w320/xx.png'; // Fallback flag
    }

    try {
      final countryService = CountryService();
      final country = countryService.findByName(countryName);
      if (country != null) {
        return 'https://flagcdn.com/w320/${country.countryCode.toLowerCase()}.png';
      }
    } catch (e) {
      print('Error finding country code: $e');
    }
    return 'https://flagcdn.com/w320/xx.png'; // Fallback flag
  }


  Future<void> _fetchLastWeekTopRoom() async {
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

        Map<String, double> roomTotals = {};

        for (var gift in gifts) {
          final roomId = gift['voiceRoomId'];
          final giftName = gift['giftname'];
          final count = gift['gift_count'] as int;

          if (diamondAmounts.containsKey(giftName)) {
            final amount = diamondAmounts[giftName]!;
            roomTotals[roomId] = (roomTotals[roomId] ?? 0) + (count * amount);
          }
        }

        if (roomTotals.isNotEmpty) {
          var topEntry = roomTotals.entries
              .reduce((a, b) => a.value > b.value ? a : b);

          final roomResponse = await http.get(
            Uri.parse('http://145.223.21.62:8090/api/collections/voiceRooms/records/${topEntry.key}'),
          );

          if (roomResponse.statusCode == 200) {
            final roomData = json.decode(roomResponse.body);
            setState(() {
              lastWeekTopRoom = {
                'roomDetails': roomData,
                'total': topEntry.value,
              };
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching last week top room: $e');
    }
  }

  Future<void> _loadGiftDiamondAmounts() async {
    try {
      final response = await http.get(
        Uri.parse('http://145.223.21.62:8090/api/collections/gifts/records'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;

        setState(() {
          diamondAmounts = Map.fromEntries(
            items.map((gift) => MapEntry(
              gift['giftname'],
              (gift['diamond_amount'] as num).toDouble(),
            )),
          );
          isLoading = false;
        });

        await _fetchLastWeekTopRoom();
      }
    } catch (e) {
      print('Error loading gift diamond amounts: $e');
      setState(() => isLoading = false);
    }
  }


  Future<List<Map<String, dynamic>>> fetchTopRooms(String timeframe) async {
    if (isLoading) {
      return [];
    }

    try {
      // Set timeframe filter
      final now = DateTime.now();
      final DateTime filterDate = switch(timeframe) {
        'Daily' => DateTime(now.year, now.month, now.day),
        'Weekly' => now.subtract(Duration(days: 7)),
        'Monthly' => now.subtract(Duration(days: 30)),
        _ => throw Exception('Invalid timeframe'),
      };

      // Fetch all gifts with their sending info
      final response = await http.get(
        Uri.parse('http://145.223.21.62:8090/api/collections/sending_recieving_gifts/records'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch gift records');
      }

      final data = json.decode(response.body);
      final gifts = data['items'] as List;

      // Calculate room totals
      Map<String, double> roomTotals = {};
      for (var gift in gifts) {
        final giftDate = DateTime.parse(gift['created']);
        if (giftDate.isAfter(filterDate)) {
          final roomId = gift['voiceRoomId'];
          final giftName = gift['giftname'];
          final count = gift['gift_count'] as int;
          final diamondAmount = diamondAmounts[giftName] ?? 0.0;

          roomTotals[roomId] = (roomTotals[roomId] ?? 0.0) + (count * diamondAmount);
        }
      }

      // Get room details for top rooms
      List<Map<String, dynamic>> rankedRooms = [];
      for (var entry in roomTotals.entries) {
        final roomResponse = await http.get(
          Uri.parse('http://145.223.21.62:8090/api/collections/voiceRooms/records/${entry.key}'),
        );

        if (roomResponse.statusCode == 200) {
          final roomData = json.decode(roomResponse.body);
          rankedRooms.add({
            'roomDetails': roomData,
            'totalDiamonds': entry.value,
          });
        }
      }

      // Sort and take top 100
      rankedRooms.sort((a, b) =>
          b['totalDiamonds'].compareTo(a['totalDiamonds'])
      );
      return rankedRooms.take(100).toList();

    } catch (e) {
      print('Error fetching top rooms: $e');
      return [];
    }
  }

  Widget _buildTimeMessage() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withOpacity(0.1),
            Colors.red.withOpacity(0.1),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Text(
        refreshMessage,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildRankingList(String timeFrame) {

    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchTopRooms(timeFrame),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading rankings',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        final rooms = snapshot.data ?? [];
        if (rooms.isEmpty) {
          return Center(
            child: Text(
              'No rankings available for this period',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index]['roomDetails'];
            final diamonds = rooms[index]['totalDiamonds'];
            final countryCode = room['voiceRoom_country'].toString().toLowerCase();

            return Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  // Rank number/medal
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

                  // Room image
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                      image: DecorationImage(
                        image: NetworkImage(
                            'http://145.223.21.62:8090/api/files/voiceRooms/${room['id']}/${room['group_photo']}'
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  SizedBox(width: 12),

                  // Room details
                  // Room details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room['voice_room_name'] ?? 'Unnamed Room', // Add null check with default value
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 16,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 0.5,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: CachedNetworkImage(
                                imageUrl: _getFlagUrl(room['voiceRoom_country']),
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[100],
                                  child: Icon(
                                    Icons.flag_outlined,
                                    size: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                room['team_moto'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
                        '${diamonds.toStringAsFixed(0)}',
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
      },
    );
  }

  Widget _buildSelectedCategory() {
    switch (currentCategory) {
      case 'TopRooms':
        return Column(
          children: [
            _buildTimeMessage(),
            Expanded(
              child: TabBarView(
                controller: _timeTabController,
                children: [
                  _buildRankingList('Daily'),
                  _buildRankingList('Weekly'),
                  _buildRankingList('Monthly'),
                ],
              ),
            ),
          ],
        );
      case 'TopGifters':
        return RankingBottomSheet();
      case 'TopStars':
        return Topstar();
      case 'Billionaires':
        return RechargeRankings();
      default:
        return Center(
          child: Text(
            'Category not found',
            style: TextStyle(color: Colors.grey[600]),
          ),
        );
    }
  }

  Widget _buildTabBar() {
    return Container(
      child: TabBar(
        controller: _timeTabController,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: 'Today'),
          Tab(text: 'This Week'),
          Tab(text: 'This Month'),
        ],
      ),
    );
  }



  void _updateRefreshMessage() {
    setState(() {
      switch (_timeTabController.index) {
        case 0:
          refreshMessage = 'This ranking will refresh every day at 00:00 (GMT+5:30)';
          break;
        case 1:
          refreshMessage = 'This ranking will refresh every Sunday at 00:00 (GMT+5:30)';
          break;
        case 2:
          refreshMessage = 'This ranking will refresh at the end of every month (GMT+5:30)';
          break;
      }
    });
  }

  Widget _buildCategoryButton(String title, List<Color> gradientColors, String category) {
    bool isSelected = currentCategory == category;

    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: () {
          setState(() {
            currentCategory = category;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 18 : 15,
            vertical: isSelected ? 10 : 8,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ] : [],
          ),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: isSelected ? 14 : 12,
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ranking',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'rewards') {
                showRankingRewardPopup(context);
              } else if (value == 'rules') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RulesPage()),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'rewards',
                child: Text('Rewards'),
              ),
              const PopupMenuItem<String>(
                value: 'rules',
                child: Text('Rules'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category buttons row
          Container(
            height: 60,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCategoryButton(
                    'Top Rooms',
                    [
                      const Color(0xFFFF8C00).withOpacity(0.95),
                      const Color(0xFFDC143C).withOpacity(0.90),
                    ],
                    'TopRooms',
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryButton(
                    'Top Gifters',
                    [
                      const Color(0xFF9370DB).withOpacity(0.95),
                      const Color(0xFF4B0082).withOpacity(0.90),
                    ],
                    'TopGifters',
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryButton(
                    'Top Stars',
                    [
                      const Color(0xFF3CB371).withOpacity(0.95),
                      const Color(0xFF006400).withOpacity(0.90),
                    ],
                    'TopStars',
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryButton(
                    'Top Recharger',
                    [
                      const Color(0xFF4682B4).withOpacity(0.95),
                      const Color(0xFF0000CD).withOpacity(0.90),
                    ],
                    'Billionaires',
                  ),
                ],
              ),
            ),
          ),

          // Top Room Card
          if (currentCategory == 'TopRooms' && lastWeekTopRoom != null)
            TopRoomCard(
              roomDetails: lastWeekTopRoom!['roomDetails'],
              totalAmount: lastWeekTopRoom!['total'],
            ),

          // TabBar for TopRooms category
          if (currentCategory == 'TopRooms')
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _timeTabController,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                labelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                tabs: const [
                  Tab(text: 'Today'),
                  Tab(text: 'This Week'),
                  Tab(text: 'This Month'),
                ],
              ),
            ),

          // Loading indicator
          if (isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          // Content area
          else
            Expanded(
              child: _buildSelectedCategory(),
            ),
        ],
      ),
    );
  }

  // Show the popup with a smooth fade animation
  void showRankingRewardPopup(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) => const RankingRewardPopup(),
      transitionBuilder: (context, animation1, animation2, child) {
        return FadeTransition(
          opacity: animation1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation1, curve: Curves.easeOutQuad),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timeTabController.dispose();
    super.dispose();
  }
}