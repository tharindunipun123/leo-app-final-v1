import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../constants.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.onTap,
    required this.text,
    this.borderRadius = 50,
    this.isLoading = false,
    this.color = kPrimaryColor,
    this.textColor = kWhiteColor,
  });

  final GestureTapCallback onTap;
  final String text;
  final double borderRadius;
  final bool isLoading;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius.h),
        // color: Colors.transparent,
      ),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius.h),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius.h),
          child: Container(
            // width: con.w(),
            height: 48.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius.h),
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
        ),
      ),
    );
  }
}