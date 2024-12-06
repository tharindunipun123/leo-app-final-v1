import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'live_page.dart';
import 'voiceRoomCreate.dart';
import 'package:country_icons/country_icons.dart';
import 'package:country_picker/country_picker.dart';

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

  String? _selectedCountry;
  bool _showCountryDialog = false;
  TextEditingController _countrySearchController = TextEditingController();

  bool _isSearchingById = false;
  TextEditingController _roomIdController = TextEditingController();

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

  List<VoiceRoom> get filteredRoomsByCountry {
    var rooms = filteredRooms;

    // Filter by country if selected
    if (_selectedCountry != null) {
      rooms = rooms.where((room) {
        return room.voiceRoomCountry.toLowerCase() == _selectedCountry!.toLowerCase();
      }).toList();
    }

    // Filter by room ID if searching
    if (_isSearchingById && _roomIdController.text.isNotEmpty) {
      rooms = rooms.where((room) {
        return room.voiceRoomId.toString().contains(_roomIdController.text);
      }).toList();
    }

    return rooms;
  }

  List<VoiceRoom> get filteredRooms {
    return _voiceRooms.where((room) {
      final query = _searchQuery.toLowerCase();
      return room.voiceRoomName.toLowerCase().contains(query) ||
          room.voiceRoomId.toString().toLowerCase().contains(query);
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildStatsSquares(),
                    _buildCountriesSection(),
                    TabBar(
                      controller: _tabController,
                      tabs: _tabs.map((String name) => Tab(text: name)).toList(),
                      labelColor: Colors.blue[700],
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blue[700],
                    ),
                    Container(
                      height: MediaQuery.of(context).size.height - 350, // Adjust this value as needed
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.lightBlue[50],
      child: Row(
        children: [
          Expanded(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              child: TextField(
                controller: _searchController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search by room name or ID...',
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
            ),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: _navigateToCreateRoom,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
        ],
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

  Widget _buildVoiceRoomsList(bool isDiscoverTab) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.blue));
    }

    return Column(
      children: [
        if (isDiscoverTab)
        Expanded(
          child: Builder(
            builder: (context) {
              final roomsToShow = isDiscoverTab
                  ? filteredRoomsByCountry
                  : filteredRooms.where((room) => room.ownerId == _userId).toList();

              if (roomsToShow.isEmpty) {
                return Center(
                  child: Text(
                    _getEmptyMessage(isDiscoverTab),
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: roomsToShow.length,
                itemBuilder: (context, index) => _buildRoomCard(roomsToShow[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getEmptyMessage(bool isDiscoverTab) {
    if (isDiscoverTab) {
      if (_isSearchingById) {
        return 'No rooms found with this ID';
      } else if (_selectedCountry != null) {
        return 'No rooms found in ${_selectedCountry}';
      }
      return 'No voice rooms found';
    }
    return 'You haven\'t created any rooms yet';
  }

  Widget _buildStatsSquares() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Family Square - Turquoise to Mint gradient
          Expanded(
            child: Container(
              height: 100,
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF40E0D0),  // Turquoise
                    Color(0xFF48F3D1),  // Mint
                  ],
                  stops: [0.2, 0.9],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF40E0D0).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.family_restroom, color: Colors.white, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Family',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Rank Square - Golden Sunset gradient
          Expanded(
            child: Container(
              height: 100,
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFB347),  // Light Orange
                    Color(0xFFFFE5B4),  // Peach
                  ],
                  stops: [0.2, 0.9],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFFB347).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.workspace_premium, color: Colors.white, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Rank',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Couple Square - Soft Rose gradient
          Expanded(
            child: Container(
              height: 100,
              margin: EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF6B95),  // Rose Pink
                    Color(0xFFFFB6C1),  // Light Pink
                  ],
                  stops: [0.2, 0.9],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF6B95).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, color: Colors.white, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Couple',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popular Countries',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_selectedCountry != null)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCountry = null;
                    });
                  },
                  child: Text(
                    'Clear Filter',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // First Row of Countries
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _countries.take(5).map((country) => _buildCountryItem(country)).toList(),
          ),
        ),
        SizedBox(height: 12),
        // Second Row of Countries
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ..._countries.skip(5).take(4).map((country) => _buildCountryItem(country)).toList(),
              // More button
              GestureDetector(
                onTap: _showCountryPicker,
                child: Container(
                  width: 60,
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.more_horiz, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'More',
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCountryItem(Map<String, String> country) {
    final isSelected = _selectedCountry == country['name'];
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCountry = isSelected ? null : country['name'];
        });
      },
      child: Container(
        width: 45, // Reduced width
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey.shade300,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(25), // More oval shape
                color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      country['flag']!,
                      width: 24, // Smaller flag
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4),
            Text(
              country['name']!,
              style: TextStyle(
                fontSize: 10, // Smaller text
                color: isSelected ? Colors.blue : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showCountrySearchDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final filteredCountries = _countries.where((country) {
            return country['name']!.toLowerCase()
                .contains(_countrySearchController.text.toLowerCase());
          }).toList();

          return AlertDialog(
            title: Text('Select Country'),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _countrySearchController,
                    decoration: InputDecoration(
                      hintText: 'Search country...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 300,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = filteredCountries[index];
                        return ListTile(
                          leading: Image.network(
                            country['flag']!,
                            width: 24,
                            height: 24,
                          ),
                          title: Text(country['name']!),
                          onTap: () {
                            this.setState(() {
                              _selectedCountry = country['name'];
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      countryListTheme: CountryListThemeData(
        flagSize: 25,
        backgroundColor: Colors.white,
        textStyle: TextStyle(fontSize: 16, color: Colors.black),
        bottomSheetHeight: 500,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        inputDecoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Start typing to search',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country.name;
        });
      },
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

  //
  // Widget _buildDiscoverHeader() {
  //   return Container(
  //     padding: EdgeInsets.all(16),
  //     child: Row(
  //       children: [
  //         Expanded(
  //           child: TextField(
  //             controller: _roomIdController,
  //             keyboardType: TextInputType.number,
  //             decoration: InputDecoration(
  //               hintText: 'Search by Room ID...',
  //               prefixIcon: Icon(Icons.search),
  //               filled: true,
  //               fillColor: Colors.grey[100],
  //               border: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(30),
  //                 borderSide: BorderSide.none,
  //               ),
  //             ),
  //             onChanged: (value) {
  //               setState(() {
  //                 _isSearchingById = value.isNotEmpty;
  //               });
  //             },
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }


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