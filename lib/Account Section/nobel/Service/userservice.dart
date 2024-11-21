import 'dart:convert';
import 'package:http/http.dart' as http;
import 'userdata.dart';

class UserService {
  final String baseUrl;

  UserService({required this.baseUrl});

  Future<List<User>> getUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }


 Future<User> getUserById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/user/$id'));
    print('API call status code: ${response.statusCode}');
    print('API call response: ${response.body}');
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user');
    }


 }


  

  Future<User> createUser(User user) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );
    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create user');
    }
  }

  Future<User> updateUser(int id, User user) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update user');
    }
  }

  Future<void> deleteUser(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/users/$id'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete user');
    }
  }
}
