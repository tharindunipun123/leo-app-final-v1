import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme.dart';

import '../../constants.dart';

class BadgeGridItem extends StatelessWidget {
  const BadgeGridItem({
    super.key,
    required this.text,
    required this.icon,
  });

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: darkModeEnabled ? kDarkBoxColor : kWhiteColor,
        borderRadius: BorderRadius.circular(10.w),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            icon,
          ),
          SizedBox(
            height: 5.w,
          ),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: darkModeEnabled ? kDarkTextColor : kLighterTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
