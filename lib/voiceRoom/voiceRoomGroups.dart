// import 'package:flutter/material.dart';
// import 'package:zego_zimkit/zego_zimkit.dart';
// import 'package:cached_network_image/cached_network_image.dart';
//
// class GroupManagementPage extends StatefulWidget {
//   @override
//   _GroupManagementPageState createState() => _GroupManagementPageState();
// }
//
// class _GroupManagementPageState extends State<GroupManagementPage> {
//   bool isLoading = true;
//   List<ZIMGroupInfo> createdGroups = [];
//   List<ZIMGroupInfo> joinedGroups = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchGroups();
//   }
//
//
//   /// Fetch all groups the user has joined
//   Future<void> _fetchGroups() async {
//     setState(() => isLoading = true);
//     try {
//       // Fetching group data
//       final groups = await ZIMKit().queryGroupMemberList(''); // Provide valid conversation ID
//       setState(() {
//         groupList = groups.cast<ZIMKitGroupInfo>(); // Cast to correct type if necessary
//         isLoading = false;
//       });
//     } catch (e) {
//       print('Error fetching groups: $e');
//       setState(() => isLoading = false);
//     }
//   }
//
//   Future<void> _deleteGroup(String groupID) async {
//     try {
//       // Show confirmation dialog
//       bool confirm = await showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: Text('Delete Group'),
//           content: Text('Are you sure you want to delete this group?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context, true),
//               style: TextButton.styleFrom(foregroundColor: Colors.red),
//               child: Text('Delete'),
//             ),
//           ],
//         ),
//       ) ?? false;
//
//       if (!confirm) return;
//
//       await ZIMKit().deleteGroup(groupID);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Group deleted successfully!')),
//       );
//       _fetchGroups(); // Refresh the group list
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error deleting group: $e')),
//       );
//     }
//   }
//
//   Widget _buildGroupCard(ZIMGroupInfo group, {bool isCreated = false}) {
//     return Card(
//       elevation: 3,
//       margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: ListTile(
//         contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         leading: CircleAvatar(
//           backgroundColor: Colors.blue[100],
//           child: Text(
//             (group.groupName ?? 'G')[0].toUpperCase(),
//             style: TextStyle(
//               color: Colors.blue[900],
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         title: Text(
//           group.groupName ?? 'Unnamed Group',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Group ID: ${group.groupID}'),
//             SizedBox(height: 4),
//             Row(
//               children: [
//                 Icon(Icons.people, size: 16, color: Colors.grey),
//                 SizedBox(width: 4),
//                 FutureBuilder<int>(
//                   future: ZIMKit().queryGroupMemberCount(group.groupID),
//                   builder: (context, snapshot) {
//                     return Text(
//                       '${snapshot.data ?? 0} members',
//                       style: TextStyle(color: Colors.grey[600]),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ],
//         ),
//         trailing: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             IconButton(
//               icon: Icon(Icons.message_outlined, color: Colors.blue),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => DemoChattingMessageListPage(
//                       conversationID: group.groupID,
//                       conversationType: ZIMConversationType.group,
//                     ),
//                   ),
//                 );
//               },
//               tooltip: 'Open Chat',
//             ),
//             if (isCreated)
//               PopupMenuButton(
//                 icon: Icon(Icons.more_vert),
//                 itemBuilder: (context) => [
//                   PopupMenuItem(
//                     value: 'manage',
//                     child: ListTile(
//                       leading: Icon(Icons.group, color: Colors.blue),
//                       title: Text('Manage Members'),
//                       contentPadding: EdgeInsets.zero,
//                     ),
//                   ),
//                   PopupMenuItem(
//                     value: 'delete',
//                     child: ListTile(
//                       leading: Icon(Icons.delete, color: Colors.red),
//                       title: Text('Delete Group'),
//                       contentPadding: EdgeInsets.zero,
//                     ),
//                   ),
//                 ],
//                 onSelected: (value) {
//                   if (value == 'delete') {
//                     _deleteGroup(group.groupID);
//                   } else if (value == 'manage') {
//                     _showGroupManagementDialog(group.groupID);
//                   }
//                 },
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showGroupManagementDialog(String groupID) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => _GroupMemberManagement(groupID: groupID),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Group Management'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: _fetchGroups,
//           ),
//         ],
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : RefreshIndicator(
//         onRefresh: _fetchGroups,
//         child: SingleChildScrollView(
//           physics: AlwaysScrollableScrollPhysics(),
//           padding: EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               if (createdGroups.isNotEmpty) ...[
//                 Text(
//                   'Created Groups',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.blue[900],
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 ...createdGroups
//                     .map((group) => _buildGroupCard(group, isCreated: true))
//                     .toList(),
//                 SizedBox(height: 24),
//               ],
//               if (joinedGroups.isNotEmpty) ...[
//                 Text(
//                   'Joined Groups',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.blue[900],
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 ...joinedGroups
//                     .map((group) => _buildGroupCard(group))
//                     .toList(),
//               ],
//               if (createdGroups.isEmpty && joinedGroups.isEmpty)
//                 Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.group_off,
//                         size: 64,
//                         color: Colors.grey,
//                       ),
//                       SizedBox(height: 16),
//                       Text(
//                         'No groups found',
//                         style: TextStyle(
//                           fontSize: 18,
//                           color: Colors.grey,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _GroupMemberManagement extends StatelessWidget {
//   final String groupID;
//
//   const _GroupMemberManagement({required this.groupID});
//
//   Future<void> _setMemberRole(BuildContext context, String userID, int role) async {
//     try {
//       await ZIMKit().setGroupMemberRole(
//         conversationID: groupID,
//         userID: userID,
//         role: role,
//       );
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Member role updated successfully!')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error updating member role: $e')),
//       );
//     }
//   }
//
//   Future<void> _removeMember(BuildContext context, String userID) async {
//     try {
//       bool confirm = await showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: Text('Remove Member'),
//           content: Text('Are you sure you want to remove this member?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context, true),
//               style: TextButton.styleFrom(foregroundColor: Colors.red),
//               child: Text('Remove'),
//             ),
//           ],
//         ),
//       ) ?? false;
//
//       if (!confirm) return;
//
//       await ZIMKit().removeUesrsFromGroup(groupID, [userID]);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Member removed successfully!')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error removing member: $e')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.8,
//       padding: EdgeInsets.all(16),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Group Members',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               IconButton(
//                 icon: Icon(Icons.close),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ],
//           ),
//           Divider(),
//           Expanded(
//             child: FutureBuilder<List<ZIMGroupMemberInfo>>(
//               future: ZIMKit().queryGroupMemberList(groupID),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return Center(child: CircularProgressIndicator());
//                 }
//                 final members = snapshot.data!;
//                 return ListView.builder(
//                   itemCount: members.length,
//                   itemBuilder: (context, index) {
//                     final member = members[index];
//                     return ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Colors.blue[100],
//                         child: Text(
//                           (member.userName ?? 'U')[0].toUpperCase(),
//                           style: TextStyle(color: Colors.blue[900]),
//                         ),
//                       ),
//                       title: Text(member.userName ?? 'Unknown User'),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text('ID: ${member.userID}'),
//                           Text(
//                             member.memberRole == ZIMGroupMemberRole.owner
//                                 ? 'Owner'
//                                 : member.memberRole == 2
//                                 ? 'Admin'
//                                 : 'Member',
//                             style: TextStyle(
//                               color: member.memberRole == ZIMGroupMemberRole.owner
//                                   ? Colors.orange
//                                   : member.memberRole == 2
//                                   ? Colors.blue
//                                   : Colors.grey,
//                             ),
//                           ),
//                         ],
//                       ),
//                       trailing: member.memberRole != ZIMGroupMemberRole.owner
//                           ? PopupMenuButton(
//                         itemBuilder: (context) => [
//                           PopupMenuItem(
//                             value: 'role',
//                             child: ListTile(
//                               leading: Icon(
//                                 Icons.admin_panel_settings,
//                                 color: Colors.blue,
//                               ),
//                               title: Text(
//                                 member.memberRole == 2
//                                     ? 'Remove Admin'
//                                     : 'Make Admin',
//                               ),
//                               contentPadding: EdgeInsets.zero,
//                             ),
//                           ),
//                           PopupMenuItem(
//                             value: 'remove',
//                             child: ListTile(
//                               leading: Icon(
//                                 Icons.person_remove,
//                                 color: Colors.red,
//                               ),
//                               title: Text('Remove Member'),
//                               contentPadding: EdgeInsets.zero,
//                             ),
//                           ),
//                         ],
//                         onSelected: (value) {
//                           if (value == 'role') {
//                             _setMemberRole(
//                               context,
//                               member.userID,
//                               member.memberRole == 2 ? 3 : 2,
//                             );
//                           } else if (value == 'remove') {
//                             _removeMember(context, member.userID);
//                           }
//                         },
//                       )
//                           : null,
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }