import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'setadmin.dart';
import 'dismissadmin.dart';

class MemberListScreen extends StatefulWidget {
  final String voiceRoomId;
  final String currentUserId;

  const MemberListScreen({
    Key? key,
    required this.voiceRoomId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _MemberListScreenState createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> usersList = [];
  Map<String, dynamic>? roomData;
  Map<String, dynamic>? ownerData;
  bool isLoading = true;
  String? ownerId;
  List<String> adminIds = [];

  final String baseUrl = 'http://145.223.21.62:8090';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      setState(() => isLoading = true);

      // Fetch voice room details
      final roomResponse = await http.get(
        Uri.parse('$baseUrl/api/collections/voiceRooms/records/${widget.voiceRoomId}'),
      );

      if (roomResponse.statusCode == 200) {
        roomData = json.decode(roomResponse.body);
        ownerId = roomData?['ownerId'];

        // Fetch owner details
        if (ownerId != null) {
          final ownerResponse = await http.get(
            Uri.parse('$baseUrl/api/collections/users/records/$ownerId'),
          );
          if (ownerResponse.statusCode == 200) {
            ownerData = json.decode(ownerResponse.body);
          }
        }
      }

      // Fetch joined users with expanded user data
      final joinedUsersResponse = await http.get(
        Uri.parse('$baseUrl/api/collections/joined_users/records?filter=(voice_room_id="${widget.voiceRoomId}")'),
      );

      if (joinedUsersResponse.statusCode == 200) {
        final joinedUsersData = json.decode(joinedUsersResponse.body);
        final joinedUsers = joinedUsersData['items'] as List;

        // Get admin IDs
        adminIds = joinedUsers
            .where((user) => user['admin_or_not'] == true)
            .map((user) => user['userid'] as String)
            .toList();

        // Fetch user details for each joined user
        final List<Map<String, dynamic>> users = [];
        for (var joinedUser in joinedUsers) {
          if (joinedUser['userid'] != ownerId) { // Skip owner as they'll be shown separately
            final userResponse = await http.get(
              Uri.parse('$baseUrl/api/collections/users/records/${joinedUser['userid']}'),
            );

            if (userResponse.statusCode == 200) {
              final userData = json.decode(userResponse.body);
              users.add({
                ...userData,
                'isAdmin': joinedUser['admin_or_not'],
                'joinedUserId': joinedUser['id'],
              });
            }
          }
        }

        // Sort users: admins first, then regular users
        users.sort((a, b) {
          if (a['isAdmin'] && !b['isAdmin']) return -1;
          if (!a['isAdmin'] && b['isAdmin']) return 1;
          return 0;
        });

        setState(() {
          usersList = users;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> removeUser(String userId, String joinedUserId) async {
    // Check permissions
    if (widget.currentUserId != ownerId &&
        !adminIds.contains(widget.currentUserId)) return;

    if (userId == ownerId) return; // Can't remove owner
    if (adminIds.contains(userId) && widget.currentUserId != ownerId) return; // Admins can't remove other admins

    try {
      // Add to removed_users
      final removeResponse = await http.post(
        Uri.parse('$baseUrl/api/collections/removed_users/records'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'voice_room_id': widget.voiceRoomId,
          'user_id': userId,
        }),
      );

      if (removeResponse.statusCode == 200) {
        // Delete from joined_users
        await http.delete(
          Uri.parse('$baseUrl/api/collections/joined_users/records/$joinedUserId'),
        );

        loadData(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User removed successfully')),
        );
      }
    } catch (e) {
      print('Error removing user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove user')),
      );
    }
  }

  Widget _buildOwnerProfile() {
    if (ownerData == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: Colors.blue,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Room Owner',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: CachedNetworkImage(
                imageUrl: "$baseUrl/api/files/${ownerData!['collectionId']}/${ownerData!['id']}/${ownerData!['avatar']}",
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.person, color: Colors.grey[400]),
                ),
              ),
            ),
            title: Text(
              ownerData!['firstname'] ?? "Unknown",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              ownerData!['bio'] ?? "No bio available",
              style: TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Settings Bar
        Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name or ID',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
              ),
              if (widget.currentUserId == ownerId || adminIds.contains(widget.currentUserId))
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: _showSettingsDialog,
                ),
            ],
          ),
        ),

        // Members List with Owner Profile at top
        Expanded(
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 80),
            children: [
              _buildOwnerProfile(),
              ...usersList.map((user) {
                if (searchController.text.isNotEmpty &&
                    !user['firstname'].toString().toLowerCase().contains(searchController.text.toLowerCase()) &&
                    !user['id'].toString().toLowerCase().contains(searchController.text.toLowerCase())) {
                  return SizedBox.shrink();
                }

                final isAdmin = user['isAdmin'] == true;

                return Container(
                  height: 70,
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isAdmin)
                          Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.person,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: CachedNetworkImage(
                            imageUrl: "$baseUrl/api/files/${user['collectionId']}/${user['id']}/${user['avatar']}",
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.person, color: Colors.grey[400]),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      user['firstname'] ?? "Unknown",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      user['bio'] ?? "No bio available",
                      style: TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isAdmin)
                          Icon(Icons.person, color: Colors.amber),
                        if ((widget.currentUserId == ownerId ||
                            (adminIds.contains(widget.currentUserId) && !isAdmin)) &&
                            widget.currentUserId != user['id'])
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => removeUser(user['id'], user['joinedUserId']),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  void _showSettingsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar at top
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Text(
              'Room Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),

            // Set Admin Option
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person_add, color: Colors.blue),
              ),
              title: Text('Set Admin'),
              subtitle: Text('Promote a member to admin'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SetAdminScreen(
                      voiceRoomId: widget.voiceRoomId,
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 12),

            // Dismiss Admin Option
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person_remove, color: Colors.red),
              ),
              title: Text('Dismiss Admin'),
              subtitle: Text('Remove admin privileges'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DismissAdminScreen(
                      voiceRoomId: widget.voiceRoomId,
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }


}


