import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/body_container.dart';
import 'widgets/primary_button.dart';
import 'widgets/back_button.dart';
import '../constants.dart';
import 'package:http/http.dart' as http;

class EditBio extends StatefulWidget {
  final String userId;
  const EditBio({super.key, required this.userId});

  @override
  State<EditBio> createState() => _EditBioState();
}

class _EditBioState extends State<EditBio> {
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentBio();
  }

  Future<void> _loadCurrentBio() async {
    try {
      final response = await http.get(
          Uri.parse('http://145.223.21.62:8090/api/collections/users/records/${widget.userId}')
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          _bioController.text = userData['bio'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading bio: $e');
    }
  }

  Future<void> _updateBio(BuildContext context) async {
    try {
      final response = await http.patch(
        Uri.parse('http://145.223.21.62:8090/api/collections/users/records/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'bio': _bioController.text.trim()}),
      );

      if (response.statusCode == 200) {
        await _updateLocalStorage(_bioController.text.trim());
        _showSuccessDialog(context);
      } else {
        _showErrorDialog(context);
      }
    } catch (e) {
      print('Error updating bio: $e');
      _showErrorDialog(context);
    }
  }

  Future<void> _updateLocalStorage(String newBio) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = jsonDecode(prefs.getString('user') ?? '{}');
      userData['bio'] = newBio;
      await prefs.setString('user', jsonEncode(userData));
    } catch (e) {
      print('Error updating local storage: $e');
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Bio updated successfully!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: const Text('Failed to update bio. Please try again later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(),
        centerTitle: true,
        title: Text(
          'Edit Bio',
          style: TextStyle(
            fontSize: 16.sp,
            color: darkModeEnabled ? kDarkTextColor : kTextColor,
          ),
        ),
      ),
      body: BodyContainer(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bio",
              style: TextStyle(
                fontSize: 16.sp,
                color: darkModeEnabled ? kDarkTextColor : kTextColor,
              ),
            ),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _bioController,
              style: TextStyle(fontSize: 16.sp),
              maxLines: 4,
              decoration: InputDecoration(
                border: kInputBorder,
                enabledBorder: kInputEnabledBorder,
                focusedBorder: kInputFocusedBorder,
              ),
            ),
            SizedBox(height: 20.h),
            PrimaryButton(
              onTap: () => _updateBio(context),
              text: 'Save',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }
}