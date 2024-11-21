import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, String>> fetchCountdown() async {
  final response = await http.get(Uri.parse('http://172.20.10.2:6060/api/time/countdown'));

  if (response.statusCode == 200) {
    return Map<String, String>.from(json.decode(response.body));
  } else {
    throw Exception('Failed to load countdown');
  }
}
