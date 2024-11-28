import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'widgets/body_container.dart';
import 'widgets/primary_button.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'widgets/back_button.dart';

class EditBio extends StatelessWidget {
  final String userId;
  const EditBio({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final TextEditingController _bioController = TextEditingController();
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
            SizedBox(
              height: 8.h,
            ),
            TextFormField(
              controller: _bioController,
              style: TextStyle(
                fontSize: 16.sp,
              ),
              maxLines: 4,
              decoration: InputDecoration(
                border: kInputBorder,
                enabledBorder: kInputEnabledBorder,
                focusedBorder: kInputFocusedBorder,
              ),
            ),
            SizedBox(
              height: 20.h,
            ),
            PrimaryButton(
              onTap: () async {
                String newName = _bioController.text.trim();
                var url =
                    'http://45.126.125.172:8080/api/v1/partialUpdateProfile';

                var headers = {
                  'Content-Type': 'application/json',
                };

                var body = {
                  'userId': userId,
                  'bio': newName,
                };

                var response = await http.post(
                  Uri.parse(url),
                  headers: headers,
                  body: jsonEncode(body),
                );

                if (response.statusCode == 200) {
                  // Update local storage (user.json) with new name
                  updateLocalStorage(newName);

                  // Show success dialog
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Success'),
                        content: Text('Bio updated successfully!'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                              // Navigator.of(context)
                              //     .pop(); // Navigate back to previous page// Navigate to edit-profile route
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Error'),
                        content: Text(
                            'Failed to update name. Please try again later.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              text: 'Save',
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> updateLocalStorage(String newName) async {
  try {
    // Get instance of SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get current user data from SharedPreferences
    String userDataString = prefs.getString('user') ?? '{}';
    Map<String, dynamic> userData = jsonDecode(userDataString);

    // Update name in user data if newName is not null or empty
    if (newName != null && newName.isNotEmpty) {
      userData['bio'] = newName;

      // Save updated user data back to SharedPreferences
      await prefs.setString('user', jsonEncode(userData));

      print('User bio updated: $newName');
    } else {
      print('New bio is invalid or empty.');
    }
  } catch (e) {
    print('Error updating user data: $e');
    // Handle any specific error cases here
  }
}
