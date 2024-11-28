import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants.dart';
import '../theme.dart';

class GenderSelectorDialog extends StatelessWidget {
  const GenderSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            onTap: () {
              Navigator.pop(context);
            },
            titleAlignment: ListTileTitleAlignment.center,
            title: Text(
              'Male',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: darkModeEnabled ? kDarkTextColor : kTextColor,
              ),
            ),
          ),
          ListTile(
            onTap: () {
              Navigator.pop(context);
            },
            titleAlignment: ListTileTitleAlignment.center,
            title: Text(
              'Female',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: darkModeEnabled ? kDarkTextColor : kTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
