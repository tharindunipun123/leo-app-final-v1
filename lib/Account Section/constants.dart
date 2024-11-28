import 'package:flutter/material.dart';

const kPrimaryColor = Color(0xFF3DB6EB);
const kTextColor = Color(0xFF080808);
const kAltTextColor = Color(0xFF424242);
const kLighterText2Color = Color(0xFF828282);
const kLighterTextColor = Color(0xFF666666);
const kLightBlueColor = Color(0xFFF7FAFF);
const kGrayShade1 = Color(0xFFF5F5F5);
const kWhiteColor = Color(0xFFFFFFFF);
const kAppBarColor = Color(0xFFFCFCFC);
const kSeperatorColor = Color(0xFFF2F2F2);
const kNeutralGray400 = Color(0xFFCBCBCB);
const kDarkTextColor = Color(0xFFd9d9d9);

const bool darkModeEnabled = false;

OutlineInputBorder kInputEnabledBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(8.0),
  borderSide: const BorderSide(
    color: kNeutralGray400,
  ),
);
OutlineInputBorder kInputFocusedBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(8.0),
  borderSide: const BorderSide(
    color: kPrimaryColor,
  ),
);

OutlineInputBorder kInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(8.0),
);

enum LayoutMode {
  defaultLayout,
  full,
  horizontal,
  vertical,
  hostTopCenter,
  hostCenter,
  fourPeoples,
}

extension LayoutModeExtension on LayoutMode {
  String get text {
    final mapValues = {
      LayoutMode.defaultLayout: 'default',
      LayoutMode.full: 'full',
      LayoutMode.horizontal: 'horizontal',
      LayoutMode.vertical: 'vertical',
      LayoutMode.hostTopCenter: 'host top center',
      LayoutMode.hostCenter: 'host center',
      LayoutMode.fourPeoples: 'four peoples',
    };

    return mapValues[this]!;
  }
}