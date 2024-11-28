import 'dart:convert';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'theme.dart';
import 'widgets/body_container.dart';
import 'widgets/gender_selector_dialog.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../constants.dart';
import 'widgets/back_button.dart';
import 'widgets/profile_edit_tile.dart';
import 'widgets/text_with_arrow.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  final String userId;
  final String name;
  const EditProfileScreen(
      {super.key, required this.name, required this.userId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  DateTime selectedDate = DateTime.now();
  final picker = ImagePicker();
  XFile? file;
  Country? selectedCountry;

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(1900, 1),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      updateBirthday(selectedDate);
    }
  }

  Future<void> updateBirthday(DateTime birthday) async {
    try {
      var url = 'http://45.126.125.172:8080/api/v1/partialUpdateProfile';
      var headers = {'Content-Type': 'application/json'};

      // Format birthday to 'YYYY-MM-DD' string
      var formattedBirthday =
          '${birthday.year}-${birthday.month.toString().padLeft(2, '0')}-${birthday.day.toString().padLeft(2, '0')}';

      var body = {
        'userId': widget.userId, // Replace with your user ID
        'birthday': formattedBirthday,
      };

      var response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('Birthday updated successfully: $formattedBirthday');
        // Handle success, e.g., show a dialog or update local state
      } else {
        print('Failed to update birthday: ${response.statusCode}');
        // Handle failure, e.g., show an error message
      }
    } catch (e) {
      print('Error updating birthday: $e');
      // Handle any exceptions thrown during the HTTP request
    }
  }

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    XFile? pickedFile;

    try {
      pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        // Rename the image file
        String newFileName = 'new_image_name.jpg';
        final directory = await getApplicationDocumentsDirectory();
        String newFilePath = join(directory.path, newFileName);
        File newImageFile = await File(pickedFile.path).copy(newFilePath);

        // Upload the renamed image file
        await uploadImage(newImageFile);
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> uploadImage(File imageFile) async {
    var uri = Uri.parse('http://45.126.125.172:8080/api/v1/updateProfile');
    var request = http.MultipartRequest('POST', uri);
    request.files
        .add(await http.MultipartFile.fromPath('file', imageFile.path));
    var response = await request.send();

    if (response.statusCode == 200) {
      print('Image uploaded successfully');
    } else {
      print('Image upload failed with status: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(),
        centerTitle: true,
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 16.sp,
            color: darkModeEnabled ? kDarkTextColor : kTextColor,
          ),
        ),
      ),
      body: BodyContainer(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Material(
              color: darkModeEnabled ? kDarkBoxColor : kLightBlueColor,
              borderRadius: BorderRadius.circular(10.w),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 20.0, horizontal: 10.0),
                child: Column(
                  children: [
                    ProfileEditTile(
                      icon: 'assets/icons/ic-user.svg',
                      text: 'Avatar',
                      onTap: () async {
                        pickAndUploadImage();
                      },
                      endWidget: ClipRRect(
                        borderRadius: BorderRadius.circular(10.w),
                        child: Image.asset(
                          'assets/images/avatar.png',
                          width: 20.w,
                          height: 20.w,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const Divider(
                      color: kSeperatorColor,
                      indent: 20.0,
                      endIndent: 20.0,
                    ),
                    ProfileEditTile(
                      icon: 'assets/icons/ic-image.svg',
                      text: 'Cover',
                      onTap: () async {
                        //await getImageFromCamera();
                      },
                      endWidget: Image.asset(
                        'assets/images/room.png',
                        width: 40.w,
                        height: 20.w,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 20.w,
            ),
            Material(
              color: darkModeEnabled ? kDarkBoxColor : kLightBlueColor,
              borderRadius: BorderRadius.circular(10.w),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 20.0, horizontal: 10.0),
                child: Column(
                  children: [
                    ProfileEditTile(
                      icon: 'assets/icons/ic-user.svg',
                      text: 'Name',
                      onTap: () {
                        Navigator.pushNamed(context, 'edit-name');
                      },
                      endWidget: TextWithArrow(
                        text: widget.name,
                      ),
                    ),
                    const Divider(
                      color: kSeperatorColor,
                      indent: 20.0,
                      endIndent: 20.0,
                    ),
                    ProfileEditTile(
                      icon: 'assets/icons/ic-info.svg',
                      text: 'ID',
                      onTap: () {},
                      endWidget: TextWithArrow(
                        text: widget.userId,
                        showArrow: false,
                      ),
                    ),
                    const Divider(
                      color: kSeperatorColor,
                      indent: 20.0,
                      endIndent: 20.0,
                    ),
                    ProfileEditTile(
                      icon: 'assets/icons/ic-users.svg',
                      text: 'Gender',
                      onTap: () {
                        showDialog(
                          context: context,
                          useSafeArea: true,
                          builder: (BuildContext context) {
                            return const AlertDialog(
                              surfaceTintColor: Colors.transparent,
                              content: GenderSelectorDialog(),
                            );
                          },
                        );
                      },
                      endWidget: const TextWithArrow(
                        text: 'Male',
                      ),
                    ),
                    const Divider(
                      color: kSeperatorColor,
                      indent: 20.0,
                      endIndent: 20.0,
                    ),
                    ProfileEditTile(
                      icon: 'assets/icons/ic-flag.svg',
                      text: 'Country',
                      onTap: () {
                        showCountryPicker(
                          context: context,
                          showPhoneCode: false,
                          onSelect: (Country country) {
                            _saveCountryToDatabase(country);
                          },
                        );
                      },
                      endWidget: const TextWithArrow(
                        text: 'Sri Lanka',
                      ),
                    ),
                    const Divider(
                      color: kSeperatorColor,
                      indent: 20.0,
                      endIndent: 20.0,
                    ),
                    ProfileEditTile(
                      icon: 'assets/icons/ic_calendar.svg',
                      text: 'Birthday',
                      onTap: () {
                        selectDate(context);
                      },
                      endWidget: const TextWithArrow(
                        text: '1997-05-28',
                      ),
                    ),
                    const Divider(
                      color: kSeperatorColor,
                      indent: 20.0,
                      endIndent: 20.0,
                    ),
                    ProfileEditTile(
                      icon: 'assets/icons/ic-list.svg',
                      text: 'Bio',
                      onTap: () {
                        Navigator.pushNamed(context, 'edit-bio');
                      },
                      endWidget: const TextWithArrow(
                        text: '',
                      ),
                    ),
                    const Divider(
                      color: kSeperatorColor,
                      indent: 20.0,
                      endIndent: 20.0,
                    ),
                    ProfileEditTile(
                      icon: 'assets/icons/ic-motto.svg',
                      text: 'Motto',
                      onTap: () {
                        Navigator.pushNamed(context, 'edit-motto');
                      },
                      endWidget: const TextWithArrow(
                        text: '',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCountryToDatabase(Country country) async {
    try {
      var url = 'http://45.126.125.172:8080/api/v1/partialUpdateProfile';
      var headers = {
        'Content-Type': 'application/json',
      };
      var body = {
        'userId': widget.userId, // Replace with actual user ID
        'country': country.name, // or any field according to your API
      };

      var response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('Country updated successfully: ${country.displayName}');
        // Handle success scenario (e.g., show confirmation to user)
      } else {
        print('Failed to update country: ${response.statusCode}');
        // Handle error scenario
      }
    } catch (e) {
      print('Error updating country: $e');
      // Handle network or other errors
    }
  }
}
