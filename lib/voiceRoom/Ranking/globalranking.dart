import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'TopGifter.dart';

class GlobalRanking extends StatefulWidget {
  const GlobalRanking({Key? key}) : super(key: key);

  @override
  _GlobalRankingState createState() => _GlobalRankingState();
}

class _GlobalRankingState extends State<GlobalRanking> with SingleTickerProviderStateMixin {
  late TabController _timeTabController;
  String currentCategory = 'TopRooms'; // Default category
  Map<String, double> diamondAmounts = {};
  bool isLoading = true; // Holds diamond values for gifts

  @override
  void initState() {
    super.initState();
    _timeTabController = TabController(length: 3, vsync: this);
    _loadGiftDiamondAmounts();
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room['voice_room_name'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Row(
                          children: [
                            Image.network(
                              'https://flagcdn.com/w320/$countryCode.png',
                              width: 20,
                              height: 12,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.flag, size: 16, color: Colors.grey),
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
        return TabBarView(
          controller: _timeTabController,
          children: [
            _buildRankingList('Daily'),
            _buildRankingList('Weekly'),
            _buildRankingList('Monthly'),
          ],
        );
      case 'TopGifters':
        return RankingBottomSheet();  // Just return the widget directly
      default:
        return TabBarView(
          controller: _timeTabController,
          children: [
            _buildRankingList('Daily'),
            _buildRankingList('Weekly'),
            _buildRankingList('Monthly'),
          ],
        );
    }
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
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Ranking'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Category buttons row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCategoryButton(
                  'Top Rooms',
                  [Color(0xFFFFB347), Color(0xFFFF7F50)],
                  'TopRooms',
                ),
                SizedBox(width: 8),
                _buildCategoryButton(
                  'Top Gifters',
                  [Color(0xFFFF69B4), Color(0xFFDA70D6)],
                  'TopGifters',
                ),
                SizedBox(width: 8),
                _buildCategoryButton(
                  'Top Stars',
                  [Color(0xFF90EE90), Color(0xFF32CD32)],
                  'TopStars',
                ),
                SizedBox(width: 8),
                _buildCategoryButton(
                  'Billionaires',
                  [Color(0xFF87CEEB), Color(0xFF4169E1)],
                  'Billionaires',
                ),
              ],
            ),
          ),

          // Only show TabBar for TopRooms category
          if (currentCategory == 'TopRooms')
            Container(
              child: TabBar(
                controller: _timeTabController,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: 'Today'),
                  Tab(text: 'This Week'),
                  Tab(text: 'This Month'),
                ],
              ),
            ),

          // Content area
          Expanded(
            child: _buildSelectedCategory(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timeTabController.dispose();
    super.dispose();
  }
}
