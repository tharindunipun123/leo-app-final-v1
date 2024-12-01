import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'live_page.dart';
import 'voiceRoomCreate.dart';
import 'package:country_icons/country_icons.dart';

class VoiceRoom {
  final String id;
  final String voiceRoomName;
  final int voiceRoomId;
  final String ownerId;
  final String voiceRoomCountry;
  final String teamMoto;
  final String groupPhoto;
  final String tags;
  final String backgroundImages;

  VoiceRoom({
    required this.id,
    required this.voiceRoomName,
    required this.voiceRoomId,
    required this.ownerId,
    required this.voiceRoomCountry,
    required this.teamMoto,
    required this.groupPhoto,
    required this.tags,
    required this.backgroundImages,
  });

  factory VoiceRoom.fromJson(Map<String, dynamic> json) {
    return VoiceRoom(
      id: json['id'],
      voiceRoomName: json['voice_room_name'],
      voiceRoomId: json['voiceRoom_id'],
      ownerId: json['ownerId'],
      voiceRoomCountry: json['voiceRoom_country'],
      teamMoto: json['team_moto'],
      groupPhoto: json['group_photo'],
      tags: json['tags'],
      backgroundImages: json['background_images'],
    );
  }
}

class GroupsScreen extends StatefulWidget {
  @override
  _GroupsScreenState createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ["Discover", "Mine"];
  List<VoiceRoom> _voiceRooms = [];
  String? _userId;
  String? _username;
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, String>> _countries = [
    {'name': 'Sri Lanka', 'flag': 'https://flagcdn.com/w320/lk.png'},
    {'name': 'USA', 'flag': 'https://flagcdn.com/w320/us.png'},
    {'name': 'UK', 'flag': 'https://flagcdn.com/w320/gb.png'},
    {'name': 'Philippines', 'flag': 'https://flagcdn.com/w320/ph.png'},
    {'name': 'Australia', 'flag': 'https://flagcdn.com/w320/au.png'},
    {'name': 'Albania', 'flag': 'https://flagcdn.com/w320/al.png'},
    {'name': 'India', 'flag': 'https://flagcdn.com/w320/in.png'},
    {'name': 'Pakistan', 'flag': 'https://flagcdn.com/w320/pk.png'},
    {'name': 'Bangladesh', 'flag': 'https://flagcdn.com/w320/bd.png'},
  ];


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadUserData();
    _fetchVoiceRooms();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  List<VoiceRoom> get filteredRooms {
    return _voiceRooms.where((room) {
      return room.voiceRoomName.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId');
      _username = prefs.getString('firstName');
    });
  }

  Future<void> _fetchVoiceRooms() async {
    try {
      final response = await http.get(
        Uri.parse('http://145.223.21.62:8090/api/collections/voiceRooms/records'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;
        setState(() {
          _voiceRooms = items.map((item) => VoiceRoom.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching voice rooms: $e');
      setState(() => _isLoading = false);
    }
  }

  void _navigateToCreateRoom() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateVoiceRoomPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildAdvertBanner(),
            _buildCountriesSection(),
            TabBar(
              controller: _tabController,
              tabs: _tabs.map((String name) => Tab(text: name)).toList(),
              labelColor: Colors.blue[700],
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue[700],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVoiceRoomsList(true),
                  _buildVoiceRoomsList(false),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateRoom,
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.lightBlue[50],
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search voice rooms...',
          prefixIcon: Icon(Icons.search, color: Colors.blue),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildAdvertBanner() {
    return Container(
      height: 100,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage('https://www.perfectly-nintendo.com/wp-content/uploads/2024/07/Battle-Crush.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildCountriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Recommend Country',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(), // Prevent scrolling within the grid
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5, // 5 columns
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1, // Square items
          ),
          itemCount: _countries.length + 1, // Add one for the "All" button
          itemBuilder: (context, index) {
            if (index < _countries.length) {
              final country = _countries[index];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50), // Circular flag
                    child: Image.network(
                      country['flag']!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    country['name']!,
                    style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            } else {
              // "All" button
              return GestureDetector(
                onTap: () {
                  // Handle "View More Countries" action
                  print('View More Countries tapped');
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(Icons.more_horiz, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'All',
                      style: TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ],
    );
  }


  Widget _buildVoiceRoomsList(bool isMineTab) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.blue));
    }

    final roomsToShow = isMineTab
        ? filteredRooms.where((room) => room.ownerId == _userId).toList()
        : filteredRooms;

    if (roomsToShow.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? 'No voice rooms found'
              : 'No matching voice rooms found',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: roomsToShow.length,
      itemBuilder: (context, index) => _buildRoomCard(roomsToShow[index]),
    );
  }

  Widget _buildRoomCard(VoiceRoom room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToLivePage(room),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Group Photo on the left
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl:
                  'http://145.223.21.62:8090/api/files/voiceRooms/${room.id}/${room.groupPhoto}',
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[200],
                    child: const Center(
                        child: CircularProgressIndicator(color: Colors.blue)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[200],
                    child: const Icon(Icons.error, color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(width: 12), // Space between image and text
              // Details and Country Flag
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Voice Room Name
                    Text(
                      room.voiceRoomName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // ID
                    Text(
                      'ID: ${room.voiceRoomId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Team Moto in Gradient Container
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.blueAccent, Colors.lightBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(12),
                          right: Radius.circular(12),
                        ), // Rounded sides
                      ),
                      child: Text(
                        room.teamMoto,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Country with Flag on the Right
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Country Flag using country_icons
                  Image.asset(
                    'icons/flags/png/${room.voiceRoomCountry.toLowerCase()}.png',
                    package: 'country_icons',
                    width: 30,
                    height: 20,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.flag, size: 20, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    room.voiceRoomCountry,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildTags(String tags) {
    final tagsList = tags.split(',');
    return Row(
      children: tagsList.map((tag) => Container(
        margin: EdgeInsets.only(left: 4),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.lightBlue[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          tag.trim(),
          style: TextStyle(fontSize: 12, color: Colors.blue[700]),
        ),
      )).toList(),
    );
  }

  void _navigateToLivePage(VoiceRoom room) {
    final isHost = room.ownerId == _userId;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LivePage(
          roomID: room.id,
          isHost: isHost,
          username1: _username ?? '',
          userId: _userId!,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}