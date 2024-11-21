import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'live_page.dart';

class CreateVoiceRoomPage extends StatefulWidget {
  @override
  _CreateVoiceRoomPageState createState() => _CreateVoiceRoomPageState();
}

class _CreateVoiceRoomPageState extends State<CreateVoiceRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _roomIdController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _mottoController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  String? ownerId;
  File? groupPhoto;
  File? backgroundImage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOwnerId();
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _roomIdController.dispose();
    _countryController.dispose();
    _mottoController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _loadOwnerId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      ownerId = prefs.getString('userId') ?? '';
    });
  }

  Future<void> _pickImage(bool isGroupPhoto) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          if (isGroupPhoto) {
            groupPhoto = File(image.path);
          } else {
            backgroundImage = File(image.path);
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (groupPhoto == null) {
      _showErrorSnackBar('Please select a group photo');
      return;
    }

    setState(() => isLoading = true);
    _formKey.currentState!.save();

    try {
      final uri = Uri.parse('http://145.223.21.62:8090/api/collections/voiceRooms/records');
      final request = http.MultipartRequest('POST', uri);

      // Add form fields
      request.fields.addAll({
        'voice_room_name': _roomNameController.text,
        'voiceRoom_id': _roomIdController.text,
        'voiceRoom_country': _countryController.text,
        'team_moto': _mottoController.text,
        'tags': _tagsController.text,
        'ownerId': ownerId ?? '',
      });

      // Add files
      if (groupPhoto != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'group_photo',
          groupPhoto!.path,
        ));
      }

      if (backgroundImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'background_images',
          backgroundImage!.path,
        ));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessSnackBar('Voice room created successfully!');

        // Get username for LivePage
        final prefs = await SharedPreferences.getInstance();
        final username = prefs.getString('firstName') ?? '';
        final userId = prefs.getString('userId') ?? '';

        // Navigate to LivePage with the correct parameters
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LivePage(
              roomID: data['id'],
              isHost: true,
              username1: username,
              userId: userId,

            ),
          ),
        );
      } else {
        throw Exception('Failed to create voice room: ${data['message']}');
      }
    } catch (e) {
      _showErrorSnackBar('Error creating voice room: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLength,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          prefixIcon: Icon(icon, color: Colors.blue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.blue.shade50,
        ),
        validator: validator ?? (value) => value?.isEmpty ?? true ? 'This field is required' : null,
        keyboardType: keyboardType,
        maxLength: maxLength,
      ),
    );
  }

  Widget _buildImageSection(bool isGroupPhoto) {
    final File? imageFile = isGroupPhoto ? groupPhoto : backgroundImage;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isGroupPhoto ? 'Group Photo' : 'Background Image',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 12),
            if (imageFile != null)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(imageFile),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _pickImage(isGroupPhoto),
              icon: Icon(isGroupPhoto ? Icons.group_add : Icons.wallpaper),
              label: Text(imageFile == null ? 'Select Image' : 'Change Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Voice Room',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: ownerId == null
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade100, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildFormField(
                          controller: _roomNameController,
                          label: 'Voice Room Name',
                          icon: Icons.meeting_room,
                        ),
                        _buildFormField(
                          controller: _roomIdController,
                          label: 'Voice Room ID',
                          icon: Icons.numbers,
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'This field is required';
                            if (!RegExp(r'^\d{10}$').hasMatch(value!)) {
                              return 'Please enter exactly 10 digits';
                            }
                            return null;
                          },
                          helperText: 'Enter a 10-digit number',
                        ),
                        _buildFormField(
                          controller: _countryController,
                          label: 'Country',
                          icon: Icons.flag,
                        ),
                        _buildFormField(
                          controller: _mottoController,
                          label: 'Team Motto',
                          icon: Icons.format_quote,
                        ),
                        _buildFormField(
                          controller: _tagsController,
                          label: 'Tags',
                          icon: Icons.tag,
                          helperText: 'Separate tags with commas',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildImageSection(true),
                const SizedBox(height: 16),
                _buildImageSection(false),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Create Voice Room',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}