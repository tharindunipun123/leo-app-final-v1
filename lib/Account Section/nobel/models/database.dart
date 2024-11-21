// 
class databases {
  final int id;
  final int count;
  bool done;

  databases({
    required this.id,
    required this.count,
    this.done = false,
  });

  factory databases.fromMap(Map<String, dynamic> databasesMap) {
    return databases(
      id: databasesMap['senderId'],
      count: databasesMap['totalGiftCount'],
    );
  }

  void toggle() {
    done = !done;
  }
}
