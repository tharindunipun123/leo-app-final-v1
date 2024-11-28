import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BodyContainer extends StatelessWidget {
  const BodyContainer({
    super.key,
    required this.child,
    this.enableScroll = false,
    this.padding = const EdgeInsets.all(0),
  });

  final Widget child;
  final bool enableScroll;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 1.sh,
      child: enableScroll ? SingleChildScrollView(
        padding: padding,
        child: child,
      ) : Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}