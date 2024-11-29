import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../constants.dart';
import '../theme.dart';

class GenderSelectorDialog extends StatelessWidget {
  const GenderSelectorDialog({super.key});

  Future<void> _updateGender(String gender, BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId != null) {
        final response = await http.patch(
          Uri.parse('http://145.223.21.62:8090/api/collections/users/records/$userId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'gender': gender}),
        );

        if (response.statusCode == 200) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Error updating gender: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            onTap: () => _updateGender('Male', context),
            titleAlignment: ListTileTitleAlignment.center,
            title: Text(
              'Male',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: darkModeEnabled ? kDarkTextColor : kTextColor,
              ),
            ),
          ),
          ListTile(
            onTap: () => _updateGender('Female', context),
            titleAlignment: ListTileTitleAlignment.center,
            title: Text(
              'Female',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: darkModeEnabled ? kDarkTextColor : kTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}