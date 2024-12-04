// import 'package:flutter/material.dart';
// import 'package:contacts_service/contacts_service.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class NewContactAndCallHistoryScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//
//       body: ListView(
//         children: [
//           _buildMenuItem(
//             icon: Icons.person_add_alt_1,
//             title: 'New Contacts',
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => NewContactsPage()),
//               );
//             },
//           ),
//           _buildMenuItem(
//             icon: Icons.history,
//             title: 'Call History',
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => CallHistoryPage()),
//               );
//             },
//           ),
//
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMenuItem({
//     required IconData icon,
//     required String title,
//     String? subtitle,
//     required VoidCallback onTap,
//   }) {
//     return ListTile(
//       leading: Icon(icon, color: Colors.blue),
//       title: Text(title),
//       subtitle: subtitle != null ? Text(subtitle) : null,
//       trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//       onTap: onTap,
//     );
//   }
// }
//
// class NewContactsPage extends StatefulWidget {
//   @override
//   _NewContactsPageState createState() => _NewContactsPageState();
// }
//
// class _NewContactsPageState extends State<NewContactsPage> {
//   List<Contact> _contacts = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadContacts();
//   }
//
//   Future<void> _loadContacts() async {
//     final permissionStatus = await Permission.contacts.request();
//     if (permissionStatus.isGranted) {
//       final contacts = await ContactsService.getContacts();
//       setState(() {
//         _contacts = contacts.toList();
//       });
//     } else {
//       // Show a message if permission is denied
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Contacts permission is required to proceed.')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Phone Contacts'),
//         backgroundColor: Colors.blue,
//       ),
//       body: _contacts.isEmpty
//           ? const Center(child: CircularProgressIndicator())
//           : ListView.builder(
//         itemCount: _contacts.length,
//         itemBuilder: (context, index) {
//           final contact = _contacts[index];
//           return ListTile(
//             leading: CircleAvatar(
//               backgroundColor: Colors.blue,
//               child: Text(
//                 contact.initials(),
//                 style: const TextStyle(color: Colors.white),
//               ),
//             ),
//             title: Text(contact.displayName ?? 'No Name'),
//             subtitle: contact.phones?.isNotEmpty == true
//                 ? Text(contact.phones!.first.value ?? '')
//                 : const Text('No phone number'),
//           );
//         },
//       ),
//     );
//   }
// }
//
// class CallHistoryPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Call History' , style: TextStyle(color: Colors.white),),
//         backgroundColor: Colors.blue,
//       ),
//       body: ListView(
//         children: List.generate(10, (index) {
//           return ListTile(
//             leading: const Icon(Icons.call, color: Colors.blue),
//             title: Text('Contact ${index + 1}'),
//             subtitle: Text('Missed Call - ${DateTime.now()}'),
//             trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//           );
//         }),
//       ),
//     );
//   }
// }
