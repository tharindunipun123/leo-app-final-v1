import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../constants.dart';

class OutlineButton extends StatelessWidget {
  const OutlineButton({
    super.key,
    required this.onTap,
    required this.text,
    this.borderRadius = 50,
    this.isLoading = false,
    this.color = kPrimaryColor,
    this.textColor = kPrimaryColor,
  });

  final GestureTapCallback onTap;
  final String text;
  final double borderRadius;
  final bool isLoading;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius.h),
      child: Container(
        height: 48.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius.h),
          border: Border.all(
            color: color,
          ),
          color: Colors.transparent,
        ),
        alignment: Alignment.center,
        child: isLoading
        ? CircularProgressIndicator(
          color: textColor,
        )
        : Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        )
      ),
    );
  }
}