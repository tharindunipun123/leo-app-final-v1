import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants.dart';

class VoiceRoomItem extends StatelessWidget {
  const VoiceRoomItem({
    super.key,
    required this.image,
    required this.text,
  });

  final String image;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10.w),
          child: Image.asset(
            image,
            width: 100.w,
            height: 80.w,
            fit: BoxFit.cover,
          ),
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
