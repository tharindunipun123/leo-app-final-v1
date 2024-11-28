import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants.dart';

class AppBarBackButton extends StatelessWidget {
  const AppBarBackButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.pop(context);
      },
      icon: SvgPicture.asset(
        'assets/icons/ic-arrow-back.svg',
        colorFilter: const ColorFilter.mode(
            darkModeEnabled ? kDarkTextColor : kTextColor, BlendMode.srcIn),
      ),
    );
  }
}
