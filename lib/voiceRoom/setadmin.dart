import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';

class SetAdminScreen extends StatefulWidget {
  final String voiceRoomId;

  const SetAdminScreen({Key? key, required this.voiceRoomId}) : super(key: key);

  @override
  _SetAdminScreenState createState() => _SetAdminScreenState();
}

class _SetAdminScreenState extends State<SetAdminScreen> {
  final String baseUrl = 'http://145.223.21.62:8090';
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  Set<String> selectedUserIds = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      setState(() => isLoading = true);

      final response = await http.get(
        Uri.parse('$baseUrl/api/collections/joined_users/records?filter=(voice_room_id="${widget.voiceRoomId}")'),
      );

      if (response.statusCode == 200) {
        final joinedUsers = json.decode(response.body)['items'] as List;

        List<Map<String, dynamic>> userProfiles = [];
        for (var joinedUser in joinedUsers) {
          if (joinedUser['admin_or_not'] == true) continue;

          final userId = joinedUser['userid'];
          final userResponse = await http.get(
            Uri.parse('$baseUrl/api/collections/users/records/$userId?fields=firstname,avatar,collectionId'),
          );

          if (userResponse.statusCode == 200) {
            final userData = json.decode(userResponse.body);
            userProfiles.add({
              'userid': userId,
              'firstname': userData['firstname'],
              'avatar': userData['avatar'],
              'collectionId': userData['collectionId'],
              'joinedId': joinedUser['id'],
            });
          }
        }

        setState(() {
          users = userProfiles;
          filteredUsers = List.from(users);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching users: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _setAdmins() async {
    if (selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one user')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Setting admins...'),
                ],
              ),
            ),
          ),
        ),
      );

      for (String userId in selectedUserIds) {
        final userRecord = users.firstWhere((user) => user['userid'] == userId);
        await http.patch(
          Uri.parse('$baseUrl/api/collections/joined_users/records/${userRecord['joinedId']}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'admin_or_not': true}),
        );
      }

      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context); // Return to previous screen

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Admins set successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to set admins'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterUsers(String query) {
    setState(() {
      filteredUsers = users.where((user) {
        final name = (user['firstname'] ?? '').toLowerCase();
        final userId = (user['userid'] ?? '').toLowerCase();
        return name.contains(query.toLowerCase()) || userId.contains(query.toLowerCase());
      }).toList();
    });
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final avatarUrl = user['avatar'] != null
        ? '$baseUrl/api/files/${user['collectionId']}/${user['userid']}/${user['avatar']}'
        : null;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: CheckboxListTile(
        value: selectedUserIds.contains(user['userid']),
        onChanged: (value) {
          setState(() {
            if (value == true) {
              selectedUserIds.add(user['userid']);
            } else {
              selectedUserIds.remove(user['userid']);
            }
          });
        },
        secondary: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: CachedNetworkImage(
            imageUrl: avatarUrl ?? '',
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: Icon(Icons.person, color: Colors.grey[400]),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: Icon(Icons.person, color: Colors.grey[400]),
            ),
          ),
        ),
        title: Text(
          user['firstname'] ?? 'Unknown User',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          user['userid'] ?? '',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Set Admins',
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
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search users',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _filterUsers,
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                ? Center(
              child: Text(
                'No users found',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                return _buildUserTile(filteredUsers[index]);
              },
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
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _setAdmins,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Set ${selectedUserIds.length} Users as Admin',
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