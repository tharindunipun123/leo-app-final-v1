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

  final String name;
  final String image;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: darkModeEnabled ? kDarkBoxColor : kLightBlueColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.w),
            child: Image.asset(
              image,
              width: 16.w,
              height: 16.w,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(
            width: 8.w,
          ),
          Text(
            '$name is your top contributor',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.normal,
              color: darkModeEnabled ? kDarkTextColor : kTextColor,
            ),
          ),
          SizedBox(
            width: 8.w,
          ),
        ],
      ),
    );
  }
}
