import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_picker/country_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'live_page.dart';

class CreateVoiceRoomPage extends StatefulWidget {
  @override
  _CreateVoiceRoomPageState createState() => _CreateVoiceRoomPageState();
}

class _CreateVoiceRoomPageState extends State<CreateVoiceRoomPage> {
  // Constants for styling
  static const primaryColor = Colors.blue; // Main blue color
  static const accentColor = Color(0xFF2196F3); // Light blue accent
  static const backgroundColor = Color(0xFFE3F2FD); // Very light blue background
  static const textColor = Color(0xFF1976D2); // Darker blue for text
  static const cardColor = Color(0xFFFFFFFF); // White for cards

  List<String> _languages = [
    'English', 'Sinhala', 'Tamil'
  ];
  String? _selectedLanguage;
  List<String> _tags = [];
  String? _selectedTag;

  Country? selectedCountry;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _roomIdController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _mottoController = TextEditingController();

  String? ownerId;
  File? groupPhoto;
  File? backgroundImage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOwnerId();
    _generateRoomId();
    _fetchTags();
  }

  Future<void> _fetchTags() async {
    try {
      final response = await http.get(
        Uri.parse('http://145.223.21.62:8090/api/collections/tags/records'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;
        setState(() {
          _tags = items.map((item) => item['tag_name'].toString()).toList();
          setState(() {
            _tags = items.map((item) => item['tag_name'].toString()).toList();
          });
        });
      }
    } catch (e) {
      print('Error fetching tags: $e');
      print('Error fetching tags: $e');
    }
  }

  void _generateRoomId() {
    final random = Random();
    String roomId = '';
    for (int i = 0; i < 10; i++) {
      roomId += random.nextInt(10).toString();
    }
    _roomIdController.text = roomId;
  }

  Future<void> _loadOwnerId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      ownerId = prefs.getString('userId') ?? '';
    });
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.blue[700],
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: Colors.blue[700]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.blue[100]!,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.blue[100]!,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.blue[400]!,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: TextStyle(
                color: Colors.blue[900],
                fontSize: 16,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down, color: Colors.blue[700]),
        style: TextStyle(
          color: Colors.blue[900],
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLength,
    String? helperText,
    bool? readOnly,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly ?? false,
        onTap: onTap,
        style: TextStyle(
          color: Colors.blue[900],
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.blue[700],
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          helperText: helperText,
          helperStyle: TextStyle(
            color: Colors.blue[400],
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.blue[700],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.blue[100]!,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.blue[100]!,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.blue[400]!,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: validator,
        keyboardType: keyboardType,
        maxLength: maxLength,
      ),
    );
  }

  Widget _buildImageSection(bool isGroupPhoto) {
    final File? imageFile = isGroupPhoto ? groupPhoto : backgroundImage;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue[50]!,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with icon
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isGroupPhoto ? Icons.group : Icons.wallpaper,
                  color: Colors.blue[700],
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  isGroupPhoto ? 'Group Photo' : 'Background Image',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ],
            ),
          ),

          // Image preview or placeholder
          Container(
            height: 200,
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.blue[100]!,
                width: 1,
              ),
            ),
            child: imageFile != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.file(
                imageFile,
                fit: BoxFit.cover,
              ),
            )
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isGroupPhoto ? Icons.add_photo_alternate : Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: Colors.blue[300],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Tap to upload ${isGroupPhoto ? 'group photo' : 'background'}',
                    style: TextStyle(
                      color: Colors.blue[400],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Upload button
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _pickImage(isGroupPhoto),
              icon: Icon(
                imageFile == null ? Icons.cloud_upload : Icons.edit,
                size: 20,
              ),
              label: Text(
                imageFile == null ? 'Upload Image' : 'Change Image',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Create Voice Room',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: ownerId == null
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                readOnly: true,
                helperText: 'Auto-generated 10-digit number',
              ),
              _buildFormField(
                controller: _countryController,
                label: 'Country',
                icon: Icons.flag,
                readOnly: true,
                onTap: () => _showCountryPicker(),
              ),
              _buildDropdownField(
                label: 'Language',
                icon: Icons.language,
                value: _selectedLanguage,
                items: _languages,
                onChanged: (value) => setState(() => _selectedLanguage = value),
                validator: (value) => value == null ? 'Please select a language' : null,
              ),
              _buildDropdownField(
                label: 'Tag',
                icon: Icons.tag,
                value: _selectedTag,
                items: _tags,
                onChanged: (value) => setState(() => _selectedTag = value),
                validator: (value) => value == null ? 'Please select a tag' : null,
              ),
              _buildFormField(
                controller: _mottoController,
                label: 'Team Motto',
                icon: Icons.format_quote,
              ),
              SizedBox(height: 16),
              _buildImageSection(true),
              _buildImageSection(false),
              SizedBox(height: 24),
              // Replace the existing ElevatedButton in _submitForm with this new implementation:

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1976D2),  // Dark blue from your existing colors
                      Color(0xFF2196F3),  // Light blue accent from your colors
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    'Create Voice Room',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
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

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      countryListTheme: CountryListThemeData(
        borderRadius: BorderRadius.circular(12),
        inputDecoration: InputDecoration(
          labelText: 'Search country',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          selectedCountry = country;
          _countryController.text = country.name;
        });
      },
    );
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

// Add this function to fetch the Admin badge
  Future<String?> _getAdminBadge() async {
    try {
      final response = await http.get(
        Uri.parse('http://145.223.21.62:8090/api/collections/badges/records'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final badges = data['items'] as List;

        // Find the Admin badge
        final adminBadge = badges.firstWhere(
              (badge) => badge['badgeName'] == 'admin',
          orElse: () => null,
        );

        if (adminBadge != null) {
          return adminBadge['id'];
        }
      }
      return null;
    } catch (e) {
      print('Error fetching admin badge: $e');
      return null;
    }
  }

// Add this function to create a received badge record
  Future<void> _createReceivedBadge(String userId, String badgeName) async {
    try {
      final response = await http.post(
        Uri.parse('http://145.223.21.62:8090/api/collections/recieved_badges/records'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'batch_name': badgeName,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create received badge');
      }
    } catch (e) {
      print('Error creating received badge: $e');
      throw e;
    }
  }

// Update your _submitForm function to include badge handling
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (groupPhoto == null) {
      _showErrorSnackBar('Please select a group photo');
      return;
    }

    setState(() => isLoading = true);
    _formKey.currentState!.save();

    try {
      // First, get the Admin badge ID
      final adminBadgeId = await _getAdminBadge();
      if (adminBadgeId == null) {
        throw Exception('Admin badge not found');
      }

      // Create voice room
      final uri = Uri.parse('http://145.223.21.62:8090/api/collections/voiceRooms/records');
      final request = http.MultipartRequest('POST', uri);

      request.fields.addAll({
        'voice_room_name': _roomNameController.text,
        'voiceRoom_id': _roomIdController.text,
        'voiceRoom_country': _countryController.text,
        'team_moto': _mottoController.text,
        'tag': _selectedTag ?? '',
        'ownerId': ownerId ?? '',
        'language': _selectedLanguage ?? '',
      });

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
        // Create received badge record for the user
        await _createReceivedBadge(ownerId!, 'Admin');

        _showSuccessSnackBar('Voice room created successfully!');

        final prefs = await SharedPreferences.getInstance();
        final username = prefs.getString('firstName') ?? '';
        final userId = prefs.getString('userId') ?? '';

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
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: accentColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}