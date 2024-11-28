import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../constants.dart';

class StatsBox extends StatelessWidget {
  const StatsBox({
    super.key,
    required this.text,
    required this.value,
  });

  final String text;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 16.sp,
            color: darkModeEnabled ? kDarkTextColor : kTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
    
        Text(
          text,
          style: TextStyle(
            fontSize: 12.sp,
            color: darkModeEnabled ? kDarkTextColor : kTextColor,
          ),
        ),
      ],
    );
  }
}