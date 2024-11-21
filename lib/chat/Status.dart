import 'package:flutter/material.dart';
import 'package:story_view/story_view.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Add_Status.dart';

// Constants for API
const String baseUrl = 'http://145.223.21.62:8090';

class Status {
  final String id;
  final String userId;
  final String caption;
  final String? statusImage;
  final String? statusVideo;
  final DateTime created;

  Status({
    required this.id,
    required this.userId,
    required this.caption,
    this.statusImage,
    this.statusVideo,
    required this.created,
  });

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      id: json['id'],
      userId: json['userId'],
      caption: json['caption'],
      statusImage: json['status_img'],
      statusVideo: json['status_video'],
      created: DateTime.parse(json['created']),
    );
  }

  String getImageUrl() {
    if (statusImage == null) return '';
    return '$baseUrl/api/files/Status/$id/$statusImage';
  }

  String getVideoUrl() {
    if (statusVideo == null) return '';
    return '$baseUrl/api/files/Status/$id/$statusVideo';
  }
}

class StatusPage extends StatefulWidget {
  @override
  _StatusPageState createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  final StoryController controller = StoryController();
  List<Status> statuses = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchStatuses();
  }

  Future<void> fetchStatuses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/collections/Status/records'),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          statuses = (data['items'] as List)
              .map((item) => Status.fromJson(item))
              .toList();
          isLoading = false;
          hasError = false;
        });
      } else {
        throw Exception('Failed to load statuses: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Error loading statuses: ${e.toString()}';
      });
      _showErrorSnackBar(e.toString());
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              isLoading = true;
              hasError = false;
            });
            fetchStatuses();
          },
        ),
      ),
    );
  }

  List<StoryItem> _buildStoryItems(Status status) {
    List<StoryItem> items = [];

    // Add caption as text story
    items.add(StoryItem.text(
      title: status.caption,
      backgroundColor: Colors.orange,
    ));

    // Add image if exists
    if (status.statusImage != null && status.statusImage!.isNotEmpty) {
      items.add(StoryItem.pageImage(
        url: status.getImageUrl(),
        controller: controller,
        caption: Text(
          status.caption,
          style: TextStyle(
            color: Colors.white,
            backgroundColor: Colors.black54,
            fontSize: 17,
          ),
        ),
        shown: false,
      ));
    }

    // Add video if exists
    if (status.statusVideo != null && status.statusVideo!.isNotEmpty) {
      items.add(StoryItem.pageVideo(
        status.getVideoUrl(),
        controller: controller,
        caption: Text(
          status.caption,
          style: TextStyle(
            color: Colors.white,
            backgroundColor: Colors.black54,
            fontSize: 17,
          ),
        ),
        shown: false,
      ));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Status"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
                hasError = false;
              });
              fetchStatuses();
            },
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddStatusScreen()),
              );
              if (result == true) {
                setState(() {
                  isLoading = true;
                });
                fetchStatuses();
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading statuses',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  hasError = false;
                });
                fetchStatuses();
              },
              child: Text('Retry'),
            ),
          ],
        ),
      )
          : statuses.isEmpty
          ? Center(child: Text('No statuses yet'))
          : RefreshIndicator(
        onRefresh: () async {
          await fetchStatuses();
        },
        child: ListView.builder(
          itemCount: statuses.length,
          itemBuilder: (context, index) {
            final status = statuses[index];
            return Card(
              margin: EdgeInsets.all(8),
              child: ListTile(
                leading: status.statusImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    status.getImageUrl(),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[300],
                        child: Icon(Icons.error),
                      );
                    },
                  ),
                )
                    : null,
                title: Text(status.caption),
                subtitle: Text(
                  'Posted ${_formatTimeAgo(status.created)}',
                ),
                trailing: status.statusVideo != null
                    ? Icon(Icons.play_circle_outline)
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoryViewPage(
                        storyItems: _buildStoryItems(status),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class StoryViewPage extends StatelessWidget {
  final List<StoryItem> storyItems;
  final StoryController controller = StoryController();

  StoryViewPage({required this.storyItems});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StoryView(
          storyItems: storyItems,
          controller: controller,
          onComplete: () {
            Navigator.pop(context);
          },
          onVerticalSwipeComplete: (direction) {
            if (direction == Direction.down) {
              Navigator.pop(context);
            }
          },
          progressPosition: ProgressPosition.top,
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
  }
}