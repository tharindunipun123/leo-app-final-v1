import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme.dart';

import '../../constants.dart';

class TopContributor extends StatelessWidget {
  const TopContributor({
    super.key,
    required this.image,
    required this.name,
  });

  final String image;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: darkModeEnabled ? kDarkBoxColor : kLightBlueColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.w),
            child: image.startsWith('http')
                ? Image.network(
              image,
              width: 16.w,
              height: 16.w,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading contributor image: $error');
                return Image.asset(
                  'assets/images/avatar.png',
                  width: 16.w,
                  height: 16.w,
                  fit: BoxFit.cover,
                );
              },
            )
                : Image.asset(
              image,
              width: 16.w,
              height: 16.w,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 16.w,
                  height: 16.w,
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.person,
                    size: 12.w,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              '$name s gift Performence',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.normal,
                color: darkModeEnabled ? kDarkTextColor : kTextColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}