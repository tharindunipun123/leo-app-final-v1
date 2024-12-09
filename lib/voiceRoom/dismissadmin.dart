import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';

class DismissAdminScreen extends StatefulWidget {
  final String voiceRoomId;

  const DismissAdminScreen({Key? key, required this.voiceRoomId}) : super(key: key);

  @override
  _DismissAdminScreenState createState() => _DismissAdminScreenState();
}

class _DismissAdminScreenState extends State<DismissAdminScreen> {
  final String baseUrl = 'http://145.223.21.62:8090';
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> adminList = [];
  List<Map<String, dynamic>> filteredAdmins = [];
  Set<String> selectedAdminIds = {};
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
  }

  Future<void> _fetchAdmins() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Fetch all admins for this voice room
      final response = await http.get(
        Uri.parse('$baseUrl/api/collections/joined_users/records?filter=(voice_room_id="${widget.voiceRoomId}" && admin_or_not=true)'),
      );

      if (response.statusCode != 200) throw Exception('Failed to fetch admin list');

      final joinedAdmins = json.decode(response.body)['items'] as List;
      List<Map<String, dynamic>> adminDetails = [];

      // Fetch detailed profile for each admin
      for (var admin in joinedAdmins) {
        final userResponse = await http.get(
          Uri.parse('$baseUrl/api/collections/users/records/${admin['userid']}?fields=id,firstname,lastname,avatar,bio,collectionId'),
        );

        if (userResponse.statusCode == 200) {
          final userData = json.decode(userResponse.body);
          adminDetails.add({
            ...userData,
            'joinedId': admin['id'],
            'userid': admin['userid'],
            'avatarUrl': userData['avatar'] != null
                ? '$baseUrl/api/files/${userData['collectionId']}/${userData['id']}/${userData['avatar']}'
                : null,
          });
        }
      }

      setState(() {
        adminList = adminDetails;
        filteredAdmins = List.from(adminDetails);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load admin list';
        isLoading = false;
      });
    }
  }

  void _filterAdmins(String query) {
    setState(() {
      filteredAdmins = adminList.where((admin) {
        final name = '${admin['firstname']} ${admin['lastname']}'.toLowerCase();
        final userId = admin['userid'].toString().toLowerCase();
        final searchQuery = query.toLowerCase();
        return name.contains(searchQuery) || userId.contains(searchQuery);
      }).toList();
    });
  }

  Future<void> _dismissSelectedAdmins() async {
    if (selectedAdminIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one admin to dismiss'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Dismissing admins...'),
            ],
          ),
        ),
      );

      // Process each selected admin
      for (String adminId in selectedAdminIds) {
        final admin = adminList.firstWhere((a) => a['userid'] == adminId);

        final response = await http.patch(
          Uri.parse('$baseUrl/api/collections/joined_users/records/${admin['joinedId']}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'admin_or_not': false}),
        );

        if (response.statusCode != 200) {
          throw Exception('Failed to dismiss admin: $adminId');
        }
      }

      // Close loading dialog and return to previous screen
      Navigator.of(context)
        ..pop() // Close loading dialog
        ..pop(); // Return to previous screen

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully dismissed ${selectedAdminIds.length} admin(s)'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to dismiss admins. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAdminCard(Map<String, dynamic> admin) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        value: selectedAdminIds.contains(admin['userid']),
        onChanged: (bool? value) {
          setState(() {
            if (value == true) {
              selectedAdminIds.add(admin['userid']);
            } else {
              selectedAdminIds.remove(admin['userid']);
            }
          });
        },
        secondary: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[200],
          backgroundImage: admin['avatarUrl'] != null
              ? CachedNetworkImageProvider(admin['avatarUrl'])
              : null,
          child: admin['avatarUrl'] == null
              ? Icon(Icons.person, color: Colors.grey[400])
              : null,
        ),
        title: Text(
          '${admin['firstname'] ?? ''} ${admin['lastname'] ?? ''}'.trim(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: ${admin['userid']}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            if (admin['bio'] != null && admin['bio'].toString().isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  admin['bio'],
                  style: TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Dismiss Admins',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search admins...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _filterAdmins,
            ),
          ),

          // Admin list
          Expanded(
            child: isLoading ? Center(
              child: CircularProgressIndicator(),
            ) : error != null ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(error!, style: TextStyle(color: Colors.red)),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchAdmins,
                    child: Text('Retry'),
                  ),
                ],
              ),
            ) : filteredAdmins.isEmpty ? Center(
              child: Text(
                searchController.text.isEmpty
                    ? 'No admins found'
                    : 'No matching admins found',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ) : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: filteredAdmins.length,
              itemBuilder: (context, index) => _buildAdminCard(filteredAdmins[index]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: Offset(0, -2),
              blurRadius: 6,
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: selectedAdminIds.isEmpty ? null : _dismissSelectedAdmins,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              selectedAdminIds.isEmpty
                  ? 'Select Admins to Dismiss'
                  : 'Dismiss ${selectedAdminIds.length} Admin${selectedAdminIds.length > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}