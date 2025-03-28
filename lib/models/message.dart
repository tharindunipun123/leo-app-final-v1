class Message {
  final String messageId;
  final String senderId;
  final String message;
  final String receiverId;
  final int timestamp;
  bool delivered;
  bool read;
  final String messageType;
  final String? fileName;
  final String? fileUrl;

  final String? statusId;
  final String? statusType;
  final String? statusContent;
  final String? statusFileUrl;

  // Broadcast message fields
  bool isBroadcast;
  bool isAdminMessage;
  // Deletion fields
  bool? deletedForEveryone;
  List<String>? deletedForUsers;

  Message({
    required this.messageId,
    required this.senderId,
    required this.message,
    required this.receiverId,
    required this.timestamp,
    this.delivered = false,
    this.read = false,
    required this.messageType,
    this.fileName,
    this.fileUrl,
    this.statusId,
    this.statusType,
    this.statusContent,
    this.statusFileUrl,
    this.isBroadcast = false,
    this.deletedForEveryone,
    this.deletedForUsers,
    this.isAdminMessage = false,
  });

  // Check if message is deleted for a specific user
  bool isDeletedFor(String userId) {
    return deletedForUsers?.contains(userId) ?? false;
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    // Parse deletedForUsers if it exists
    List<String>? deletedForUsers;
    if (json['deletedForUsers'] != null) {
      deletedForUsers = List<String>.from(json['deletedForUsers']);
    }

    return Message(
      messageId: json['messageId'] ?? '',
      senderId: json['senderId'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      delivered: json['delivered'] ?? false,
      read: json['read'] ?? false,
      messageType: json['messageType'] ?? 'text',
      fileName: json['fileName'],
      fileUrl: json['fileUrl'],
      receiverId: json['receiverId'] ?? '',
      statusId: json['statusId'],
      statusType: json['statusType'],
      statusContent: json['statusContent'],
      statusFileUrl: json['statusFileUrl'],
      isBroadcast: json['isBroadcast'] ?? false,
      deletedForEveryone: json['deletedForEveryone'],
      deletedForUsers: deletedForUsers,
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'delivered': delivered,
      'read': read,
      'messageType': messageType,
      'isBroadcast': isBroadcast,
    };

    // Add optional fields only if they're not null
    if (fileName != null) map['fileName'] = fileName!;
    if (fileUrl != null) map['fileUrl'] = fileUrl!;
    if (statusId != null) map['statusId'] = statusId!;
    if (statusType != null) map['statusType'] = statusType!;
    if (statusContent != null) map['statusContent'] = statusContent!;
    if (statusFileUrl != null) map['statusFileUrl'] = statusFileUrl!;

    if (deletedForEveryone != null)
      map['deletedForEveryone'] = deletedForEveryone!;
    if (deletedForUsers != null) map['deletedForUsers'] = deletedForUsers!;

    return map;
  }
}
