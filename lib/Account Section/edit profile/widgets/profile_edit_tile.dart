import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants.dart';

class ProfileEditTile extends StatelessWidget {
  const ProfileEditTile({
    super.key,
    required this.text,
    required this.icon,
    required this.endWidget,
    required this.onTap,
  });

  final String text;
  final String icon;
  final Widget endWidget;
  final GestureTapCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 10.0,
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              colorFilter: const ColorFilter.mode(
                  darkModeEnabled ? kDarkTextColor : kTextColor,
                  BlendMode.srcIn),
            ),
            SizedBox(
              width: 15.w,
            ),
            Text(
              text,
              style: TextStyle(
                fontSize: 16.sp,
                color: darkModeEnabled ? kDarkTextColor : kTextColor,
              ),
            ),
            const Spacer(),
            endWidget,
          ],
        ),
      ),
    );
  }
}
