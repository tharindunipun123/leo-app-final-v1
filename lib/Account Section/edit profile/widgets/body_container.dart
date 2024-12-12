import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BodyContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool enableScroll;

  const BodyContainer({
    Key? key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.enableScroll = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (enableScroll) {
      content = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: content,
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
     // color: darkModeEnabled ? kDarkBgColor : kBgColor,
      child: SafeArea(
        child: Padding(
          padding: padding,
          child: content,
        ),
      ),
    );
  }
}