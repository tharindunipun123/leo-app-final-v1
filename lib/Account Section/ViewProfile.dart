import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileViewScreen extends StatefulWidget {
  final String userId;

  const ProfileViewScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  final String _baseUrl = 'http://145.223.21.62:8090';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/collections/users/records/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _userData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load profile')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    if (_userData == null) {
      return const Center(child: Text('No data available'));
    }

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //_buildUserInfo(),
                const SizedBox(height: 24),
                _buildBadgesSection(),
                const SizedBox(height: 24),
                _buildGiftsSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _userData?['avatar'] != null
                ? Image.network(
                    '$_baseUrl/api/files/${_userData!['collectionId']}/${_userData!['id']}/${_userData!['avatar']}',
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.person, size: 100, color: Colors.white),
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_userData?['firstname'] ?? ''} ${_userData?['lastname'] ?? ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_userData?['moto'] != null)
                    Text(
                      _userData!['moto'],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
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



  Widget _buildBadgesSection() {
    final List badges = _userData?['badges'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Badges',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        badges.isEmpty
            ? const Text('No badges earned yet')
            : SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: badges.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            '$_baseUrl/api/files/${_userData!['collectionId']}/${_userData!['id']}/${badges[index]}',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildGiftsSection() {
    final List gifts = _userData?['gift'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Received Gifts',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        gifts.isEmpty
            ? const Text('No gifts received yet')
            : GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: gifts.length,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        '$_baseUrl/api/files/${_userData!['collectionId']}/${_userData!['id']}/${gifts[index]}',
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}