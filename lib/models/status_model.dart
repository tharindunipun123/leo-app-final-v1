class Status {
  final String statusId;
  final String userId;
  final String statusType; // 'text', 'image', 'video'
  final String content; // Text or caption
  final String? fileUrl; // For media
  final String? fileName; // For media
  final int timestamp;
  final int expiresAt;

  Status({
    required this.statusId,
    required this.userId,
    required this.statusType,
    required this.content,
    this.fileUrl,
    this.fileName,
    required this.timestamp,
    required this.expiresAt,
  });

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      statusId: json['statusId'],
      userId: json['userId'],
      statusType: json['statusType'],
      content: json['content'],
      fileUrl: json['fileUrl'],
      fileName: json['fileName'],
      timestamp: int.parse(json['timestamp']),
      expiresAt: int.parse(json['expiresAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusId': statusId,
      'userId': userId,
      'statusType': statusType,
      'content': content,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'timestamp': timestamp.toString(),
      'expiresAt': expiresAt.toString(),
    };
  }
}

class StatusUser {
  final String userId;
  final int statusCount;
  final Map<String, dynamic> latestStatus;

  StatusUser({
    required this.userId,
    required this.statusCount,
    required this.latestStatus,
  });

  factory StatusUser.fromJson(Map<String, dynamic> json) {
    return StatusUser(
      userId: json['userId'],
      statusCount: json['statusCount'],
      latestStatus: json['latestStatus'],
    );
  }
}
