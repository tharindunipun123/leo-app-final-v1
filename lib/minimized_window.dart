// Create a new file called minimized_window.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MinimizedWindow extends StatelessWidget {
  final String roomId;
  final String groupPhotoUrl;
  final String roomName;
  final bool isHost;
  final String username;
  final String userId;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final Offset position;
  final Function(Offset) onPositionChanged;

  const MinimizedWindow({
    Key? key,
    required this.roomId,
    required this.groupPhotoUrl,
    required this.roomName,
    required this.isHost,
    required this.username,
    required this.userId,
    required this.onTap,
    required this.onClose,
    required this.position,
    required this.onPositionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Positioned(
        left: position.dx,
        top: position.dy,
        child: GestureDetector(
          onTap: onTap,
          child: Draggable(
            feedback: _buildContent(context),
            childWhenDragging: Container(),
            child: _buildContent(context),
            onDragEnd: (details) {
              // Ensure the window stays within screen bounds
              final screen = MediaQuery.of(context).size;
              final width = screen.width;
              final height = screen.height;

              double newX = details.offset.dx;
              double newY = details.offset.dy;

              if (newX < 0) newX = 0;
              if (newX > width - 90) newX = width - 90;
              if (newY < 0) newY = 0;
              if (newY > height - 90) newY = height - 90;

              onPositionChanged(Offset(newX, newY));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(45),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: CachedNetworkImage(
                    imageUrl: groupPhotoUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.image, color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.error, color: Colors.white),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                roomName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Positioned(
            right: -6,
            top: -6,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Center(
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}