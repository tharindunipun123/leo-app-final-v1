import 'dart:convert';
import 'package:http/http.dart' as http;

class User {
  final String id;
  final String firstname;
  final String lastname;
  final int phonenumber;
  final String moto;
  final String bio;
  final int wallet;
  final String country;
  final String gender;
  final DateTime birthday;
  final bool is_notification_off;
  final String player_id;
  final bool is_admin;

  User({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.phonenumber,
    required this.moto,
    required this.bio,
    required this.wallet,
    required this.country,
    required this.gender,
    required this.birthday,
    required this.is_notification_off,
    required this.player_id,
    required this.is_admin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      phonenumber: json['phonenumber'],
      moto: json['moto'],
      bio: json['bio'],
      wallet: json['wallet'],
      country: json['country'],
      gender: json['gender'],
      birthday: DateTime.parse(json['birthday']),
      is_notification_off: json['is_notification_off'],
      player_id: json['player_id'],
      is_admin: json['is_admin'],
    );
  }
}

class UserApiService {
  final String baseUrl;

  UserApiService({required this.baseUrl});

  Future<User> getUserById(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/collections/users/records/$id'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          'Failed to load user with ID: $id. Status code: ${response.statusCode}');
    }
  }

  // Additional methods that could be implemented:

  Future<List<User>> getAllUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/collections/users/records'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> items = data['items'];
      return items.map((item) => User.fromJson(item)).toList();
    } else {
      throw Exception(
          'Failed to load users. Status code: ${response.statusCode}');
    }
  }

  Future<User> createUser(Map<String, dynamic> userBody) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/collections/users/records'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(userBody),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          'Failed to create user. Status code: ${response.statusCode}');
    }
  }

  Future<User> updateUser(String id, Map<String, dynamic> userBody) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/collections/users/records/$id'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(userBody),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
          'Failed to update user with ID: $id. Status code: ${response.statusCode}');
    }
  }

  Future<void> deleteUser(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/collections/users/records/$id'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 204) {
      throw Exception(
          'Failed to delete user with ID: $id. Status code: ${response.statusCode}');
    }
  }
}

// Example usage:
// void main() async {
//   final userApiService = UserApiService(baseUrl: 'http://145.223.21.62:8090');

//   try {
//     // Get user by ID
//     final user = await userApiService.getUserById('USER_ID_HERE');
//     print('User: ${user.firstname} ${user.lastname}');

//     // Create a new user
//     final newUserBody = <String, dynamic>{
//       "firstname": "John",
//       "lastname": "Doe",
//       "phonenumber": 1234567890,
//       "moto": "Live life to the fullest",
//       "bio": "Flutter developer",
//       "wallet": 100,
//       "country": "USA",
//       "gender": "male",
//       "birthday": "1990-01-01 10:00:00.123Z",
//       "is_notification_off": false,
//       "player_id": "player123",
//       "is_admin": false
//     };
//     final newUser = await userApiService.createUser(newUserBody);
//     print('New user created with ID: ${newUser.id}');
//   } catch (e) {
//     print('Error: $e');
//   }
// }
