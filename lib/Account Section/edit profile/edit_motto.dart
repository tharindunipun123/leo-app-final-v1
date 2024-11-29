import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'widgets/body_container.dart';
import 'widgets/primary_button.dart';
import 'widgets/back_button.dart';
import '../constants.dart';

class EditMotto extends StatefulWidget {
  final String userId;
  const EditMotto({super.key, required this.userId});

  @override
  State<EditMotto> createState() => _EditMottoState();
}

class _EditMottoState extends State<EditMotto> {
  final TextEditingController _mottoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentMotto();
  }

  Future<void> _loadCurrentMotto() async {
    try {
      final response = await http.get(
          Uri.parse('http://145.223.21.62:8090/api/collections/users/records/${widget.userId}')
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          _mottoController.text = userData['moto'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading motto: $e');
    }
  }

  Future<void> _updateMotto(BuildContext context) async {
    try {
      final response = await http.patch(
        Uri.parse('http://145.223.21.62:8090/api/collections/users/records/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'moto': _mottoController.text.trim()}),
      );

      if (response.statusCode == 200) {
        await _updateLocalStorage(_mottoController.text.trim());
        _showSuccessDialog(context);
      } else {
        _showErrorDialog(context);
      }
    } catch (e) {
      print('Error updating motto: $e');
      _showErrorDialog(context);
    }
  }

  Future<void> _updateLocalStorage(String newMotto) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = jsonDecode(prefs.getString('user') ?? '{}');
      userData['moto'] = newMotto;
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
        content: const Text('Motto updated successfully!'),
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
        content: const Text('Failed to update motto. Please try again later.'),
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
          'Edit Motto',
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
              "Motto",
              style: TextStyle(
                fontSize: 16.sp,
                color: darkModeEnabled ? kDarkTextColor : kTextColor,
              ),
            ),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _mottoController,
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
              onTap: () => _updateMotto(context),
              text: 'Save',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mottoController.dispose();
    super.dispose();
  }
}