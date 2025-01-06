// Create a new file called minimized_state.dart
import 'package:flutter/material.dart';

class MinimizedRoomState extends ChangeNotifier {
  static final MinimizedRoomState _instance = MinimizedRoomState._internal();
  factory MinimizedRoomState() => _instance;
  MinimizedRoomState._internal();

  bool _isMinimized = false;
  String? _roomId;
  String? _groupPhotoUrl;
  String? _roomName;
  bool? _isHost;
  String? _username;
  String? _userId;
  Offset _position = const Offset(20, 100);

  bool get isMinimized => _isMinimized;
  String? get roomId => _roomId;
  String? get groupPhotoUrl => _groupPhotoUrl;
  String? get roomName => _roomName;
  bool? get isHost => _isHost;
  String? get username => _username;
  String? get userId => _userId;
  Offset get position => _position;

  void minimize({
    required String roomId,
    required String groupPhotoUrl,
    required String roomName,
    required bool isHost,
    required String username,
    required String userId,
  }) {
    _isMinimized = true;
    _roomId = roomId;
    _groupPhotoUrl = groupPhotoUrl;
    _roomName = roomName;
    _isHost = isHost;
    _username = username;
    _userId = userId;
    notifyListeners();
  }

  void maximize() {
    _isMinimized = false;
    _roomId = null;
    _groupPhotoUrl = null;
    _roomName = null;
    _isHost = null;
    _username = null;
    _userId = null;
    notifyListeners();
  }

  void updatePosition(Offset newPosition) {
    _position = newPosition;
    notifyListeners();
  }
}