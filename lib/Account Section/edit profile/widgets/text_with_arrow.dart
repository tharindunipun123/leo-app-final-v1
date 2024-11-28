import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants.dart';

class TextWithArrow extends StatelessWidget {
  const TextWithArrow({
    super.key,
    required this.text,
    this.showArrow = true,
  });

  final String text;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 14.sp,
            color: kLighterText2Color,
            fontWeight: FontWeight.w400,
          ),
        ),

        if (showArrow) ...[
          SizedBox(
            width: 10.w,
          ),
      
          SvgPicture.asset(
            'assets/icons/ic-arrow-right.svg',
          ),
        ]
      ],
    );
  }
}
