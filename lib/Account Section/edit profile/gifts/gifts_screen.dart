import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/body_container.dart';

import '../../constants.dart';
import '../widgets/back_button.dart';
import '../widgets/gift_grid_item.dart';
import '../widgets/top_contributor.dart';

class GiftsScreen extends StatelessWidget {
  const GiftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(),
      ),
      body: BodyContainer(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/ic-gift.svg',
                  width: 80.w,
                  height: 80.w,
                ),
                SizedBox(
                  width: 10.w,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '63,859',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: darkModeEnabled ? kDarkTextColor : kTextColor,
                      ),
                    ),
                    Text(
                      'Over 98% of users',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.normal,
                        color: darkModeEnabled ? kDarkTextColor : kTextColor,
                      ),
                    ),
                    SizedBox(
                      height: 5.w,
                    ),
                    const TopContributor(
                      name: 'gihanlf',
                      image: 'assets/images/avatar.png',
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: 30.w,
            ),
            Text(
              'Gifts Display',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 16.sp,
                color: kPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: 20.w,
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.74,
                ),
                itemCount: 25,
                itemBuilder: (context, index) {
                  return const GiftGridItem(
                    icon: 'assets/icons/ic-gifticon.svg',
                    text: 'x125',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
