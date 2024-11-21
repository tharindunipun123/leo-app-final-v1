import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../HomeScreen.dart';
import 'package:zego_zimkit/zego_zimkit.dart';

class ProfileCreationScreen extends StatefulWidget {
  final String userId;

  ProfileCreationScreen({required this.userId});

  @override
  _ProfileCreationScreenState createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  String firstname = "";
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  File? _profileImage;

  Future<void> _pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final url = Uri.parse(
        'http://145.223.21.62:8090/api/collections/users/records/${widget.userId}');

    var request = http.MultipartRequest('PATCH', url);
    request.fields['firstname'] = _firstNameController.text;
    request.fields['lastname'] = _lastNameController.text;

    if (_profileImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'avatar',
        _profileImage!.path,
      ));
    }

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        await prefs.setString('firstName', _firstNameController.text);
        firstname = prefs.getString('firstName') ?? 'User';

        if (firstname != "User") {
          ZIMKit().connectUser(id: widget.userId, name: firstname);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                userId: widget.userId,
                username: firstname,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to save profile. Error ${response.statusCode}. Please try again.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Profile',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.deepPurple[50],
                  backgroundImage:
                  _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? Icon(
                    Icons.add_a_photo,
                    size: 50,
                    color: Colors.blue[700],
                  )
                      : null,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Upload Profile Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 30),
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  labelStyle: TextStyle(color: Colors.blue[700]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.person, color: Colors.blue[700]),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  labelStyle: TextStyle(color: Colors.blue[700]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.person_outline, color: Colors.blue[700]),
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  backgroundColor: Colors.blue[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
