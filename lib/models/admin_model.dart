class AdminUser {
  final String userId;
  final String name;
  final String? avatar;
  final bool isOnline;
  final int? lastSeen;
  final int unreadCount;

  AdminUser({
    required this.userId,
    required this.name,
    this.avatar,
    this.isOnline = false,
    this.lastSeen,
    this.unreadCount = 0,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      userId: json['userId'] ?? '',
      name: json['name'] ?? 'Admin',
      avatar: json['avatar'],
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'],
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'avatar': avatar,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'unreadCount': unreadCount,
    };
  }
}
