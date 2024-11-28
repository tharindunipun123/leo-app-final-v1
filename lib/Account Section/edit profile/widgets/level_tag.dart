import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme.dart';

import '../../constants.dart';

class LevelTag extends StatelessWidget {
  const LevelTag({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: darkModeEnabled ? kDarkBoxColor : kGrayShade1,
        borderRadius: BorderRadius.circular(20.w),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 5.w,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          color: darkModeEnabled ? kDarkTextColor : kLighterTextColor,
        ),
      ),
    );
  }
}
