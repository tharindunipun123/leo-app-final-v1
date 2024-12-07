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
  final String language;  // Added language field

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
    required this.language,  // Added to constructor
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
      language: json['language'] ?? '',  // Added with null safety
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

  Map<String, String> _tagPhotos = {};

  Future<void> _fetchTagPhotos() async {
    try {
      final response = await http.get(
        Uri.parse('http://145.223.21.62:8090/api/collections/tags/records'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tags = data['items'] as List;
        setState(() {
          for (var tag in tags) {
            _tagPhotos[tag['tag_name']] = tag['tag_photo'];
          }
        });
      }
    } catch (e) {
      print('Error fetching tag photos: $e');
    }
  }



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadUserData();
    _fetchVoiceRooms();
    _fetchTagPhotos();
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

  Future<bool> _checkExistingRoom() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        return false;
      }

      final response = await http.get(
        Uri.parse('http://145.223.21.62:8090/api/collections/voiceRooms/records?filter=(ownerId="$userId")'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rooms = data['items'] as List;
        return rooms.isNotEmpty;
      }
      return false;
    } catch (e) {
      print('Error checking existing room: $e');
      return false;
    }
  }

  void _navigateToCreateRoom() async {
    final hasExistingRoom = await _checkExistingRoom();

    if (!mounted) return;

    if (hasExistingRoom) {
      _showErrorDialog(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateVoiceRoomPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildStatsSquares(),
                          _buildCountriesSection(),
                        ],
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          controller: _tabController,
                          tabs: _tabs.map((String name) => Tab(text: name)).toList(),
                          labelColor: Colors.blue[700],
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Colors.blue[700],
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildVoiceRoomsList(true),
                    _buildVoiceRoomsList(false),
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

  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue[50]!,
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  spreadRadius: 4,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error Icon
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: Colors.red[400],
                    size: 40,
                  ),
                ),
                SizedBox(height: 20),

                // Title
                Text(
                  'Room Already Exists',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                SizedBox(height: 12),

                // Message
                Text(
                  'You can only create one voice room at a time. Please delete your existing room before creating a new one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue[700],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 24),

                // Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[700]!, Colors.blue[500]!],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      'Got it',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoiceRoomsList(bool isDiscoverTab) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.blue));
    }

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
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToLivePage(room),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image with Gold Frame
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Color(0xFFD4AF37),  // Gold color
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: CachedNetworkImage(
                          imageUrl: 'http://145.223.21.62:8090/api/files/voiceRooms/${room.id}/${room.groupPhoto}',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              color: Colors.blue[300],
                            ),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.error,
                            color: Colors.red[300],
                          ),
                        ),
                      ),
                    ),
                    // Bronze/Silver/Gold Badge
                    Positioned(
                      bottom: -15,
                      right: -15,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Color(0xFFD4AF37),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.military_tech,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 16),

                // Room Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Room Name and ID
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  room.voiceRoomName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'ID: ${room.voiceRoomId}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Signal Strength Indicator
                          Container(
                            padding: EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.signal_cellular_alt,
                                  size: 16,
                                  color: Colors.purple,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '8',
                                  style: TextStyle(
                                    color: Colors.purple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),

                      // Team Motto
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[700]!, Colors.blue[400]!],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          room.teamMoto,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: 8),

                      // Badges Row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Country Flag Badge
                            Container(
                              margin: EdgeInsets.only(right: 8),
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'icons/flags/png/${room.voiceRoomCountry.toLowerCase()}.png',
                                    package: 'country_icons',
                                    width: 20,
                                    height: 15,
                                  ),
                                ],
                              ),
                            ),

                            // Language Badge
                            Container(
                              margin: EdgeInsets.only(right: 8),
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                room.language,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),

                            // Tags as Badges
                            ...room.tags.split(',').map((tag) {
                              final tagPhoto = _tagPhotos[tag.trim()];
                              return Container(
                                margin: EdgeInsets.only(right: 8),
                                child: tagPhoto != null
                                    ? CachedNetworkImage(
                                  imageUrl: 'http://145.223.21.62:8090/api/files/tags/${tag.trim()}/$tagPhoto',
                                  width: 30,
                                  height: 30,
                                  placeholder: (context, url) => Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                )
                                    : Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    tag.trim(),
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
    _fetchTagPhotos();
    super.dispose();
  }
}


class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
