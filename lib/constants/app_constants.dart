class AppConstants {
  // Server URL - Change this to your server address
  static const String serverUrl =
      'http://82.25.180.4:4000'; // For Android emulator

  // For iOS simulator, use:
  // static const String serverUrl = 'http://localhost:3000';

  // Message types
  static const String messageTypeText = 'text';
  static const String messageTypeImage = 'image';
  static const String messageTypeVideo = 'video';
  static const String messageTypeDocument = 'document';
  static const String messageTypeAudio = 'audio';

  // UI Constants
  static const double messageBubbleRadius = 16.0;
  static const double chatInputHeight = 60.0;

  // File upload endpoint
  static String get fileUploadUrl => '$serverUrl/upload';

  //Test users for demo
  // static const List<String> testUsers = [
  //   'user5',
  //   'user6',
  //   'user7',
  //   'user8',
  //   'mt2efg6pqk4eysg',
  //   'tialt8tmiab76a6',
  //   'bmjsc6jg8znd3as',
  // ];

  static const List<String> adminUsers = [
    'mt2efg6pqk4eysg',
    'tialt8tmiab76a6',
    'bmjsc6jg8znd3as',
  ];
  static bool isAdmin(String userId) {
    return adminUsers.contains(userId);
  }

  // ///zegocloud appID
  // static const int appID = 1793152448;

  // ///zegocloud appSign
  // static const String appSign =
  //     'b0e180830429a7eedf06658a004e21a9b4dfbebf9a5af9234f9a94ceba0ad93b';
}
