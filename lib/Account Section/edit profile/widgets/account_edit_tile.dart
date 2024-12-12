import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants.dart';

class AccountTile extends StatelessWidget {
  const AccountTile({
    super.key,
    required this.text,
    required this.icon,
    required this.endWidget,
    required this.onTap,
  });

  final String text;
  final IconData icon;
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
            Icon(
              icon,
              color: darkModeEnabled ? kDarkTextColor : kTextColor,
              grade: 200,
              weight: 600,
            ),
        
            SizedBox(
              width: 15.w,
            ),
        
            Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                color: darkModeEnabled ? kDarkTextColor : kTextColor,
                fontWeight: FontWeight.bold,
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