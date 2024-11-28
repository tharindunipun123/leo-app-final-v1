import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants.dart';

class GiftItem extends StatelessWidget {
  const GiftItem({
    super.key,
    required this.text,
    required this.icon,
  });

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SvgPicture.asset(
          icon,
          width: 50.w,
        ),
        SizedBox(
          height: 5.w,
        ),
        Text(
          text,
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: 12.sp,
            color: darkModeEnabled ? kDarkTextColor : kLighterTextColor,
          ),
        ),
      ],
    );
  }
}
