// new_peer_chat_dialog.dart
part of 'default_dialogs.dart';

class _UserListItem {
  final String id;
  final String name;
  final String? avatar;
  final String? bio;

  _UserListItem({
    required this.id,
    required this.name,
    this.avatar,
    this.bio,
  });
}

void showDefaultNewPeerChatDialog(BuildContext context) {
  Timer.run(() async {
    try {
      // Get current user ID
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('userId');

      // Fetch users
      final response = await http.get(
        Uri.parse('http://145.223.21.62:8090/api/collections/users/records'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<_UserListItem> users = (data['items'] as List)
            .where((item) => item['id'] != currentUserId)
            .map((item) => _UserListItem(
          id: item['id'],
          name: '${item['firstname'] ?? ''} ${item['lastname'] ?? ''}'.trim(),
          avatar: item['avatar'],
          bio: item['bio'],
        ))
            .toList();

        // Show dialog with users
        if (context.mounted) {
          showDialog<String>(
            useRootNavigator: false,
            context: context,
            builder: (BuildContext context) {
              return _UserSelectionDialog(users: users);
            },
          ).then((selectedUserId) {
            if (selectedUserId != null && selectedUserId.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DemoChattingMessageListPage(
                    conversationID: selectedUserId,
                    conversationType: ZIMConversationType.peer,
                  ),
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      print('Error loading users: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load users. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  });
}

class _UserSelectionDialog extends StatefulWidget {
  final List<_UserListItem> users;

  const _UserSelectionDialog({required this.users});

  @override
  _UserSelectionDialogState createState() => _UserSelectionDialogState();
}

class _UserSelectionDialogState extends State<_UserSelectionDialog> {
  late List<_UserListItem> filteredUsers;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredUsers = widget.users;
  }

  void _filterUsers(String query) {
    setState(() {
      filteredUsers = widget.users
          .where((user) =>
          user.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'New Chat',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: Colors.grey),
                  splashRadius: 20,
                ),
              ],
            ),
            SizedBox(height: 20),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  hintStyle: TextStyle(color: Colors.blue[200]),
                  prefixIcon: Icon(Icons.search, color: Colors.blue[300]),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
                onChanged: _filterUsers,
              ),
            ),
            SizedBox(height: 20),

            // Users List
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: filteredUsers.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Colors.blue[200],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'No users found',
                      style: TextStyle(
                        color: Colors.blue[300],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.blue[100]!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: user.avatar != null
                            ? CachedNetworkImage(
                          imageUrl:
                          'http://145.223.21.62:8090/api/files/users/${user.id}/${user.avatar}',
                          imageBuilder: (context, imageProvider) =>
                              CircleAvatar(
                                backgroundImage: imageProvider,
                                radius: 25,
                              ),
                          placeholder: (context, url) => CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.blue[50],
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue[300],
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.blue[50],
                                child: Icon(
                                  Icons.person,
                                  color: Colors.blue[300],
                                ),
                              ),
                        )
                            : CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.blue[50],
                          child: Icon(
                            Icons.person,
                            color: Colors.blue[300],
                          ),
                        ),
                      ),
                      title: Text(
                        user.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue[900],
                        ),
                      ),
                      subtitle: Text(
                        user.bio?.isNotEmpty == true
                            ? user.bio!
                            : "Hey I'm using Leo Chat",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.blue[300],
                          fontSize: 14,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.blue[200],
                      ),
                      onTap: () => Navigator.of(context).pop(user.id),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),

            // Cancel Button
            Container(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  backgroundColor: Colors.blue[50],
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}